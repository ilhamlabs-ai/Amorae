# 🔒 SSL/TLS Setup Commands

## ⚠️ Important: You Need a Domain Name

Let's Encrypt requires a **domain name** (e.g., `api.amorae.com`). You cannot use just an IP address (3.127.210.200).

---

## Option 1: With Domain Name (Recommended)

### Step 1: Point Domain to Server
First, create an A record in your domain's DNS:
```
Type: A
Name: api (or @ for root domain)
Value: 3.127.210.200
TTL: 300
```

Wait 5-10 minutes for DNS propagation. Verify:
```bash
nslookup api.yourdomain.com
```

### Step 2: Install Certbot
```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

### Step 3: Get SSL Certificate
```bash
# Replace api.yourdomain.com with your actual domain
sudo certbot --nginx -d api.yourdomain.com
```

Follow the prompts:
- Enter your email address
- Agree to Terms of Service
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

### Step 4: Test Auto-Renewal
```bash
sudo certbot renew --dry-run
```

### Step 5: Configure Firewall
```bash
# Allow HTTPS traffic
sudo ufw allow 'Nginx Full'

# Allow SSH (CRITICAL - do this first to avoid lockout!)
sudo ufw allow OpenSSH

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 6: Update Flutter App
```dart
// lib/shared/providers/providers.dart
const String productionUrl = 'https://api.yourdomain.com';
```

---

## Option 2: Without Domain (IP Only - Not Recommended)

If you must use IP address only, you can use a self-signed certificate for testing:

### Create Self-Signed Certificate
```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/CN=3.127.210.200"
```

### Update Nginx Config
```bash
sudo nano /etc/nginx/sites-available/amorae-backend
```

Add:
```nginx
server {
    listen 443 ssl;
    server_name 3.127.210.200;

    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name 3.127.210.200;
    return 301 https://$server_name$request_uri;
}
```

Restart Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

**Note**: Self-signed certificates will show security warnings in browsers and Flutter apps.

---

## Option 3: Get a Free Domain First

### Free Domain Providers:
1. **Freenom** (freenom.com) - Free .tk, .ml, .ga, .cf, .gq domains
2. **DuckDNS** (duckdns.org) - Free subdomain (yourname.duckdns.org)
3. **No-IP** (noip.com) - Free subdomain
4. **Cloudflare** - Buy domain ($10-15/year) with free SSL

### Using DuckDNS (Easiest Free Option)

1. Go to https://www.duckdns.org/
2. Sign in with GitHub/Google
3. Create subdomain: `amorae` → `amorae.duckdns.org`
4. Point to IP: `3.127.210.200`

Then run:
```bash
sudo certbot --nginx -d amorae.duckdns.org
```

---

## Current Setup (No SSL)

Your current configuration:
- **Backend**: http://3.127.210.200:8000
- **No encryption**: Traffic is not secure
- **Not recommended for production**: Credentials sent in plain text

---

## Firewall Configuration

### Basic Setup (Current)
```bash
# Check if UFW is active
sudo ufw status

# Allow backend port
sudo ufw allow 8000/tcp

# Allow SSH (CRITICAL!)
sudo ufw allow OpenSSH

# Enable firewall
sudo ufw enable
```

### With Nginx Reverse Proxy
```bash
# Allow Nginx (HTTP + HTTPS)
sudo ufw allow 'Nginx Full'

# Allow SSH
sudo ufw allow OpenSSH

# Block direct access to backend port
sudo ufw delete allow 8000/tcp

# Enable firewall
sudo ufw enable

# Check rules
sudo ufw status numbered
```

### Security Best Practices
```bash
# Restrict backend to localhost only in supervisor config
sudo nano /etc/supervisor/conf.d/amorae-backend.conf
```

Change:
```ini
command=/home/ubuntu/Amorae/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 2
```

Then restart:
```bash
sudo supervisorctl restart amorae-backend
```

---

## Recommended Action Plan

1. **Get a domain name** (even a free one from DuckDNS)
2. **Point domain to your server IP**
3. **Install Certbot and get SSL certificate**
4. **Set up Nginx reverse proxy**
5. **Configure firewall to block direct backend access**
6. **Update Flutter app with HTTPS URL**

---

## Quick Commands Summary

### With Domain
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d api.yourdomain.com

# Configure firewall
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable

# Check certificate renewal
sudo certbot renew --dry-run
```

### Without Domain (Testing Only)
```bash
# Create self-signed cert
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/CN=3.127.210.200"

# Update nginx config manually
sudo nano /etc/nginx/sites-available/amorae-backend

# Restart
sudo nginx -t && sudo systemctl restart nginx
```

---

## Need Help?

**Option 1**: Get a free DuckDNS subdomain (5 minutes)
- Go to https://www.duckdns.org/
- Sign in and create: `amorae.duckdns.org`
- Run: `sudo certbot --nginx -d amorae.duckdns.org`

**Option 2**: Use IP address without SSL (not secure)
- Keep current setup: http://3.127.210.200:8000
- Only use for development/testing

**Option 3**: Buy a domain ($10-15/year)
- Namecheap, Cloudflare, Google Domains
- Set up proper SSL with Let's Encrypt
