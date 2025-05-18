# Publishing to pub.dev

This GitHub workflow automatically publishes your package to pub.dev when you create a new release on GitHub.

## Setup Instructions

To set up the publishing workflow, you need to add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the following repository secrets:

- `PUB_DEV_ACCESS_TOKEN`
- `PUB_DEV_REFRESH_TOKEN`
- `PUB_DEV_ID_TOKEN`
- `PUB_DEV_TOKEN_ENDPOINT`
- `PUB_DEV_EXPIRATION`

You can obtain these credentials by running `flutter pub login` on your local machine and then copying the values from the credentials file. On macOS, this file is located at:

```
~/Library/Application Support/dart/pub-credentials.json
```

The values in this file map to the GitHub secrets as follows:

- `accessToken` → `PUB_DEV_ACCESS_TOKEN`
- `refreshToken` → `PUB_DEV_REFRESH_TOKEN`
- `idToken` → `PUB_DEV_ID_TOKEN`
- `tokenEndpoint` → `PUB_DEV_TOKEN_ENDPOINT`
- `expiration` → `PUB_DEV_EXPIRATION`

## Publishing Process

1. Update the version in `pubspec.yaml`
2. Update `CHANGELOG.md` with the changes in the new version
3. Go to your GitHub repository's Actions tab
4. Select the "Publish to pub.dev" workflow
5. Click "Run workflow"
6. Enter the version you want to publish (should match your pubspec.yaml version)
7. Optionally select the "dry run" option to verify everything works without actually publishing
8. Click "Run workflow" to start the publishing process

## Troubleshooting

If the workflow fails, check the following:

- Ensure all tests pass locally before creating a release
- Verify that your package meets pub.dev's requirements
- Check that all required secrets are correctly set up in your GitHub repository
- Make sure the tokens haven't expired (they typically last 30 days)
