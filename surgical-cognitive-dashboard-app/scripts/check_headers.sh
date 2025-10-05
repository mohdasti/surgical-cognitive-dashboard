#!/usr/bin/env bash
set -euo pipefail

# Check iframe embedding headers for a deployed app
# Usage: ./scripts/check_headers.sh [URL]
# Default: https://<your-app-host>/embed-check.html

APP="${1:-https://your-app-host/embed-check.html}"

echo "=== Checking iframe embedding headers ==="
echo "URL: $APP"
echo ""

# Get headers and extract iframe-related ones
echo "=== Headers Analysis ==="
curl -s -D - "$APP" -o /dev/null | awk 'BEGIN{IGNORECASE=1} /content-security-policy|x-frame-options/ {print}'

echo ""
echo "=== Interpretation ==="
echo "✓ Content-Security-Policy with 'frame-ancestors' = iframe embedding allowed"
echo "✓ X-Frame-Options: ALLOWALL = iframe embedding allowed"
echo "✗ X-Frame-Options: DENY/SAMEORIGIN = iframe embedding blocked"
echo ""

echo "=== Test Commands ==="
echo "Direct access: curl -I $APP"
echo "Embed test: Open $APP in iframe on your domain"
echo ""

echo "=== Expected Results ==="
echo "When opened directly: 'Top ≠ Self? No'"
echo "When embedded in iframe: 'Top ≠ Self? Yes'"
