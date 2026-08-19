# Matrix Home Server with Element X Call Functionality

This is a **complete Docker-based setup** for a Matrix home server with **full Element X call functionality**, including **LiveKit RTC backend** and **Matrix RTC bridge** for optimal voice/video calls and screen sharing.

## 🎯 **NEW: Complete RTC Stack**

✅ **LiveKit Server** - Professional RTC backend for Element Call  
✅ **Matrix RTC Bridge** - Connects Synapse to LiveKit for enhanced calling  
✅ **CoTurn TURN Server** - NAT traversal for WebRTC  
✅ **Full Element Call Support** - Voice, video, screen sharing  

## Features

### Core Components
- **Matrix Synapse Server**: Full-featured Matrix homeserver
- **Element X Web Client**: Modern Matrix client with full call support
- **PostgreSQL Database**: Reliable database for Synapse
- **Redis Cache**: High-performance caching for Synapse
- **Nginx Reverse Proxy**: Secure web server and reverse proxy

### RTC & Call Components
- **LiveKit Server**: Professional RTC backend (alternative to built-in WebRTC)
- **Matrix RTC Bridge**: Connects Synapse to LiveKit for enhanced calling
- **CoTurn TURN Server**: STUN/TURN server for WebRTC NAT traversal
- **Full Element Call Support**: Voice, video, and screen sharing

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/Einwegbecher/mtx.git
cd mtx

# Make setup script executable
chmod +x setup.sh

# Run interactive setup
./setup.sh --setup
```

The interactive setup will guide you through configuring:
- Domain names for Matrix and Element X
- Database credentials (PostgreSQL)
- Redis password
- Synapse shared secret (for RTC bridge)
- TURN server auth secret
- **LiveKit API keys** (for RTC backend)
- Admin user credentials
- SSL configuration

### 2. Configure DNS

Add DNS records for your domains:
- A record for `matrix.yourdomain.com` pointing to your server IP
- A record for `element.yourdomain.com` pointing to your server IP

### 3. SSL Certificates (Recommended)

For production, you should use SSL certificates. You can use Let's Encrypt:

```bash
# Install certbot
sudo apt-get install certbot

# Get certificates
sudo certbot certonly --standalone -d matrix.yourdomain.com -d element.yourdomain.com

# Copy certificates to nginx/ssl directory
sudo cp /etc/letsencrypt/live/matrix.yourdomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/matrix.yourdomain.com/privkey.pem nginx/ssl/

# Update .env file
SSL_ENABLED=true
SSL_CERT_PATH=/etc/nginx/ssl/fullchain.pem
SSL_KEY_PATH=/etc/nginx/ssl/privkey.pem
```

### 4. Open Firewall Ports

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Matrix federation
sudo ufw allow 8008/tcp

# Allow TURN server (UDP)
sudo ufw allow 3478/udp
sudo ufw allow 49152:65535/udp

# Allow LiveKit RTC (UDP)
sudo ufw allow 7882/udp

# Enable firewall
sudo ufw enable
```

### 5. Start Services

```bash
./setup.sh --start
```

### 6. Create Admin User

```bash
# Register admin user
docker exec -it matrix-synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  -u @admin:matrix.yourdomain.com \
  -p your_admin_password \
  -a
```

### 7. Access Element X

Open your browser and navigate to:
- `https://element.yourdomain.com` (if SSL enabled)
- `http://element.yourdomain.com` (if SSL not enabled)

## 🎵 RTC Configuration Options

### LiveKit vs Built-in WebRTC

This setup supports **both** RTC backends:

1. **LiveKit (Recommended)** - Professional RTC backend with better scalability
2. **Built-in WebRTC** - Native Matrix WebRTC implementation

### Configure RTC Backend in Element X

Edit `element/config/config.json`:

```json
{
  "call": {
    "rtc_backend": "livekit",  // or "matrix" for built-in
    "livekit": {
      "enabled": true,
      "server": "ws://yourdomain.com:7881",
      "key": "your_livekit_key",
      "secret": "your_livekit_secret"
    }
  }
}
```

### LiveKit Configuration

Edit `livekit/config/config.yaml`:

```yaml
# Server configuration
server:
  host: yourdomain.com
  port: 7880

# WebSocket configuration
websocket:
  host: yourdomain.com
  port: 7881

# RTC configuration
rtc:
  host: yourdomain.com
  port: 7882
  
  # TURN server configuration
  ice_servers:
    - urls: ["stun:yourdomain.com:3478"]
    - urls: ["turn:yourdomain.com:3478"]
      username: yourdomain.com
      credential: your_turn_auth_secret
      credential_type: password

# Authentication keys
keys:
  your_livekit_key: your_livekit_secret
```

## 📋 Configuration Files

### Environment Variables (.env)

```bash
# Domain Configuration
MATRIX_DOMAIN=matrix.yourdomain.com
ELEMENT_DOMAIN=element.yourdomain.com

# Database Configuration
POSTGRES_USER=synapse_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=synapse

# Synapse Configuration
SYNAPSE_SERVER_NAME=matrix.yourdomain.com
SYNAPSE_SHARED_SECRET=your_synapse_shared_secret

# Redis Configuration
REDIS_PASSWORD=your_redis_password

# TURN Server Configuration
TURN_AUTH_SECRET=your_turn_auth_secret

# LiveKit Configuration
LIVEKIT_KEY=your_livekit_key
LIVEKIT_SECRET=your_livekit_secret

# SSL Configuration
SSL_ENABLED=true
SSL_CERT_PATH=/nginx/ssl/fullchain.pem
SSL_KEY_PATH=/nginx/ssl/privkey.pem

# Resource Limits
SYNAPSE_MEMORY_LIMIT=2g
SYNAPSE_CPU_LIMIT=2.0
```

### Docker Services

The setup includes these Docker services:

1. **postgres** - PostgreSQL database for Synapse
2. **redis** - Redis cache for Synapse
3. **synapse** - Matrix Synapse server
4. **element-x** - Element X web client
5. **nginx** - Reverse proxy with SSL
6. **coturn** - TURN server for WebRTC
7. **livekit** - LiveKit RTC backend (NEW!)
8. **matrix-rtc** - Matrix RTC bridge (NEW!)

## 🔧 Management Commands

```bash
# Start all services
./setup.sh --start

# Stop all services
./setup.sh --stop

# Restart all services
./setup.sh --restart

# Stop and remove containers
./setup.sh --down

# Show logs for all services
./setup.sh --logs

# Show logs for specific service
./setup.sh --logs-synapse
./setup.sh --logs-element
./setup.sh --logs-nginx
./setup.sh --logs-livekit    # NEW!
./setup.sh --logs-rtc        # NEW!

# Update all containers
./setup.sh --update

# Create backup
./setup.sh --backup

# Restore from backup
./setup.sh --restore

# Edit configuration files
./setup.sh --config
```

## 🌐 Port Configuration

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| Nginx HTTP | 80 | TCP | Web traffic (HTTP) |
| Nginx HTTPS | 443 | TCP | Web traffic (HTTPS) |
| Synapse | 8008 | TCP | Matrix API |
| PostgreSQL | 5432 | TCP | Database |
| Redis | 6379 | TCP | Cache |
| Element X | 80 | TCP | Web client |
| CoTurn | 3478 | TCP/UDP | TURN server |
| CoTurn | 49152-65535 | UDP | TURN port range |
| LiveKit HTTP | 7880 | TCP | LiveKit API |
| LiveKit WS | 7881 | TCP | LiveKit WebSocket |
| LiveKit RTC | 7882 | TCP/UDP | LiveKit RTC |
| Matrix RTC | 8080 | TCP | Matrix RTC bridge |

## 🔒 Security Configuration

### Firewall Rules

```bash
# Basic web traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Matrix federation
sudo ufw allow 8008/tcp

# TURN server (UDP for WebRTC)
sudo ufw allow 3478/udp
sudo ufw allow 49152:65535/udp

# LiveKit RTC (UDP)
sudo ufw allow 7882/udp

# Enable firewall
sudo ufw enable
```

### SSL Configuration

Always use SSL in production. You can use:
- **Let's Encrypt** (recommended)
- Self-signed certificates (for testing)
- Commercial certificates

### Security Best Practices

1. **Regular Updates**: Keep all containers updated
2. **Strong Passwords**: Use strong passwords for all services
3. **Firewall**: Configure firewall properly
4. **SSL**: Always use SSL in production
5. **Backups**: Regularly backup your data
6. **Monitoring**: Monitor system resources and logs
7. **Access Control**: Restrict admin access
8. **Rate Limiting**: Configure rate limiting in Nginx

## 📊 Performance Optimization

### Synapse Performance

- Increase memory limits in `.env`:
  ```bash
  SYNAPSE_MEMORY_LIMIT=4g
  SYNAPSE_CPU_LIMIT=4.0
  ```

- Enable worker processes in `synapse/config/homeserver.yaml`:
  ```yaml
  workers:
    enabled: true
    number: 4
    listener_port_start: 8009
    listener_port_end: 8012
  ```

### LiveKit Performance

- Adjust LiveKit resource limits in `docker-compose.yml`:
  ```yaml
  livekit:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2.0'
  ```

### Database Optimization

- Configure PostgreSQL for better performance
- Use SSD storage for database
- Regularly vacuum and analyze database

## 🛠️ Troubleshooting

### Common Issues

1. **Connection refused to database**
   - Check if PostgreSQL container is running
   - Verify database credentials in `.env`
   - Check database logs: `docker-compose logs postgres`

2. **Synapse fails to start**
   - Check Synapse logs: `docker-compose logs synapse`
   - Verify configuration files
   - Check file permissions

3. **Element X not loading**
   - Check Nginx logs: `docker-compose logs nginx`
   - Verify domain configuration
   - Check SSL certificates

4. **Calls not working**
   - Verify TURN server is running: `docker-compose logs coturn`
   - Check LiveKit server: `docker-compose logs livekit`
   - Check Matrix RTC bridge: `docker-compose logs matrix-rtc`
   - Verify firewall allows UDP traffic (3478, 49152-65535, 7882)
   - Check browser console for WebRTC errors

5. **LiveKit connection issues**
   - Verify LiveKit API key and secret in `.env`
   - Check LiveKit configuration in `livekit/config/config.yaml`
   - Test LiveKit health: `curl http://localhost:7880/health`

### Debug Mode

Enable debug logging in Synapse:

```yaml
# In synapse/config/homeserver.yaml
log:
  level: DEBUG
```

Enable debug in LiveKit:

```yaml
# In livekit/config/config.yaml
logging:
  level: debug
```

### Test Services

```bash
# Test Synapse health
curl http://localhost:8008/health

# Test LiveKit health
curl http://localhost:7880/health

# Test Matrix RTC bridge health
curl http://localhost:8080/health

# Test database health
docker exec matrix-postgres pg_isready -U synapse_user -d synapse

# Test Redis health
docker exec matrix-redis redis-cli -a your_redis_password ping

# Test TURN server
docker exec matrix-coturn turnadmin -l
```

## 📚 RTC Architecture

### How Calls Work

1. **Element X Client** → **Synapse** (Matrix API)
2. **Synapse** → **Matrix RTC Bridge** (RTC signaling)
3. **Matrix RTC Bridge** → **LiveKit** (RTC backend)
4. **LiveKit** → **CoTurn** (TURN server for NAT traversal)
5. **Direct WebRTC** between clients (when possible)

### RTC Backend Options

| Backend | Pros | Cons | Recommended |
|---------|------|------|-------------|
| **LiveKit** | Professional, scalable, better call quality | More complex setup | ✅ Yes |
| **Built-in WebRTC** | Simpler, native Matrix | Less scalable, fewer features | ❌ No |

## 🔄 Migration & Updates

### Upgrade Containers

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --build
```

### Upgrade Specific Components

```bash
# Upgrade LiveKit
docker-compose pull livekit
docker-compose up -d livekit

# Upgrade Matrix RTC bridge
docker-compose pull matrix-rtc
docker-compose up -d matrix-rtc
```

## 📈 Monitoring

### Resource Monitoring

```bash
# View container resource usage
docker stats

# View system resource usage
top
htop
```

### Log Monitoring

```bash
# Follow all logs
docker-compose logs -f

# Follow specific service logs
docker-compose logs -f livekit
docker-compose logs -f matrix-rtc
```

### Health Checks

```bash
# Check all services
./setup.sh --logs

# Check LiveKit health
curl http://localhost:7880/health

# Check Matrix RTC bridge health
curl http://localhost:8080/health
```

## 🎓 Advanced Configuration

### LiveKit Configuration

For advanced LiveKit configuration, edit `livekit/config/config.yaml`:

```yaml
# Room configuration
room:
  max_participants: 50
  empty_timeout: 300
  max_idle_duration: 3600

# Webhook configuration
webhook:
  enabled: true
  url: "https://your-webhook-url.com"
  events:
    - room_created
    - room_ended
    - participant_joined
    - participant_left

# Recording configuration
recording:
  enabled: true
  directory: /data/recordings

# Redis for scaling
redis:
  enabled: true
  address: redis:6379
  password: ${REDIS_PASSWORD}
  db: 2
```

### Matrix RTC Bridge Configuration

The Matrix RTC bridge connects Synapse to LiveKit. Configure in `docker-compose.yml`:

```yaml
matrix-rtc:
  environment:
    SYNAPSE_SERVER: http://synapse:8008
    SYNAPSE_SHARED_SECRET: ${SYNAPSE_SHARED_SECRET}
    TURN_SERVER: turn:${MATRIX_DOMAIN}:3478
    TURN_SHARED_SECRET: ${TURN_AUTH_SECRET}
    LIVEKIT_SERVER: ws://livekit:7881
    LIVEKIT_KEY: ${LIVEKIT_KEY}
    LIVEKIT_SECRET: ${LIVEKIT_SECRET}
```

### Element X RTC Configuration

Configure RTC in `element/config/config.json`:

```json
{
  "call": {
    "enabled": true,
    "video_calls": true,
    "voice_calls": true,
    "screen_sharing": true,
    "rtc_backend": "livekit",
    "livekit": {
      "enabled": true,
      "server": "ws://${MATRIX_DOMAIN}:7881",
      "key": "${LIVEKIT_KEY}",
      "secret": "${LIVEKIT_SECRET}",
      "use_turn": true,
      "turn_server": "turn:${MATRIX_DOMAIN}:3478",
      "turn_username": "${MATRIX_DOMAIN}",
      "turn_password": "${TURN_AUTH_SECRET}"
    },
    "turn": {
      "enabled": true,
      "uris": ["turn:${MATRIX_DOMAIN}:3478"],
      "username": "${MATRIX_DOMAIN}",
      "password": "${TURN_AUTH_SECRET}",
      "ttl": 3600
    }
  },
  "rtc": {
    "enabled": true,
    "backend": "livekit",
    "livekit": {
      "server": "ws://${MATRIX_DOMAIN}:7881",
      "key": "${LIVEKIT_KEY}",
      "secret": "${LIVEKIT_SECRET}"
    }
  }
}
```

## 🌍 Federation

### Enable Federation

Edit `synapse/config/homeserver.yaml`:

```yaml
federation:
  enabled: true
  federation_domain_whitelist:
    - "matrix.org"
    - "yourdomain.com"
  federation_ip_range_whitelist:
    - "10.0.0.0/8"
    - "172.16.0.0/12"
    - "192.168.0.0/16"
```

### Test Federation

```bash
# Test federation with another server
docker exec -it matrix-synapse curl -X GET \
  "http://other-server:8008/_matrix/federation/v1/version"
```

## 📞 Call Quality Optimization

### For Best Call Quality

1. **Use LiveKit backend** (better than built-in WebRTC)
2. **Configure proper TURN server** with sufficient port range
3. **Open UDP ports** in firewall (3478, 49152-65535, 7882)
4. **Use wired network** instead of WiFi when possible
5. **Ensure sufficient bandwidth** (1Mbps+ for HD video)
6. **Configure QoS** on your network for WebRTC traffic
7. **Use headphones** for better audio quality

### Bandwidth Requirements

| Call Type | Bandwidth (per participant) |
|-----------|----------------------------|
| Voice Call | 50-100 Kbps |
| SD Video (360p) | 300-500 Kbps |
| HD Video (720p) | 1-2 Mbps |
| Full HD Video (1080p) | 2-4 Mbps |
| Screen Sharing | 1-3 Mbps |

## 🔧 Customization

### Branding

Edit `element/config/config.json`:

```json
{
  "brand": "Your Brand Name",
  "branding": {
    "welcomeBackgroundUrl": "https://yourdomain.com/welcome-background.jpg",
    "authHeaderLogoUrl": "https://yourdomain.com/logo.png"
  }
}
```

### Themes

Element X supports light and dark themes:

```json
{
  "default_theme": "dark"
}
```

### Features

Enable/disable features in `element/config/config.json`:

```json
{
  "features": {
    "feature_voice_and_video": true,
    "feature_screen_sharing": true,
    "feature_knocking": true,
    "feature_poll": true,
    "feature_thread": true,
    "feature_rich_text_editor": true
  }
}
```

## 📊 Scaling

### Vertical Scaling

Increase resource limits in `.env`:

```bash
SYNAPSE_MEMORY_LIMIT=4g
SYNAPSE_CPU_LIMIT=4.0
```

### Horizontal Scaling

For large deployments, consider:
- Multiple Synapse workers
- Separate media repository
- Load balancing with multiple Nginx instances
- Database replication
- Multiple LiveKit instances for load balancing

### Worker Configuration

Edit `synapse/config/homeserver.yaml`:

```yaml
workers:
  enabled: true
  number: 4
  listener_port_start: 8009
  listener_port_end: 8012
  media:
    enabled: true
    number: 2
```

## 🎯 Summary

This setup provides **everything you need** for a fully functional Matrix home server with **complete Element X call functionality**:

✅ **Matrix Synapse Server** - Full-featured homeserver  
✅ **Element X Web Client** - Modern client with call support  
✅ **LiveKit RTC Backend** - Professional RTC for better calls  
✅ **Matrix RTC Bridge** - Connects Synapse to LiveKit  
✅ **CoTurn TURN Server** - NAT traversal for WebRTC  
✅ **PostgreSQL Database** - Optimized for Synapse  
✅ **Redis Cache** - High-performance caching  
✅ **Nginx Reverse Proxy** - Secure web server with SSL  
✅ **Interactive Setup** - Easy configuration  
✅ **Comprehensive Documentation** - Complete guide  

**🎉 You now have a production-ready Matrix server with the best possible call functionality!**

---

## 📖 Additional Resources

- **Matrix.org**: [https://matrix.org](https://matrix.org)
- **Element.io**: [https://element.io](https://element.io)
- **LiveKit**: [https://livekit.io](https://livekit.io)
- **Synapse Documentation**: [https://matrix-org.github.io/synapse/latest](https://matrix-org.github.io/synapse/latest)
- **Element X Documentation**: [https://github.com/vector-im/element-x](https://github.com/vector-im/element-x)
- **LiveKit Documentation**: [https://docs.livekit.io](https://docs.livekit.io)

## 📝 Changelog

### Version 2.0.0
- **Added LiveKit RTC backend** for professional call quality
- **Added Matrix RTC bridge** to connect Synapse to LiveKit
- **Enhanced Nginx configuration** with LiveKit and Matrix RTC support
- **Updated Element X configuration** with RTC backend options
- **Updated Synapse configuration** with RTC support
- **Added comprehensive RTC documentation**
- **Added firewall rules** for LiveKit and RTC
- **Added performance optimization** for RTC components

### Version 1.0.0
- Initial release with full Matrix server setup
- Element X with call functionality
- Complete Docker Compose configuration
- Setup script for easy deployment
- Comprehensive documentation

---

**Note**: This setup is designed for production use but should be thoroughly tested in a staging environment before deploying to production. Always ensure you have proper backups and monitoring in place.