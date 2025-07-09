# GitHub Actions Permissions and Troubleshooting

This document explains common GitHub Actions permission issues and how to resolve them.

## 🔐 Artifact Cleanup Permission Issue

### Symptom
```
RequestError [HttpError]: Resource not accessible by integration
Error: Unhandled error: HttpError: Resource not accessible by integration
```

### Cause
The default `GITHUB_TOKEN` in GitHub Actions has restricted permissions and may not be able to delete artifacts, especially in repositories with enhanced security settings.

### Solutions

#### Solution 1: Workflow-Level Permissions (Implemented)
The workflow now includes explicit permissions:
```yaml
permissions:
  contents: read
  actions: write
  deployments: write
  id-token: write
```

#### Solution 2: Repository Settings
If you continue to see permission errors:

1. Go to your repository **Settings**
2. Navigate to **Actions** → **General**
3. Under **Workflow permissions**, select:
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**

#### Solution 3: Personal Access Token (Advanced)
For persistent issues, create a personal access token:

1. Go to GitHub **Settings** → **Developer settings** → **Personal access tokens**
2. Create a token with `repo` and `actions` scopes
3. Add as repository secret: `PERSONAL_ACCESS_TOKEN`
4. Update the cleanup job to use it:
```yaml
- name: Delete artifacts
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
    script: |
      # ... cleanup script
```

#### Solution 4: Accept Automatic Cleanup
GitHub automatically deletes artifacts after their retention period (30 days by default). The workflow now handles permission errors gracefully and will continue without failing.

## 🛠️ Current Implementation

The workflow has been updated to:
- **Handle permission errors gracefully** with try-catch blocks
- **Continue on error** so deployment isn't affected
- **Provide clear feedback** about cleanup status
- **Explain the issue** when permissions are insufficient

## 📊 Monitoring Artifacts

To manually check and clean up artifacts:

### Via GitHub Web UI
1. Go to your repository **Actions** tab
2. Click on any workflow run
3. Scroll down to **Artifacts** section
4. Delete artifacts manually if needed

### Via GitHub CLI
```bash
# List artifacts
gh api repos/:owner/:repo/actions/artifacts

# Delete specific artifact
gh api repos/:owner/:repo/actions/artifacts/:artifact_id -X DELETE
```

### Via REST API
```bash
# List artifacts
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/artifacts

# Delete artifact
curl -X DELETE -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/artifacts/ARTIFACT_ID
```

## 🔍 Other Common Permission Issues

### AWS Credential Access
**Error**: `The security token included in the request is invalid`

**Solution**: Verify secrets are set correctly:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Terraform State Access
**Error**: `Backend configuration changed`

**Solution**: Ensure Terraform backend permissions are correct and state file is accessible.

### Environment Protection Rules
**Error**: `Required reviewers have not approved this deployment`

**Solution**: Configure environment protection rules in repository settings under **Environments**.

## 💡 Best Practices

1. **Use minimal required permissions** in workflow files
2. **Store sensitive data in repository secrets** not in code
3. **Use environment-specific secrets** for different deployment targets
4. **Monitor GitHub Actions usage** to stay within limits
5. **Regularly clean up old artifacts** to save storage space

## 🔧 Debugging Tips

### Check Current Permissions
Add this step to debug permission issues:
```yaml
- name: Check permissions
  run: |
    echo "GITHUB_TOKEN permissions:"
    curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
      https://api.github.com/repos/${{ github.repository }}
```

### Verify Token Scope
```yaml
- name: Verify token scope
  uses: actions/github-script@v7
  with:
    script: |
      const response = await github.rest.users.getAuthenticated();
      console.log('Token scopes:', response.headers['x-oauth-scopes']);
```

### Test Artifact Operations
```yaml
- name: Test artifact operations
  uses: actions/github-script@v7
  with:
    script: |
      try {
        const artifacts = await github.rest.actions.listWorkflowRunArtifacts({
          owner: context.repo.owner,
          repo: context.repo.repo,
          run_id: context.runId,
        });
        console.log('✅ Can list artifacts');
        console.log('Artifacts found:', artifacts.data.artifacts.length);
      } catch (error) {
        console.log('❌ Cannot list artifacts:', error.message);
      }
```

## 📞 Getting Help

If permission issues persist:

1. **Check the [GitHub Actions documentation](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)**
2. **Review repository settings** for workflow permissions
3. **Contact repository administrators** if you don't have permission to change settings
4. **Consider using organization-level settings** for consistent permissions across repositories

Remember: Artifact cleanup failures don't affect your application deployment - they're just housekeeping operations.
