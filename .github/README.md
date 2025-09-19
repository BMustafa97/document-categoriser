# GitHub Actions Setup

## Required Configuration

### GitHub Secrets

Set these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key for deployment | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key for deployment | `abc123...` |

### GitHub Variables

Set these variables in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Variable Name | Description | Example Value |
|---------------|-------------|---------------|
| `DOMAIN_NAME` | Your application domain name | `your-app.com` |

## Setting up GitHub Variables

1. Navigate to your repository on GitHub
2. Go to `Settings` > `Secrets and variables` > `Actions`
3. Click on the `Variables` tab
4. Click `New repository variable`
5. Add the following variable:
   - **Name**: `DOMAIN_NAME`
   - **Value**: Your domain (e.g., `your-app.com`)

## Setting up GitHub Environments

For the CD pipeline to work properly, you need to create GitHub environments:

### Staging Environment
1. Go to `Settings` > `Environments`
2. Click `New environment`
3. Name: `staging`
4. (Optional) Add protection rules if needed

### Production Environment
1. Go to `Settings` > `Environments`
2. Click `New environment`
3. Name: `production`
4. **Important**: Add protection rules:
   - ✅ Required reviewers (at least 1)
   - ✅ Wait timer (optional, e.g., 5 minutes)

This ensures production deployments require manual approval.

## AWS Configuration

The workflows are configured for the **eu-west-1** region. If you need to use a different region, update the `AWS_REGION` environment variable in the workflow files.

## Workflow Overview

- **CI (`ci.yml`)**: Runs on all pushes and pull requests
- **CD (`cd.yml`)**: Runs when CI completes successfully on main branch
- **Security (`security.yml`)**: Runs on pushes/PRs and weekly schedule
- **Cleanup (`cleanup.yml`)**: Runs daily and can be triggered manually

## Testing the Workflows

1. Push code to any branch to trigger CI
2. Create a pull request to test PR workflows
3. Merge to `main` branch to trigger the full CI/CD pipeline