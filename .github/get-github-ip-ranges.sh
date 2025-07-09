#!/bin/bash

# Script to get current GitHub Actions IP ranges
# Usage: ./get-github-ip-ranges.sh

echo "🔍 Fetching current GitHub Actions IP ranges..."

# Fetch GitHub's IP ranges
GITHUB_IPS=$(curl -s https://api.github.com/meta | jq -r '.actions[]' 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$GITHUB_IPS" ]; then
    echo "✅ Successfully fetched GitHub Actions IP ranges"
    echo ""
    echo "🔧 Add this to your ALLOWED_CIDR_BLOCKS GitHub secret:"
    echo ""
    echo "["
    echo "$GITHUB_IPS" | sed 's/^/  "/' | sed 's/$/",/' | sed '$s/,$//'
    echo "]"
    echo ""
    echo "📝 Note: These IP ranges may change over time. Check periodically."
else
    echo "❌ Failed to fetch GitHub IP ranges"
    echo "💡 Using fallback ranges (may be outdated):"
    echo ""
    echo '["4.175.114.0/24", "4.175.115.0/24", "13.64.0.0/16", "20.21.0.0/16", "20.36.0.0/16", "20.37.0.0/16", "20.38.0.0/16", "20.39.0.0/16", "20.40.0.0/16", "20.41.0.0/16", "20.42.0.0/16", "20.43.0.0/16", "20.44.0.0/16", "20.45.0.0/16"]'
fi

echo ""
echo "🛡️ Security Tips:"
echo "- These ranges allow GitHub Actions runners to SSH to your EC2"
echo "- Consider using AWS Systems Manager Session Manager for better security"
echo "- Monitor your security group rules regularly"
echo "- Use environment-specific restrictions when possible"
