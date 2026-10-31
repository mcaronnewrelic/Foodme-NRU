# 🍕 FoodMe - Restaurant Ordering Application

[![Node.js](https://img.shields.io/badge/Node.js-22-green.svg)](https://nodejs.org/)
[![Angular](https://img.shields.io/badge/Angular-20-red.svg)](https://angular.io/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Validated-brightgreen.svg)](#-security-features)
[![New Relic](https://img.shields.io/badge/New%20Relic-Integrated-purple.svg)](https://newrelic.com/)

A modern, full-stack restaurant ordering application built with Angular 20 frontend and Node.js backend, featuring comprehensive monitoring, security, and deployment automation.

## 📋 Table of Contents

- [🎯 Project Overview](#-project-overview)
- [🚀 Quick Start](#-quick-start)
- [🏗️ Architecture](#️-architecture)
- [� Project Structure](#-project-structure)
- [�📚 Documentation](#-documentation)
- [🛠️ Development](#️-development)
- [🔧 Configuration](#-configuration)
- [🧪 Testing & Quality](#-testing--quality)
- [📊 Monitoring](#-monitoring)
- [🔒 Security Features](#-security-features)
- [🤝 Contributing](#-contributing)

## 🎯 Project Overview

FoodMe is a demonstration application that showcases modern web development practices, security implementations, and operational excellence. Originally designed as an educational workshop application, it has evolved into a production-ready example of:

- **Modern Frontend**: Angular 20 with TypeScript, responsive design, and component-based architecture
- **Robust Backend**: Node.js/Express server with RESTful APIs and structured data handling
- **Monitoring Integration**: New Relic APM for performance monitoring and observability
- **Security First**: Comprehensive secret management and security validation
- **DevOps Ready**: Docker containerization, automated deployment, and load testing

## ✨ Key Features

### User Experience
- 🍽️ **Restaurant Discovery**: Browse and filter from multiple restaurant options
- 📱 **Responsive Design**: Seamless experience across desktop, tablet, and mobile
- 🛒 **Shopping Cart**: Add, remove, and modify orders with real-time updates
- 💳 **Checkout Process**: Streamlined ordering with customer information collection
- ✅ **Order Confirmation**: Clear confirmation and thank you experience

### Technical Features
- ⚡ **Real-time Performance**: Optimized Angular components with efficient rendering
- 🔍 **Search & Filter**: Dynamic restaurant and menu item filtering
- 📊 **Analytics Ready**: Comprehensive event tracking and user behavior monitoring
- 🛡️ **Security Hardened**: OWASP compliant with comprehensive secret management
- 🚀 **Production Ready**: Full CI/CD pipeline with automated testing and deployment

### Developer Experience
- 🐳 **Containerized**: Full Docker support with dev containers
- 🧪 **Load Testing**: Built-in performance testing with realistic user scenarios
- 📋 **Documentation**: Comprehensive guides for setup, deployment, and maintenance
- 🔐 **Security Validation**: Automated security scanning and compliance checks
- 📈 **Monitoring**: Integrated observability with New Relic APM

## 🚀 Quick Start

### Option 1: Simple Docker Development (Recommended for Mac)

Perfect for new developers - get up and running in minutes:

```bash
# 1. Setup environment
npm run setup:env
# Edit .env with your values (copy from .env.example)

# 2. Start simple development environment
npm run docker:dev:simple

# 3. Access your app
# Main app: http://localhost
# Health check: http://localhost/health
# API: http://localhost/api/restaurant
```

**Need more features?** Try the full production simulation:
```bash
npm run docker:dev:full
```

📖 **For complete Docker guide**: [DOCKER_DEVELOPMENT_GUIDE.md](./DOCKER_DEVELOPMENT_GUIDE.md)

### Option 2: GitHub Actions Deployment

Deploy automatically to AWS EC2 using GitHub Actions:

1. **Fork this repository**
2. **Configure GitHub Secrets**:
   ```
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   EC2_KEY_NAME=your-key-pair-name
   EC2_PRIVATE_KEY=your-private-key-content
   NEW_RELIC_API_KEY=your-newrelic-api-key
   ALLOWED_CIDR_BLOCKS=["YOUR_IP/32"]
   ```
3. **Push to main branch** or manually trigger the deployment workflow
4. **Access your application** at the provided EC2 instance IP

### Option 3: Local Development (Non-Docker)

```bash
# Setup environment
npm run setup:env
# Edit .env with your configuration

# Install dependencies
npm run install:all

# Start development server
npm run dev
```

> 📚 **For detailed setup instructions**, see [SETUP_GUIDE.md](./docs/setup/SETUP_GUIDE.md)  
> 🗄️ **For database setup**, see [DATABASE_GUIDE.md](./docs/setup/DATABASE_GUIDE.md)

## 🏗️ Architecture

### Frontend (Angular 20)
- **Components**: Modular UI components for restaurants, menu, checkout, and customer management
- **Services**: Data management for cart, customer, and restaurant operations
- **Responsive Design**: Mobile-first approach with modern CSS
- **TypeScript**: Type-safe development with strict compilation

### Backend (Node.js)
- **Express Server**: RESTful API with structured routing
- **Data Management**: In-memory storage with JSON data persistence
- **Monitoring**: Integrated New Relic APM agent
- **Security**: Environment-based configuration and header protection

### Infrastructure
- **Docker**: Multi-stage builds with production optimization
- **Deployment**: Automated scripts with validation and monitoring
- **Load Testing**: Locust-based performance testing
- **Security**: Comprehensive validation and compliance checks

## � Project Structure

The FoodMe project is organized for clarity and ease of development:

```
foodme/
├── README.md                    # 👈 Project overview and quick start
├── DOCKER_DEVELOPMENT_GUIDE.md # 🐳 Complete Docker development guide
├── package.json                # 📦 Main project dependencies and scripts
│
├── angular-app/                # 🅰️ Angular frontend application
├── server/                     # 🌐 Node.js backend server
├── docker/                     # 🐳 Docker configurations (simplified)
├── docs/                       # 📚 Organized documentation
│   ├── setup/                 # 🛠️ Setup and configuration guides
│   ├── deployment/            # 🚀 Deployment documentation
│   └── troubleshooting/       # 🔧 Problem-solving guides
└── scripts/                    # 🔧 Deployment and utility scripts
```

**📖 For complete project structure details**: [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)

**🎯 New Developer Path:**
1. This README for overview
2. [DOCKER_DEVELOPMENT_GUIDE.md](./DOCKER_DEVELOPMENT_GUIDE.md) for quick start
3. [docs/README.md](./docs/README.md) for specific documentation

## �📚 Documentation

### � Essential Reading
- **[Docker Development Guide](./DOCKER_DEVELOPMENT_GUIDE.md)** - 🐳 **START HERE** for local development
- **[Project Structure](./PROJECT_STRUCTURE.md)** - 📁 Understanding the organized codebase
- **[Documentation Index](./docs/README.md)** - 📚 Which document to read for what

### 🎯 Quick Access by Topic

#### �️ Setup & Configuration
- **[Setup Guide](./docs/setup/SETUP_GUIDE.md)** - Complete project setup and dependencies
- **[Database Guide](./docs/setup/DATABASE_GUIDE.md)** - PostgreSQL configuration and management
- **[Environment Variables](./docs/setup/ENVIRONMENT_VARIABLES.md)** - Configuration and secrets
- **[DevContainer Setup](./docs/setup/DEVCONTAINER_SETUP.md)** - VS Code development containers

#### 🚀 Deployment & Operations  
- **[Deployment Guide](./docs/deployment/DEPLOYMENT_GUIDE.md)** - Production deployment workflows
- **[CloudFormation Templates](./cloudformation/README.md)** - AWS infrastructure deployment
- **[Terraform Deployment](./terraform/README.md)** - Infrastructure as code with Terraform

#### 📊 Monitoring & Testing
- **[New Relic Demo Features](./docs/NEW_RELIC_DEMO.md)** - "Behind the scenes" callouts, planned failures and source maps
- **[New Relic Setup Scripts](./newrelic/README.md)** - Dashboard, service levels, alerts and workload
- **[New Relic Infrastructure Setup](./docs/NEW_RELIC_INFRA_SETUP.md)** - Host and database monitoring
- **[Load Testing](./docs/LOAD_TESTING.md)** - Performance testing with Locust
- **[Security](./docs/SECURITY.md)** - Practices, checks and the open findings from the security review

#### 🔧 Troubleshooting
- **[EC2 and Terraform Troubleshooting](./docs/troubleshooting/EC2_TROUBLESHOOTING.md)** - Terraform errors and EC2 deployment issues
- **[Docker Comprehensive Guide](./docs/troubleshooting/DOCKER_COMPREHENSIVE_GUIDE.md)** - Docker services, commands and fixes for common problems

### 💡 Quick Reference for New Developers
1. **[README.md](./README.md)** - This file, project overview
2. **[DOCKER_DEVELOPMENT_GUIDE.md](./DOCKER_DEVELOPMENT_GUIDE.md)** - Get coding in 3 steps
3. **[docs/README.md](./docs/README.md)** - Find any specific documentation
- **DevContainer Setup**: Use [DEVCONTAINER_SETUP.md](./docs/setup/DEVCONTAINER_SETUP.md) for dev container configurations
- **Database Setup**: Use [DATABASE_GUIDE.md](./docs/setup/DATABASE_GUIDE.md) for PostgreSQL initialization  
- **Terraform Deployment**: Use [terraform/README.md](./terraform/README.md) for AWS EC2 deployment
- **GitHub Actions**: Push to main branch for automatic deployment to EC2
- **Security Validation**: Run `npm run security:validate` for comprehensive security checks
- **Load Testing**: Execute `npm run loadtest` for performance testing
- **Deployment**: Use `npm run deploy` for full deployment workflow
- **Environment Setup**: Copy `.env.example` to `.env` and configure your settings
- **AWS Cleanup**: Use [Cleanup Guide](./.github/CLEANUP_GUIDE.md) for removing failed deployments

## 🛠️ Development

### Prerequisites
- Node.js 22+ (or use the included dev container)
- Docker and Docker Compose
- Python 3.11+ (for load testing)

### Project Structure
```
foodme/
├── angular-app/          # Angular 20 frontend application
│   ├── src/app/         # Application components and services
│   └── public/          # Static assets and icons
├── server/              # Node.js/Express backend
│   ├── data/           # JSON data files
│   └── views/          # Handlebars templates
├── .devcontainer/      # VS Code dev container configuration
└── docs/               # Documentation files (*.md)
```

### Available Scripts

#### Development
```bash
npm run dev              # Start development server
npm run build           # Build Angular app and server
npm run start           # Production start with New Relic
```

#### Docker Operations
```bash
npm run docker:build    # Build Docker image
npm run docker:run      # Run container with environment file
npm run docker:with-secrets  # Interactive deployment with secrets
```

#### Deployment & Testing
```bash
npm run deploy          # Full deployment workflow
npm run loadtest        # Run load tests with Locust
npm run security:validate    # Run security validation
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:

```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your_license_key
NEW_RELIC_API_KEY=your_api_key

# Application Settings
NODE_ENV=production
PORT=3000
```

### Docker Configuration
- **Multi-stage builds** for optimized production images
- **Non-root user** execution for security
- **Environment variable injection** for configuration
- **.dockerignore** for build context optimization

### DevContainer & Docker Compose Configurations

FoodMe includes multiple Docker Compose configurations to support different development environments:

#### Main Configuration (`docker-compose.yml`)
- **Purpose**: Production-ready setup with full New Relic monitoring
- **Features**: Complete infrastructure monitoring, nginx reverse proxy, PostgreSQL
- **Best for**: Host development, CI/CD pipelines, production deployment

#### DevContainer Fallback (`docker-compose.dev.yml`)
- **Purpose**: Simplified setup for dev containers with limited privileges
- **Features**: Basic New Relic monitoring without privileged access requirements
- **Best for**: GitHub Codespaces, VS Code dev containers, restricted environments

#### Load Testing (`docker-compose.loadtest.yml`)
- **Purpose**: Isolated load testing with Locust
- **Features**: Performance testing against running application
- **Best for**: Load testing, performance benchmarking

#### Using Fallback Configurations in DevContainers

**Method 1: Override with specific compose file**
```bash
# Use dev container friendly configuration
docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up -d

# Use load testing configuration
docker compose -f docker/docker-compose.loadtest.yml up -d
```

**Method 2: Environment-specific startup**
```bash
# For restricted environments (like dev containers)
export DOCKER_COMPOSE_ENV=dev
npm run docker:compose:dev

# For load testing
npm run loadtest:docker
```

**Method 3: Manual container selection**
```bash
# Start only specific services from dev config
docker compose -f docker/docker-compose.dev.yml up newrelic-infra-simple -d

# Start load testing
docker compose -f docker/docker-compose.loadtest.yml up locust
```

#### DevContainer Configuration Differences

| Feature                | Main Config                | DevContainer Config        |
| ---------------------- | -------------------------- | -------------------------- |
| **Privileged Access**  | ✅ Full host access         | ❌ Restricted for security  |
| **Process Monitoring** | ✅ Enabled                  | ❌ Disabled                 |
| **Host Volume Mounts** | ✅ Full host filesystem     | ❌ Docker socket only       |
| **Network Mode**       | Bridge with custom network | Bridge mode                |
| **New Relic Features** | Full monitoring suite      | Basic container monitoring |

#### Troubleshooting DevContainer Issues

If you encounter issues with the main configuration in a dev container:

1. **Permission Errors**: Use the dev configuration
   ```bash
   docker compose -f docker/docker-compose.dev.yml up -d
   ```

2. **Privileged Access Denied**: The dev config removes privileged requirements
   ```bash
   # Check what's different
   grep -A 10 "privileged\|cap_add\|pid:" docker/docker-compose.yml
   # vs
   grep -A 10 "network_mode\|volumes:" docker/docker-compose.dev.yml
   ```

3. **Volume Mount Issues**: Dev config uses minimal volume mounts
   ```bash
   # Only mounts Docker socket instead of full host
   docker compose -f docker/docker-compose.dev.yml logs newrelic-infra-simple
   ```

#### Adding to Package.json Scripts

Add these convenience scripts to your `package.json`:

```json
{
  "scripts": {
    "docker:compose:dev": "docker compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up -d",
    "docker:compose:loadtest": "docker compose -f docker/docker-compose.loadtest.yml up",
    "docker:dev:logs": "docker compose -f docker/docker-compose.dev.yml logs -f",
    "docker:dev:down": "docker compose -f docker/docker-compose.dev.yml down"
  }
}
```

## 🧪 Testing & Quality

### Load Testing
Built-in Locust configuration for performance testing:
```bash
npm run loadtest        # Interactive load testing
npm run loadtest:headless   # Automated performance tests
```

### Security Validation
Comprehensive security checks:
```bash
npm run security:validate   # Full security audit
npm run security:docker     # Dockerfile security scanning
```

## 📊 Monitoring

### New Relic Integration
- **APM Monitoring**: Application performance and error tracking
- **Browser Monitoring**: Real user monitoring and page load times
- **Custom Metrics**: Business-specific monitoring and alerting
- **Deployment Tracking**: Automated deployment markers

### Key Metrics
- Response times and throughput
- Error rates and exceptions  
- Database query performance
- User experience metrics

## 🔒 Security Features

- **Secret Management**: Environment-based configuration with no hardcoded credentials
- **Container Security**: Non-root execution and minimal attack surface
- **Header Protection**: Security headers and sensitive data filtering
- **Validation Pipeline**: Automated security checks in CI/CD
- **Compliance**: OWASP security guidelines and best practices

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow TypeScript best practices
- Maintain test coverage
- Update documentation
- Run security validation before commits

## 📄 License

This project is part of the New Relic University workshop series and is provided for educational purposes.

## 🆘 Support & Resources

- **Workshop Materials**: Part of New Relic University curriculum
- **Documentation**: Comprehensive guides in the `/docs` folder
- **Issues**: Report bugs and feature requests via GitHub Issues
- **New Relic**: [Official Documentation](https://docs.newrelic.com/)

---

**Built with ❤️ for learning modern web development, security, and observability practices.**





