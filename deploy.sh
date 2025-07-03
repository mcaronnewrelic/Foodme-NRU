#!/bin/bash

# FoodMe Deployment Script
# This script handles the complete deployment workflow including New Relic deployment markers

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables from .env file
load_env_file() {
    if [ -f ".env" ]; then
        print_info "Loading environment variables from .env file..."
        
        # Source the .env file while handling potential issues
        set -a  # Automatically export all variables
        source .env
        set +a  # Turn off automatic export
        
        print_success "Environment variables loaded from .env file"
    else
        print_warning ".env file not found, using system environment variables"
        print_info "To create .env file, run: cp .env.template .env"
    fi
}

# Validate .env file contents
validate_env_file() {
    print_info "Validating .env file contents..."
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found"
        print_info "Create one from template: cp .env.template .env"
        return 1
    fi
    
    # Check for required variables in .env file
    local missing_vars=()
    local placeholder_vars=()
    
    # Read .env file and check each required variable
    if ! grep -q "^ENTITY_GUID=" .env || [ -z "$(grep "^ENTITY_GUID=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")" ]; then
        missing_vars+=("ENTITY_GUID")
    elif grep -q "your-new-relic-entity-guid-here" .env; then
        placeholder_vars+=("ENTITY_GUID")
    fi
    
    if ! grep -q "^NEW_RELIC_API_KEY=" .env || [ -z "$(grep "^NEW_RELIC_API_KEY=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")" ]; then
        missing_vars+=("NEW_RELIC_API_KEY")
    elif grep -q "your-new-relic-api-key-here" .env; then
        placeholder_vars+=("NEW_RELIC_API_KEY")
    fi
    
    # Report issues
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required variables in .env file:"
        printf '  %s\n' "${missing_vars[@]}"
        return 1
    fi
    
    if [ ${#placeholder_vars[@]} -ne 0 ]; then
        print_error "Found placeholder values in .env file:"
        printf '  %s\n' "${placeholder_vars[@]}"
        print_info "Please update .env file with your actual New Relic credentials"
        return 1
    fi
    
    print_success ".env file is properly configured"
    return 0
}

# Check if required environment variables are set
check_env_vars() {
    print_info "Checking environment variables..."
    
    # Run security validation first
    run_security_check
    
    # Load .env file
    load_env_file
    
    if [ -z "$ENTITY_GUID" ]; then
        print_error "ENTITY_GUID environment variable is not set"
        print_info "Please set it in .env file or export ENTITY_GUID=your-entity-guid"
        print_info "You can find your Entity GUID in New Relic One > Your App > Settings > Application"
        exit 1
    fi
    
    if [ -z "$NEW_RELIC_API_KEY" ]; then
        print_error "NEW_RELIC_API_KEY environment variable is not set"
        print_info "Please set it in .env file or export NEW_RELIC_API_KEY=your-api-key"
        print_info "Create an API key at: New Relic One > User Profile > API Keys"
        exit 1
    fi
    
    # Optional: Check for placeholder values
    if [ "$NEW_RELIC_API_KEY" = "your-new-relic-api-key-here" ] || [ "$ENTITY_GUID" = "your-new-relic-entity-guid-here" ]; then
        print_error "Found placeholder values in .env file"
        print_info "Please update .env file with your actual New Relic credentials"
        exit 1
    fi
    
    print_success "Environment variables are set:"
    print_info "  ENTITY_GUID: ${ENTITY_GUID:0:20}..."
    print_info "  NEW_RELIC_API_KEY: ${NEW_RELIC_API_KEY:0:20}..."
    print_info "  NEW_RELIC_APP_NAME: ${NEW_RELIC_APP_NAME:-FoodMe}"
}

# Check if we're in a git repository
check_git() {
    print_info "Checking git repository..."
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    print_success "Git repository detected"
}

# Build the application
build_app() {
    print_info "Building FoodMe application..."
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing server dependencies..."
        npm install
    fi
    
    if [ ! -d "angular-app/node_modules" ]; then
        print_info "Installing Angular dependencies..."
        cd angular-app && npm install && cd ..
    fi
    
    # Build the application
    print_info "Building Angular application and preparing distribution..."
    npm run build
    
    print_success "Application built successfully"
}

# Send deployment marker to New Relic
send_deployment_marker() {
    print_info "Sending deployment marker to New Relic..."
    
    # Get git information and escape for JSON
    REVISION=$(git rev-parse HEAD)
    CHANGELOG=$(git log --oneline -1 | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    USER=$(git config user.name | sed 's/"/\\"/g')
 
    print_info "Deployment details:"
    print_info "  Revision: $REVISION"
    print_info "  Changelog: $CHANGELOG"
    print_info "  User: $USER"
    
    # Create JSON payload with proper escaping
    cat > /tmp/deployment_payload.json << EOF
{
  "query": "mutation { changeTrackingCreateDeployment( deployment: {commit: \"$REVISION\", description: \"$CHANGELOG\", user: \"$USER\", changelog: \"$CHANGELOG\", version: \"1.0.0\", deploymentType: BASIC, entityGuid: \"$ENTITY_GUID\"}) { deploymentId entityGuid } }",
  "variables": {}
}
EOF
    
    print_info "JSON Payload:"
    cat /tmp/deployment_payload.json
    
    # Send deployment marker for the main server
    print_info "Marking server deployment..."
    
    # Use the JSON file for the request
    curl -s -w "\nHTTP Response Code: %{http_code}\n" \
      https://api.newrelic.com/graphql \
      -H 'Content-Type: application/json' \
      -H "API-Key: $NEW_RELIC_API_KEY" \
      --data @/tmp/deployment_payload.json
    
    # Clean up temporary file
    rm -f /tmp/deployment_payload.json

    print_success "Deployment marker sent to New Relic"
}

# Run security validation
run_security_check() {
    print_info "Running security validation..."
    
    if [ -f "./validate-security.sh" ]; then
        if ./validate-security.sh; then
            print_success "Security validation passed"
        else
            print_error "Security validation failed"
            exit 1
        fi
    else
        print_warning "Security validation script not found (validate-security.sh)"
    fi
}

# Show deployment status and next steps
show_deployment_status() {
    print_success "Deployment Summary"
    echo "=================="
    print_info "✅ Application built successfully"
    print_info "✅ Deployment marker sent to New Relic"
    print_info "✅ Environment configured from .env file"
    echo ""
    print_info "Your deployment is tracked in New Relic with:"
    print_info "  App Name: ${NEW_RELIC_APP_NAME:-FoodMe}"
    print_info "  Entity GUID: ${ENTITY_GUID:0:20}..."
    echo ""
    print_info "Next steps:"
    print_info "  • Start app: npm start"
    print_info "  • Run tests: ./deploy.sh -l"
    print_info "  • View in New Relic: https://one.newrelic.com"
    print_info "  • Docker deploy: npm run docker:with-secrets"
}

# Start the application
start_app() {
    print_info "Starting FoodMe application..."
    print_warning "Application will start with New Relic monitoring enabled"
    print_info "Press Ctrl+C to stop the application"
    
    # Start the application with New Relic
    npm start
}

# Run load tests
run_load_test() {
    print_info "Running load tests against FoodMe application..."
    print_warning "Make sure the application is running on http://localhost:3000"
    
    # Check if locust is available
    if [ ! -f ".venv/bin/locust" ]; then
        print_error "Locust is not installed. Install it with: pip install -r requirements.txt"
        print_info "Or run: ./configure_python_environment && pip install -r requirements.txt"
        exit 1
    fi
    
    # Check if the application is running
    if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_error "Application is not running on http://localhost:3000"
        print_info "Start the application first with: npm start or ./deploy.sh -s"
        exit 1
    fi
    
    print_info "Starting Locust load test..."
    print_info "Locust web interface will be available at http://localhost:8089"
    npm run loadtest:web
}

# Main deployment workflow
main() {
    print_info "Starting FoodMe deployment workflow..."
    echo "=================================================="
    
    # Check prerequisites
    validate_env_file || exit 1
    check_env_vars
    check_git
    
    # Build and deploy
    build_app
    send_deployment_marker
    
    # Show deployment status
    show_deployment_status
    
    print_success "Deployment completed successfully!"
    echo "=================================================="
    
    # Ask if user wants to start the application
    read -p "Do you want to start the application now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_app
    else
        print_info "To start the application later, run: npm start"
        print_info "Application files are ready in the dist/ directory"
    fi
}

# Help function
show_help() {
    echo "FoodMe Deployment Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -b, --build    Build only (skip deployment marker and start)"
    echo "  -m, --marker   Send deployment marker only"
    echo "  -s, --start    Start application only"
    echo "  -l, --loadtest Run load tests (requires app to be running)"
    echo ""
    echo "Environment Variables:"
    echo "  This script automatically loads variables from .env file if present"
    echo "  Required variables:"
    echo "    ENTITY_GUID       Your New Relic application Entity GUID"
    echo "    NEW_RELIC_API_KEY Your New Relic User API key"
    echo ""
    echo "  Optional variables:"
    echo "    NEW_RELIC_APP_NAME     App name in New Relic (default: FoodMe)"
    echo "    NEW_RELIC_LICENSE_KEY  License key for APM agent"
    echo ""
    echo "Setup:"
    echo "  1. Copy template: cp .env.template .env"
    echo "  2. Edit .env with your actual New Relic credentials"
    echo "  3. Run: $0"
    echo ""
    echo "Alternative (without .env file):"
    echo "  export ENTITY_GUID=MTM1MjgxMXxBUE18QVBQTElDQVRJT058OTI2MzIxNzQ"
    echo "  export NEW_RELIC_API_KEY=NRAK-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo "  $0"
    echo ""
    echo "Find your credentials:"
    echo "  Entity GUID: New Relic One > Your App > Settings > Application"
    echo "  API Key: New Relic One > User Profile > API Keys > Create User API Key"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--build)
        check_git
        build_app
        exit 0
        ;;
    -m|--marker)
        check_env_vars
        check_git
        send_deployment_marker
        exit 0
        ;;
    -s|--start)
        start_app
        exit 0
        ;;
    -l|--loadtest)
        run_load_test
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
