#!/bin/bash

echo "============================================================"
echo " Deploying Stable MTProxy"
echo "============================================================"

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

# Show connection information
echo "Connection URLs:"
echo "TLS URL: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=$USER1_SECRET"
echo "Secure URL: tg://proxy?server=$EXTERNAL_IP&port=$MTPROTO_PORT&secret=$USER2_SECRET"
echo
echo "Manual Configuration:"
echo "   Server: $EXTERNAL_IP"
echo "   Port: $MTPROTO_PORT"
echo "   Secret 1: $USER1_SECRET"
echo "   Secret 2: $USER2_SECRET"
echo

# Load .env to show correct info
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

echo "Logs: docker-compose logs -f mtproxy"
echo "============================================================" 