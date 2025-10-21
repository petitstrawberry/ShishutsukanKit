# Integration Test Script

This directory contains the integration test script for ShishutsukanKit.

## run-integration-tests.sh

This shell script automates the process of setting up a shishutsukan server and running integration tests against it.

### What it does:

1. Clones the shishutsukan server repository
2. Installs Python dependencies (FastAPI and uvicorn)
3. Starts the shishutsukan server on port 8000
4. Waits for the server to be ready
5. Runs the integration tests
6. Cleans up the server and temporary files on exit

### Requirements:

- bash
- git
- Python 3.10+
- pip
- curl (for health checks)
- Swift 5.9+

### Usage:

```bash
./scripts/run-integration-tests.sh
```

### Running in CI:

The script is integrated into the GitHub Actions workflow and runs automatically on pull requests and pushes to the main branch.

### Running Tests Separately:

**Unit tests only** (no server required):
```bash
swift test --filter ShishutsukanKitTests
```

**Integration tests only** (requires server):
```bash
# Start server first, then:
swift test --filter IntegrationTests
```

**All tests with server** (recommended):
```bash
./scripts/run-integration-tests.sh
```

### Troubleshooting:

If the script fails:

1. Check that all required dependencies are installed
2. Ensure port 8000 is not already in use
3. Check the server log in the temporary directory (path shown in script output)
4. Verify Python and pip are available in your PATH
