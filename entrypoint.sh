#!/bin/sh
set -e

echo "[Traccar] Preparing configuration from template..."
echo "[DEBUG] DB_URL=$DB_URL"
echo "[DEBUG] DB_USER=$DB_USER"
echo "[DEBUG] GOOGLE_GEOLOCATION_KEY=$GOOGLE_GEOLOCATION_KEY"

# Render config from template with env vars
envsubst < /opt/traccar/conf/traccar.xml.template > /opt/traccar/conf/traccar.xml

# Test Google API depuis Railway
echo "[DEBUG] Testing Google Geolocation API from Railway..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://www.googleapis.com/geolocation/v1/geolocate?key=$GOOGLE_GEOLOCATION_KEY" \
  -H "Content-Type: application/json" \
  -d '{"wifiAccessPoints":[{"macAddress":"e8:a1:f8:eb:d6:0a","signalStrength":-40}]}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "[DEBUG] HTTP Code: $HTTP_CODE"
echo "[DEBUG] Response: $BODY"

echo "[Traccar] Starting server..."

# IMPORTANT: use Traccar’s bundled JRE
exec /opt/traccar/jre/bin/java \
  -Djava.net.preferIPv4Stack=true \
  -jar /opt/traccar/tracker-server.jar \
  conf/traccar.xml
