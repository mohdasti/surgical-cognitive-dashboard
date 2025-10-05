# Embed Readiness Guide

## 🎯 iframe Embedding Test Suite

This guide provides utilities to test iframe embedding compatibility for the Surgical Cognitive Dashboard.

## 📋 Test Files

### 1. `www/embed-check.html` - Basic iframe Detection
Simple test to detect if the page is loaded in an iframe:
- **Direct access**: Shows "Top ≠ Self? No"
- **iframe access**: Shows "Top ≠ Self? Yes"

### 2. `www/embed-test.html` - Comprehensive Test Suite
Full test suite with multiple checks:
- Direct access detection
- iframe embedding test
- Header analysis
- Cross-origin testing

### 3. `scripts/check_headers.sh` - Header Validation
Command-line tool to check iframe-related headers:
```bash
./scripts/check_headers.sh https://your-app-host/embed-check.html
```

## 🚀 Quick Test

### Local Testing
```bash
# Start the app locally
Rscript -e "shiny::runApp()"

# Test embed check
open http://localhost:3838/embed-check.html

# Test full suite
open http://localhost:3838/embed-test.html
```

### Deployed Testing
```bash
# Check headers
./scripts/check_headers.sh https://your-deployed-app.com/embed-check.html

# Test embedding
open https://your-deployed-app.com/embed-test.html
```

## 🔧 Configuration

### App Configuration
The app includes iframe-friendly settings:
- `tags$base(target="_parent")` in UI head
- nginx headers for iframe embedding
- Content Security Policy with frame-ancestors

### nginx Headers
```nginx
add_header Content-Security-Policy "frame-ancestors 'self' https://mdastgheib.com https://*.netlify.app" always;
add_header X-Frame-Options "ALLOWALL" always;
```

## ✅ Expected Results

### Direct Access
- **URL**: `https://your-app.com/embed-check.html`
- **Result**: "Top ≠ Self? No"
- **Meaning**: Page is not in an iframe

### iframe Embedding
- **URL**: Embedded in iframe on allowed domain
- **Result**: "Top ≠ Self? Yes"
- **Meaning**: Page is successfully embedded in iframe

### Header Check
```bash
$ ./scripts/check_headers.sh https://your-app.com/embed-check.html
Content-Security-Policy: frame-ancestors 'self' https://mdastgheib.com https://*.netlify.app
X-Frame-Options: ALLOWALL
```

## 🐛 Troubleshooting

### Common Issues

#### 1. "Top ≠ Self? No" in iframe
- **Cause**: iframe embedding blocked by headers
- **Fix**: Check nginx configuration and CSP headers

#### 2. iframe shows blank page
- **Cause**: X-Frame-Options blocking
- **Fix**: Ensure X-Frame-Options is set to ALLOWALL

#### 3. Cross-origin errors
- **Cause**: CSP frame-ancestors doesn't include your domain
- **Fix**: Add your domain to frame-ancestors in nginx.conf

### Debug Commands
```bash
# Check all headers
curl -I https://your-app.com/embed-check.html

# Check specific headers
curl -s -D - https://your-app.com/embed-check.html | grep -i frame

# Test iframe embedding
curl -s -D - https://your-app.com/embed-check.html | awk '/content-security-policy|x-frame-options/'
```

## 🌐 Netlify Integration

### Embedding in Netlify
```html
<iframe 
  src="https://your-app.com" 
  width="100%" 
  height="600px"
  frameborder="0"
  title="Surgical Cognitive Dashboard">
</iframe>
```

### Custom Domain Setup
1. Update nginx.conf with your domain:
```nginx
add_header Content-Security-Policy "frame-ancestors 'self' https://yourdomain.com https://*.netlify.app" always;
```

2. Rebuild and redeploy Docker container

## 📊 Test Results Interpretation

| Test | Direct Access | iframe Access | Status |
|------|---------------|---------------|---------|
| embed-check.html | "No" | "Yes" | ✅ Working |
| embed-check.html | "No" | "No" | ❌ Blocked |
| Header check | CSP present | CSP present | ✅ Configured |
| Header check | No CSP | No CSP | ❌ Missing |

## 🔗 Integration Examples

### WordPress
```html
<iframe src="https://your-app.com" width="100%" height="600px"></iframe>
```

### React/Next.js
```jsx
<iframe 
  src="https://your-app.com" 
  width="100%" 
  height="600px"
  title="Surgical Dashboard"
/>
```

### HTML Page
```html
<!DOCTYPE html>
<html>
<head>
    <title>My Site</title>
</head>
<body>
    <h1>My Site</h1>
    <iframe src="https://your-app.com" width="100%" height="600px"></iframe>
</body>
</html>
```
