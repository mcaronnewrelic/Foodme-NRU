#!/bin/bash

# Security validation script for Docker secrets
# Checks for common security issues in Dockerfiles and related files

set -e

echo "🔍 Security Validation Report"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

# Function to report issues
report_issue() {
    echo -e "${RED}❌ ISSUE: $1${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

# Function to report success
report_success() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

# Function to report warning
report_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

echo
echo "🐳 Dockerfile Security Checks"
echo "------------------------------"

# Check 1: No ARG instructions with secrets
if grep -r "ARG.*SECRET\|ARG.*PASSWORD\|ARG.*KEY\|ARG.*TOKEN" dockerfile* 2>/dev/null; then
    report_issue "Found ARG instructions with sensitive data in Dockerfile"
else
    report_success "No ARG instructions with sensitive data found"
fi

# Check 2: No ENV instructions with hardcoded secrets
if grep -r "ENV.*SECRET.*=\|ENV.*PASSWORD.*=\|ENV.*KEY.*=.*[a-zA-Z0-9]\|ENV.*TOKEN.*=.*[a-zA-Z0-9]" dockerfile* 2>/dev/null; then
    report_issue "Found ENV instructions with hardcoded secrets in Dockerfile"
else
    report_success "No hardcoded secrets in ENV instructions"
fi

echo
echo "🏗️  Build Script Security Checks"
echo "--------------------------------"

# Check 3: No --build-arg with secrets in scripts
if grep -r "\-\-build-arg.*SECRET\|\-\-build-arg.*PASSWORD\|\-\-build-arg.*KEY\|\-\-build-arg.*TOKEN" . --include="*.sh" 2>/dev/null; then
    report_issue "Found --build-arg with secrets in shell scripts"
else
    report_success "No --build-arg with secrets in shell scripts"
fi

echo
echo "🐙 Docker Compose Security Checks"
echo "----------------------------------"

# Check 4: Docker Compose using environment variables instead of build args
if grep -A5 -B5 "build:" docker-compose.yml compose.yml 2>/dev/null | grep -q "args:"; then
    if grep -A10 "args:" docker-compose.yml compose.yml 2>/dev/null | grep -q "SECRET\|PASSWORD\|KEY\|TOKEN"; then
        report_issue "Found build args with secrets in Docker Compose"
    else
        report_success "Build args in Docker Compose don't contain secrets"
    fi
else
    report_success "No build args found in Docker Compose files"
fi

echo
echo "📁 File Security Checks"
echo "------------------------"

# Check 5: Source code doesn't contain hardcoded secrets
echo "Checking for hardcoded secrets in source code..."
if grep -r "license_key.*['\"][a-zA-Z0-9]\{20,\}['\"]" . --include="*.js" --include="*.ts" --exclude-dir=node_modules --exclude-dir=dist 2>/dev/null; then
    report_issue "Found hardcoded license keys in source code"
else
    report_success "No hardcoded license keys found in source code"
fi

if grep -r "api_key.*['\"][a-zA-Z0-9]\{20,\}['\"]" . --include="*.js" --include="*.ts" --exclude-dir=node_modules --exclude-dir=dist 2>/dev/null; then
    report_issue "Found hardcoded API keys in source code"
else
    report_success "No hardcoded API keys found in source code"
fi

if grep -r "secret.*['\"][a-zA-Z0-9]\{20,\}['\"]" . --include="*.js" --include="*.ts" --exclude-dir=node_modules --exclude-dir=dist 2>/dev/null; then
    report_issue "Found hardcoded secrets in source code"
else
    report_success "No hardcoded secrets found in source code"
fi

# Check 7: .env file is properly ignored
if [ -f .dockerignore ]; then
    if grep -q "\.env" .dockerignore; then
        report_success ".env file is excluded from Docker context"
    else
        report_warning ".env file not explicitly excluded in .dockerignore"
    fi
else
    report_warning "No .dockerignore file found"
fi

# Check 8: Secrets are not committed to git
if [ -d .git ]; then
    if git check-ignore .env >/dev/null 2>&1; then
        report_success ".env file is properly gitignored"
    else
        if [ -f .env ]; then
            report_warning ".env file exists but may not be gitignored"
        else
            report_success "No .env file to worry about"
        fi
    fi
fi

echo
echo "🎯 Current Dockerfile Analysis"
echo "------------------------------"

# Show current Dockerfile structure
echo "Lines 30-40 of current Dockerfile:"
sed -n '30,40p' dockerfile 2>/dev/null || echo "Could not read dockerfile lines 30-40"

echo
echo "📊 Summary"
echo "----------"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 All security checks passed! No issues found.${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $ISSUES_FOUND security issue(s) that need attention.${NC}"
    exit 1
fi
