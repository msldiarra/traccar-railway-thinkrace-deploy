#!/bin/sh
set -e

echo "[Traccar] Preparing configuration from template..."
echo "[DEBUG] DB_URL=$DB_URL"
echo "[DEBUG] DB_USER=$DB_USER"
echo "[DEBUG] GOOGLE_GEOLOCATION_KEY=$GOOGLE_GEOLOCATION_KEY"

# Render config from template with env vars
envsubst < /opt/traccar/conf/traccar.xml.template > /opt/traccar/conf/traccar.xml

# Afficher la section geolocation du XML généré
echo "[DEBUG] Geolocation config:"
grep -A5 "geolocation" /opt/traccar/conf/traccar.xml || echo "No geolocation config found"


echo "[Traccar] Starting server..."

# IMPORTANT: use Traccar’s bundled JRE
exec /opt/traccar/jre/bin/java \
  -Djava.net.preferIPv4Stack=true \
  -jar /opt/traccar/tracker-server.jar \
  conf/traccar.xml
