#!/bin/bash
# Quick diagnostic script to check user_data execution status

echo "🔍 User Data Execution Diagnostic"
echo "================================="
echo "Current time: $(date)"
echo ""

echo "📋 Cloud-init status:"
cloud-init status --long || echo "Cloud-init status unavailable"
echo ""

echo "📋 Recent progress markers (last 20):"
grep "🔄 PROGRESS" /var/log/cloud-init-output.log /var/log/user-data-execution.log 2>/dev/null | tail -20 || echo "No progress markers found"
echo ""

echo "📋 Active processes (user_data related):"
ps aux | grep -E "(user.?data|cloud.?init|dnf|yum|postgresql|nginx|newrelic)" | grep -v grep || echo "No related processes found"
echo ""

echo "📋 Service status:"
echo "  - PostgreSQL: $(systemctl is-active postgresql-16 2>/dev/null || echo 'inactive')"
echo "  - Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'inactive')"
if command -v newrelic-infra >/dev/null 2>&1; then
    echo "  - New Relic: $(systemctl is-active newrelic-infra 2>/dev/null || echo 'inactive')"
else
    echo "  - New Relic: not installed"
fi
echo ""

echo "📋 System load:"
uptime
echo ""

echo "📋 Recent errors in logs:"
tail -20 /var/log/cloud-init.log | grep -i error || echo "No recent errors in cloud-init.log"
echo ""

echo "📋 Disk space:"
df -h / || echo "Disk space check failed"
echo ""

echo "📋 Memory usage:"
free -h || echo "Memory check failed"
echo ""

echo "📋 Network connectivity test:"
curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/instance-id > /dev/null && echo "✅ Metadata service reachable" || echo "❌ Metadata service unreachable"
curl -s --connect-timeout 5 https://download.newrelic.com > /dev/null && echo "✅ External connectivity working" || echo "❌ External connectivity issues"
