#!/bin/bash

# Get current CPU usage (subtracting idle time)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

# Get current Memory usage as a percentage
MEM_USAGE=$(free | awk '/Mem/{printf("%.0f"), $3/$2*100}')

echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEM_USAGE%"

# Check if either CPU or Memory usage exceeds 75%
if (( $(echo "$CPU_USAGE > 75" | bc -l) )) || [ "$MEM_USAGE" -gt 75 ]; then
  echo "Resource usage exceeded 75%!"
  # Insert your API call or auto-scaling trigger here.
  # Example (pseudo-code):
  # curl -X POST http://your-cloud-provider/scale -d '{"action":"increase"}'
else
  echo "Resource usage is within limits."
fi

