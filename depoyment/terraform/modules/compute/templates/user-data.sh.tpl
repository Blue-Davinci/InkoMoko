#!/bin/bash

# Update system (Amazon Linux 2023 uses dnf)
dnf update -y
dnf install -y nginx docker

# Enable and start Docker first (needed for image pull)
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group for permissions
usermod -a -G docker ec2-user

# Pull Docker image (before nginx to ensure it's available)
docker pull ${docker_image_url}

# Enable nginx
systemctl enable nginx

# Create nginx configuration
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api {
        server 127.0.0.1:4000;
    }

    # Rate limiting
    limit_req_zone $remote_addr zone=api_limit:10m rate=10r/s;

    # Log format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    server {
        listen 80;
        server_name _;

        # Health check endpoint (for load balancers)
        location /health {
            access_log off;
            proxy_pass http://api/v1/health/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Health check timeouts
            proxy_connect_timeout 1s;
            proxy_send_timeout 3s;
            proxy_read_timeout 3s;
        }

        # Metrics endpoint (internal access only)
        location /metrics {
            proxy_pass http://api/v1/health/metrics;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;

            # Restrict to VPC CIDR block (will be replaced by Terraform)
            allow ${vpc_cidr_block};
            allow 127.0.0.1;
            deny all;
        }

        # API endpoints
        location /v1/ {
            # Apply rate limiting
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Timeouts
            proxy_connect_timeout 5s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # Buffer settings
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # Root redirect
        location = / {
            return 301 /v1/;
        }

        # Handle favicon requests
        location = /favicon.ico {
            access_log off;
            log_not_found off;
            return 204;
        }

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Referrer-Policy "strict-origin-when-cross-origin";
    }
}
EOF

# Add ec2-user to docker group for permissions
usermod -a -G docker ec2-user

# Pull and run your Docker container
docker run -d --name inkomoko-api \
  --restart unless-stopped \
  -p 127.0.0.1:4000:4000 \
  ${docker_image_url}

# Start nginx (Docker already started)
systemctl start nginx

# Verify services are running
sleep 5
systemctl status nginx --no-pager
systemctl status docker --no-pager
docker ps

# Enable CloudWatch agent
# dnf install -y amazon-cloudwatch-agent
# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#   -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
