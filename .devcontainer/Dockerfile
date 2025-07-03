# This file is not currently used in the project.
# Note: This Dockerfile is for a development container setup in Visual Studio Code.
# It is designed to provide a consistent development environment for Node.js applications.
# It includes the necessary tools and configurations to work with Node.js and JavaScript projects.
# If you want to use the custom Dockerfile instead, update your devcontainer.json:
# {
#    "name": "FoodMe Development Container",
#    "build": {
#        "dockerfile": "Dockerfile"
#    },
#    // ... rest of config
# }

# Use the official dev container base image
FROM mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm

# Install additional tools including curl (though it's usually already included)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    htop \
    tree \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install additional global npm packages if needed
# RUN npm install -g @angular/cli

# Set the default user back to vscode
USER vscode
