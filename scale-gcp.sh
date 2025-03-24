#!/bin/bash

# Enable debugging and error handling
set -e
set -x

echo "🚀 Starting auto-scaling script..."

# Get current CPU usage and print it
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
echo "🔍 Detected CPU Usage: $CPU_USAGE%"

# Set CPU threshold
THRESHOLD=75.0
echo "⚠️ Threshold set at: $THRESHOLD%"

# Check if CPU usage exceeds threshold
if (( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) )); then
    echo "🔥 CPU usage is HIGH ($CPU_USAGE%), triggering auto-scale..."

    # Scale up GCP instance group (Replace with your instance group & region)
    gcloud compute instance-groups managed set-autoscaling ass3-mig \
        --region=us-central1 \
        --max-num-replicas=5 \
        --cool-down-period=60

    echo "✅ Scaling command executed!"
else
    echo "✅ CPU usage is normal ($CPU_USAGE%), no scaling needed."
fi

