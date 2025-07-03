#!/bin/bash

# This script sets up a development server for any application(running on a local port) using Docker, Nginx, and mkcert.
# It downloads mkcert, generates SSL certificates, creates an Nginx configuration file, and sets up a Docker Compose file.
# The script requires a Domain Name, Application Name and Port as an argument.

# Get the operating system type
OS_TYPE="$(echo "$(uname -s)" | tr '[:upper:]' '[:lower:]')"

# Get the system architecture
ARCHITECTURE="$(echo "$(uname -m)" | tr '[:upper:]' '[:lower:]')"

ACTUAL_OS_TYPE="$OS_TYPE"
ACTUAL_ARCHITECTURE="$ARCHITECTURE"

PROCESS_DIR=".setup"


# Function to check if Docker is installed and running
check_dependencies() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker and try again."
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo "Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to preprocess the script
pre_process() {
    if [[ "$OS_TYPE" != "darwin" && "$OS_TYPE" != "linux" ]]; then
        ACTUAL_OS_TYPE="windows"
    fi

    # Reassign the architecture value based on the correct knowledge available
    if [[ "$ARCHITECTURE" == "x86_64" ]]; then
        ACTUAL_ARCHITECTURE="amd64"
    fi

    echo; echo "OS Type: $ACTUAL_OS_TYPE"; echo "OS Architecture: $ACTUAL_ARCHITECTURE"

    # Check if the '.setup' directory exists
    if [ ! -d "$PROCESS_DIR" ]; then
        mkdir "$PROCESS_DIR" 2>/dev/null
        echo; echo "Created '$PROCESS_DIR' folder"
    fi

    cd "$PROCESS_DIR"
}


add_virtual_host() {
    HOSTS_FILE="/etc/hosts"

    if [[ "$ACTUAL_OS_TYPE" == "windows" ]]; then
        HOSTS_FILE="/c/Windows/System32/drivers/etc/hosts"
    fi

    if ! grep -q "$1" "$HOSTS_FILE"; then

        if [[ "$ACTUAL_OS_TYPE" == "windows" ]]; then
                echo "127.0.0.1 $1" | tee -a "$HOSTS_FILE" > /dev/null
        else
                echo "127.0.0.1 $1" | sudo tee -a "$HOSTS_FILE" > /dev/null
        fi

        echo; echo "Added $1 to '"$HOSTS_FILE"' file"
    else
        echo ""\
        "'$1' already added in '"$HOSTS_FILE"' file, skipping this step."
    fi
}


# Function to download mkcert
download_mkcert() {
    echo; echo "Downlinading mkcert."

    MKCERT_EXECUTABLE="mkcert-v*-$ACTUAL_OS_TYPE-$ACTUAL_ARCHITECTURE*"
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=$ACTUAL_OS_TYPE/$ACTUAL_ARCHITECTURE"
    mv $MKCERT_EXECUTABLE "mkcert"
    chmod +x "mkcert"
}

# Function to generate SSL certificates using mkcert
generate_certificates() {
    mkdir 'certs' 2>/dev/null
    "./mkcert" -install -key-file "./certs/$1.key" -cert-file "./certs/$1.crt" $1 *.$1
    chmod +rw "./certs"
}

# Function to create the Nginx configuration file
create_nginx_conf() {
    echo; echo "Generating nginx configuration file."

    mkdir "nginx" 2>/dev/null

    cat <<EOF >"nginx/$1.conf"
    server {
        listen 80;
        server_name $1 www.$1;

        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    server {
        listen 443 ssl;
        server_name $1 www.$1;
        ssl_certificate /etc/nginx/certs/$1.crt;
        ssl_certificate_key /etc/nginx/certs/$1.key;

        location / {
            proxy_pass http://foodme:${2};
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
EOF
}

# Function to create the Docker Compose file
create_docker_compose() {
     echo; echo "Generating 'docker-compose.yml' file."

    cat <<EOF >"docker-compose.yml"
    services:
        nginx:
            image: nginx:latest
            container_name: nginx-$2
            ports:
            - '80:80'
            - "443:443"
            volumes:
            - './nginx/$1.conf:/etc/nginx/conf.d/$1.conf'
            - './certs/$1.crt:/etc/nginx/certs/$1.crt'
            - './certs/$1.key:/etc/nginx/certs/$1.key'
            networks:
            - nginx_network

    networks:
        nginx_network:
EOF
}

# Function to run Docker Compose
run_docker_compose() {
    echo; echo "Starting nginx docker container"

    docker-compose up -d
}

# Function to post-process the script
post_process() {
    cd ".."
    echo "Setup complete! Now you can run this command if nginx server is not started due to any reason: cd .setup && docker-compose up -d"
}

# Check if argument count is correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <Domain> <App Name> <Port>"
    exit 1
fi

# check_dependencies
pre_process

download_mkcert

# generate certificate
generate_certificates "$1"

# generate nginx config file
create_nginx_conf "$1" "$3"

# generate docker compose file
create_docker_compose "$1" "$2"

add_virtual_host "$1"

run_docker_compose

post_process