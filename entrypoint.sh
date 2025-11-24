#!/bin/sh
set -e

echo "[Traccar] Preparing configuration from template..."

# Render config from env vars into traccar.xml
envsubst < /opt/traccar/conf/traccar.xml.template > /opt/traccar/conf/traccar.xml

echo "[Traccar] Starting server..."
exec java -jar /opt/traccar/tracker-server.jar /opt/traccar/conf/traccar.xml
