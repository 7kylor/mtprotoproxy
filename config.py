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

# Client side TCP keep-alive settings – tune to minimise idle drops
# Time (in seconds) the connection should remain idle before TCP starts sending keep-alives.
CLIENT_KEEPALIVE = int(os.environ.get('MTPROTO_CLIENT_KEEPALIVE', 40))

# Maximum time (in seconds) that transmitted data may remain unacknowledged before the connection is aborted.
CLIENT_ACK_TIMEOUT = int(os.environ.get('MTPROTO_CLIENT_ACK_TIMEOUT', 60))
