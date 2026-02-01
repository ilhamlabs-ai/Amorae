# Amorae Backend

FastAPI backend for the Amorae AI Companion app.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
```

2. Install dependencies:
```bash
pip install -e ".[dev]"
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run the development server:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Chat
- `POST /v1/chat/send_stream` - Send message with SSE streaming response

### Memory
- `POST /v1/memory/curate` - Trigger memory curation
- `GET /v1/memory/facts` - Get user facts
- `DELETE /v1/memory/facts/{fact_id}` - Delete a fact

### Privacy
- `POST /v1/privacy/delete_user` - Delete all user data
- `GET /v1/privacy/export_data` - Export all user data

### Health
- `GET /health` - Health check

## Environment Variables

See `.env.example` for required environment variables.

## Deployment

Deploy to Cloud Run:
```bash
gcloud run deploy amorae-api \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```
