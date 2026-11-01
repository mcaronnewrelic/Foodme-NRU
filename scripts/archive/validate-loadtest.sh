#!/bin/bash

# Quick validation script for load testing setup
echo "🔍 Validating Load Testing Setup..."

# Check Python
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
else
    echo "❌ Python3 not found"
    exit 1
fi

# Check virtual environment
if [ -d ".venv" ]; then
    echo "✅ Virtual environment found"
    
    # Check Locust installation
    if [ -f ".venv/bin/locust" ]; then
        echo "✅ Locust: $(.venv/bin/locust --version)"
    else
        echo "❌ Locust not found in virtual environment"
        echo "💡 Run: .venv/bin/pip install -r requirements.txt"
        exit 1
    fi
    
    # Check Faker
    if .venv/bin/python -c "import faker; print('✅ Faker: imported successfully')" 2>/dev/null; then
        :
    else
        echo "❌ Faker not found"
        exit 1
    fi
    
    # Check requests
    if .venv/bin/python -c "import requests; print('✅ Requests: ' + requests.__version__)" 2>/dev/null; then
        :
    else
        echo "❌ Requests not found"
        exit 1
    fi
else
    echo "❌ Virtual environment not found"
    echo "💡 Run: python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    exit 1
fi

# Check locustfile syntax
if .venv/bin/python -m py_compile locustfile.py 2>/dev/null; then
    echo "✅ locustfile.py syntax is valid"
else
    echo "❌ locustfile.py has syntax errors"
    exit 1
fi

echo ""
echo "🎉 Load testing setup is ready!"
echo ""
echo "Available commands:"
echo "  npm run loadtest:web    - Start with web interface (http://localhost:8089)"
echo "  npm run loadtest:headless - Run automated test (10 users, 60s)"
echo "  ./deploy.sh -l          - Run via deploy script"
echo ""
echo "Make sure your application is running on http://localhost:3000 before starting load tests."
