````markdown
# VCC Assignment 3 — Auto-Scaling from Local VM to GCP

This project demonstrates how to monitor system resources on a local Ubuntu Virtual Machine and automatically trigger scaling on Google Cloud Platform (GCP) when CPU or memory usage exceeds 75%. The setup uses simple shell scripts and `gcloud` CLI commands to link the local environment with cloud infrastructure.

---

## Table of Contents
- [Objective](#objective)
- [Architecture](#architecture)
- [Repository Contents](#repository-contents)
- [Prerequisites](#prerequisites)
- [VM Setup](#vm-setup)
- [Script Details](#script-details)
  - [monitor.sh](#monitorsh)
  - [scale-gcp.sh](#scale-gcpsh)
- [GCP Configuration](#gcp-configuration)
- [How It Works](#how-it-works)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)
- [Cleanup and Security](#cleanup-and-security)
- [Files](#files)
- [License](#license)

---

## Objective
Create a local VM and implement a mechanism to monitor resource usage. Configure it to automatically scale to a public cloud (e.g., GCP) when CPU or memory usage exceeds **75%**.

---

## Architecture
1. A **local Ubuntu VM** runs the monitoring script (`monitor.sh`).
2. The script tracks CPU and memory utilization.
3. When usage crosses the threshold (75%), it triggers the **auto-scaling script (`scale-gcp.sh`)**.
4. The scaling script interacts with a **GCP Managed Instance Group (MIG)** using `gcloud` commands.
5. The MIG increases the number of VM replicas in the cloud to handle increased load.

---

## Repository Contents
- `monitor.sh` — Monitors CPU and memory usage, triggers scaling when threshold is crossed.  
- `scale-gcp.sh` — Uses `gcloud` CLI to scale up instances in GCP.  
- `B22ES020_VCC_Ass3 (2).pdf` — Detailed project report with screenshots and explanation.

---

## Prerequisites
- **Local System**
  - VirtualBox or any other hypervisor.
  - Ubuntu 22.04 installed on the VM.
  - Shared folder configured (optional).

- **Software inside VM**
  - `gcloud` SDK installed and authenticated.
  - `bc`, `awk`, `top`, `free` utilities (default on Ubuntu).
  - `stress-ng` for load testing (optional).

---

## VM Setup
1. Create an Ubuntu VM in VirtualBox.  
   - Recommended specs: 2 CPUs, 4 GB RAM.  
   - Enable bridged networking for easy access.  
2. Install required packages:
   ```bash
   sudo apt update
   sudo apt install -y bc stress-ng
````

3. Copy both scripts (`monitor.sh` and `scale-gcp.sh`) into the VM and make them executable:

   ```bash
   chmod +x monitor.sh scale-gcp.sh
   ```

---

## Script Details

### monitor.sh

This script continuously checks the CPU and memory usage of the system.
If usage exceeds **75%**, it triggers the GCP scaling script.

```bash
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
  /path/to/scale-gcp.sh
else
  echo "Resource usage is within limits."
fi
```

To schedule this script to run automatically every minute using cron:

```bash
(crontab -l 2>/dev/null; echo "* * * * * /path/to/monitor.sh") | crontab -
```

---

### scale-gcp.sh

This script is responsible for scaling up the instance group in GCP when triggered.

```bash
#!/bin/bash

set -e
set -x

echo "🚀 Starting auto-scaling script..."

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
echo "🔍 Detected CPU Usage: $CPU_USAGE%"

THRESHOLD=75.0
echo "⚠️ Threshold set at: $THRESHOLD%"

if (( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) )); then
    echo "🔥 CPU usage is HIGH ($CPU_USAGE%), triggering auto-scale..."

    gcloud compute instance-groups managed set-autoscaling ass3-mig \
        --region=us-central1 \
        --max-num-replicas=5 \
        --cool-down-period=60

    echo "✅ Scaling command executed!"
else
    echo "✅ CPU usage is normal ($CPU_USAGE%), no scaling needed."
fi
```

Replace `ass3-mig` and `us-central1` with your own instance group and region.

---

## GCP Configuration

1. **Enable Compute Engine API:**

   ```bash
   gcloud services enable compute.googleapis.com
   ```
2. **Create an instance template:**

   ```bash
   gcloud compute instance-templates create ass3-template \
       --machine-type=e2-medium \
       --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud
   ```
3. **Create a Managed Instance Group (MIG):**

   ```bash
   gcloud compute instance-groups managed create ass3-mig \
       --base-instance-name=ass3-vm \
       --template=ass3-template \
       --size=1 \
       --region=us-central1
   ```
4. **Enable autoscaling:**

   ```bash
   gcloud compute instance-groups managed set-autoscaling ass3-mig \
       --region=us-central1 \
       --max-num-replicas=5 \
       --min-num-replicas=1 \
       --target-cpu-utilization=0.6 \
       --cool-down-period=60
   ```

Ensure your service account or user has appropriate permissions (Compute Admin roles).

---

## How It Works

1. The **monitor.sh** script runs periodically on the local VM.
2. When CPU or memory usage goes above 75%, it calls **scale-gcp.sh**.
3. The scaling script uses the `gcloud` CLI to modify autoscaling settings for the GCP Managed Instance Group.
4. The Managed Instance Group automatically scales up instances in GCP to handle the increased load.
5. When resource usage decreases, autoscaling gradually scales the group back down.

---

## Testing and Validation

To simulate high CPU load on the VM, use:

```bash
stress-ng --cpu 4 --io 2 --vm 1 --vm-bytes 1G --timeout 300s
```

During this test, the monitor script detects increased CPU usage and triggers scaling.
The event logs and screenshots of this behavior are available in the attached project report PDF.

---

## Troubleshooting

* **`gcloud` not found:** Install it using the Google Cloud SDK installation instructions.
* **Permission errors:** Verify IAM roles for the service account.
* **No scaling happening:** Check if the Managed Instance Group name and region match your configuration.
* **Too frequent triggers:** Increase the cooldown period in GCP or add a local delay in `monitor.sh`.

---

## Cleanup and Security

After testing, remove all created resources:

```bash
gcloud compute instance-groups managed delete ass3-mig --region=us-central1
gcloud compute instance-templates delete ass3-template
```

Use a dedicated service account with minimum permissions. Avoid hardcoding credentials in scripts.

---

## Files

* `monitor.sh` — Monitoring script.
* `scale-gcp.sh` — GCP scaling script.
* `B22ES020_VCC_Ass3 (2).pdf` — Detailed project report.

---

## License

This project is provided for academic and educational purposes.

```
```
