#!/bin/bash

# Amorae Backend Quick Deploy Script for AWS Lightsail Ubuntu
# Run this on your Lightsail instance: bash quick-deploy.sh

set -e  # Exit on error

echo "🚀 Amorae Backend Deployment Script"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo -e "${RED}❌ Please run this script as ubuntu user${NC}"
    exit 1
fi

# Check if in correct directory
if [ ! -f "app/main.py" ]; then
    echo -e "${RED}❌ Please run this script from ~/Amorae/backend directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Starting deployment...${NC}"

# Step 1: Check environment file
echo -e "\n${YELLOW}📝 Step 1: Checking environment configuration...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create .env file with:"
    echo "  - OPENAI_API_KEY"
    echo "  - FIREBASE_CREDENTIALS_PATH"
    echo "  - FIREBASE_DATABASE_ID"
    exit 1
fi
echo -e "${GREEN}✅ .env file found${NC}"

# Step 2: Check Firebase credentials
echo -e "\n${YELLOW}🔑 Step 2: Checking Firebase credentials...${NC}"
FIREBASE_CREDS=$(grep FIREBASE_CREDENTIALS_PATH .env | cut -d '=' -f2)
if [ ! -f "$FIREBASE_CREDS" ]; then
    echo -e "${RED}❌ Firebase credentials file not found at: $FIREBASE_CREDS${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Firebase credentials found${NC}"

# Step 3: Activate virtual environment
echo -e "\n${YELLOW}🐍 Step 3: Activating virtual environment...${NC}"
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
fi
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"

# Step 4: Install dependencies
echo -e "\n${YELLOW}📦 Step 4: Installing dependencies...${NC}"
pip install --upgrade pip
pip install -e .
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Step 5: Test backend
echo -e "\n${YELLOW}🧪 Step 5: Testing backend...${NC}"
timeout 10s uvicorn app.main:app --host 0.0.0.0 --port 8000 &
sleep 5
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is working!${NC}"
    pkill -f uvicorn
else
    echo -e "${RED}❌ Backend test failed${NC}"
    pkill -f uvicorn
    exit 1
fi

# Step 6: Install supervisor
echo -e "\n${YELLOW}⚙️  Step 6: Setting up Supervisor...${NC}"
if ! command -v supervisorctl &> /dev/null; then
    echo "Installing supervisor..."
    sudo apt update
    sudo apt install -y supervisor
fi
echo -e "${GREEN}✅ Supervisor installed${NC}"

# Step 7: Create supervisor config
echo -e "\n${YELLOW}📝 Step 7: Creating supervisor configuration...${NC}"
sudo tee /etc/supervisor/conf.d/amorae-backend.conf > /dev/null <<EOF
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
echo -e "${GREEN}✅ Supervisor config created${NC}"

# Step 8: Start service
echo -e "\n${YELLOW}🚀 Step 8: Starting backend service...${NC}"
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart amorae-backend
sleep 3

# Check status
if sudo supervisorctl status amorae-backend | grep RUNNING > /dev/null; then
    echo -e "${GREEN}✅ Backend service is running!${NC}"
else
    echo -e "${RED}❌ Backend service failed to start${NC}"
    echo "Check logs with: sudo tail -100 /var/log/amorae-backend.log"
    exit 1
fi

# Step 9: Display summary
echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Backend is running at:"
echo "  🌐 http://63.177.232.248:8000"
echo "  📚 API Docs: http://63.177.232.248:8000/docs"
echo ""
echo "Useful commands:"
echo "  📊 Check status: sudo supervisorctl status amorae-backend"
echo "  🔄 Restart: sudo supervisorctl restart amorae-backend"
echo "  📝 View logs: sudo tail -f /var/log/amorae-backend.log"
echo ""
echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
echo "  1. Configure AWS Lightsail firewall to allow port 8000"
echo "  2. Update Flutter app with new URL: http://63.177.232.248:8000"
echo ""

# Check if port is accessible from outside
echo -e "${YELLOW}Testing external access...${NC}"
if curl -s --max-time 5 http://63.177.232.248:8000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is accessible from internet!${NC}"
else
    echo -e "${YELLOW}⚠️  Backend not accessible from internet yet${NC}"
    echo "   Please configure AWS Lightsail firewall to allow port 8000"
fi
