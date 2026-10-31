# Application Load Balancer Setup Guide

This document explains the Application Load Balancer (ALB) configuration added to the FoodMe CloudFormation template to provide a stable public endpoint.

## Overview

The ALB provides several key benefits:
- **Stable DNS Name**: The ALB DNS name remains constant across deployments
- **High Availability**: Distributes traffic across multiple availability zones
- **Health Checks**: Automatically routes traffic only to healthy instances
- **Security**: Centralizes access control and allows private EC2 instances
- **Load Distribution**: Can distribute traffic across multiple instances (future scalability)

## Architecture Changes

### Before ALB
```
Internet → EC2 Public IP → FoodMe Application
```

### After ALB
```
Internet → ALB → Target Groups → EC2 Instance (Private)
```

## Infrastructure Components

### 1. **Application Load Balancer**
- **Name**: `{Environment}-foodme-alb`
- **Scheme**: Internet-facing
- **Subnets**: Two subnets across different AZs for high availability
- **Security Group**: Allows HTTP/HTTPS from internet

### 2. **Target Groups**
- **Application Target Group**: Routes traffic to Angular app on port 80
- **API Target Group**: Routes traffic to Node.js API on port 3000

### 3. **Listeners**
- **Port 80**: Routes to Application Target Group
- **Port 3000**: Routes to API Target Group

### 4. **Security Groups**
- **ALB Security Group**: Allows inbound HTTP/HTTPS from internet
- **EC2 Security Group**: Updated to only allow traffic from ALB

### 5. **Additional Subnet**
- **ApplicationSubnetB**: Second subnet in different AZ (10.0.2.0/24)

## Networking Updates

### New Subnets
- **ApplicationSubnet**: 10.0.1.0/24 (AZ-a)
- **ApplicationSubnetB**: 10.0.2.0/24 (AZ-b)

### Security Group Changes
- **Removed**: Direct internet access to EC2 (ports 80, 443, 3000)
- **Added**: ALB security group allowing internet access
- **Modified**: EC2 security group to only accept traffic from ALB

## Health Checks

### Application Health Check
- **Path**: `/` (root path)
- **Port**: 80
- **Protocol**: HTTP
- **Expected Codes**: 200, 301, 302

### API Health Check
- **Path**: `/api/restaurant`
- **Port**: 3000
- **Protocol**: HTTP
- **Expected Codes**: 200

## Access URLs

After deployment, access your application using these stable URLs:

### Web Application
```
http://{ALB-DNS-NAME}
```

### API Endpoints
```
http://{ALB-DNS-NAME}:3000/api/restaurant
http://{ALB-DNS-NAME}:3000/api/order
```

## CloudFormation Outputs

The template now provides these key outputs:

```yaml
LoadBalancerDNS: # Use this for stable access
ApplicationUrl: # Full URL with http:// prefix
APIUrl: # API URL with port 3000
```

## Deployment

### 1. **Initial Deployment**
```bash
cd cloudformation
./deploy-stack.sh staging t3.medium your-key-pair-name your-db-password
```

### 2. **Get ALB DNS Name**
```bash
aws cloudformation describe-stacks \
  --stack-name foodme-staging \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text
```

### 3. **Verify Health Checks**
```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws cloudformation describe-stacks \
    --stack-name foodme-staging \
    --query 'Stacks[0].Outputs[?OutputKey==`ApplicationTargetGroupArn`].OutputValue' \
    --output text)
```

## Load Testing Integration

The load testing infrastructure automatically uses the ALB DNS name:
- **LOCUST_HOST**: Set to `http://{ALB-DNS-NAME}`
- **Target**: ALB instead of EC2 public IP
- **Consistency**: Tests always target the same endpoint

## Troubleshooting

### 1. **503 Service Unavailable**
- Check target group health status
- Verify EC2 instance is running and healthy
- Check security group rules

### 2. **Health Check Failures**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn YOUR_TG_ARN

# Check ALB logs (if enabled)
aws logs filter-log-events --log-group-name /aws/applicationelb/YOUR_ALB_NAME
```

### 3. **Cannot Connect to Application**
- Verify ALB DNS resolution: `nslookup ALB_DNS_NAME`
- Check ALB security group allows inbound traffic
- Ensure listeners are configured correctly

### 4. **API Endpoints Not Working**
- Verify API target group health
- Check Node.js service is running on port 3000
- Test direct EC2 access via SSH

## Security Considerations

### Benefits
- **Reduced Attack Surface**: EC2 instances no longer need public IPs
- **Centralized Access Control**: All traffic flows through ALB
- **DDoS Protection**: ALB provides basic DDoS protection

### Security Groups
```yaml
# ALB Security Group (Internet-facing)
Ingress:
  - Port 80 from 0.0.0.0/0
  - Port 443 from 0.0.0.0/0

# EC2 Security Group (Private)
Ingress:
  - Port 80 from ALB Security Group only
  - Port 3000 from ALB Security Group only
  - Port 22 from allowed CIDR (management)
```

## Cost Implications

### Additional Costs
- **ALB**: ~$16-22/month (base cost)
- **Data Processing**: $0.008 per GB processed
- **Additional Subnet**: No additional cost

### Example Monthly Cost (Low Traffic)
- **ALB Base**: ~$18/month
- **Data Processing**: ~$1-5/month (depending on traffic)
- **Total Additional**: ~$20-25/month

## High Availability

### Current Setup
- **AZs**: 2 availability zones
- **Instances**: 1 EC2 instance (single point of failure)

### Future Scaling
To add high availability:
1. Create Auto Scaling Group with min 2 instances
2. Update target groups to register instances automatically
3. Add database clustering (RDS Multi-AZ)

## Monitoring

### CloudWatch Metrics
- **ALB Metrics**: Request count, response time, error rates
- **Target Group Metrics**: Healthy/unhealthy host count
- **Health Check Metrics**: Success/failure rates

### Recommended Alarms
```bash
# Unhealthy targets
aws cloudwatch put-metric-alarm \
  --alarm-name "foodme-unhealthy-targets" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold
```

## Migration from Direct EC2 Access

### For Existing Deployments
1. **Deploy Updated Stack**: CloudFormation will create ALB and update security groups
2. **Update DNS**: Point your domain to ALB DNS name instead of EC2 IP
3. **Update Monitoring**: Update health checks to use ALB endpoints
4. **Update Documentation**: Reference ALB URLs in runbooks

### For Applications Using EC2 IP
If any external services reference the EC2 public IP:
1. Update configurations to use ALB DNS name
2. Update API documentation
3. Notify integration partners of the change

## Best Practices

### 1. **DNS Management**
- Use Route 53 to create a CNAME record pointing to ALB DNS
- Example: `foodme-staging.yourdomain.com` → ALB DNS

### 2. **SSL/TLS Termination**
Future enhancement: Add HTTPS listener with SSL certificate
```yaml
# Example HTTPS listener (not yet implemented)
HTTPSListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    Certificates:
      - CertificateArn: !Ref SSLCertificate
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref ApplicationTargetGroup
    LoadBalancerArn: !Ref ApplicationLoadBalancer
    Port: 443
    Protocol: HTTPS
```

### 3. **Health Check Tuning**
- Adjust timeout and threshold based on application startup time
- Use specific health check endpoints that verify full application stack
- Monitor health check failure patterns

This ALB setup provides a robust, scalable foundation for the FoodMe application with stable endpoints and improved security.