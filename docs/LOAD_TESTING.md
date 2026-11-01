# Load Testing with Locust

This project includes load testing capabilities using [Locust](https://locust.io/), a Python-based load testing tool.

## Prerequisites

- Python 3.11+ (included in dev container)
- Locust and dependencies (automatically installed in dev container)

## Quick Start

1. **Start the FoodMe application:**
   ```bash
   npm start
   # or
   ./deploy.sh -s
   ```

2. **Run load tests:**
   ```bash
   # Interactive web interface (recommended)
   npm run loadtest:web
   # or
   ./deploy.sh -l
   
   # Headless mode (10 users, 2 users/sec spawn rate, 60 seconds)
   npm run loadtest:headless
   
   # Custom parameters
   npm run loadtest
   ```

## Available Scripts

- `npm run loadtest` - Start Locust with interactive CLI
- `npm run loadtest:web` - Start Locust with web interface (http://localhost:8089)
- `npm run loadtest:headless` - Run automated test (10 users, 60 seconds)
- `./deploy.sh -l` - Run load tests via deploy script

## Web Interface

When using `npm run loadtest:web`, navigate to http://localhost:8089 to:
- Set number of users to simulate
- Set spawn rate (users per second)
- Monitor real-time statistics
- View response time charts
- Download test reports

## Test Scenarios

The `locustfile.py` includes the following test scenarios:
- Restaurant browsing and filtering
- Customer information submission
- Menu browsing and item selection
- Order placement and checkout
- Payment processing simulation

## Monitoring with New Relic

Since the application includes New Relic monitoring, you can observe the performance impact of load tests in your New Relic dashboard in real-time.

## Tips

- Start with a small number of users (5-10) and gradually increase
- Monitor your application's resource usage during tests
- Use the web interface for interactive testing and analysis
- Check New Relic APM for detailed performance metrics during load tests
