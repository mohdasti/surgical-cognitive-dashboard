# iframe Embedding Setup for Quarto/Netlify

This guide provides everything needed to embed the Surgical Cognitive Dashboard in your Quarto site hosted on Netlify.

## 🎯 Quick Setup

### Option 1: ShinyApps.io (Easiest)
```bash
cd surgical-cognitive-dashboard-app
export SHINYAPPS_ACCOUNT="your-account"
export SHINYAPPS_TOKEN="your-token"
export SHINYAPPS_SECRET="your-secret"
Rscript deploy.R
```

### Option 2: Docker + nginx (Full Control)
```bash
cd surgical-cognitive-dashboard-app
docker build -t cogbb .
docker run -p 8080:80 cogbb
```

## 🔗 iframe Embedding

### 1. Add to your Quarto .qmd file:
```html
<iframe src="https://<APP_URL>/" width="100%" height="820" loading="lazy"
        style="border:1px solid #ddd;border-radius:12px;"></iframe>
```

Replace `<APP_URL>` with:
- **ShinyApps.io**: `https://your-account.shinyapps.io/surgical-cognitive-dashboard`
- **Docker**: `https://your-domain.com` (port 8080)

### 2. Verify iframe embedding works:
```bash
# Test headers (replace <APP_URL> with your actual URL)
curl -s -D - https://<APP_URL>/embed-check.html -o /dev/null | awk 'BEGIN{IGNORECASE=1} /content-security-policy|x-frame-options/ {print}'
```

Expected output:
```
Content-Security-Policy: frame-ancestors 'self' https://mdastgheib.com https://www.mdastgheib.com https://mdastgheib.netlify.app
X-Frame-Options: ALLOWALL
```

### 3. Manual verification:
Visit `https://<APP_URL>/embed-check.html` in your browser:
- **Standalone**: Should show "No (standalone)"
- **Embedded in iframe**: Should show "Yes (embedded)"

## 🛡️ Security Headers

### App Host Headers (Set by nginx.conf or ShinyApps.io)
```
Content-Security-Policy: frame-ancestors 'self' https://mdastgheib.com https://www.mdastgheib.com https://mdastgheib.netlify.app
X-Frame-Options: ALLOWALL
```

### Netlify Site Headers (Optional - for parent site CSP)
Create `_headers` in your Quarto site root:
```
/*
  Content-Security-Policy: default-src 'self';
  Content-Security-Policy: img-src 'self' data: https:;
  Content-Security-Policy: script-src 'self' https: 'unsafe-inline';
  Content-Security-Policy: style-src 'self' https: 'unsafe-inline';
  Content-Security-Policy: font-src 'self' https: data:;
  Content-Security-Policy: connect-src 'self' https:;
  Content-Security-Policy: frame-src <APP_ORIGIN>;
```

Update your `quarto.yml`:
```yaml
project:
  type: website
  resources:
    - "_headers"
```

## 🚨 Troubleshooting

### If iframe doesn't load:
1. **Check headers**: Run the curl command above
2. **ShinyApps.io blocking**: Some ShinyApps.io instances block iframe embedding
3. **Solution**: Use Docker + nginx deployment for full control

### If embed-check shows "No (standalone)":
- The page is being accessed directly, not in an iframe
- This is normal when testing the URL directly

### If embed-check shows "Yes (embedded)" but still doesn't work:
- Check browser console for CSP violations
- Verify the parent site allows iframe embedding
- Ensure HTTPS is used (required for iframe embedding)

## 📁 File Locations

- **nginx.conf**: `surgical-cognitive-dashboard-app/nginx.conf`
- **deploy.R**: `surgical-cognitive-dashboard-app/deploy.R`
- **embed-check.html**: `surgical-cognitive-dashboard-app/www/embed-check.html`
- **Example files**: Root directory (`netlify_headers_example`, `iframe_snippet_example.html`, etc.)

## 🔄 Deployment Workflow

1. **Deploy app** using either ShinyApps.io or Docker
2. **Test headers** with curl command
3. **Add iframe** to your Quarto .qmd file
4. **Deploy Quarto site** to Netlify
5. **Verify embedding** works on your live site

## 📞 Support

If you encounter issues:
1. Check the embed-check.html page
2. Verify headers with curl
3. Check browser console for errors
4. Ensure both sites use HTTPS
