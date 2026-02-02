# DuckDNS Setup Guide

## Problem
Let's Encrypt cannot verify your domain because the DNS record doesn't exist yet:
```
DNS problem: NXDOMAIN looking up A for amorae.duckdns.org
```

## Step 1: Register Your DuckDNS Domain

1. **Go to DuckDNS website**:
   ```
   https://www.duckdns.org/
   ```

2. **Sign in** with GitHub, Google, or other provider

3. **Create subdomain**:
   - Enter: `amorae` (not the full domain)
   - Click "add domain"
   - You'll get: `amorae.duckdns.org`

4. **Point to your AWS IP**:
   - In the "current ip" field, enter: `3.127.210.200`
   - Click "update ip"
   - Copy your token (you'll need it later)

## Step 2: Update DuckDNS IP (Keep It Updated)

DuckDNS requires periodic updates to keep the IP active. There are two options:

### Option A: Manual Update (Quick Test)
Just visit this URL in your browser (replace YOUR_TOKEN):
```
https://www.duckdns.org/update?domains=amorae&token=YOUR_TOKEN&ip=3.127.210.200
```

You should see: `OK`

### Option B: Automated Update (Recommended)
Create a cron job to update every 5 minutes:

```bash
# Create update script
cat > ~/duckdns-update.sh << 'EOF'
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=amorae&token=YOUR_TOKEN&ip=3.127.210.200" | curl -k -o ~/duckdns.log -K -
EOF

# Replace YOUR_TOKEN with actual token
nano ~/duckdns-update.sh

# Make executable
chmod +x ~/duckdns-update.sh

# Test it
~/duckdns-update.sh
cat ~/duckdns.log  # Should show "OK"

# Add to cron (runs every 5 minutes)
crontab -e
# Add this line:
*/5 * * * * ~/duckdns-update.sh >/dev/null 2>&1
```

## Step 3: Verify DNS Propagation

Wait 2-5 minutes, then test:

```bash
# Check if DNS resolves to your IP
dig amorae.duckdns.org +short
# Should return: 3.127.210.200

# Or use nslookup
nslookup amorae.duckdns.org
# Should show: Address: 3.127.210.200

# Or simple ping
ping -c 3 amorae.duckdns.org
```

## Step 4: Update Nginx Configuration

```bash
# Edit nginx config
sudo nano /etc/nginx/sites-available/amorae-backend
```

Change the server_name:
```nginx
server {
    listen 80;
    server_name amorae.duckdns.org 3.127.210.200;  # Add both
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Step 5: Run Certbot Again

```bash
sudo certbot --nginx -d amorae.duckdns.org
```

This time it should succeed! Certbot will:
- Verify domain ownership via HTTP challenge
- Issue SSL certificate
- Automatically update nginx config for HTTPS
- Set up auto-renewal

## Step 6: Update Flutter App URL

After SSL is set up, update your Flutter app:

**File**: `lib/shared/providers/providers.dart`
```dart
const String productionUrl = 'https://amorae.duckdns.org';  // HTTPS + domain
```

## Step 7: Test HTTPS

```bash
# Test from server
curl https://amorae.duckdns.org/health

# Check certificate details
curl -vI https://amorae.duckdns.org 2>&1 | grep -i 'SSL\|TLS\|certificate'
```

## Troubleshooting

### DNS still not resolving
```bash
# Force update
curl "https://www.duckdns.org/update?domains=amorae&token=YOUR_TOKEN&ip=3.127.210.200"

# Wait 5 minutes and check again
dig amorae.duckdns.org +short
```

### Certbot fails with "Connection refused"
```bash
# Ensure port 80 is open
sudo ufw status
sudo ufw allow 'Nginx Full'

# Check nginx is running
sudo systemctl status nginx

# Test nginx is accessible
curl http://3.127.210.200/health
```

### Certificate expires
Certbot sets up auto-renewal via cron/systemd. Check it:
```bash
# Test renewal
sudo certbot renew --dry-run

# Check renewal timer (Ubuntu 20.04+)
sudo systemctl status certbot.timer
```

## Notes

- **DuckDNS is free** but requires regular updates (every 30 days minimum)
- **SSL certificates expire** every 90 days but Certbot auto-renews them
- **Keep your token secret** - it's like a password for your domain
- **Backup your token** - save it in a secure location

## After SSL Setup

1. Update AWS Lightsail firewall to allow HTTPS (443)
2. Update Flutter app to use HTTPS URL
3. Test all API endpoints with HTTPS
4. Verify Firebase authentication still works
5. Update any hardcoded HTTP URLs to HTTPS
