FROM ubuntu:24.04

# Install dependencies with performance-focused packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    python3-cryptography \
    python3-socks \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install high-performance async libraries
RUN pip3 install --no-cache-dir \
    uvloop \
    cython \
    --break-system-packages

# Create non-root user first
RUN useradd tgproxy -u 10000 --create-home

# Set working directory
WORKDIR /home/tgproxy/

# Copy application files with correct ownership
COPY --chown=tgproxy:tgproxy mtprotoproxy.py config.py /home/tgproxy/
COPY --chown=tgproxy:tgproxy pyaes/ /home/tgproxy/pyaes/

# Switch to non-root user
USER tgproxy

# Expose port
EXPOSE 8080

# Performance-optimized health check with shorter intervals
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=2 \
    CMD python3 -c "import socket; s=socket.socket(); s.settimeout(1); s.connect(('127.0.0.1', 8080)); s.close()"

# Run with performance optimizations
CMD ["python3", "-O", "mtprotoproxy.py"]
