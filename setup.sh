#!/bin/bash

# FoodMe Development Environment Setup Script
# ===========================================
# This script sets up a secure HTTPS development environment for the FoodMe application
# using Docker, Nginx reverse proxy, and mkcert for SSL certificates.
# 
# Features:
# - Automatic SSL certificate generation with mkcert
# - Nginx reverse proxy configuration with HTTPS redirect
# - Docker Compose setup for easy container management
# - Cross-platform support (macOS, Linux, Windows via WSL)
# - Automatic hosts file management
# - Comprehensive error handling and validation
#
# Requirements:
# - Docker and Docker Compose
# - Internet connection (to download mkcert)
# - sudo privileges (for hosts file modification)
#
# Usage: ./setup.sh <domain> <app_name> <port>
# Example: ./setup.sh foodme.local foodme 3000

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROCESS_DIR=".setup"
readonly MKCERT_VERSION="latest"

# Global variables
declare OS_TYPE=""
declare ARCHITECTURE=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Setup failed with exit code $exit_code"
        log_info "Cleaning up temporary files..."
        [[ -d "$PROCESS_DIR" ]] && rm -rf "$PROCESS_DIR/mkcert*" 2>/dev/null || true
        log_info "You can try running the script again or check the logs above for more details"
    fi
}

trap cleanup EXIT

# Show usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME <domain> <app_name> <port>

Arguments:
  domain    - The domain name for the local HTTPS setup (e.g., foodme.local)
  app_name  - The application name for Docker containers (e.g., foodme)
  port      - The port where your application is running (e.g., 3000)

Examples:
  $SCRIPT_NAME foodme.local foodme 3000
  $SCRIPT_NAME myapp.dev myapp 8080

This script will:
1. Download and install mkcert for SSL certificate generation
2. Create SSL certificates for the specified domain
3. Set up an Nginx reverse proxy with HTTPS redirect
4. Configure Docker Compose for easy container management
5. Add the domain to your hosts file (requires sudo)

Requirements:
- Docker and Docker Compose installed and running
- Internet connection (to download mkcert)
- sudo privileges (for hosts file modification)
EOF
}

# System detection
get_system_info() {
    local os_type="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local architecture="$(uname -m | tr '[:upper:]' '[:lower:]')"
    
    # Normalize OS type
    case "$os_type" in
        darwin) OS_TYPE="darwin" ;;
        linux) OS_TYPE="linux" ;;
        mingw*|msys*|cygwin*) OS_TYPE="windows" ;;
        *) OS_TYPE="linux" ;; # Default fallback
    esac
    
    # Normalize architecture
    case "$architecture" in
        x86_64|amd64) ARCHITECTURE="amd64" ;;
        arm64|aarch64) ARCHITECTURE="arm64" ;;
        armv7l) ARCHITECTURE="armv7" ;;
        i386|i686) ARCHITECTURE="386" ;;
        *) ARCHITECTURE="amd64" ;; # Default fallback
    esac
    
    log_info "Detected system: $OS_TYPE/$ARCHITECTURE"
}


# Input validation
validate_inputs() {
    local domain="$1"
    local app_name="$2"
    local port="$3"
    
    # Validate domain format
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
        log_error "Invalid domain format: $domain"
        log_info "Domain should contain only letters, numbers, dots, and hyphens"
        return 1
    fi
    
    # Validate app name format
    if [[ ! "$app_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        log_error "Invalid app name format: $app_name"
        log_info "App name should contain only letters, numbers, underscores, and hyphens"
        return 1
    fi
    
    # Validate port number
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log_error "Invalid port number: $port"
        log_info "Port should be a number between 1 and 65535"
        return 1
    fi
    
    # Check for privileged ports
    if [[ "$port" -lt 1024 ]] && [[ "$(id -u)" -ne 0 ]]; then
        log_warning "Port $port is privileged (< 1024) and may require root access"
    fi
    
    log_success "Input validation passed"
}

# Function to check if Docker is installed and running
check_dependencies() {
    log_info "Checking system dependencies..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        log_info "Please install Docker from: https://docs.docker.com/get-docker/"
        return 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        log_info "Please start Docker and try again"
        return 1
    fi

    # Check if Docker Compose is available
    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose is not available"
        log_info "Please install Docker Compose or use a newer version of Docker"
        return 1
    fi
    
    # Check internet connectivity
    if ! curl -s --connect-timeout 5 https://dl.filippo.io &> /dev/null; then
        log_error "No internet connection to download mkcert"
        log_info "Please check your internet connection"
        return 1
    fi
    
    log_success "All dependencies are available"
}

# Function to setup working directory
setup_workspace() {
    log_info "Setting up workspace in $PROCESS_DIR..."
    
    # Create process directory if it doesn't exist
    if [[ ! -d "$PROCESS_DIR" ]]; then
        mkdir -p "$PROCESS_DIR" || {
            log_error "Failed to create $PROCESS_DIR directory"
            return 1
        }
        log_success "Created $PROCESS_DIR directory"
    else
        log_info "$PROCESS_DIR directory already exists"
    fi

    # Change to process directory
    cd "$PROCESS_DIR" || {
        log_error "Failed to change to $PROCESS_DIR directory"
        return 1
    }
    
    log_success "Workspace setup complete"
}


# Function to manage hosts file entries
manage_hosts_file() {
    local domain="$1"
    local hosts_file="/etc/hosts"
    
    # Determine hosts file location based on OS
    case "$OS_TYPE" in
        windows)
            hosts_file="/c/Windows/System32/drivers/etc/hosts"
            ;;
        *)
            hosts_file="/etc/hosts"
            ;;
    esac
    
    log_info "Managing hosts file: $hosts_file"
    
    # Check if entry already exists
    if grep -q "127.0.0.1[[:space:]]*$domain" "$hosts_file" 2>/dev/null; then
        log_info "Entry for $domain already exists in hosts file"
        return 0
    fi
    
    # Add entry to hosts file
    local entry="127.0.0.1 $domain"
    log_info "Adding $domain to hosts file..."
    
    case "$OS_TYPE" in
        windows)
            echo "$entry" >> "$hosts_file" || {
                log_error "Failed to add entry to hosts file"
                log_info "You may need to run this script as Administrator"
                return 1
            }
            ;;
        *)
            if [[ "$(id -u)" -eq 0 ]]; then
                echo "$entry" >> "$hosts_file"
            else
                echo "$entry" | sudo tee -a "$hosts_file" > /dev/null || {
                    log_error "Failed to add entry to hosts file"
                    log_info "Please run with sudo or add '$entry' to $hosts_file manually"
                    return 1
                }
            fi
            ;;
    esac
    
    log_success "Added $domain to hosts file"
}

# Function to download mkcert
download_mkcert() {
    log_info "Downloading mkcert for $OS_TYPE/$ARCHITECTURE..."
    
    # Check if mkcert already exists and is executable
    if [[ -x "./mkcert" ]]; then
        log_info "mkcert already exists and is executable"
        return 0
    fi
    
    # Download mkcert
    local download_url="https://dl.filippo.io/mkcert/latest?for=$OS_TYPE/$ARCHITECTURE"
    log_info "Downloading from: $download_url"
    
    if ! curl -fsSL "$download_url" -o mkcert; then
        log_error "Failed to download mkcert"
        log_info "Please check your internet connection and try again"
        return 1
    fi
    
    # Make executable
    chmod +x mkcert || {
        log_error "Failed to make mkcert executable"
        return 1
    }
    
    # Verify download
    if [[ ! -x "./mkcert" ]]; then
        log_error "Downloaded mkcert is not executable"
        return 1
    fi
    
    log_success "mkcert downloaded successfully"
}

# Function to generate SSL certificates using mkcert
generate_certificates() {
    local domain="$1"
    local certs_dir="$PROCESS_DIR/certs"
    
    log_info "Generating SSL certificates for $domain..."
    
    # Create certs directory
    mkdir -p "$certs_dir" || {
        log_error "Failed to create certificates directory"
        return 1
    }
    
    # Check if certificates already exist
    if [[ -f "$certs_dir/$domain.crt" && -f "$certs_dir/$domain.key" ]]; then
        log_info "SSL certificates for $domain already exist, skipping generation"
        log_success "Using existing SSL certificates"
        return 0
    fi
    
    # Check if we have existing certificates we can copy
    if [[ -f "$certs_dir/local.foodme.nru.to.crt" && -f "$certs_dir/local.foodme.nru.to.key" ]]; then
        log_info "Found existing certificates, copying for $domain..."
        cp "$certs_dir/local.foodme.nru.to.crt" "$certs_dir/$domain.crt" || {
            log_error "Failed to copy existing certificate"
            return 1
        }
        cp "$certs_dir/local.foodme.nru.to.key" "$certs_dir/$domain.key" || {
            log_error "Failed to copy existing key"
            return 1
        }
        log_success "SSL certificates copied successfully"
        return 0
    fi
    
    # Try to use mkcert if available
    if [[ -x "./mkcert" ]]; then
        # Install CA if not already installed
        log_info "Installing mkcert CA (may prompt for password)..."
        if ! ./mkcert -install; then
            log_warning "Failed to install mkcert CA, but continuing..."
        fi
        
        # Generate certificates
        log_info "Generating certificates for $domain and *.$domain..."
        if ./mkcert -key-file "./$certs_dir/$domain.key" -cert-file "./$certs_dir/$domain.crt" "$domain" "*.$domain"; then
            # Set appropriate permissions
            chmod 644 "./$certs_dir/$domain.crt" "./$certs_dir/$domain.key" || {
                log_warning "Failed to set certificate permissions"
            }
            log_success "SSL certificates generated successfully"
            return 0
        else
            log_warning "mkcert failed, but continuing with setup..."
        fi
    fi
    
    log_warning "Could not generate certificates, you may need to provide them manually"
    log_info "Place your certificate files at:"
    log_info "  - $certs_dir/$domain.crt"
    log_info "  - $certs_dir/$domain.key"
    
    return 0  # Don't fail the entire setup
}

# Function to create the Nginx configuration file
create_nginx_config() {
    local domain="$1"
    local port="$2"
    local nginx_dir="$PROCESS_DIR/nginx"
    
    log_info "Creating Nginx configuration for $domain:$port..."
    
    # Create nginx directory in .setup
    mkdir -p "$nginx_dir" || {
        log_error "Failed to create nginx directory"
        return 1
    }
    
    # Generate nginx configuration with FoodMe-specific settings
    cat > "$nginx_dir/$domain.conf" << EOF
server {
    listen 80;
    server_name $domain www.$domain localhost;

    # Health check endpoint for Docker
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # New Relic monitoring endpoint
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $domain www.$domain localhost;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/certs/$domain.crt;
    ssl_certificate_key /etc/nginx/certs/$domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;

    # New Relic monitoring endpoint (HTTPS)
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }

    # Main application proxy
    location / {
        proxy_pass http://foodme:$port;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Static assets with long cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        proxy_pass http://foodme:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to create Nginx configuration"
        return 1
    fi
    
    log_success "Nginx configuration created successfully at $nginx_dir/$domain.conf"
}

# Function to create the Docker Compose file
create_docker_compose() {
    local domain="$1"
    local app_name="$2"
    
    log_info "Creating Docker Compose configuration..."
    
    # Check if docker-compose.yml already exists in the project root
    if [[ -f "../docker-compose.yml" ]]; then
        log_info "Existing docker-compose.yml found in project root, skipping generation"
        log_info "To use the generated nginx configuration, ensure docker-compose.yml references:"
        log_info "  - .setup/nginx/$domain.conf for nginx config"
        log_info "  - .setup/certs/$domain.crt and .setup/certs/$domain.key for SSL"
        log_success "Using existing Docker Compose configuration"
        return 0
    fi
    
    cat > docker-compose.yml << EOF
# Docker Compose configuration for $domain
# Generated by FoodMe setup script

services:
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-$app_name
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./$PROCESS_DIR/nginx/$domain.conf:/etc/nginx/conf.d/default.conf:ro
      - ./$PROCESS_DIR/certs/$domain.crt:/etc/nginx/certs/$domain.crt:ro
      - ./$PROCESS_DIR/certs/$domain.key:/etc/nginx/certs/$domain.key:ro
    networks:
      - ${app_name}_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://127.0.0.1/nginx-health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    labels:
      - "traefik.enable=false"
      - "com.docker.compose.project=$app_name"

networks:
  ${app_name}_network:
    name: ${app_name}_network
    driver: bridge
EOF
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to create Docker Compose configuration"
        return 1
    fi
    
    log_success "Docker Compose configuration created successfully"
}

# Function to start Docker services
start_services() {
    local app_name="$1"
    
    log_info "Starting Docker services..."
    
    # Choose docker compose command
    local compose_cmd="docker compose"
    if ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    # Check if we should use existing docker-compose.yml in project root
    if [[ -f "../docker-compose.yml" ]]; then
        log_info "Using existing docker-compose.yml from project root..."
        cd ..
        
        # Stop any existing services
        log_info "Stopping any existing services..."
        $compose_cmd down --remove-orphans &> /dev/null || true
        
        # Start services
        log_info "Starting services with existing configuration..."
        if ! $compose_cmd up -d; then
            log_error "Failed to start Docker services"
            log_info "You can try manually with: $compose_cmd up -d"
            cd "$PROCESS_DIR"
            return 1
        fi
        
        # Wait for services to be ready
        log_info "Waiting for services to be ready..."
        sleep 5
        
        # Check if nginx is running
        if $compose_cmd ps | grep -q "nginx.*Up"; then
            log_success "Docker services started successfully"
        else
            log_warning "Services may not be running properly"
            log_info "Check status with: $compose_cmd ps"
            log_info "View logs with: $compose_cmd logs"
        fi
        
        cd "$PROCESS_DIR"
    else
        # Use generated docker-compose.yml in .setup directory
        # Stop any existing services
        log_info "Stopping any existing services..."
        $compose_cmd down --remove-orphans &> /dev/null || true
        
        # Start services
        log_info "Starting nginx container..."
        if ! $compose_cmd up -d; then
            log_error "Failed to start Docker services"
            log_info "You can try manually with: cd $PROCESS_DIR && $compose_cmd up -d"
            return 1
        fi
        
        # Wait for services to be ready
        log_info "Waiting for services to be ready..."
        sleep 5
        
        # Check if nginx is running
        if ! $compose_cmd ps | grep -q "nginx-$app_name.*Up"; then
            log_warning "Nginx container may not be running properly"
            log_info "Check status with: cd $PROCESS_DIR && $compose_cmd ps"
            log_info "View logs with: cd $PROCESS_DIR && $compose_cmd logs nginx"
        else
            log_success "Docker services started successfully"
        fi
    fi
}

# Function to verify the setup
verify_setup() {
    local domain="$1"
    local port="$2"
    
    log_info "Verifying setup..."
    
    # Check if certificates exist
    if [[ ! -f "certs/$domain.crt" ]] || [[ ! -f "certs/$domain.key" ]]; then
        log_error "SSL certificates not found"
        return 1
    fi
    
    # Check if nginx config exists
    if [[ ! -f "nginx/$domain.conf" ]]; then
        log_error "Nginx configuration not found"
        return 1
    fi
    
    # Check if docker-compose.yml exists
    if [[ ! -f "docker-compose.yml" ]]; then
        log_error "Docker Compose configuration not found"
        return 1
    fi
    
    # Test nginx configuration syntax
    local compose_cmd="docker compose"
    if ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    if ! $compose_cmd config > /dev/null 2>&1; then
        log_error "Docker Compose configuration is invalid"
        return 1
    fi
    
    log_success "Setup verification completed successfully"
}

# Function to show completion summary
show_completion_summary() {
    local domain="$1"
    local app_name="$2"
    local port="$3"
    
    log_success "FoodMe HTTPS development environment setup completed!"
    echo
    echo "📋 Setup Summary:"
    echo "  • Domain: https://$domain"
    echo "  • App Name: $app_name" 
    echo "  • Backend Port: $port"
    echo "  • SSL Certificates: Generated and installed"
    echo "  • Nginx Proxy: Configured and running"
    echo "  • Hosts File: Updated"
    echo
    echo "🚀 Next Steps:"
    echo "  1. Start your application on port $port"
    echo "  2. Visit https://$domain in your browser"
    echo "  3. Your app will be served with HTTPS automatically"
    echo
    echo "📝 Useful Commands:"
    echo "  • View nginx status: cd $PROCESS_DIR && docker compose ps"
    echo "  • View nginx logs: cd $PROCESS_DIR && docker compose logs nginx"
    echo "  • Stop nginx: cd $PROCESS_DIR && docker compose down"
    echo "  • Restart nginx: cd $PROCESS_DIR && docker compose restart"
    echo
    echo "🔧 Troubleshooting:"
    echo "  • If nginx fails to start: Check if ports 80/443 are available"
    echo "  • If certificates don't work: Try running 'mkcert -install' manually"
    echo "  • If domain doesn't resolve: Check your hosts file entry"
    echo
    echo "📁 Generated Files:"
    echo "  • SSL Certificates: $PROCESS_DIR/certs/"
    echo "  • Nginx Config: $PROCESS_DIR/nginx/$domain.conf"
    echo "  • Docker Compose: $PROCESS_DIR/docker-compose.yml"
}

# Main execution function
main() {
    local domain="$1"
    local app_name="$2"
    local port="$3"
    
    log_info "Starting FoodMe HTTPS development environment setup..."
    log_info "Domain: $domain, App: $app_name, Port: $port"
    echo
    
    # Step 1: Get system information
    get_system_info
    
    # Step 2: Validate inputs
    validate_inputs "$domain" "$app_name" "$port"
    
    # Step 3: Check dependencies
    check_dependencies
    
    # Step 4: Setup workspace
    setup_workspace
    
    # Step 5: Download mkcert
    download_mkcert
    
    # Step 6: Generate SSL certificates
    generate_certificates "$domain"
    
    # Step 7: Create nginx configuration
    create_nginx_config "$domain" "$port"
    
    # Step 8: Create docker compose configuration
    create_docker_compose "$domain" "$app_name"
    
    # Step 9: Manage hosts file
    manage_hosts_file "$domain"
    
    # Step 10: Start services
    start_services "$app_name"
    
    # Step 11: Verify setup
    verify_setup "$domain" "$port"
    
    # Step 12: Change back to original directory
    cd "$SCRIPT_DIR"
    
    # Step 13: Show completion summary
    show_completion_summary "$domain" "$app_name" "$port"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if help is requested
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # Check argument count
    if [[ $# -ne 3 ]]; then
        log_error "Invalid number of arguments"
        echo
        show_usage
        exit 1
    fi
    
    # Run main function with provided arguments
    main "$1" "$2" "$3"
fi