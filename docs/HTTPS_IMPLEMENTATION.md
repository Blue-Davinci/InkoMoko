# HTTPS Implementation Guide for InkoMoko

## Overview
This guide explains how to implement production-ready HTTPS with SSL/TLS certificates for the InkoMoko application using AWS Certificate Manager (ACM).

> **⚠️ Important**: HTTPS requires a custom domain. You cannot use HTTPS with ALB DNS names like `my-alb-123.elb.amazonaws.com`. For immediate testing, use HTTP-only mode.

## Prerequisites

### 1. Domain Requirements (MANDATORY for HTTPS)
- **Domain Name**: You must own a domain (e.g., `inkomoko.com`)
- **Route53 Hosted Zone**: Required for automatic certificate validation
- **DNS Delegation**: Domain nameservers must point to Route53

### 2. Current Setup Options

| Setup Type | Domain Required | SSL Certificate | Access Method |
|------------|----------------|-----------------|---------------|
| **HTTP-only** | ❌ No | ❌ No | `http://alb-dns-name` |
| **HTTPS** | ✅ Yes | ✅ Auto (ACM) | `https://yourdomain.com` |

## Quick Start Decision Tree

```
Do you have a custom domain?
├── NO  → Use HTTP-only mode (current setup)
│        → Deploy immediately and test
│        → Add HTTPS later when you get a domain
│
└── YES → Continue with HTTPS setup below
         → Get Route53 hosted zone
         → Follow implementation steps
```

## HTTP-Only Setup (Current Default)

If you don't have a domain yet, you can deploy and test immediately:

### 1. Deploy Current Configuration
```bash
cd depoyment/terraform/environments/dev
terraform apply plan.out
```

### 2. Test HTTP Access
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl http://$ALB_DNS/health

# Expected response: {"status": "ok", "timestamp": "..."}
```

### 3. Access Your Application
- ✅ **Works immediately**: `http://your-alb-dns-name`
- ❌ **HTTPS will fail**: Certificate errors in browser
- 🔄 **Easy upgrade**: Add domain later for HTTPS

---

## HTTPS Setup (Requires Domain)

## Implementation Steps

### Step 1: Update Your Environment Configuration

Update your environment-specific Terraform files (e.g., `environments/dev/main.tf`):

```hcl
module "alb" {
  source = "../../modules/alb"

  # Basic ALB Configuration
  alb_name               = "inkomoko-dev-alb"
  vpc_id                 = module.networking.vpc_id
  subnet_ids             = module.networking.public_subnet_ids
  enable_alb_deletion    = false

  # HTTPS Configuration
  enable_https               = true
  domain_name               = "api-dev.inkomoko.com"
  subject_alternative_names = ["dev.inkomoko.com"]
  route53_zone_id           = "Z1234567890ABC"  # Your Route53 zone ID
  create_www_redirect       = true

  tags = local.tags
}
```

### Step 2: DNS Configuration

1. **Create Route53 Hosted Zone** (if not exists):
   ```bash
   aws route53 create-hosted-zone \
     --name inkomoko.com \
     --caller-reference $(date +%s)
   ```

2. **Update Domain Nameservers**:
   - Copy the nameservers from Route53 hosted zone
   - Update your domain registrar's nameserver settings

### Step 3: Certificate Validation

The Terraform configuration will:
1. Create an ACM certificate
2. Add DNS validation records to Route53
3. Wait for certificate validation
4. Configure ALB with the validated certificate

### Step 4: Docker Image Configuration

Update your environment variables to use the latest image:

```hcl
module "compute" {
  source = "../../modules/compute"

  # ... other configuration ...

  docker_image_url = "ghcr.io/blue-davinci/inkomoko"  # Will pull latest tag
}
```

## Security Best Practices

### 1. SSL/TLS Configuration
- **TLS Version**: Uses `ELBSecurityPolicy-TLS-1-2-2017-01` (configurable)
- **Certificate Type**: RSA 2048-bit (ACM default)
- **Validation**: DNS validation (automated)

### 2. HTTPS Redirection
- All HTTP traffic (port 80) redirects to HTTPS (port 443)
- Uses 301 permanent redirect for SEO benefits

### 3. Security Headers
The nginx configuration includes:
```nginx
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

### 4. Rate Limiting
```nginx
limit_req_zone $remote_addr zone=api_limit:10m rate=10r/s;
limit_req zone=api_limit burst=20 nodelay;
```

## Monitoring and Logging

### 1. CloudWatch Integration
- Container logs automatically sent to CloudWatch
- Log retention: 7 days (configurable)
- Log groups:
  - `/aws/ec2/inkomoko` - Application logs
  - `/aws/ec2/user-data` - Deployment logs

### 2. Health Checks
- ALB health check: `/health` endpoint
- Health check interval: 30 seconds
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 3 consecutive failures

## Deployment Process

### 1. Infrastructure Deployment
```bash
cd depoyment/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Certificate Validation
- ACM certificate creation: ~2-5 minutes
- DNS validation: ~5-10 minutes
- Total setup time: ~10-15 minutes

### 3. Application Deployment
- Docker image pulled automatically during EC2 launch
- Auto Scaling Group ensures high availability
- Rolling updates via ASG launch template

## Production Considerations

### 1. Environment Separation
- **Development**: `api-dev.inkomoko.com`
- **Staging**: `api-staging.inkomoko.com`
- **Production**: `api.inkomoko.com`

### 2. Certificate Management
- ACM handles automatic renewal (60 days before expiry)
- No manual intervention required
- Validation records remain in Route53

### 3. Backup Domain Strategy
```hcl
subject_alternative_names = [
  "api-backup.inkomoko.com",
  "www.api.inkomoko.com"
]
```

### 4. Multi-Region Setup
For production resilience:
- Primary region: us-east-1
- Secondary region: us-west-2
- Route53 health checks for failover

## Troubleshooting

### Common Issues

1. **Certificate Validation Timeout**
   - Check Route53 hosted zone ID
   - Verify nameserver delegation
   - Wait up to 10 minutes for DNS propagation

2. **ALB Health Check Failures**
   - Verify `/health` endpoint returns 200
   - Check security group allows ALB to EC2 communication
   - Review CloudWatch logs for application errors

3. **Docker Image Pull Failures**
   - Verify image exists in registry
   - Check IAM permissions for ECR access
   - Review user-data logs in CloudWatch

### Monitoring Commands
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <cert-arn>

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Check application logs
aws logs tail /aws/ec2/inkomoko --follow
```

## Cost Optimization

### 1. Certificate Costs
- ACM certificates: **FREE**
- Route53 hosted zone: **$0.50/month**
- DNS queries: **$0.40/million queries**

### 2. ALB Costs
- ALB base cost: **~$16/month**
- Load Balancer Capacity Units (LCU): **$0.008/hour**

### 3. Monitoring Costs
- CloudWatch Logs: **$0.50/GB ingested**
- Log retention: 7 days (minimal cost)

## Next Steps

1. **WAF Integration**: Add AWS WAF for advanced security
2. **CloudFront**: Add CDN for global performance
3. **Monitoring**: Implement comprehensive monitoring with CloudWatch/Grafana
4. **Backup Strategy**: Implement automated backup solutions
5. **Disaster Recovery**: Set up multi-region deployment

## Security Checklist

- [ ] Domain validated certificate
- [ ] HTTPS-only access (HTTP redirects)
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] VPC security groups properly configured
- [ ] IAM roles follow least privilege
- [ ] CloudWatch logging enabled
- [ ] Health checks configured
- [ ] Auto Scaling configured
- [ ] Backup strategy implemented
