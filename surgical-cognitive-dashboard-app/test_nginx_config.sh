#!/bin/bash

# Test nginx configuration syntax
echo "=== Testing nginx Configuration ==="

# Check if nginx is available (in Docker container)
if command -v nginx &> /dev/null; then
    echo "Testing nginx configuration syntax..."
    nginx -t
    if [ $? -eq 0 ]; then
        echo "✓ nginx configuration is valid"
    else
        echo "✗ nginx configuration has errors"
        exit 1
    fi
else
    echo "nginx not available (expected outside Docker container)"
fi

# Check configuration file content
echo ""
echo "=== Configuration File Analysis ==="

if [ -f "nginx.conf" ]; then
    echo "nginx.conf content analysis:"
    
    if grep -q "listen 80" nginx.conf; then
        echo "✓ nginx listens on port 80"
    else
        echo "✗ nginx port configuration missing"
    fi
    
    if grep -q "proxy_pass.*3838" nginx.conf; then
        echo "✓ nginx proxies to Shiny server (port 3838)"
    else
        echo "✗ nginx proxy configuration missing"
    fi
    
    if grep -q "frame-ancestors" nginx.conf; then
        echo "✓ iframe headers configured"
    else
        echo "✗ iframe headers missing"
    fi
    
    if grep -q "WebSocket" nginx.conf; then
        echo "✓ WebSocket support configured"
    else
        echo "✗ WebSocket support missing"
    fi
else
    echo "✗ nginx.conf file not found"
fi

echo ""
echo "=== Docker Commands ==="
echo "Build: docker build -t cogbb ."
echo "Run:   docker run -p 8080:80 cogbb"
echo "Test:  curl -I http://localhost:8080"
echo ""
echo "=== Iframe Test ==="
echo "After deployment, test iframe embedding:"
echo '<iframe src="http://localhost:8080" width="100%" height="600px"></iframe>'
