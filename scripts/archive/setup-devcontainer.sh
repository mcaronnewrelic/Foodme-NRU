#!/bin/bash

# FoodMe DevContainer Development Environment Setup Script
# ======================================================
# This script sets up a secure HTTPS development environment specifically
# for GitHub Codespaces and DevContainer environments.
# 
# Key differences from setup.sh:
# - Uses localhost instead of custom domain (avoids hosts file modification)
# - Uses different port mappings to avoid conflicts
# - Optimized for container-to-container networking
#
# Usage: ./setup-devcontainer.sh <app_name> <port>
# Example: ./setup-devcontainer.sh foodme 3000

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROCESS_DIR=".setup"
readonly DOMAIN="localhost"

# Global variables
declare OS_TYPE=""
declare ARCHITECTURE=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Setup failed with exit code $exit_code"
        log_info "Cleaning up temporary files..."
        [[ -d "$PROCESS_DIR" ]] && rm -rf "$PROCESS_DIR/mkcert*" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME <app_name> <port>

Arguments:
  app_name  - The application name for Docker containers (e.g., foodme)
  port      - The port where your application is running (e.g., 3000)

Examples:
  $SCRIPT_NAME foodme 3000
  $SCRIPT_NAME myapp 8080

This DevContainer-optimized script will:
1. Download and install mkcert for SSL certificate generation
2. Create SSL certificates for localhost
3. Set up an Nginx reverse proxy accessible via HTTPS
4. Configure Docker Compose for container management
5. Use localhost (no hosts file modification needed)

The app will be accessible at: https://localhost:8443

Requirements:
- Docker (available via docker-outside-of-docker feature)
- Internet connection (to download mkcert)
EOF
}

# System detection
get_system_info() {
    local os_type="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local architecture="$(uname -m | tr '[:upper:]' '[:lower:]')"
    
    case "$os_type" in
        darwin) OS_TYPE="darwin" ;;
        linux) OS_TYPE="linux" ;;
        *) OS_TYPE="linux" ;;
    esac
    
    case "$architecture" in
        x86_64|amd64) ARCHITECTURE="amd64" ;;
        arm64|aarch64) ARCHITECTURE="arm64" ;;
        armv7l) ARCHITECTURE="armv7" ;;
        i386|i686) ARCHITECTURE="386" ;;
        *) ARCHITECTURE="amd64" ;;
    esac
    
    log_info "Detected system: $OS_TYPE/$ARCHITECTURE"
}

# Input validation
validate_inputs() {
    local app_name="$1"
    local port="$2"
    
    if [[ ! "$app_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        log_error "Invalid app name format: $app_name"
        return 1
    fi
    
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log_error "Invalid port number: $port"
        return 1
    fi
    
    log_success "Input validation passed"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        return 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        return 1
    fi

    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose is not available"
        return 1
    fi
    
    if ! curl -s --connect-timeout 5 https://dl.filippo.io &> /dev/null; then
        log_error "No internet connection"
        return 1
    fi
    
    log_success "All dependencies available"
}

# Setup workspace
setup_workspace() {
    log_info "Setting up workspace..."
    
    if [[ ! -d "$PROCESS_DIR" ]]; then
        mkdir -p "$PROCESS_DIR" || return 1
        log_success "Created $PROCESS_DIR directory"
    fi

    cd "$PROCESS_DIR" || return 1
    log_success "Workspace ready"
}

# Download mkcert
download_mkcert() {
    log_info "Downloading mkcert..."
    
    if [[ -x "./mkcert" ]]; then
        log_info "mkcert already exists"
        return 0
    fi
    
    local download_url="https://dl.filippo.io/mkcert/latest?for=$OS_TYPE/$ARCHITECTURE"
    
    if ! curl -fsSL "$download_url" -o mkcert; then
        log_error "Failed to download mkcert"
        return 1
    fi
    
    chmod +x mkcert || return 1
    log_success "mkcert downloaded"
}

# Generate certificates
generate_certificates() {
    log_info "Generating SSL certificates for localhost..."
    
    mkdir -p certs || return 1
    
    log_info "Installing mkcert CA..."
    ./mkcert -install || {
        log_warning "CA installation failed, but continuing..."
    }
    
    log_info "Generating certificates..."
    if ! ./mkcert -key-file "./certs/localhost.key" -cert-file "./certs/localhost.crt" localhost 127.0.0.1 ::1; then
        log_error "Failed to generate certificates"
        return 1
    fi
    
    chmod 644 "./certs/localhost.crt" "./certs/localhost.key" || true
    log_success "SSL certificates generated"
}

# Create nginx config
create_nginx_config() {
    local port="$1"
    
    log_info "Creating Nginx configuration..."
    
    mkdir -p nginx || return 1
    
    cat > "nginx/localhost.conf" << EOF
# Nginx configuration for DevContainer
# Generated by FoodMe setup script

server {
    listen 80;
    server_name localhost;
    
    location / {
        return 301 https://\$host:8443\$request_uri;
    }
    
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}

server {
    listen 443 ssl http2;
    server_name localhost;
    
    ssl_certificate /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    location / {
        # Forward to application running in devcontainer
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /nginx-status {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF
    
    log_success "Nginx configuration created"
}

# Create docker compose
create_docker_compose() {
    local app_name="$1"
    
    log_info "Creating Docker Compose configuration..."
    
    cat > docker-compose.yml << EOF
# Docker Compose for DevContainer
# Generated by FoodMe setup script

services:
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-devcontainer-$app_name
    restart: unless-stopped
    ports:
      - "8080:80"   # HTTP on port 8080 to avoid conflicts
      - "8443:443"  # HTTPS on port 8443 to avoid conflicts
    volumes:
      - ./nginx/localhost.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs/localhost.crt:/etc/nginx/certs/localhost.crt:ro
      - ./certs/localhost.key:/etc/nginx/certs/localhost.key:ro
    network_mode: host  # Use host networking for devcontainer compatibility
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/nginx-health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    labels:
      - "com.docker.compose.project=devcontainer-$app_name"
EOF
    
    log_success "Docker Compose configuration created"
}

# Start services
start_services() {
    local app_name="$1"
    
    log_info "Starting services..."
    
    local compose_cmd="docker compose"
    if ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    log_info "Stopping any existing services..."
    $compose_cmd down --remove-orphans &> /dev/null || true
    
    log_info "Starting nginx container..."
    if ! $compose_cmd up -d; then
        log_error "Failed to start services"
        return 1
    fi
    
    sleep 5
    
    if ! $compose_cmd ps | grep -q "nginx-devcontainer-$app_name.*Up"; then
        log_warning "Nginx container may not be running properly"
        log_info "Check with: cd $PROCESS_DIR && $compose_cmd ps"
    else
        log_success "Services started successfully"
    fi
}

# Show completion summary
show_completion_summary() {
    local app_name="$1"
    local port="$2"
    
    log_success "DevContainer HTTPS environment setup completed!"
    echo
    echo "📋 Setup Summary:"
    echo "  • HTTPS URL: https://localhost:8443"
    echo "  • HTTP URL: http://localhost:8080 (redirects to HTTPS)"
    echo "  • App Name: $app_name"
    echo "  • Backend Port: $port"
    echo
    echo "🚀 Next Steps:"
    echo "  1. Start your FoodMe application on port $port"
    echo "  2. Visit https://localhost:8443 in your browser"
    echo "  3. Accept the self-signed certificate if prompted"
    echo
    echo "📝 Useful Commands:"
    echo "  • Check status: cd $PROCESS_DIR && docker compose ps"
    echo "  • View logs: cd $PROCESS_DIR && docker compose logs nginx"
    echo "  • Stop nginx: cd $PROCESS_DIR && docker compose down"
    echo "  • Restart: cd $PROCESS_DIR && docker compose restart"
    echo
    echo "🔧 DevContainer Notes:"
    echo "  • Uses localhost (no hosts file modification)"
    echo "  • HTTPS on port 8443 to avoid conflicts"
    echo "  • HTTP on port 8080 (redirects to HTTPS)"
    echo "  • Self-signed certificate (normal in dev)"
}

# Main function
main() {
    local app_name="$1"
    local port="$2"
    
    log_info "Starting DevContainer HTTPS setup..."
    log_info "App: $app_name, Port: $port"
    echo
    
    get_system_info
    validate_inputs "$app_name" "$port"
    check_dependencies
    setup_workspace
    download_mkcert
    generate_certificates
    create_nginx_config "$port"
    create_docker_compose "$app_name"
    start_services "$app_name"
    
    cd "$SCRIPT_DIR"
    show_completion_summary "$app_name" "$port"
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ $# -ne 2 ]]; then
        log_error "Invalid number of arguments"
        echo
        show_usage
        exit 1
    fi
    
    main "$1" "$2"
fi
