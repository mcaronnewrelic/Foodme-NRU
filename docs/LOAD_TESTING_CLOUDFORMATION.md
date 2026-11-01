# Automated Load Testing with CloudFormation

This guide explains how to deploy and manage automated load testing for the FoodMe application using AWS ECS Fargate and EventBridge.

## Overview

The load testing infrastructure automatically runs Locust-based load tests every 4 hours for 30 minutes. The tests use the existing `locustfile.py` to simulate realistic user behavior against your deployed FoodMe application.

## Architecture

- **ECS Fargate**: Runs containerized Locust load tests
- **EventBridge**: Schedules tests every 4 hours
- **ECR**: Stores the load test container image
- **CloudWatch Logs**: Captures test execution logs
- **Docker**: Containerizes the Locust test environment

## Quick Start

### 1. Deploy the Infrastructure

The load testing infrastructure is automatically included when you deploy the CloudFormation stack:

```bash
cd cloudformation
./deploy-stack.sh staging t3.medium your-key-pair-name your-db-password
```

This will:
- Create the ECS cluster and task definition
- Build and push the load test container to ECR
- Set up the EventBridge schedule (every 4 hours)
- Configure CloudWatch logging

### 2. Verify Deployment

Check that the load testing infrastructure was deployed successfully:

```bash
./manage-loadtest.sh -e staging -a status
```

### 3. Manual Testing

Trigger a manual load test to verify everything works:

```bash
./manage-loadtest.sh -e staging -a trigger
```

## Load Test Configuration

The load test runs with the following default parameters:

- **Duration**: 30 minutes
- **Users**: 10 concurrent users
- **Spawn Rate**: 2 users per second
- **Target**: Your deployed FoodMe application
- **Test Mix**: 75% restaurant browsing, 25% order placement

### Customizing Load Test Parameters

You can modify the test parameters by updating the task definition in the CloudFormation template (`foodme-stack.yaml`):

```yaml
Environment:
  - Name: LOCUST_USERS
    Value: '20'  # Number of concurrent users
  - Name: LOCUST_SPAWN_RATE
    Value: '3'   # Users spawned per second
  - Name: LOCUST_RUN_TIME
    Value: '45m' # Test duration
```

After making changes, redeploy the stack:

```bash
./deploy-stack.sh staging t3.medium your-key-pair-name your-db-password
```

## Management Commands

### Check Load Test Status

```bash
./manage-loadtest.sh -e staging -a status
```

This shows:
- Currently running load tests
- Recently completed tests
- Task exit codes and stop reasons

### View Load Test Logs

```bash
./manage-loadtest.sh -e staging -a logs
```

Shows the most recent log entries from load test executions.

### Trigger Manual Load Test

```bash
./manage-loadtest.sh -e staging -a trigger
```

Starts an immediate load test (doesn't interfere with the scheduled tests).

## Scheduled Execution

Load tests run automatically every 4 hours using EventBridge rules:

- **Schedule**: `rate(4 hours)`
- **Execution Time**: 30 minutes per test
- **Overlap Prevention**: Each test runs independently

### Modifying the Schedule

To change the schedule, update the EventBridge rule in `foodme-stack.yaml`:

```yaml
LoadTestScheduleRule:
  Type: AWS::Events::Rule
  Properties:
    ScheduleExpression: 'rate(2 hours)'  # Run every 2 hours instead
```

Common schedule expressions:
- `rate(30 minutes)` - Every 30 minutes
- `rate(2 hours)` - Every 2 hours
- `rate(1 day)` - Daily
- `cron(0 9 * * ? *)` - Daily at 9:00 AM UTC

## Monitoring and Observability

### CloudWatch Logs

Load test logs are stored in CloudWatch Logs under:
- **Log Group**: `/ecs/{environment}-foodme-loadtest`
- **Retention**: 7 days

### Locust Reports

Each test execution generates:
- **HTML Report**: `/tmp/report.html` (within container)
- **CSV Results**: `/tmp/results_*.csv` (within container)

> **Note**: Reports are currently stored within the container. For persistent storage, consider mounting an EFS volume or uploading results to S3.

### New Relic Integration

If New Relic is configured for your FoodMe application, load test traffic will appear in your APM dashboard, allowing you to:
- Monitor application performance under load
- Identify bottlenecks and errors
- Track response times and throughput

## Troubleshooting

### Load Test Not Starting

1. Check ECS cluster status:
   ```bash
   aws ecs describe-clusters --clusters staging-foodme-loadtest-cluster
   ```

2. Verify task definition exists:
   ```bash
   aws ecs describe-task-definition --task-definition staging-foodme-loadtest
   ```

3. Check EventBridge rule:
   ```bash
   aws events describe-rule --name staging-foodme-loadtest-schedule
   ```

### Container Image Issues

1. Verify ECR repository and image:
   ```bash
   aws ecr describe-repositories --repository-names staging-foodme-loadtest
   aws ecr list-images --repository-name staging-foodme-loadtest
   ```

2. Rebuild and push the image:
   ```bash
   ./build-loadtest-image.sh -e staging
   ```

### Network Connectivity Issues

1. Ensure security groups allow outbound HTTPS traffic
2. Verify the application is accessible from the ECS subnet
3. Check that the public IP is correctly passed to the container

### Load Test Failures

1. Check CloudWatch logs for error details:
   ```bash
   ./manage-loadtest.sh -e staging -a logs
   ```

2. Common issues:
   - Application not responding (check application health)
   - DNS resolution failures (verify target URL)
   - Authentication errors (check test data)

## Cost Considerations

### Resource Usage

- **ECS Fargate**: ~$0.05 per hour of testing (512 CPU, 1024 MB memory)
- **CloudWatch Logs**: ~$0.50 per GB ingested
- **ECR Storage**: ~$0.10 per GB per month

### Estimated Monthly Cost

For default configuration (6 tests per day, 30 minutes each):
- **Compute**: ~$2.25/month (3 hours/day × 30 days × $0.025/hour)
- **Logs**: ~$1.00/month (assuming 500MB logs/month)
- **Storage**: ~$0.10/month (assuming 1GB image)

**Total**: ~$3.35/month

## Security Considerations

### IAM Permissions

The load testing infrastructure uses minimal required permissions:
- ECS task execution (pulling images, writing logs)
- CloudWatch Logs creation and writing
- No access to production data or sensitive resources

### Network Security

- Load tests run in the same VPC as your application
- Security groups allow only necessary outbound traffic
- No inbound access to load test containers

### Container Security

- Base image: `python:3.11-slim` (regularly updated)
- ECR image scanning enabled
- No sensitive data stored in container images

## Advanced Configuration

### Custom Test Scenarios

To modify the load test behavior, edit `locustfile.py`:

```python
class UserBehavior(TaskSet):
    @task(5)  # Higher weight = more frequent
    def browse_restaurants(self):
        get_restaurants(self)
    
    @task(2)  # Lower weight = less frequent  
    def place_order(self):
        place_order(self)
```

### Multiple Test Profiles

You can create different container images for different test profiles:

1. Create profile-specific Dockerfiles:
   - `Dockerfile.loadtest-light`
   - `Dockerfile.loadtest-heavy`

2. Build separate ECR repositories
3. Deploy separate ECS task definitions

### Results Storage

To persist test results beyond container lifetime:

1. Add S3 bucket to CloudFormation template
2. Mount EFS volume to containers
3. Modify container command to upload results

Example S3 upload addition to container:
```bash
CMD ["sh", "-c", "locust ... && aws s3 cp /tmp/report.html s3://my-bucket/reports/$(date +%Y%m%d-%H%M%S).html"]
```

## Support

For issues with the load testing infrastructure:

1. Check CloudWatch logs first
2. Verify all prerequisites are met
3. Ensure AWS permissions are correctly configured
4. Review the CloudFormation stack events for deployment issues

For load test customization:
1. Review Locust documentation: https://locust.io/
2. Modify `locustfile.py` to match your testing requirements
3. Adjust container environment variables as needed