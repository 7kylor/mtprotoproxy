import os
import secrets

# Dynamic port selection (environment variable or auto-discovery)
PORT = int(os.environ.get('MTPROTO_PORT', 8080))

# Auto-generate secure secrets dynamically 
def generate_secret():
    return secrets.token_hex(16)

# Dynamic users with auto-generated secrets
USERS = {
    "user1": os.environ.get('USER1_SECRET', generate_secret()),
    "user2": os.environ.get('USER2_SECRET', generate_secret()),
}

MODES = {
    # Classic mode disabled for security
    "classic": False,

    # Secure mode enabled for better detection resistance
    "secure": True,

    # TLS mode enabled for maximum security
    "tls": True
}

# Dynamic TLS domain for better camouflage
TLS_DOMAIN = os.environ.get('TLS_DOMAIN', "www.cloudflare.com")

# Override IP detection for Docker environments
MY_DOMAIN = os.environ.get('MY_IP', None)

# Optional advertising tag (can be set via environment)
AD_TAG = os.environ.get('AD_TAG', None)

# ===== PERFORMANCE OPTIMIZATIONS FOR LOW-RESOURCE SERVERS (1 vCPU, 2GB RAM) =====

# Enable fast mode for reduced encryption overhead (already enabled by default)
FAST_MODE = True

# Optimized buffer sizes for low-memory environments
# Format: (low_watermark, user_threshold, high_watermark)
TO_CLT_BUFSIZE = (8192, 20, 65536)  # Smaller buffers for memory efficiency
TO_TG_BUFSIZE = 32768  # Reduced buffer for Telegram direction

# Reduced timeouts for faster failure detection and recovery
TG_CONNECT_TIMEOUT = 5  # Faster Telegram server connection timeout
CLIENT_HANDSHAKE_TIMEOUT = 3  # Faster client handshake timeout
CLIENT_ACK_TIMEOUT = 60  # Reduced ACK timeout but not too aggressive

# Optimized keepalive settings
CLIENT_KEEPALIVE = 300  # 5 minutes instead of 10

# Disable time-intensive operations where possible
GET_TIME_PERIOD = 0  # Disable time sync to reduce overhead
STATS_PRINT_PERIOD = 3600  # Print stats less frequently (1 hour)

# Memory-efficient connection pool (reduced for low-resource servers)
# Note: This setting is in mtprotoproxy.py - MAX_CONNS_IN_POOL
# For 1 vCPU/2GB: recommend 16-32 connections max

# Prefer IPv6 if available for potentially better routing
PREFER_IPV6 = True

# Reduced replay check length for memory efficiency
REPLAY_CHECK_LEN = 4096  # Further reduced for low-memory environments

# Disable middle proxy if not needed for ads (improves latency and reduces memory)
# Only enable if you need advertising functionality
USE_MIDDLE_PROXY = len(os.environ.get('AD_TAG', '')) == 32

# Reduce certificate check frequency
GET_CERT_LEN_PERIOD = 12 * 60 * 60  # Check every 12 hours to reduce overhead

# Performance monitoring (disabled by default for resource efficiency)
METRICS_PORT = int(os.environ.get('METRICS_PORT', 9090)) if os.environ.get('ENABLE_METRICS') else None

# ===== LOW-RESOURCE SPECIFIC OPTIMIZATIONS =====

# Reduce client IP tracking for memory efficiency
CLIENT_IPS_LEN = 1024  # Reduced from default 131072

# More aggressive connection limits for resource management
USER_MAX_TCP_CONNS = {
    # Limit each user to fewer concurrent connections
    "user1": 4,
    "user2": 4
}
