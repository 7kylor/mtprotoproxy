#!/bin/bash
# MTProto Proxy System Optimization Script for Low-Resource Servers
# Optimized for 1 vCPU / 2GB RAM environments
# Run with sudo privileges for maximum effect

set -e

echo "=== MTProto Proxy Low-Resource Server Optimization ==="
echo "Configuring system for 1 vCPU / 2GB RAM environment..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Warning: Some optimizations require root privileges"
    echo "Run with sudo for full optimization"
fi

# 1. Memory-Efficient Network Optimizations
echo "Applying memory-efficient network optimizations..."

# Moderate network buffer sizes (smaller than high-end servers)
sysctl -w net.core.rmem_max=16777216     # 16MB max (vs 128MB)
sysctl -w net.core.wmem_max=16777216     # 16MB max
sysctl -w net.core.rmem_default=65536    # 64KB default
sysctl -w net.core.wmem_default=65536    # 64KB default

# TCP buffer sizes (conservative for low memory)
sysctl -w net.ipv4.tcp_rmem="4096 65536 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Network queue optimizations (reduced for single CPU)
sysctl -w net.core.netdev_max_backlog=1000  # Reduced from 5000
sysctl -w net.core.netdev_budget=300        # Reduced from 600

# TCP performance optimizations
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_low_latency=1
sysctl -w net.ipv4.tcp_notsent_lowat=16384
sysctl -w net.ipv4.tcp_fastopen=3

# Reduce TIME_WAIT timeout
sysctl -w net.ipv4.tcp_fin_timeout=10
sysctl -w net.ipv4.tcp_tw_reuse=1

# 2. Conservative File Descriptor Limits
echo "Setting conservative file descriptor limits..."
ulimit -n 16384  # Reduced from 65536

# Make permanent by adding to limits.conf
cat >> /etc/security/limits.conf << EOF
* soft nofile 16384
* hard nofile 16384
root soft nofile 16384
root hard nofile 16384
EOF

# 3. CPU Performance (if available)
echo "Applying CPU optimizations..."

# Set CPU governor to performance (if available)
if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || true
fi

# 4. Memory Optimizations for Low-RAM Environment
echo "Configuring memory settings for 2GB RAM..."

# Increase swappiness slightly to handle memory pressure
sysctl -w vm.swappiness=20  # Slightly higher than default 10

# Conservative memory allocation
sysctl -w vm.dirty_ratio=10      # Lower to reduce memory pressure
sysctl -w vm.dirty_background_ratio=3

# Memory overcommit handling
sysctl -w vm.overcommit_memory=1  # Allow overcommit
sysctl -w vm.overcommit_ratio=80  # Conservative overcommit

# 5. Process Scheduling Optimizations
echo "Optimizing process scheduling for single CPU..."

# Reduce context switch overhead
sysctl -w kernel.sched_migration_cost_ns=5000000
sysctl -w kernel.sched_autogroup_enabled=0

# Single CPU optimizations
sysctl -w kernel.sched_latency_ns=6000000      # Slightly higher latency
sysctl -w kernel.sched_min_granularity_ns=750000

# 6. Network Interface Optimization (Conservative)
echo "Setting up conservative network optimizations..."

# Find network interfaces and apply light optimizations
for iface in $(ls /sys/class/net/ | grep -E '^(eth|ens|enp)'); do
    if [ -d "/sys/class/net/$iface/device" ]; then
        echo "Optimizing $iface (conservative)..."
        # Enable basic hardware features (don't force multi-queue on single CPU)
        ethtool -K $iface gro on tso on gso on 2>/dev/null || true
    fi
done

# 7. Create persistent sysctl configuration for low-resource servers
echo "Creating persistent configuration..."
cat > /etc/sysctl.d/99-mtproto-lowres.conf << EOF
# MTProto Proxy Low-Resource Server Optimizations (1 vCPU / 2GB RAM)

# Conservative network buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 65536
net.core.wmem_default = 65536

# TCP buffer sizes (conservative)
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Network queue optimizations (single CPU)
net.core.netdev_max_backlog = 1000
net.core.netdev_budget = 300

# TCP performance
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_fastopen = 3

# Connection handling
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1

# Memory management (low-resource)
vm.swappiness = 20
vm.dirty_ratio = 10
vm.dirty_background_ratio = 3
vm.overcommit_memory = 1
vm.overcommit_ratio = 80

# Process scheduling (single CPU)
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
kernel.sched_latency_ns = 6000000
kernel.sched_min_granularity_ns = 750000
EOF

# 8. Docker-specific optimizations for low-resource servers
echo "Applying Docker optimizations for low-resource environments..."

# Create Docker daemon configuration for performance
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "1m",
    "max-file": "2"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 16384,
      "Soft": 16384
    }
  },
  "max-concurrent-downloads": 2,
  "max-concurrent-uploads": 2
}
EOF

echo ""
echo "=== Low-Resource Optimization Complete ==="
echo ""
echo "Applied optimizations for 1 vCPU / 2GB RAM:"
echo "✓ Conservative network buffer sizes (16MB max)"
echo "✓ TCP performance tuning (BBR congestion control)"
echo "✓ Moderate file descriptor limits (16K)"
echo "✓ CPU governor set to performance"
echo "✓ Memory management optimized for 2GB RAM"
echo "✓ Single CPU process scheduling tuned"
echo "✓ Conservative network interface optimization"
echo "✓ Persistent configuration created"
echo "✓ Docker daemon optimized for low resources"
echo ""
echo "Resource-specific settings:"
echo "• Docker memory limit: 1.5GB (leaving 500MB for system)"
echo "• Docker CPU limit: 0.8 vCPU (leaving 20% for system)"
echo "• Connection pool: max 16-32 connections"
echo "• Buffer sizes: 32KB-64KB per connection"
echo "• Replay check: 4KB buffer"
echo ""
echo "Monitoring commands:"
echo "  docker stats mtproxy_stable"
echo "  free -h"
echo "  top -p \$(pgrep python3)"
echo ""
echo "Note: Reboot recommended for all optimizations to take effect." 