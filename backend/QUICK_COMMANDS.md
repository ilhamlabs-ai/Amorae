# 🚀 Quick Deploy Commands

## Copy these commands to your SSH session

### 1. Create .env file
```bash
cd ~/Amorae/backend
nano .env
```

Paste this content (replace with your actual keys):
```
OPENAI_API_KEY=your_openai_api_key_here
FIREBASE_CREDENTIALS_PATH=/home/ubuntu/Amorae/backend/firebase-adminsdk.json
FIREBASE_DATABASE_ID=amorae
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
ENVIRONMENT=production
```

Save: `Ctrl+X` → `Y` → `Enter`

---

### 2. Upload Firebase credentials

#### Option A: From your Windows machine (PowerShell)
```powershell
# Replace with actual path to your firebase-adminsdk.json
scp "C:\path\to\firebase-adminsdk.json" ubuntu@3.127.210.200:~/Amorae/backend/
```

#### Option B: Create file on server
```bash
nano ~/Amorae/backend/firebase-adminsdk.json
# Paste entire JSON content, then save
```

---

### 3. Run deployment script
```bash
cd ~/Amorae/backend
bash quick-deploy.sh
```

---

### 4. Configure AWS Lightsail Firewall

Go to AWS Console → Lightsail → Your Instance → Networking tab

Add firewall rule:
- Protocol: TCP
- Port: 8000
- Source: Allow all (0.0.0.0/0)

---

### 5. Test deployment
```bash
# From server
curl http://localhost:8000/health

# From your machine (after firewall configured)
curl http://3.127.210.200:8000/health
```

---

### 6. View logs
```bash
# Real-time logs
sudo tail -f /var/log/amorae-backend.log

# Last 100 lines
sudo tail -100 /var/log/amorae-backend.log

# Error logs
sudo tail -f /var/log/amorae-backend-error.log
```

---

### 7. Manage service
```bash
# Check status
sudo supervisorctl status amorae-backend

# Restart
sudo supervisorctl restart amorae-backend

# Stop
sudo supervisorctl stop amorae-backend

# Start
sudo supervisorctl start amorae-backend
```

---

## One-Liner Setup (if quick-deploy.sh not available)

```bash
cd ~/Amorae/backend && \
source venv/bin/activate && \
pip install --upgrade pip && \
pip install -e . && \
sudo tee /etc/supervisor/conf.d/amorae-backend.conf > /dev/null <<'EOF'
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
EOF
sudo supervisorctl reread && \
sudo supervisorctl update && \
sudo supervisorctl restart amorae-backend && \
sudo supervisorctl status amorae-backend
```

---

## After Deployment

Test API endpoints:
```bash
curl http://3.127.210.200:8000/
curl http://3.127.210.200:8000/health
```

Open in browser:
- API Docs: http://3.127.210.200:8000/docs
- Health: http://3.127.210.200:8000/health

---

## Troubleshooting

### Backend won't start
```bash
# Check logs for errors
sudo tail -100 /var/log/amorae-backend.log

# Try running manually
cd ~/Amorae/backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Port already in use
```bash
# Find process using port 8000
sudo lsof -i :8000
sudo netstat -tulpn | grep 8000

# Kill process
sudo kill -9 <PID>
```

### Permission errors
```bash
# Fix ownership
sudo chown -R ubuntu:ubuntu ~/Amorae

# Fix .env permissions
chmod 600 ~/Amorae/backend/.env
chmod 600 ~/Amorae/backend/firebase-adminsdk.json
```

### Can't access from internet
1. Check firewall in AWS Lightsail Console
2. Check Ubuntu UFW: `sudo ufw status`
3. Verify service is running: `sudo supervisorctl status`
4. Check if port is listening: `sudo netstat -tulpn | grep 8000`

---

## Update Backend Later

```bash
cd ~/Amorae/backend
git pull origin main
source venv/bin/activate
pip install -e .
sudo supervisorctl restart amorae-backend
sudo tail -f /var/log/amorae-backend.log
```
