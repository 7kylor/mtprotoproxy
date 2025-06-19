#!/bin/bash

echo "============================================================"
echo " Deploying Stable MTProxy"
echo "============================================================"

echo "Applying kernel tuning for stable connections..."
if [ "$(id -u)" = "0" ]; then
  cp sysctl_mtproxy.conf /etc/sysctl.d/99-mtproxy.conf || true
  sysctl --system > /dev/null 2>&1 || true
  echo "Kernel tuning applied successfully"
else
  echo "(non-root) Please copy sysctl_mtproxy.conf to /etc/sysctl.d/ and run 'sudo sysctl --system' manually" >&2
fi

echo "Checking system resources..."
MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEMORY_MB=$((MEMORY_KB / 1024))
echo "Available memory: ${MEMORY_MB}MB"

if [ "$MEMORY_MB" -lt 1024 ]; then
    echo "Warning: Low memory detected. Applying conservative settings..."
    export MTPROTO_RECV_BUFFER=16384
    export MTPROTO_SEND_BUFFER=16384
    export MTPROTO_CLIENT_KEEPALIVE=20
    export MTPROTO_CLIENT_ACK_TIMEOUT=120
fi

echo "Setting up Python environment..."
# Install required packages if not present
python3 -c "import uvloop" 2>/dev/null || {
    echo "Installing uvloop for better performance..."
    pip3 install uvloop --user || echo "Warning: Could not install uvloop"
}

# Function to generate secure random hex string
generate_secret() {
    python3 -c "import secrets; print(secrets.token_hex(16))"
}

# Function to find available port
find_available_port() {
    local start_port=${1:-8080}
    local end_port=${2:-9999}
    
    for port in $(seq $start_port $end_port); do
        if ! ss -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
    done
    
    echo "8080" # fallback
}

# Get external IP
get_external_ip() {
    curl -s http://ifconfig.me || curl -s http://ipinfo.io/ip || echo "unknown"
}

# Find available port
MTPROTO_PORT=$(find_available_port 8080 9999)
echo "Selected port: $MTPROTO_PORT"

# Generate secrets if not provided
if [ -z "$USER1_SECRET" ]; then
    export USER1_SECRET=$(generate_secret)
    echo "Generated USER1_SECRET: $USER1_SECRET"
else
    echo "Using provided USER1_SECRET"
fi

if [ -z "$USER2_SECRET" ]; then
    export USER2_SECRET=$(generate_secret)
    echo "Generated USER2_SECRET: $USER2_SECRET"
else
    echo "Using provided USER2_SECRET"
fi

# Set default values for optional variables
export AD_TAG=${AD_TAG:-""}

# Set environment variables
export MTPROTO_PORT
export TLS_DOMAIN=${TLS_DOMAIN:-www.cloudflare.com}

# Get external IP
EXTERNAL_IP=$(get_external_ip)

echo "============================================================"
echo " Configuration Generated"
echo "============================================================"
echo "Port: $MTPROTO_PORT"
echo "External IP: $EXTERNAL_IP"
echo "TLS Domain: $TLS_DOMAIN"
echo "User1 Secret: $USER1_SECRET"
echo "User2 Secret: $USER2_SECRET"
echo "============================================================"

echo "============================================================"
echo " Generating .env file for consistent configuration"
echo "============================================================"
{
    echo "MTPROTO_PORT=${MTPROTO_PORT}"
    echo "TLS_DOMAIN=${TLS_DOMAIN}"
    echo "USER1_SECRET=${USER1_SECRET}"
    echo "USER2_SECRET=${USER2_SECRET}"
    echo "AD_TAG=${AD_TAG}"
    echo "MY_IP=${EXTERNAL_IP}"
} > .env
echo ".env file created successfully."
echo "============================================================"

# Stop any existing containers
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Build and start the proxy
echo "Building and starting MTProxy..."
docker-compose build --no-cache
docker-compose up -d

echo "============================================================"
echo " MTProxy Deployment Complete!"
echo "============================================================"

# Wait for container to start
sleep 5

# Generate correct connection URLs with protocol prefixes
TLS_DOMAIN_HEX=$(echo -n "$TLS_DOMAIN" | xxd -p | tr -d '\n')

# Show connection information
echo "Connection URLs:"
echo
echo "Secure URLs (dd prefix):"
echo "  User1: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=dd$USER1_SECRET"
echo "  User2: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=dd$USER2_SECRET"
echo
echo "TLS URLs (ee prefix):"
echo "  User1: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=ee$USER1_SECRET$TLS_DOMAIN_HEX"
echo "  User2: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=ee$USER2_SECRET$TLS_DOMAIN_HEX"
echo
echo "Manual Configuration:"
echo "   Server: $EXTERNAL_IP"
echo "   Port: $MTPROTO_PORT"
echo "   Secure Secret 1: dd$USER1_SECRET"
echo "   Secure Secret 2: dd$USER2_SECRET"
echo "   TLS Secret 1: ee$USER1_SECRET$TLS_DOMAIN_HEX"
echo "   TLS Secret 2: ee$USER2_SECRET$TLS_DOMAIN_HEX"
echo

# Load .env to show correct info
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

echo "Logs: docker-compose logs -f mtproxy"
echo "============================================================"

echo "Deployment configuration complete."
echo ""
echo "To start the proxy:"
echo "  python3 mtprotoproxy.py"
echo ""
echo "To run as systemd service:"
echo "  sudo cp mtprotoproxy.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable mtprotoproxy"
echo "  sudo systemctl start mtprotoproxy" 