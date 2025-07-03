#!/bin/bash
# Run Locust load test from within the Docker network

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "Starting Docker Compose services..."
    docker-compose up -d
    echo "Waiting for services to be ready..."
    sleep 10
fi

# Create a temporary container to run Locust from within the network
echo "Running Locust load test from within Docker network..."

# Copy locustfile to a temp directory that can be mounted
mkdir -p /tmp/foodme-loadtest
cp locustfile.py /tmp/foodme-loadtest/
cp requirements.txt /tmp/foodme-loadtest/

# Run Locust in a temporary container connected to the foodme network
docker run --rm \
    --network foodme_foodme_network \
    -v /tmp/foodme-loadtest:/app \
    -w /app \
    python:3.11-slim \
    bash -c "
        pip install -r requirements.txt && 
        locust -f locustfile.py --host=http://foodme:3000 --headless -u 10 -r 2 -t 30s
    "

# Clean up
rm -rf /tmp/foodme-loadtest

echo "Load test completed!"
