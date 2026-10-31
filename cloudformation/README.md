# FoodMe CloudFormation Deployment - File Organization Guide

## 🎯 **RECOMMENDED FILES TO USE**

### **Production Deployment (RECOMMENDED)**
- **Template**: `foodme-production-stack.yaml` ✅ **USE THIS**
- **Script**: `deploy-production.sh` ✅ **USE THIS**
- **Purpose**: Production-ready template with all troubleshooting fixes incorporated

### **Supporting Files (KEEP)**
- `install-foodme.sh` ✅ **KEEP** - Enhanced installation script with monitoring
- `validate-monitoring.sh` ✅ **KEEP** - Validates PostgreSQL and Nginx monitoring
- `diagnose-postgresql-monitoring.sh` ✅ **KEEP** - PostgreSQL troubleshooting
- `diagnose-nginx-monitoring.sh` ✅ **KEEP** - Nginx troubleshooting

---

## 📁 **FILE ANALYSIS & RECOMMENDATIONS**

### **CloudFormation Templates**

| File                           | Status                | Purpose                                      | Recommendation |
| ------------------------------ | --------------------- | -------------------------------------------- | -------------- |
| `foodme-production-stack.yaml` | ✅ **NEW/RECOMMENDED** | Production-ready with all fixes              | **USE THIS**   |
| `foodme-stack.yaml`            | ⚠️ Legacy              | Original full stack (has load testing)       | Archive/backup |
| `foodme-monitoring-stack.yaml` | ⚠️ Legacy              | Monitoring-focused variant                   | Archive/backup |
| `monitoring-stack.yaml`        | ⚠️ Legacy              | Simplified variant (used in troubleshooting) | Archive/backup |

### **Deployment Scripts**

| File                         | Status                | Template Used                  | Recommendation |
| ---------------------------- | --------------------- | ------------------------------ | -------------- |
| `deploy-production.sh`       | ✅ **NEW/RECOMMENDED** | `foodme-production-stack.yaml` | **USE THIS**   |
| `deploy-stack.sh`            | ⚠️ Legacy              | `foodme-stack.yaml`            | Archive/backup |
| `deploy-simple.sh`           | ⚠️ Troubleshooting     | `monitoring-stack.yaml`        | Archive/backup |
| `deploy-monitoring-stack.sh` | ⚠️ Legacy              | `foodme-monitoring-stack.yaml` | Archive/backup |
| `deploy-code.sh`             | ❌ Incomplete          | N/A - Code only                | **DELETE**     |

### **Utility Scripts**

| File                                | Status      | Purpose                    | Recommendation |
| ----------------------------------- | ----------- | -------------------------- | -------------- |
| `install-foodme.sh`                 | ✅ Essential | Main installation script   | **KEEP**       |
| `validate-monitoring.sh`            | ✅ Useful    | Monitoring validation      | **KEEP**       |
| `diagnose-postgresql-monitoring.sh` | ✅ Useful    | PostgreSQL troubleshooting | **KEEP**       |
| `diagnose-nginx-monitoring.sh`      | ✅ Useful    | Nginx troubleshooting      | **KEEP**       |
| `validate-deployment.sh`            | ⚠️ Legacy    | General validation         | Optional       |
| `build-loadtest-image.sh`           | ❌ Unused    | Load testing (not needed)  | **DELETE**     |
| `manage-loadtest.sh`                | ❌ Unused    | Load testing (not needed)  | **DELETE**     |

---

## 🚀 **HOW TO DEPLOY**

### **Quick Deployment (Recommended)**
```bash
cd cloudformation
./deploy-production.sh staging t3.medium foodme-keypair mysecurepasswordexample
```

### **What This Includes**
- ✅ Amazon Linux 2023 (AL2023)
- ✅ PostgreSQL 16 with monitoring extensions
- ✅ Nginx on port 8080 with proper Angular routing
- ✅ Node.js backend with PM2 process management
- ✅ Application Load Balancer with API routing
- ✅ New Relic Infrastructure monitoring
- ✅ All troubleshooting fixes from manual testing

---

## 🧹 **CLEANUP RECOMMENDATIONS**

### **Files to Archive/Move to `archive/` folder**
```bash
mkdir -p archive
mv foodme-stack.yaml archive/
mv foodme-monitoring-stack.yaml archive/
mv monitoring-stack.yaml archive/
mv deploy-stack.sh archive/
mv deploy-simple.sh archive/
mv deploy-monitoring-stack.sh archive/
mv validate-deployment.sh archive/
```

### **Files to Delete**
```bash
rm deploy-code.sh
rm build-loadtest-image.sh
rm manage-loadtest.sh
```

---

## 🔧 **KEY FIXES INCORPORATED**

### **From Manual Troubleshooting**
1. **Angular Build Structure**: Fixed browser/ subdirectory handling
2. **Nginx Configuration**: Proper port 8080 setup with Angular routing
3. **API Proxy**: Correct /api/* and /health routing to backend
4. **PM2 Management**: Automatic backend process management
5. **Environment Variables**: Proper passing to user data script
6. **Error Handling**: Enhanced logging and error recovery
7. **New Relic Setup**: Automated configuration with license key

### **User Data Script Improvements**
- Added comprehensive logging to `/var/log/user-data.log`
- Fixed Angular browser files copying
- Proper Nginx configuration generation
- PM2 backend startup verification
- New Relic configuration automation

---

## 📊 **VALIDATION & TESTING**

### **After Deployment**
```bash
# Validate monitoring setup
./validate-monitoring.sh -e staging

# Test endpoints
curl http://YOUR-ALB-DNS/
curl http://YOUR-ALB-DNS/health
curl http://YOUR-ALB-DNS/api/
```

### **Expected Results**
- Frontend: HTTP 200 (Angular app loads)
- Health Check: HTTP 200 (Backend healthy)
- API: HTTP 200 or appropriate API response

---

## 🎯 **SUMMARY**

**Use these files for production deployments:**
- `foodme-production-stack.yaml` (CloudFormation template)
- `deploy-production.sh` (Deployment script)
- `install-foodme.sh` (Installation script)
- `validate-monitoring.sh` (Validation script)

**Archive the rest** - they were useful for development and troubleshooting but are no longer needed for production use.

This production template incorporates all the manual fixes we discovered during troubleshooting, ensuring reliable deployments without manual intervention.