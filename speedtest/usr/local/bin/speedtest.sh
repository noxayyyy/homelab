#!/bin/bash

# Define where Node Exporter looks for text files
PROM_DIR="/srv/monitoring/textfiles"
PROM_FILE="$PROM_DIR/speedtest.prom"
TMP_FILE="$PROM_DIR/speedtest.tmp"

# Ensure the directory exists
# mkdir -p "$PROM_DIR"

# Run the official speedtest CLI silently and output as JSON
RESULT=$(/usr/bin/speedtest -f json)

# If the speedtest fails (e.g. internet is down), exit so we don't write blank data
if [ -z "$RESULT" ]; then
    exit 1
fi

# Extract metrics using jq
DOWNLOAD=$(echo "$RESULT" | jq -r '.download.bandwidth // 0')
UPLOAD=$(echo "$RESULT" | jq -r '.upload.bandwidth // 0')
PING=$(echo "$RESULT" | jq -r '.ping.latency // 0')
JITTER=$(echo "$RESULT" | jq -r '.ping.jitter // 0')
PACKET_LOSS=$(echo "$RESULT" | jq -r '.packetLoss // 0')

# Write metrics to a temporary file
cat <<EOF > "$TMP_FILE"
# HELP speedtest_download_bytes_per_second Download bandwidth in bytes/sec
# TYPE speedtest_download_bytes_per_second gauge
speedtest_download_bytes_per_second $DOWNLOAD
# HELP speedtest_upload_bytes_per_second Upload bandwidth in bytes/sec
# TYPE speedtest_upload_bytes_per_second gauge
speedtest_upload_bytes_per_second $UPLOAD
# HELP speedtest_ping_latency_milliseconds Ping latency in ms
# TYPE speedtest_ping_latency_milliseconds gauge
speedtest_ping_latency_milliseconds $PING
# HELP speedtest_ping_jitter_milliseconds Ping jitter in ms
# TYPE speedtest_ping_jitter_milliseconds gauge
speedtest_ping_jitter_milliseconds $JITTER
# HELP speedtest_packet_loss_percentage Packet loss percentage
# TYPE speedtest_packet_loss_percentage gauge
speedtest_packet_loss_percentage $PACKET_LOSS
EOF

# Atomically move the temp file to the final file so Prometheus doesn't read a half-written file
mv "$TMP_FILE" "$PROM_FILE"
