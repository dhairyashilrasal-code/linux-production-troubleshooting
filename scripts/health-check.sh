#!/bin/bash

DEFAULT_CONFIG="config/health.conf"
CONFIG_FILE="${1:-$DEFAULT_CONFIG}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found"
    exit 2
fi

# ShellCheck cannot follow a variable config path
# shellcheck disable=SC1090
source "$CONFIG_FILE"

mkdir -p server_logs

timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
log_file="server_logs/server_health_${timestamp}.log"

exec > >(tee "$log_file") 2>&1

echo "===== SERVER HEALTH ====="

echo "Environment: ${ENVIRONMENT:-local}"

echo "Hostname: $(hostname)"

echo "Uptime: $(uptime -p)"

echo "Load Average: $(uptime | awk -F'load average: ' '{print $2}')"

echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8 "%"}')"

echo "Memory: $(free -h | awk '/Mem:/ {print $3 " used / " $2 " total"}')"

echo "Disk: $(df -h / | awk 'NR==2 {print $3 " used / " $2 " total (" $5 ")"}')"

echo "Top CPU Process:"
ps aux --sort=-%cpu | sed -n '2p'

echo "Top Memory Process:"
ps aux --sort=-%mem | sed -n '2p'

echo "Listening Ports:"
ss -tuln

echo "Failed Services:"
systemctl --failed --no-pager

if [[ -n "${APP_TOKEN:-}" ]]; then
    echo "APP_TOKEN is configured"
else
    echo "WARNING: APP_TOKEN is not configured"
fi

disk_usage=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

if (( disk_usage > DISK_THRESHOLD )); then
    echo "ERROR: Disk usage is ${disk_usage}%"
    exit 1
fi

echo "========================="
echo "Log saved to: $log_file"

exit 0
