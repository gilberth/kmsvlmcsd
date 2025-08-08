# GitHub Container Registry Setup

To enable automatic Docker image publishing to GitHub Container Registry, you need to configure the repository settings:

## Required Steps

### 1. Enable GitHub Actions
- Go to your repository settings
- Navigate to **Actions** > **General**
- Ensure "Allow all actions and reusable workflows" is selected

### 2. Configure Package Permissions
- Go to your repository settings
- Navigate to **Actions** > **General**
- Scroll down to "Workflow permissions"
- Select "Read and write permissions" 
- Check "Allow GitHub Actions to create and approve pull requests"

### 3. Repository Package Settings
- Go to your GitHub profile/organization packages
- Navigate to **Settings** > **Package settings** 
- For the vlmcsd package, set visibility to public if desired
- Ensure the repository has write access to the package

### 4. Manual Trigger (if needed)
If the workflow still fails, you can trigger it manually:
- Go to **Actions** tab in your repository
- Select "Build and Push Docker Images"
- Click "Run workflow"

## Expected Images

Once configured, the workflow will create:
- `ghcr.io/gilberth/vlmcsd:latest` - Standard image
- `ghcr.io/gilberth/vlmcsd-secure:latest` - Secure image with SSL support

## Troubleshooting

If you still get permission errors:
1. Check that the GITHUB_TOKEN has package write permissions
2. Verify the repository is not in an organization with restricted package access
3. Ensure the package doesn't already exist with conflicting permissions

## Alternative: Manual Docker Build

If automatic publishing doesn't work, you can build and push manually:

```bash
# Build and tag
docker build -t ghcr.io/gilberth/vlmcsd:latest .
docker build -f Dockerfile.secure -t ghcr.io/gilberth/vlmcsd-secure:latest .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u gilberth --password-stdin

# Push images
docker push ghcr.io/gilberth/vlmcsd:latest
docker push ghcr.io/gilberth/vlmcsd-secure:latest
```