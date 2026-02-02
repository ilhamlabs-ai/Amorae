# 🚀 Deployment Guide - AWS Lightsail Ubuntu

## Prerequisites Checklist
- ✅ AWS Lightsail instance running Ubuntu
- ✅ Repository cloned: `~/Amorae/backend`
- ✅ Virtual environment created
- ⬜ OpenAI API key
- ⬜ Firebase Admin SDK JSON file
- ⬜ Environment variables configured

## Step 1: Install System Dependencies

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python 3.11+ and pip (if not already installed)
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install supervisor for process management
sudo apt install -y supervisor

# Install nginx (optional, for reverse proxy)
sudo apt install -y nginx
```

## Step 2: Configure Environment Variables

Create `.env` file in `~/Amorae/backend/`:

```bash
cd ~/Amorae/backend
nano .env
```

Add the following configuration:

```env
# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key_here

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH=/home/ubuntu/Amorae/backend/firebase-adminsdk.json
FIREBASE_DATABASE_ID=amorae

# Server Configuration
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000

# Environment
ENVIRONMENT=production
```

Save with `Ctrl+X`, then `Y`, then `Enter`.

## Step 3: Upload Firebase Admin SDK Credentials

### Option A: Using SCP from your local machine

```bash
# From your local machine (PowerShell/CMD)
scp path/to/firebase-adminsdk.json ubuntu@63.177.232.248:~/Amorae/backend/
```

### Option B: Manual upload via nano

```bash
cd ~/Amorae/backend
nano firebase-adminsdk.json
# Paste the entire JSON content, then save
```

## Step 4: Install Python Dependencies

```bash
cd ~/Amorae/backend

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -e .

# Or if using requirements.txt
pip install -r requirements.txt
```

## Step 5: Test Backend Server

```bash
# Run backend manually to test
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Test in another terminal
curl http://localhost:8000/
curl http://localhost:8000/health

# If working, press Ctrl+C to stop
```

## Step 6: Configure AWS Lightsail Firewall

1. Go to AWS Lightsail Console
2. Select your instance
3. Go to "Networking" tab
4. Under "IPv4 Firewall", add rule:
   - **Application**: Custom
   - **Protocol**: TCP
   - **Port**: 8000
   - **Restricted to**: Allow all (or specific IPs for security)

5. Under "IPv6 Firewall", add same rule for IPv6

## Step 7: Set Up Supervisor for Auto-Start

Create supervisor configuration:

```bash
sudo nano /etc/supervisor/conf.d/amorae-backend.conf
```

Add this configuration:

```ini
[program:amorae-backend]
directory=/home/ubuntu/Amorae/backend
command=/home/ubuntu/Amorae/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/amorae-backend.log
stderr_logfile=/var/log/amorae-backend-error.log
environment=PATH="/home/ubuntu/Amorae/backend/venv/bin"
```

Save and enable supervisor:

```bash
# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update

# Start the backend
sudo supervisorctl start amorae-backend

# Check status
sudo supervisorctl status amorae-backend

# View logs
sudo tail -f /var/log/amorae-backend.log
```

## Step 8: Configure Nginx Reverse Proxy (Optional but Recommended)

Create nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/amorae-backend
```

Add:

```nginx
server {
    listen 80;
    server_name 63.177.232.248;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable the site:

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/amorae-backend /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

# Enable nginx to start on boot
sudo systemctl enable nginx
```

If using nginx, update Lightsail firewall to allow HTTP (port 80) and HTTPS (port 443).

## Step 9: Update Flutter App Configuration

Update the API endpoint in your Flutter app:

**File**: `lib/shared/services/api_client.dart`

```dart
static const String baseUrl = 'http://63.177.232.248:8000';
// Or if using nginx on port 80:
// static const String baseUrl = 'http://63.177.232.248';
```

## Step 10: Verify Deployment

Test from your local machine:

```bash
# Test health endpoint
curl http://63.177.232.248:8000/health

# Test API docs
# Open in browser: http://63.177.232.248:8000/docs
```

## Supervisor Commands (Useful)

```bash
# Check status
sudo supervisorctl status amorae-backend

# Start service
sudo supervisorctl start amorae-backend

# Stop service
sudo supervisorctl stop amorae-backend

# Restart service
sudo supervisorctl restart amorae-backend

# View logs
sudo tail -f /var/log/amorae-backend.log

# View error logs
sudo tail -f /var/log/amorae-backend-error.log
```

## Troubleshooting

### Backend not starting
```bash
# Check logs
sudo tail -100 /var/log/amorae-backend.log

# Check if port is in use
sudo netstat -tulpn | grep 8000

# Verify Python environment
source ~/Amorae/backend/venv/bin/activate
python --version
pip list
```

### Firebase connection issues
```bash
# Verify credentials file exists
ls -la ~/Amorae/backend/firebase-adminsdk.json

# Check .env file
cat ~/Amorae/backend/.env

# Test Firebase connection
cd ~/Amorae/backend
source venv/bin/activate
python -c "from app.core.firebase import db; print('Firebase connected:', db is not None)"
```

### Permission issues
```bash
# Fix file permissions
sudo chown -R ubuntu:ubuntu ~/Amorae
chmod 600 ~/Amorae/backend/.env
chmod 600 ~/Amorae/backend/firebase-adminsdk.json
```

### Check service logs
```bash
# System logs
sudo journalctl -u supervisor -f

# Application logs
sudo tail -f /var/log/amorae-backend.log
```

## Security Recommendations

1. **Use HTTPS**: Set up SSL/TLS certificate with Let's Encrypt
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d yourdomain.com
   ```

2. **Firewall**: Restrict port 8000 to only nginx if using reverse proxy
   ```bash
   sudo ufw allow 'Nginx Full'
   sudo ufw allow OpenSSH
   sudo ufw enable
   ```

3. **Environment Variables**: Never commit `.env` or Firebase credentials to git

4. **API Keys**: Rotate OpenAI API keys regularly

5. **Monitoring**: Set up CloudWatch or similar monitoring

## Updating the Backend

```bash
cd ~/Amorae/backend

# Pull latest changes
git pull origin main

# Activate virtual environment
source venv/bin/activate

# Install new dependencies
pip install -e .

# Restart service
sudo supervisorctl restart amorae-backend

# Check logs
sudo tail -f /var/log/amorae-backend.log
```

## Production Checklist

- [ ] Environment variables configured
- [ ] Firebase credentials uploaded
- [ ] Dependencies installed
- [ ] Backend tested manually
- [ ] Firewall rules configured
- [ ] Supervisor configured and running
- [ ] Nginx configured (if using)
- [ ] Flutter app updated with new URL
- [ ] Health check endpoint accessible
- [ ] API docs accessible
- [ ] Logs monitoring setup

## Support

If you encounter issues:
1. Check logs: `sudo tail -100 /var/log/amorae-backend.log`
2. Verify service status: `sudo supervisorctl status`
3. Test manually: `uvicorn app.main:app --host 0.0.0.0 --port 8000`

---

**Server Details:**
- Public IPv4: 63.177.232.248
- Public IPv6: 2a05:d014:d88:3b00:c12d:51c9:6a5:d470
- Backend Path: ~/Amorae/backend
- API Endpoint: http://63.177.232.248:8000
