#!/bin/bash
# Deploy GPS WebSocket server to Cloud Run
# Usage: ./deploy.sh

gcloud run deploy gps-server \
  --source . \
  --region me-west1 \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 3 \
  --memory 256Mi \
  --cpu 1 \
  --timeout 3600 \
  --session-affinity \
  --project logiroute-app

echo ""
echo "After deploy, update GPS_WS_URL in lib/config/app_config.dart"
echo "with the Cloud Run URL (wss://gps-server-XXXXX.run.app)"
