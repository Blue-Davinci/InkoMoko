# Quick Setup Guide for InkoMoko

## 🚀 Current Status
✅ **HTTP-only setup** - Your infrastructure is ready and working without SSL
✅ **HTTPS-ready** - SSL/TLS configuration is prepared but disabled
✅ **Latest Docker images** - Automatic deployment from GitHub Container Registry

## 1️⃣ Deploy HTTP-only (Recommended First Step)

### Why Start with HTTP?
- ✅ **Works immediately** - No domain setup required
- ✅ **Test your application** - Verify everything works before adding SSL
- ✅ **No additional cost** - HTTP testing is free
- ✅ **Easy HTTPS upgrade** - Add domain later when ready

### Deploy Now
```bash
cd depoyment/terraform/environments/dev
terraform apply plan.out
```

### Test Your Deployment
```bash
# Get your ALB URL
ALB_URL=$(terraform output -raw alb_dns_name)
echo "Your application is available at: http://$ALB_URL"

# Test health endpoint
curl http://$ALB_URL/health

# Test API endpoint
curl http://$ALB_URL/v1/
```

### What You Get
- **Load Balancer**: Highly available ALB
- **Auto Scaling**: 2-3 EC2 instances based on load
- **Latest Docker Images**: Automatically pulls from `ghcr.io/blue-davinci/inkomoko:latest`
- **CloudWatch Logging**: Full observability
- **Security Groups**: Properly configured network isolation

## 2️⃣ Add HTTPS Later (When You Have a Domain)

### Prerequisites for HTTPS
- 🌐 **Own a domain** (e.g., `example.com`)
- 📋 **Route53 hosted zone** for your domain
- 🔗 **Updated nameservers** pointing to Route53

### Quick HTTPS Activation

1. **Add variables to `terraform.tfvars`**:
```hcl
enable_https = true
domain_name = "api.yourdomain.com"  # Replace with your domain
route53_zone_id = "Z1234567890ABC"   # Your Route53 hosted zone ID
```

2. **Update `main.tf`**:
```hcl
module "alb" {
  source = "../../modules/alb"

  # Existing configuration...
  alb_name            = "my-alb-${var.environment}"
  subnet_ids          = module.networking.public_subnet_ids_list
  vpc_id              = module.networking.vpc_id
  tags                = var.tags
  enable_alb_deletion = var.enable_alb_deletion

  # Add HTTPS configuration
  enable_https     = var.enable_https
  domain_name      = var.domain_name
  route53_zone_id  = var.route53_zone_id
}
```

3. **Add variables to `variables.tf`**:
```hcl
variable "enable_https" {
  description = "Whether to enable HTTPS with SSL certificate"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The primary domain name for SSL certificate"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
  default     = ""
}
```

4. **Deploy HTTPS**:
```bash
terraform plan
terraform apply
```

## 🔄 What Happens When You Enable HTTPS

### Automatic SSL Setup (5-15 minutes)
1. **ACM Certificate** - Created automatically for your domain
2. **DNS Validation** - Route53 records added automatically
3. **Certificate Validation** - AWS validates domain ownership
4. **ALB Configuration** - HTTPS listener added with certificate
5. **HTTP Redirect** - All HTTP traffic redirects to HTTPS

### After HTTPS is Enabled
- ✅ **Your domain works**: `https://api.yourdomain.com/health`
- ✅ **HTTP redirects**: `http://api.yourdomain.com` → `https://`
- ✅ **Auto-renewal**: AWS handles certificate renewal
- ✅ **Security headers**: Production security enabled

## 🎯 Recommended Path

### Phase 1: Test HTTP (Now - 5 minutes)
```bash
terraform apply plan.out
curl http://$(terraform output -raw alb_dns_name)/health
```

### Phase 2: Get Domain (When Ready)
- Purchase domain from any registrar
- Create Route53 hosted zone
- Update domain nameservers

### Phase 3: Enable HTTPS (5 minutes)
- Add domain variables
- Run `terraform apply`
- Access via `https://yourdomain.com`

## 🔍 Troubleshooting

### Common Issues

**❌ "This site can't provide a secure connection"**
- You're trying to access ALB DNS with HTTPS
- Solution: Use HTTP with ALB DNS, or set up custom domain

**❌ Certificate validation timeout**
- Check domain nameservers point to Route53
- Wait up to 10 minutes for DNS propagation

**❌ Health check failures**
- Check if `/health` endpoint returns 200
- Review CloudWatch logs: `/aws/ec2/inkomoko`

### Monitoring Commands
```bash
# Check infrastructure status
terraform output

# Check application logs
aws logs tail /aws/ec2/inkomoko --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)
```

## 💰 Cost Breakdown

### HTTP-only Testing
- **ALB**: ~$16/month
- **EC2 (t2.micro x2)**: ~$17/month
- **Data Transfer**: Minimal
- **Total**: ~$33/month

### HTTPS Addition
- **SSL Certificate**: **FREE** (AWS ACM)
- **Route53 Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40/million queries
- **Additional Cost**: ~$1/month

## 🔐 Security Features

### Current (HTTP)
- ✅ VPC isolation
- ✅ Private subnets for EC2
- ✅ Security groups restricting access
- ✅ CloudWatch logging
- ✅ IAM roles with least privilege

### With HTTPS
- ✅ **All of the above, plus:**
- ✅ End-to-end encryption
- ✅ Automatic HTTP→HTTPS redirect
- ✅ Security headers (XSS protection, etc.)
- ✅ Rate limiting
- ✅ Modern TLS policies

Your infrastructure is **production-ready** right now! 🎉
