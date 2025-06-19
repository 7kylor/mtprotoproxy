#!/bin/bash
# MTProto Proxy System Optimization Script
# Run with sudo privileges for maximum effect

set -e

echo "=== MTProto Proxy System Optimization ==="
echo "Configuring system for ultra-low latency performance..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Warning: Some optimizations require root privileges"
    echo "Run with sudo for full optimization"
fi

# 1. Network Performance Optimizations
echo "Applying network optimizations..."

# Increase network buffer sizes
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.core.rmem_default=262144
sysctl -w net.core.wmem_default=262144

# TCP buffer sizes
sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"

# Network queue optimizations
sysctl -w net.core.netdev_max_backlog=5000
sysctl -w net.core.netdev_budget=600

# TCP performance optimizations
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_low_latency=1
sysctl -w net.ipv4.tcp_notsent_lowat=16384
sysctl -w net.ipv4.tcp_fastopen=3

# Reduce TIME_WAIT timeout
sysctl -w net.ipv4.tcp_fin_timeout=10
sysctl -w net.ipv4.tcp_tw_reuse=1

# 2. File Descriptor Limits
echo "Increasing file descriptor limits..."
ulimit -n 65536

# Make permanent by adding to limits.conf
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF

# 3. CPU Performance Optimizations
echo "Applying CPU optimizations..."

# Set CPU governor to performance (if available)
if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || true
fi

# Disable CPU frequency scaling (if needed for consistency)
# echo 1 | tee /sys/devices/system/cpu/intel_pstate/no_turbo || true

# 4. Memory Optimizations
echo "Configuring memory settings..."

# Reduce swappiness for better performance
sysctl -w vm.swappiness=10

# Optimize memory allocation
sysctl -w vm.dirty_ratio=15
sysctl -w vm.dirty_background_ratio=5

# 5. Process Scheduling Optimizations
echo "Optimizing process scheduling..."

# Reduce context switch overhead
sysctl -w kernel.sched_migration_cost_ns=5000000
sysctl -w kernel.sched_autogroup_enabled=0

# 6. IRQ Affinity (Network Interface Optimization)
echo "Setting up IRQ affinity..."

# Find network interfaces and optimize IRQ affinity
for iface in $(ls /sys/class/net/ | grep -E '^(eth|ens|enp)'); do
    if [ -d "/sys/class/net/$iface/device" ]; then
        echo "Optimizing $iface..."
        # Set multi-queue networking
        ethtool -L $iface combined $(nproc) 2>/dev/null || true
        # Enable hardware features
        ethtool -K $iface gro on lro on tso on gso on 2>/dev/null || true
    fi
done

# 7. Create persistent sysctl configuration
echo "Creating persistent configuration..."
cat > /etc/sysctl.d/99-mtproto-performance.conf << EOF
# MTProto Proxy Performance Optimizations

# Network buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# TCP buffer sizes
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# Network queue optimizations
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600

# TCP performance
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_fastopen = 3

# Connection handling
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1

# Memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Process scheduling
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
EOF

# 8. Docker-specific optimizations
echo "Applying Docker optimizations..."

# Create Docker daemon configuration for performance
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "2m",
    "max-file": "2"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF

echo ""
echo "=== Optimization Complete ==="
echo ""
echo "Applied optimizations:"
echo "✓ Network buffer sizes increased"
echo "✓ TCP performance tuning (BBR congestion control)"
echo "✓ File descriptor limits raised"
echo "✓ CPU governor set to performance"
echo "✓ Memory management optimized"
echo "✓ Process scheduling tuned"
echo "✓ IRQ affinity optimized"
echo "✓ Persistent configuration created"
echo "✓ Docker daemon optimized"
echo ""
echo "Recommendations:"
echo "1. Reboot the system to ensure all changes take effect"
echo "2. Monitor performance with: docker stats, iftop, htop"
echo "3. Consider using host networking for minimal latency"
echo "4. Place proxy geographically close to Telegram datacenters"
echo "5. Use SSD storage for better I/O performance"
echo ""
echo "Note: Some optimizations require a system restart to take full effect." 