#!/bin/bash
endpoints=("/health")
base_url="http://localhost:3000"

for endpoint in "${endpoints[@]}"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$base_url$endpoint" 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo "✅ Health check passed on $endpoint"
        exit 0
    fi
done

if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    if timeout 5 bash -c "</dev/tcp/localhost/3000" 2>/dev/null; then
        echo "✅ TCP connection successful"
        exit 0
    fi
fi

echo "❌ Health checks failed"
exit 1
