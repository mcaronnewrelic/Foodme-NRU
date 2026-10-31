# New Relic Infrastructure Agent Installation Guide for Amazon Linux 2023

## Issue
The New Relic Infrastructure Agent has dependency conflicts on Amazon Linux 2023 due to OpenSSL library requirements.

## Manual Installation (if needed)

### Option 1: Install with --skip-broken (recommended)
```bash
# Add New Relic repository
curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2/x86_64/newrelic-infra.repo

# Update repository cache
dnf makecache -y --disablerepo='*' --enablerepo='newrelic-infra'

# Install with dependency conflict resolution
sudo dnf install -y newrelic-infra --skip-broken
```

### Option 2: Use Docker version
```bash
# Install and configure New Relic via Docker
docker run -d \
  --name newrelic-infra \
  --network=host \
  --cap-add=SYS_PTRACE \
  --privileged \
  --pid=host \
  -v "/:/host:ro" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -e NRIA_LICENSE_KEY=YOUR_LICENSE_KEY \
  newrelic/infrastructure:latest
```

### Option 3: Use New Relic Agent API (alternative)
Consider using the New Relic APM agent directly in your Node.js application instead of the infrastructure agent.

## Configuration
Once installed, configure with your license key:
```bash
echo "license_key: YOUR_LICENSE_KEY" > /etc/newrelic-infra.yml
systemctl enable newrelic-infra
systemctl start newrelic-infra
```

## Verification
```bash
systemctl status newrelic-infra
tail -f /var/log/newrelic-infra/newrelic-infra.log
```
