#!/bin/bash
set -e

# Integration test script for ShishutsukanKit
# This script sets up a shishutsukan server and runs tests against it

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
SERVER_DIR="$TMP_DIR/shishutsukan"
SERVER_PORT=8000
MAX_WAIT=30

echo "=== ShishutsukanKit Integration Test ==="
echo "Temporary directory: $TMP_DIR"

# Cleanup function
cleanup() {
    echo ""
    echo "=== Cleaning up ==="
    if [ ! -z "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Stopping server (PID: $SERVER_PID)..."
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    
    if [ -d "$TMP_DIR" ]; then
        echo "Removing temporary directory: $TMP_DIR"
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT INT TERM

# Clone shishutsukan repository
echo ""
echo "=== Cloning shishutsukan repository ==="
git clone --depth 1 https://github.com/sfujibijutsukan/shishutsukan.git "$SERVER_DIR"

# Install Python dependencies for the backend
echo ""
echo "=== Installing Python dependencies ==="
cd "$SERVER_DIR/backend"
pip install -q fastapi uvicorn

# Start the server in background
echo ""
echo "=== Starting shishutsukan server on port $SERVER_PORT ==="
python -m uvicorn main:app --host 0.0.0.0 --port "$SERVER_PORT" > "$TMP_DIR/server.log" 2>&1 &
SERVER_PID=$!

echo "Server started with PID: $SERVER_PID"
echo "Waiting for server to be ready..."

# Wait for server to be ready
SECONDS=0
while [ $SECONDS -lt $MAX_WAIT ]; do
    if curl -s "http://localhost:$SERVER_PORT/expenses" > /dev/null 2>&1; then
        echo "Server is ready!"
        break
    fi
    sleep 1
done

if [ $SECONDS -ge $MAX_WAIT ]; then
    echo "ERROR: Server did not start within $MAX_WAIT seconds"
    echo "Server log:"
    cat "$TMP_DIR/server.log"
    exit 1
fi

# Run integration tests
echo ""
echo "=== Running integration tests ==="
cd "$REPO_ROOT"
swift test --filter IntegrationTests

echo ""
echo "=== Integration tests completed successfully! ==="
