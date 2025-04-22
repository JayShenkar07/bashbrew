#!/bin/bash

# system-health-check.sh
# Description: A structured, tabular system health report for Linux servers.

set -euo pipefail

# Colors for pretty output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

header() {
  echo -e "\n${BLUE}==> $1${NC}"
}

success() {
  echo -e "${GREEN}[✔] $1${NC}"
}

fail() {
  echo -e "${RED}[✘] $1${NC}"
}

# Output report
header "System Health Report for: $(hostname)"
echo "Generated on: $(date)"
echo "--------------------------------------------------"

### CPU USAGE
header "CPU Usage"
top -bn1 | grep "Cpu(s)" | awk -F',' '{ 
  printf "%-20s %-10s\n%-20s %-10s\n%-20s %-10s\n%-20s %-10s\n", 
  "User:", $1, "System:", $2, "Idle:", $4, "IO Wait:", $5
}' | column -t

### MEMORY USAGE
header "Memory Usage"
free -h | awk 'NR==1 || NR==2 {printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $4}' | column -t

### DISK USAGE
header "Disk Usage"
df -h --output=source,size,used,avail,pcent,target | column -t

### UPTIME & LOAD AVERAGE
header "Uptime and Load Average"
uptime | awk -F'( |,|:)+' '{ 
  printf "%-15s: %s days, %s hours, %s minutes\n", "Uptime", $4, $5, $6
  printf "%-15s: %s %s %s\n", "Load Average", $(NF-2), $(NF-1), $NF 
}'

### TOP MEMORY-CONSUMING PROCESSES
header "Top 5 Memory-Consuming Processes"
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 6 | awk 'BEGIN { printf "%-8s %-20s %-8s %-8s\n", "PID", "COMMAND", "%MEM", "%CPU" } { printf "%-8s %-20s %-8s %-8s\n", $1, $2, $3, $4 }'

### TOP CPU-CONSUMING PROCESSES
header "Top 5 CPU-Consuming Processes"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 | awk 'BEGIN { printf "%-8s %-20s %-8s %-8s\n", "PID", "COMMAND", "%CPU", "%MEM" } { printf "%-8s %-20s %-8s %-8s\n", $1, $2, $3, $4 }'

### OPEN PORTS
header "Listening Ports"
ss -tuln | awk 'NR==1 { print "Proto\tRecv-Q\tSend-Q\tLocal Address:Port\t\tState" } NR>1 { printf "%-7s %-7s %-7s %-30s %-10s\n", $1, $2, $3, $5, $6 }'

### SERVICE STATUS CHECK
header "Service Status"
services=("nginx" "docker" "mysql" "postgresql" "sshd")
printf "%-15s %-10s\n" "Service" "Status"
for svc in "${services[@]}"; do
  if systemctl list-unit-files --type=service | grep -q "$svc"; then
    if systemctl is-active --quiet "$svc"; then
      printf "%-15s %-10s\n" "$svc" "running"
    else
      printf "%-15s %-10s\n" "$svc" "stopped"
    fi
  else
    printf "%-15s %-10s\n" "$svc" "not found"
  fi
done

echo
success "System health check complete ✅"
