# Docker Deployment Guide

## 🐳 Self-Hosted Shiny App with nginx

This setup provides full control over headers for iframe embedding with nginx as a reverse proxy.

## 🚀 Quick Start

### Build and Run

```bash
# Build the Docker image
docker build -t cogbb .

# Run the container
docker run -p 8080:80 cogbb
```

### Access the App

- **Local**: http://localhost:8080
- **Network**: http://your-server-ip:8080

## 🔧 Configuration

### nginx Configuration

The `nginx.conf` includes iframe-safe headers:

```nginx
add_header Content-Security-Policy "frame-ancestors 'self' https://mdastgheib.com https://*.netlify.app" always;
add_header X-Frame-Options "ALLOWALL" always;
```

### Customizing Domains

Edit `nginx.conf` to add your domains to the `frame-ancestors` directive:

```nginx
add_header Content-Security-Policy "frame-ancestors 'self' https://yourdomain.com https://*.yourdomain.com" always;
```

## 📦 Docker Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   nginx:80      │───▶│ Shiny:3838   │───▶│   R App         │
│  (Reverse Proxy)│    │ (Shiny Server)│    │  (app.R)        │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## 🔒 Security Features

- **Content Security Policy**: Controls which domains can embed the app
- **X-Frame-Options**: Allows iframe embedding from specified domains
- **WebSocket Support**: Full WebSocket proxying for Shiny reactivity
- **Reverse Proxy**: nginx handles external traffic

## 🛠️ Production Deployment

### Environment Variables

```bash
# Optional: Set custom port
docker run -p 80:80 -e PORT=80 cogbb
```

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  cogbb:
    build: .
    ports:
      - "80:80"
    restart: unless-stopped
```

Run with:
```bash
docker-compose up -d
```

### SSL/HTTPS

For production with SSL, add SSL certificates and update nginx.conf:

```nginx
server {
  listen 443 ssl;
  ssl_certificate /path/to/cert.pem;
  ssl_certificate_key /path/to/key.pem;
  # ... rest of configuration
}
```

## 🐛 Troubleshooting

### Check Container Logs

```bash
docker logs <container-id>
```

### Access Container Shell

```bash
docker exec -it <container-id> /bin/bash
```

### Test nginx Configuration

```bash
docker exec -it <container-id> nginx -t
```

## 📊 Performance

- **nginx**: Handles static content and reverse proxy
- **Shiny Server**: Manages R processes and WebSocket connections
- **R App**: Runs the cognitive dashboard application

## 🔗 Iframe Embedding

Once deployed, embed in your website:

```html
<iframe 
  src="http://your-server:8080" 
  width="100%" 
  height="600px"
  frameborder="0">
</iframe>
```
