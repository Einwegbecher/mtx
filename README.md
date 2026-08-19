# Matrix Home Server with Element X Call Functionality

This is a complete Docker-based setup for a Matrix home server with full Element X call functionality, including voice/video calls and screen sharing.

## Features

- **Matrix Synapse Server**: Full-featured Matrix homeserver
- **Element X Web Client**: Modern Matrix client with full call support
- **PostgreSQL Database**: Reliable database for Synapse
- **Redis Cache**: High-performance caching for Synapse
- **Nginx Reverse Proxy**: Secure web server and reverse proxy
- **CoTurn TURN Server**: STUN/TURN server for WebRTC calls
- **Full Element Call Support**: Voice, video, and screen sharing

## Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Git
- curl
- At least 4GB RAM (8GB recommended for production)
- At least 2 CPU cores
- Domain name with DNS configured

## Quick Start

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

### 4. Start Services

```bash
./setup.sh --start
```

### 5. Create Admin User

```bash
# Register admin user
docker exec -it matrix-synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  -u @admin:matrix.yourdomain.com \
  -p your_admin_password \
  -a
```

### 6. Access Element X

Open your browser and navigate to:
- `https://element.yourdomain.com` (if SSL enabled)
- `http://element.yourdomain.com` (if SSL not enabled)

## Configuration

### Environment Variables

Edit the `.env` file to configure your setup:

```bash
# Domain Configuration
MATRIX_DOMAIN=matrix.yourdomain.com
ELEMENT_DOMAIN=element.yourdomain.com

# Database Configuration
POSTGRES_USER=synapse_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=synapse

# Redis Configuration
REDIS_PASSWORD=your_redis_password

# Admin User
ADMIN_USER=admin
ADMIN_PASSWORD=admin_password
ADMIN_EMAIL=admin@yourdomain.com

# SSL Configuration
SSL_ENABLED=true
SSL_CERT_PATH=/nginx/ssl/fullchain.pem
SSL_KEY_PATH=/nginx/ssl/privkey.pem

# Resource Limits
SYNAPSE_MEMORY_LIMIT=2g
SYNAPSE_CPU_LIMIT=2.0
```

### Synapse Configuration

Edit `synapse/config/homeserver.yaml` for advanced Synapse settings.

### Element X Configuration

Edit `element/config/config.json` for Element X settings.

### Nginx Configuration

Edit `nginx/conf.d/matrix.conf` for web server settings.

### TURN Server Configuration

Edit `coturn/config/turnserver.conf` for TURN server settings.

## Management Commands

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

# Update all containers
./setup.sh --update

# Create backup
./setup.sh --backup

# Restore from backup
./setup.sh --restore

# Edit configuration files
./setup.sh --config
```

## Docker Commands

```bash
# View running containers
docker-compose ps

# View container logs
docker-compose logs -f

# View specific container logs
docker-compose logs -f synapse
docker-compose logs -f element-x
docker-compose logs -f nginx

# Execute command in container
docker exec -it matrix-synapse bash
docker exec -it matrix-postgres psql -U synapse_user -d synapse

# View resource usage
docker stats
```

## Security Considerations

### Firewall Rules

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Matrix federation
sudo ufw allow 8008/tcp

# Allow TURN server (UDP)
sudo ufw allow 3478/udp
sudo ufw allow 49152:65535/udp

# Enable firewall
sudo ufw enable
```

### SSL Configuration

Always use SSL in production. You can use:
- Let's Encrypt (recommended)
- Self-signed certificates (for testing)
- Commercial certificates

### Database Security

- Use strong passwords for PostgreSQL and Redis
- Regularly back up your database
- Consider using database encryption

### TURN Server Security

- Use strong auth secrets
- Configure proper IP filtering
- Monitor TURN server usage

## Performance Optimization

### Synapse Performance

- Increase memory limits in `.env`:
  ```
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

### Database Optimization

- Configure PostgreSQL for better performance
- Use SSD storage for database
- Regularly vacuum and analyze database

### Caching

- Redis is already configured for caching
- Adjust cache sizes based on your usage

## Troubleshooting

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
   - Verify TURN server is running
   - Check TURN server configuration
   - Verify firewall allows UDP traffic
   - Check browser console for WebRTC errors

### Debug Mode

Enable debug logging in Synapse:

```yaml
# In synapse/config/homeserver.yaml
log:
  level: DEBUG
```

### Test Federation

```bash
# Test federation with matrix.org
docker exec -it matrix-synapse curl -X GET \
  "http://matrix.org:8008/_matrix/federation/v1/version"
```

## Backup and Restore

### Manual Backup

```bash
# Backup PostgreSQL database
docker exec matrix-postgres pg_dump -U synapse_user -d synapse > backup.sql

# Backup configuration files
cp -r .env config/ synapse/config/ element/config/ nginx/conf.d/ coturn/config/ backup_config/

# Create tar archive
tar -czvf matrix_backup_$(date +%Y%m%d).tar.gz backup.sql backup_config/
```

### Manual Restore

```bash
# Stop services
docker-compose down

# Restore database
docker exec matrix-postgres psql -U synapse_user -d synapse < backup.sql

# Restore configuration files
cp -r backup_config/* ./

# Start services
docker-compose up -d
```

## Upgrading

### Upgrade Containers

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --build
```

### Upgrade Synapse

```bash
# Backup current configuration
cp synapse/config/homeserver.yaml synapse/config/homeserver.yaml.bak

# Pull latest Synapse image
docker-compose pull synapse

# Recreate Synapse container
docker-compose up -d synapse

# Check for configuration changes
# Compare old and new configuration files
```

## Monitoring

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
docker-compose logs -f synapse
```

### Health Checks

```bash
# Check Synapse health
curl http://localhost:8008/health

# Check database health
docker exec matrix-postgres pg_isready -U synapse_user -d synapse

# Check Redis health
docker exec matrix-redis redis-cli -a your_redis_password ping
```

## Federation

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

### Federation Troubleshooting

- Check firewall allows port 8008
- Verify DNS records are correct
- Check SSL certificates are valid
- Verify federation is enabled in configuration

## Element Call Configuration

### TURN Server Configuration

For optimal call quality, configure TURN server properly:

1. **Public IP**: Ensure `external-ip` in `coturn/config/turnserver.conf` is your public IP
2. **Port Range**: Configure proper port range (49152-65535 recommended)
3. **Auth Secret**: Use strong auth secret and keep it secure
4. **Firewall**: Open UDP ports 3478 and 49152-65535

### Element X Call Settings

Edit `element/config/config.json`:

```json
{
  "call": {
    "enabled": true,
    "video_calls": true,
    "voice_calls": true,
    "screen_sharing": true,
    "turn": {
      "enabled": true,
      "uris": ["turn:matrix.yourdomain.com:3478"],
      "username": "matrix.yourdomain.com",
      "password": "your_turn_auth_secret",
      "ttl": 3600
    }
  }
}
```

### Call Quality Optimization

- Use wired network connection for better quality
- Ensure sufficient bandwidth (at least 1Mbps for HD video)
- Configure QoS on your network
- Use headphones for better audio quality

## Customization

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

## Scaling

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

## Migration

### Migrate from Existing Synapse

1. Backup your existing Synapse database
2. Copy configuration files
3. Update `homeserver.yaml` with new settings
4. Start new containers
5. Verify data integrity

### Migrate from Other Matrix Servers

1. Export data from old server
2. Import data into PostgreSQL
3. Configure Synapse with existing data
4. Start services

## Security Best Practices

1. **Regular Updates**: Keep all containers updated
2. **Strong Passwords**: Use strong passwords for all services
3. **Firewall**: Configure firewall properly
4. **SSL**: Always use SSL in production
5. **Backups**: Regularly backup your data
6. **Monitoring**: Monitor system resources and logs
7. **Access Control**: Restrict admin access
8. **Rate Limiting**: Configure rate limiting in Nginx

## Performance Tuning

### Synapse Tuning

```yaml
# In synapse/config/homeserver.yaml
performance:
  max_concurrent_requests: 200
  max_concurrent_federation_requests: 100
  max_concurrent_media_requests: 100

caches:
  global:
    enabled: true
    backend: redis
    redis:
      host: redis
      port: 6379
      password: your_redis_password
      db: 1
```

### Database Tuning

Configure PostgreSQL for better performance:

```yaml
# In docker-compose.yml for postgres
environment:
  POSTGRES_USER: synapse_user
  POSTGRES_PASSWORD: your_password
  POSTGRES_DB: synapse
  POSTGRES_INITDB_ARGS: --encoding=UTF8 --data-checksums
  PGDATA: /var/lib/postgresql/data/pgdata
command: >
  postgres -c shared_buffers=1GB \
           -c effective_cache_size=3GB \
           -c maintenance_work_mem=256MB \
           -c work_mem=16MB \
           -c random_page_cost=1.1 \
           -c max_connections=200
```

## API Access

### Synapse Admin API

```bash
# List all users
curl -X GET \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  "http://localhost:8008/_synapse/admin/v2/users"

# Get user information
curl -X GET \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  "http://localhost:8008/_synapse/admin/v2/users/@user:domain.com"
```

### Element X API

Element X provides various APIs for integration and customization.

## Community and Support

- **Matrix.org**: [https://matrix.org](https://matrix.org)
- **Element.io**: [https://element.io](https://element.io)
- **Synapse Documentation**: [https://matrix-org.github.io/synapse/latest](https://matrix-org.github.io/synapse/latest)
- **Element X Documentation**: [https://github.com/vector-im/element-x](https://github.com/vector-im/element-x)

## License

This setup uses the following open-source software:
- Synapse: Apache License 2.0
- Element X: Apache License 2.0
- PostgreSQL: PostgreSQL License
- Redis: BSD License
- Nginx: BSD License
- CoTurn: BSD License

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Changelog

### Version 1.0.0
- Initial release with full Matrix server setup
- Element X with call functionality
- Complete Docker Compose configuration
- Setup script for easy deployment
- Comprehensive documentation

---

**Note**: This setup is designed for production use but should be thoroughly tested in a staging environment before deploying to production. Always ensure you have proper backups and monitoring in place.