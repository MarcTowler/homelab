#!/bin/bash
# Fitbit Stack Diagnostics Script
# Run this on the fitbit host to debug data collection issues

set -e

echo "🔍 FITBIT DIAGNOSTICS REPORT"
echo "======================================"
echo "Host: $(hostname) | Time: $(date)"
echo ""

# 1. Docker Compose Status
echo "📦 DOCKER COMPOSE STATUS"
echo "------------------------------------"
cd /opt/fitbit-grafana
docker compose ps
echo ""

# 2. Check Token File
echo "🔑 TOKEN BOOTSTRAP STATUS"
echo "------------------------------------"
if [ -f "tokens/fitbit.token" ]; then
  echo "✅ Token file exists"
  echo "Last modified: $(date -r tokens/fitbit.token)"
  echo "File size: $(stat -f%z tokens/fitbit.token 2>/dev/null || stat -c%s tokens/fitbit.token)"
else
  echo "❌ Token file MISSING - Bootstrap not completed"
  echo "⚠️  Manual setup required - run: docker compose run --rm fitbit-fetch-data"
fi
echo ""

# 3. Fitbit Container Logs (last 50 lines)
echo "📋 FITBIT-FETCH-DATA LOGS (last 50 lines)"
echo "------------------------------------"
docker compose logs fitbit-fetch-data --tail=50
echo ""

# 4. InfluxDB Container Logs (last 30 lines)
echo "📋 INFLUXDB LOGS (last 30 lines)"
echo "------------------------------------"
docker compose logs influxdb --tail=30
echo ""

# 5. InfluxDB API Health Check
echo "🏥 INFLUXDB API HEALTH"
echo "------------------------------------"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8086/ping || echo "❌ Unable to reach InfluxDB"
echo ""

# 6. Container Environment Variables
echo "🔧 FITBIT CONTAINER ENV VARIABLES"
echo "------------------------------------"
docker exec fitbit-fetch-data env | grep -E "GOOGLE|INFLUXDB|HEALTH_API" || echo "No matching env vars found"
echo ""

# 7. InfluxDB Database Check
echo "📊 INFLUXDB DATABASE & SCHEMA"
echo "------------------------------------"
docker exec influxdb influx -execute "SHOW DATABASES" || echo "Unable to query InfluxDB"
echo ""
docker exec influxdb influx -database FitbitHealthStats -execute "SHOW MEASUREMENTS" || echo "Unable to query measurements"
echo ""

# 8. Recent Data Check
echo "📈 RECENT DATA (last 5 measurements)"
echo "------------------------------------"
docker exec influxdb influx -database FitbitHealthStats -execute "SELECT * FROM /./ LIMIT 5" 2>/dev/null || echo "No data found in InfluxDB"
echo ""

# 9. Volume Permissions
echo "📁 VOLUME PERMISSIONS"
echo "------------------------------------"
ls -la /opt/fitbit-grafana/tokens/ 2>/dev/null || echo "tokens directory not found"
ls -la /opt/fitbit-grafana/logs/ 2>/dev/null || echo "logs directory not found"
echo ""

echo "======================================"
echo "✅ Diagnostics Complete"
echo ""
echo "Next steps based on findings:"
echo "1. If token missing → Run manual bootstrap: docker compose run --rm fitbit-fetch-data"
echo "2. If API errors → Check GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in env"
echo "3. If InfluxDB errors → Check influxdb logs and DB connectivity"
echo "4. If no data → Check that fitbit-fetch-data container is actually running"
