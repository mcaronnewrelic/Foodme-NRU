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
- [📚 Documentation](#-documentation)
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

```bash
# Setup environment
npm run setup:env
# Edit .env with your configuration

# Install dependencies
npm run install:all

# Start development server
npm run dev

# Or run with Docker
npm run docker:run
```

> 📚 **For detailed setup instructions**, see [SETUP_GUIDE.md](./SETUP_GUIDE.md)  
> 🗄️ **For database setup**, see [DATABASE_GUIDE.md](./DATABASE_GUIDE.md)

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

## 📚 Documentation

### 🔐 Security & Configuration
| Document | Description |
|----------|-------------|
| **[Security Documentation](./SECURITY.md)** | Comprehensive security measures, secret management, and best practices |
| **[Secret Management Guide](./SECRET_MANAGEMENT.md)** | Environment variable configuration and secret handling |
| **[Docker Secrets](./DOCKER_SECRETS.md)** | Container security and secret injection patterns |
| **[Security Compliance](./SECURITY_COMPLIANCE.md)** | Compliance checks and validation procedures |

### 🚀 Deployment & Operations  
| Document | Description |
|----------|-------------|
| **[Setup Guide](./SETUP_GUIDE.md)** | Complete project setup, dependencies, and development environment configuration |
| **[Database Guide](./DATABASE_GUIDE.md)** | PostgreSQL setup, initialization, and restaurant data management |
| **[Deployment Guide](./DEPLOYMENT_GUIDE.md)** | Complete deployment workflows and environment management |
| **[Load Testing](./LOAD_TESTING.md)** | Performance testing with Locust, metrics, and analysis |

### 💡 Quick Reference
- **Setup Guide**: Follow [SETUP_GUIDE.md](./SETUP_GUIDE.md) for complete project setup
- **Database Setup**: Use [DATABASE_GUIDE.md](./DATABASE_GUIDE.md) for PostgreSQL initialization  
- **Security Validation**: Run `npm run security:validate` for comprehensive security checks
- **Load Testing**: Execute `npm run loadtest` for performance testing
- **Deployment**: Use `npm run deploy` for full deployment workflow
- **Environment Setup**: Copy `.env.example` to `.env` and configure your settings

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





