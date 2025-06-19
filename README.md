# MTProto Proxy

A high-performance, secure MTProto proxy implementation based on [alexbers/mtprotoproxy](https://github.com/alexbers/mtprotoproxy) with enhanced Docker support and dynamic configuration.

## Features

- **High Performance**: Async implementation using uvloop for optimal performance
- **Security**: TLS obfuscation with domain camouflage (<www.cloudflare.com>)
- **Scalability**: Supports 4,000+ concurrent users
- **Anti-Censorship**: Advanced obfuscation techniques to bypass restrictions
- **Dynamic Configuration**: Auto-generated secrets, no hardcoded values
- **Singapore DC**: Optimized for Singapore Data Center 5 (91.108.56.130) by default
- **Lightweight**: Optimized Docker container with security hardening
- **Production Ready**: Battle-tested codebase with comprehensive health checks

## Quick Start

1. **Clone and deploy:**

   ```bash
   git clone <your-repo-url>
   cd mtprotoproxy
   ./deploy.sh
   ```

2. **Use the generated connection URLs** displayed after deployment

## Configuration

The proxy automatically generates secure configuration:

- **Port**: Auto-discovered (default: 8080)
- **Secrets**: Randomly generated 32-character hex strings
- **TLS Domain**: <www.cloudflare.com> (configurable)
- **Modes**: Secure + TLS enabled

### Environment Variables

- `MTPROTO_PORT`: Port number (default: 8080)
- `TLS_DOMAIN`: Domain for TLS camouflage (default: <www.cloudflare.com>)
- `USER1_SECRET`: First user secret (auto-generated if not set)
- `USER2_SECRET`: Second user secret (auto-generated if not set)
- `AD_TAG`: Optional advertising tag
- `FORCE_SINGAPORE_DC`: Force connections to Singapore Data Center 5 (default: true)

## Connection Formats

The proxy generates multiple connection URLs:

- **Secure Mode**: `tg://proxy?server=IP&port=PORT&secret=dd[SECRET]`
- **TLS Mode**: `tg://proxy?server=IP&port=PORT&secret=ee[SECRET][DOMAIN_HEX]`

## Testing

Run comprehensive tests:

```bash
python3 test.py
```

Tests include:

- Telegram datacenter connectivity (all 5 DCs)
- Proxy connection and handshake
- Container health monitoring
- Performance benchmarks

## Management Commands

```bash
# Deploy/redeploy
./deploy.sh

# View logs
docker-compose logs -f

# Stop proxy
docker-compose down

# Check status
docker-compose ps

# Run tests
python3 test.py
```

## Architecture

- **Base**: Ubuntu 24.04 LTS
- **Runtime**: Python 3 with uvloop
- **Security**: Non-root user, read-only filesystem, dropped capabilities
- **Networking**: Dynamic port mapping with health checks
- **Storage**: No persistent data, everything in memory

## Performance

- **Concurrent Users**: 4,000+
- **Connection Success Rate**: 100%
- **Memory Usage**: <256MB typical
- **CPU Usage**: <0.5 cores typical
- **Latency**: Minimal overhead

## Security Features

- TLS obfuscation with domain fronting
- Dynamic secret generation
- No persistent configuration files
- Container security hardening
- Network isolation
- Health monitoring

## Singapore Data Center Configuration

This proxy is specifically optimized for **Singapore Data Center 5** (`91.108.56.130`) to provide optimal performance for Asia-Pacific users.

### Configuration Details

- **Primary DC**: Singapore DC5 (91.108.56.130)
- **IPv6 Support**: 2001:b28:f23f:f005::a
- **Auto-forced**: Enabled by default (`FORCE_SINGAPORE_DC=true`)
- **Fallback**: Will use other DCs if Singapore is unavailable

### To disable Singapore forcing

Set `FORCE_SINGAPORE_DC=false` in your environment before deployment:

```bash
export FORCE_SINGAPORE_DC=false
./deploy.sh
```

## Troubleshooting

1. **Port conflicts**: The deployment script automatically finds available ports
2. **Connection issues**: Check firewall settings and ensure port is accessible
3. **Singapore DC issues**: Monitor logs for "Forcing connection to Singapore DC" messages
4. **Performance**: Monitor with `docker stats` and logs
5. **Updates**: Redeploy with `./deploy.sh` for latest configuration

## Requirements

- Docker and Docker Compose
- Port 8080+ available (auto-discovered)
- Internet connectivity for initial setup

## License

MIT - Licensed under the same terms as the original alexbers/mtprotoproxy project.
