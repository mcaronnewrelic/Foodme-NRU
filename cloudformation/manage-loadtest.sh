#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
ENVIRONMENT="staging"
AWS_REGION=""
ACTION="trigger"

# Function to show usage
usage() {
    echo "Usage: $0 -e ENVIRONMENT [-r AWS_REGION] [-a ACTION]"
    echo ""
    echo "Options:"
    echo "  -e ENVIRONMENT    Environment name (staging/production) [required]"
    echo "  -r AWS_REGION     AWS region (defaults to current AWS CLI region)"
    echo "  -a ACTION         Action to perform: trigger, status, logs [default: trigger]"
    echo "  -h                Show this help message"
    echo ""
    echo "Actions:"
    echo "  trigger           Manually trigger a load test"
    echo "  status            Check the status of running load tests"
    echo "  logs              Show recent load test logs"
    echo ""
    echo "Examples:"
    echo "  $0 -e staging -a trigger"
    echo "  $0 -e staging -a status"
    echo "  $0 -e staging -a logs"
    exit 1
}

# Parse command line arguments
while getopts "e:r:a:h" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        r)
            AWS_REGION="$OPTARG"
            ;;
        a)
            ACTION="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Environment is required"
    usage
fi

# Validate action
if [[ ! "$ACTION" =~ ^(trigger|status|logs)$ ]]; then
    echo "❌ Invalid action: $ACTION"
    usage
fi

# Get AWS region if not provided
if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        echo "❌ AWS region not configured. Please set it with -r option or configure AWS CLI"
        exit 1
    fi
fi

# Stack and resource names
STACK_NAME="foodme-${ENVIRONMENT}"
CLUSTER_NAME="${ENVIRONMENT}-foodme-loadtest-cluster"
TASK_DEFINITION_FAMILY="${ENVIRONMENT}-foodme-loadtest"

trigger_load_test() {
    echo "🚀 Triggering manual load test"
    echo "   Environment: $ENVIRONMENT"
    echo "   Cluster: $CLUSTER_NAME"
    
    # Get the task definition ARN
    TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
        --task-definition "$TASK_DEFINITION_FAMILY" \
        --region "$AWS_REGION" \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    if [ -z "$TASK_DEFINITION_ARN" ] || [ "$TASK_DEFINITION_ARN" == "None" ]; then
        echo "❌ Task definition not found: $TASK_DEFINITION_FAMILY"
        echo "   Make sure the CloudFormation stack is deployed"
        exit 1
    fi
    
    # Get subnet and security group from stack outputs
    SUBNET_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApplicationSubnet`].OutputValue' \
        --output text)
    
    SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`SecurityGroupId`].OutputValue' \
        --output text)
    
    if [ -z "$SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ]; then
        echo "❌ Could not retrieve network configuration from stack"
        exit 1
    fi
    
    echo "📋 Running task with:"
    echo "   Task Definition: $TASK_DEFINITION_ARN"
    echo "   Subnet: $SUBNET_ID"
    echo "   Security Group: $SECURITY_GROUP_ID"
    
    # Run the task
    TASK_ARN=$(aws ecs run-task \
        --cluster "$CLUSTER_NAME" \
        --task-definition "$TASK_DEFINITION_ARN" \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
        --region "$AWS_REGION" \
        --query 'tasks[0].taskArn' \
        --output text)
    
    if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
        echo "❌ Failed to start load test task"
        exit 1
    fi
    
    echo "✅ Load test started successfully"
    echo "   Task ARN: $TASK_ARN"
    echo "   Monitor progress with: $0 -e $ENVIRONMENT -a status"
}

check_status() {
    echo "📊 Checking load test status"
    echo "   Environment: $ENVIRONMENT"
    echo "   Cluster: $CLUSTER_NAME"
    
    # List running tasks
    RUNNING_TASKS=$(aws ecs list-tasks \
        --cluster "$CLUSTER_NAME" \
        --desired-status RUNNING \
        --region "$AWS_REGION" \
        --query 'taskArns' \
        --output text)
    
    if [ -z "$RUNNING_TASKS" ] || [ "$RUNNING_TASKS" == "None" ]; then
        echo "ℹ️  No running load test tasks found"
    else
        echo "🏃 Running load test tasks:"
        for task_arn in $RUNNING_TASKS; do
            echo "   - $task_arn"
        done
        
        # Get detailed status of the first task
        TASK_ARN=$(echo "$RUNNING_TASKS" | cut -d' ' -f1)
        echo ""
        echo "📋 Task details for: $TASK_ARN"
        aws ecs describe-tasks \
            --cluster "$CLUSTER_NAME" \
            --tasks "$TASK_ARN" \
            --region "$AWS_REGION" \
            --query 'tasks[0].{Status:lastStatus,Health:healthStatus,CreatedAt:createdAt,StartedAt:startedAt}' \
            --output table
    fi
    
    # Check for recently stopped tasks
    echo ""
    echo "🔍 Recently completed tasks (last 10):"
    aws ecs list-tasks \
        --cluster "$CLUSTER_NAME" \
        --desired-status STOPPED \
        --region "$AWS_REGION" \
        --max-items 10 \
        --query 'taskArns' \
        --output text | head -10 | while read task_arn; do
        if [ -n "$task_arn" ] && [ "$task_arn" != "None" ]; then
            STATUS=$(aws ecs describe-tasks \
                --cluster "$CLUSTER_NAME" \
                --tasks "$task_arn" \
                --region "$AWS_REGION" \
                --query 'tasks[0].{StoppedReason:stoppedReason,ExitCode:containers[0].exitCode,StoppedAt:stoppedAt}' \
                --output table)
            echo "   Task: $task_arn"
            echo "$STATUS"
            echo ""
        fi
    done
}

show_logs() {
    echo "📜 Showing recent load test logs"
    echo "   Environment: $ENVIRONMENT"
    
    LOG_GROUP="/ecs/${ENVIRONMENT}-foodme-loadtest"
    
    # Check if log group exists
    if ! aws logs describe-log-groups \
        --log-group-name-prefix "$LOG_GROUP" \
        --region "$AWS_REGION" \
        --query 'logGroups[0].logGroupName' \
        --output text > /dev/null 2>&1; then
        echo "❌ Log group not found: $LOG_GROUP"
        echo "   Make sure the load test has run at least once"
        exit 1
    fi
    
    echo "📋 Recent log entries from: $LOG_GROUP"
    echo "   (showing last 50 lines from the past 1 hour)"
    
    # Get logs from the past hour
    START_TIME=$(date -d '1 hour ago' +%s)000
    
    aws logs filter-log-events \
        --log-group-name "$LOG_GROUP" \
        --start-time "$START_TIME" \
        --region "$AWS_REGION" \
        --query 'events[*].[timestamp,message]' \
        --output text | tail -50 | while IFS=$'\t' read timestamp message; do
        # Convert timestamp to readable format
        readable_time=$(date -d "@$(echo $timestamp | cut -c1-10)" "+%Y-%m-%d %H:%M:%S")
        echo "[$readable_time] $message"
    done
}

# Main execution
case $ACTION in
    trigger)
        trigger_load_test
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
esac