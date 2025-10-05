# Surgical Cognitive Dashboard - Deployment Package 🚀

This is the **deployment-ready** version of the Surgical Cognitive Dashboard, optimized for production use with minimal dependencies and multiple deployment options.

## 🎯 Quick Start

### **Local Testing**
```bash
Rscript -e "shiny::runApp(port=3838, host='127.0.0.1')"
# Open: http://localhost:3838
```

## 🌐 Deployment Options

### **1. ShinyApps.io (Recommended)**

#### **Setup Credentials**
```bash
# Set environment variables (see env_example.txt)
export SHINYAPPS_ACCOUNT="your-account-name"
export SHINYAPPS_TOKEN="your-token-here"  
export SHINYAPPS_SECRET="your-secret-here"
```

#### **One-Command Deploy**
```bash
Rscript deploy.R
```

**Expected Output:**
```
Deploying to shinyapps.io...
Deployment complete! Check your shinyapps.io dashboard for the URL.
```

**Troubleshooting:**
- Ensure `.rscignore` excludes development files
- Check bundle size: should be < 100MB
- Verify all required packages are in `renv.lock`

### **2. Docker + nginx (Self-Hosted)**

#### **Build and Run**
```bash
docker build -t cogbb .
docker run -p 8080:80 cogbb
# Open: http://localhost:8080
```

#### **Docker Compose (Production)**
```bash
docker-compose up -d
# Open: http://localhost:8080
```

**nginx Configuration Highlights:**
- **WebSocket Support**: For real-time Shiny updates
- **iframe-Safe Headers**:
  ```nginx
  add_header Content-Security-Policy "frame-ancestors 'self' https://mdastgheib.com https://*.netlify.app" always;
  add_header X-Frame-Options "ALLOWALL" always;
  ```

## 🔗 iframe Embedding

### **Embed Code**
```html
<iframe 
  src="https://your-deployed-url/" 
  width="100%" 
  height="820" 
  loading="lazy"
  style="border:1px solid #ddd;border-radius:12px">
</iframe>
```

### **Verify Embed Readiness**

1. **Check Headers**:
   ```bash
   ./scripts/check_headers.sh https://your-deployed-url/embed-check.html
   ```

2. **Manual Test**:
   - Visit: `https://your-deployed-url/embed-check.html`
   - Should show: **"Top ≠ Self? Yes"** when embedded in iframe
   - Should show: **"Top ≠ Self? No"** when accessed directly

3. **Full Embed Test**:
   - Visit: `https://your-deployed-url/embed-test.html`
   - Tests cross-origin iframe loading and navigation

## 📦 Package Contents

```
surgical-cognitive-dashboard-app/
├── app.R                    # Main Shiny application
├── 00_setup.R              # Minimal runtime setup
├── deploy.R                # ShinyApps.io deployment script
├── config/
│   └── config.yml          # Application configuration
├── R/
│   ├── streaming_inference.R  # Real-time ML engine
│   └── diagnostics_module.R   # 6-tab diagnostics interface
├── data/
│   ├── processed/           # Demo data and models
│   └── diagnostics/         # Precomputed artifacts
├── www/
│   ├── embed-check.html     # iframe compatibility test
│   └── embed-test.html      # Comprehensive embed test
├── scripts/
│   └── check_headers.sh     # Header verification utility
├── renv.lock               # Package dependencies
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker orchestration
├── nginx.conf              # nginx reverse proxy config
└── shiny-server.conf       # Shiny Server configuration
```

## 🛠️ Configuration

### **Application Settings** (`config/config.yml`)
- **Thresholds**: Alert probability thresholds
- **Windows**: Feature engineering time windows  
- **Models**: Model parameters and paths
- **Streaming**: Update frequency and buffer sizes

### **Deployment Settings**
- **`.rscignore`**: Optimizes bundle size for ShinyApps.io
- **`.dockerignore`**: Minimizes Docker image size
- **`nginx.conf`**: Configures reverse proxy and headers

## 🔍 Diagnostics & Monitoring

### **Application Health**
- **Startup**: Check console for package loading
- **Runtime**: Monitor for feature computation errors
- **Performance**: 5Hz update rate, <200ms response time

### **Common Issues**

**1. Feature Computation Errors**
```
Warning: Error in -: non-numeric argument to binary operator
```
**Fix**: Ensure data contains numeric columns, check for NA handling

**2. Model Loading Failures**
```
Error: cannot open the connection
```
**Fix**: Verify model files exist in `data/processed/`

**3. Docker Build Issues**
```
Package installation failed
```
**Fix**: Check `renv.lock` compatibility with base image

## 📊 Performance Metrics

### **Bundle Sizes**
- **ShinyApps.io**: ~15MB (with `.rscignore`)
- **Docker Image**: ~800MB (R + system dependencies)
- **Runtime Memory**: ~200MB (typical usage)

### **Response Times**
- **Initial Load**: 3-5 seconds
- **HUD Updates**: <200ms (5Hz)
- **Diagnostics**: 1-2 seconds (tab switching)

## 🔐 Security & Headers

### **iframe Security**
- **CSP**: Allows embedding on specified domains
- **X-Frame-Options**: Permits iframe embedding
- **HTTPS**: Required for production deployment

### **Data Privacy**
- **No PHI**: All data is synthetic
- **Local Processing**: No external API calls
- **Session Isolation**: Each user session is independent

## 📚 Additional Resources

- **Main Repository**: [surgical-cognitive-dashboard](../README.md)
- **Development Guide**: [surgical-cognitive-dashboard-1/README.md](../surgical-cognitive-dashboard-1/README.md)
- **Deployment Guides**: 
  - [DEPLOY.md](DEPLOY.md) - ShinyApps.io details
  - [DOCKER.md](DOCKER.md) - Docker deployment
  - [EMBED.md](EMBED.md) - iframe embedding guide

## 🆘 Support

For deployment issues:
1. Check application logs
2. Verify environment variables
3. Test locally first
4. Review configuration files

**Contact**: Mohammad Dastgheib - [mdastgheib.com](https://mdastgheib.com)