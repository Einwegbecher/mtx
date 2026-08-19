#!/bin/bash

# Matrix Server Setup Script with LiveKit and Matrix RTC
# This script helps you set up and configure your Matrix home server with Element X
# including LiveKit RTC backend and Matrix RTC bridge

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root. Run it as a regular user.${NC}"
    exit 1
fi

# Function to display help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --setup           Setup the Matrix server (interactive)"
    echo "  --start           Start all services"
    echo "  --stop            Stop all services"
    echo "  --restart         Restart all services"
    echo "  --down            Stop and remove containers"
    echo "  --logs            Show logs for all services"
    echo "  --logs-synapse    Show Synapse logs"
    echo "  --logs-element    Show Element X logs"
    echo "  --logs-nginx      Show Nginx logs"
    echo "  --logs-livekit    Show LiveKit logs"
    echo "  --logs-rtc        Show Matrix RTC logs"
    echo "  --update          Update all containers"
    echo "  --backup          Create backup of databases"
    echo "  --restore         Restore from backup"
    echo "  --config          Edit configuration files"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --setup       # Interactive setup"
    echo "  $0 --start       # Start all services"
    echo "  $0 --logs        # Show all logs"
}

# Function to check dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    # Check for docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    # Check for docker-compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing_deps[*]}${NC}"
        echo "Please install them before continuing."
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies are installed.${NC}"
}

# Function for interactive setup
interactive_setup() {
    echo -e "${BLUE}Matrix Server Interactive Setup with LiveKit RTC${NC}"
    echo "======================================================"
    echo ""
    
    # Get domain information
    read -p "Enter your domain for Matrix server (e.g., matrix.yourdomain.com): " MATRIX_DOMAIN
    read -p "Enter your domain for Element X (e.g., element.yourdomain.com): " ELEMENT_DOMAIN
    
    # Database configuration
    read -p "Enter PostgreSQL username [synapse_user]: " POSTGRES_USER
    POSTGRES_USER=${POSTGRES_USER:-synapse_user}
    
    read -p "Enter PostgreSQL password: " -s POSTGRES_PASSWORD
    echo ""
    read -p "Confirm PostgreSQL password: " -s POSTGRES_PASSWORD_CONFIRM
    echo ""
    
    if [ "$POSTGRES_PASSWORD" != "$POSTGRES_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match. Please try again.${NC}"
        exit 1
    fi
    
    read -p "Enter PostgreSQL database name [synapse]: " POSTGRES_DB
    POSTGRES_DB=${POSTGRES_DB:-synapse}
    
    # Redis configuration
    read -p "Enter Redis password: " -s REDIS_PASSWORD
    echo ""
    read -p "Confirm Redis password: " -s REDIS_PASSWORD_CONFIRM
    echo ""
    
    if [ "$REDIS_PASSWORD" != "$REDIS_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match. Please try again.${NC}"
        exit 1
    fi
    
    # Synapse shared secret
    read -p "Enter Synapse shared secret (for RTC bridge): " -s SYNAPSE_SHARED_SECRET
    echo ""
    read -p "Confirm Synapse shared secret: " -s SYNAPSE_SHARED_SECRET_CONFIRM
    echo ""
    
    if [ "$SYNAPSE_SHARED_SECRET" != "$SYNAPSE_SHARED_SECRET_CONFIRM" ]; then
        echo -e "${RED}Secrets do not match. Please try again.${NC}"
        exit 1
    fi
    
    # TURN server configuration
    read -p "Enter TURN server auth secret: " -s TURN_AUTH_SECRET
    echo ""
    read -p "Confirm TURN server auth secret: " -s TURN_AUTH_SECRET_CONFIRM
    echo ""
    
    if [ "$TURN_AUTH_SECRET" != "$TURN_AUTH_SECRET_CONFIRM" ]; then
        echo -e "${RED}Secrets do not match. Please try again.${NC}"
        exit 1
    fi
    
    # LiveKit configuration
    read -p "Enter LiveKit API key: " LIVEKIT_KEY
    read -p "Enter LiveKit API secret: " -s LIVEKIT_SECRET
    echo ""
    read -p "Confirm LiveKit API secret: " -s LIVEKIT_SECRET_CONFIRM
    echo ""
    
    if [ "$LIVEKIT_SECRET" != "$LIVEKIT_SECRET_CONFIRM" ]; then
        echo -e "${RED}Secrets do not match. Please try again.${NC}"
        exit 1
    fi
    
    # Admin user
    read -p "Enter admin username: " ADMIN_USER
    read -p "Enter admin password: " -s ADMIN_PASSWORD
    echo ""
    read -p "Confirm admin password: " -s ADMIN_PASSWORD_CONFIRM
    echo ""
    
    if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match. Please try again.${NC}"
        exit 1
    fi
    
    read -p "Enter admin email: " ADMIN_EMAIL
    
    # SSL configuration
    read -p "Do you have SSL certificates? (y/n) [n]: " SSL_ANSWER
    SSL_ENABLED=${SSL_ANSWER:-n}
    
    if [ "$SSL_ENABLED" = "y" ] || [ "$SSL_ENABLED" = "Y" ]; then
        SSL_ENABLED=true
        read -p "Enter path to SSL certificate (fullchain.pem): " SSL_CERT_PATH
        read -p "Enter path to SSL key (privkey.pem): " SSL_KEY_PATH
    else
        SSL_ENABLED=false
        SSL_CERT_PATH=""
        SSL_KEY_PATH=""
    fi
    
    # Create .env file
    create_env_file
    
    # Update configuration files
    update_config_files
    
    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo ""
    echo "You can now start the services with: $0 --start"
    echo ""
    echo "Your Matrix server now includes:"
    echo "  ✓ Synapse Matrix Server"
    echo "  ✓ Element X Web Client"
    echo "  ✓ LiveKit RTC Backend"
    echo "  ✓ Matrix RTC Bridge"
    echo "  ✓ CoTurn TURN Server"
    echo "  ✓ PostgreSQL Database"
    echo "  ✓ Redis Cache"
    echo "  ✓ Nginx Reverse Proxy"
}

# Function to create .env file
create_env_file() {
    echo -e "${BLUE}Creating .env file...${NC}"
    
    cat > .env << EOF
# Matrix Server Configuration
MATRIX_DOMAIN=${MATRIX_DOMAIN}
ELEMENT_DOMAIN=${ELEMENT_DOMAIN}

# Database Configuration
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}

# Synapse Configuration
SYNAPSE_SERVER_NAME=${MATRIX_DOMAIN}
SYNAPSE_CONFIG_PATH=/data/homeserver.yaml
SYNAPSE_REPORT_STATS=no
SYNAPSE_SHARED_SECRET=${SYNAPSE_SHARED_SECRET}

# Element X Configuration
ELEMENT_X_SERVER=https://${MATRIX_DOMAIN}
ELEMENT_X_BASE_URL=https://${ELEMENT_DOMAIN}

# Redis Configuration
REDIS_PASSWORD=${REDIS_PASSWORD}

# TURN Server Configuration
TURN_AUTH_SECRET=${TURN_AUTH_SECRET}

# LiveKit Configuration (Alternative RTC backend)
LIVEKIT_KEY=${LIVEKIT_KEY}
LIVEKIT_SECRET=${LIVEKIT_SECRET}

# SSL Configuration
SSL_ENABLED=${SSL_ENABLED}
SSL_CERT_PATH=${SSL_CERT_PATH}
SSL_KEY_PATH=${SSL_KEY_PATH}

# Admin User
ADMIN_USER=${ADMIN_USER}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ADMIN_EMAIL=${ADMIN_EMAIL}

# Ports
SYNAPSE_PORT=8008
POSTGRES_PORT=5432
REDIS_PORT=6379
ELEMENT_X_PORT=80
NGINX_PORT=80
NGINX_SSL_PORT=443
LIVEKIT_HTTP_PORT=7880
LIVEKIT_WS_PORT=7881
LIVEKIT_RTC_PORT=7882
MATRIX_RTC_PORT=8080

# Docker Network
DOCKER_NETWORK=matrix-network

# Resource Limits
SYNAPSE_MEMORY_LIMIT=2g
SYNAPSE_CPU_LIMIT=2.0
EOF
    
    echo -e "${GREEN}.env file created.${NC}"
}

# Function to update configuration files
update_config_files() {
    echo -e "${BLUE}Updating configuration files...${NC}"
    
    # Update Synapse configuration
    sed -i "s/matrix.yourdomain.com/${MATRIX_DOMAIN}/g" synapse/config/homeserver.yaml
    sed -i "s/element.yourdomain.com/${ELEMENT_DOMAIN}/g" synapse/config/homeserver.yaml
    sed -i "s/your_secure_password_here/${POSTGRES_PASSWORD}/g" synapse/config/homeserver.yaml
    sed -i "s/your_redis_password_here/${REDIS_PASSWORD}/g" synapse/config/homeserver.yaml
    sed -i "s/your_turn_auth_secret_here/${TURN_AUTH_SECRET}/g" synapse/config/homeserver.yaml
    sed -i "s/your_synapse_shared_secret_here/${SYNAPSE_SHARED_SECRET}/g" synapse/config/homeserver.yaml
    sed -i "s/your_livekit_key_here/${LIVEKIT_KEY}/g" synapse/config/homeserver.yaml
    sed -i "s/your_livekit_secret_here/${LIVEKIT_SECRET}/g" synapse/config/homeserver.yaml
    sed -i "s/@admin:matrix.yourdomain.com/@${ADMIN_USER}:${MATRIX_DOMAIN}/g" synapse/config/homeserver.yaml
    
    # Update Element X configuration
    sed -i "s/matrix.yourdomain.com/${MATRIX_DOMAIN}/g" element/config/config.json
    sed -i "s/element.yourdomain.com/${ELEMENT_DOMAIN}/g" element/config/config.json
    sed -i "s/your_turn_auth_secret_here/${TURN_AUTH_SECRET}/g" element/config/config.json
    sed -i "s/your_livekit_key_here/${LIVEKIT_KEY}/g" element/config/config.json
    sed -i "s/your_livekit_secret_here/${LIVEKIT_SECRET}/g" element/config/config.json
    
    # Update Nginx configuration
    sed -i "s/matrix.yourdomain.com/${MATRIX_DOMAIN}/g" nginx/conf.d/matrix.conf
    sed -i "s/element.yourdomain.com/${ELEMENT_DOMAIN}/g" nginx/conf.d/matrix.conf
    
    # Update CoTurn configuration
    sed -i "s/matrix.yourdomain.com/${MATRIX_DOMAIN}/g" coturn/config/turnserver.conf
    sed -i "s/your_turn_auth_secret_here/${TURN_AUTH_SECRET}/g" coturn/config/turnserver.conf
    
    # Update LiveKit configuration
    sed -i "s/matrix.yourdomain.com/${MATRIX_DOMAIN}/g" livekit/config/config.yaml
    sed -i "s/your_turn_auth_secret_here/${TURN_AUTH_SECRET}/g" livekit/config/config.yaml
    sed -i "s/your_livekit_key_here/${LIVEKIT_KEY}/g" livekit/config/config.yaml
    sed -i "s/your_livekit_secret_here/${LIVEKIT_SECRET}/g" livekit/config/config.yaml
    
    echo -e "${GREEN}Configuration files updated.${NC}"
}

# Function to start services
start_services() {
    echo -e "${BLUE}Starting Matrix services...${NC}"
    docker-compose up -d
    echo -e "${GREEN}Services started.${NC}"
    echo ""
    echo "You can access:"
    echo "  - Element X: http://${ELEMENT_DOMAIN}"
    echo "  - Synapse Admin API: http://${MATRIX_DOMAIN}:8008"
    echo "  - LiveKit Dashboard: http://${MATRIX_DOMAIN}:7880"
    echo "  - Matrix RTC Bridge: http://${MATRIX_DOMAIN}:8080"
    echo ""
    echo "To check the status: $0 --logs"
}

# Function to stop services
stop_services() {
    echo -e "${BLUE}Stopping Matrix services...${NC}"
    docker-compose down
    echo -e "${GREEN}Services stopped.${NC}"
}

# Function to restart services
restart_services() {
    echo -e "${BLUE}Restarting Matrix services...${NC}"
    docker-compose restart
    echo -e "${GREEN}Services restarted.${NC}"
}

# Function to show logs
show_logs() {
    local service="$1"
    
    if [ -z "$service" ]; then
        echo -e "${BLUE}Showing logs for all services...${NC}"
        docker-compose logs -f
    else
        echo -e "${BLUE}Showing logs for ${service}...${NC}"
        docker-compose logs -f "$service"
    fi
}

# Function to update containers
update_containers() {
    echo -e "${BLUE}Updating Matrix containers...${NC}"
    docker-compose pull
    docker-compose up -d --build
    echo -e "${GREEN}Containers updated.${NC}"
}

# Function to create backup
create_backup() {
    echo -e "${BLUE}Creating backup...${NC}"
    
    local backup_dir="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup databases
    docker exec matrix-postgres pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB} > "${backup_dir}/postgres_backup.sql"
    
    # Backup configuration files
    cp -r .env config/ synapse/config/ element/config/ nginx/conf.d/ coturn/config/ livekit/config/ "$backup_dir/"
    
    # Create tar archive
    tar -czvf "${backup_dir}.tar.gz" "$backup_dir"
    
    # Remove temporary directory
    rm -rf "$backup_dir"
    
    echo -e "${GREEN}Backup created: ${backup_dir}.tar.gz${NC}"
}

# Function to restore from backup
restore_backup() {
    echo -e "${BLUE}Restoring from backup...${NC}"
    
    # List available backups
    echo "Available backups:"
    ls -la backups/*.tar.gz 2>/dev/null || echo "No backups found."
    
    read -p "Enter backup filename to restore: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup file not found.${NC}"
        exit 1
    fi
    
    # Extract backup
    local temp_dir="./backup_temp"
    mkdir -p "$temp_dir"
    tar -xzvf "$backup_file" -C "$temp_dir"
    
    # Stop services
    docker-compose down
    
    # Restore databases
    docker exec matrix-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < "${temp_dir}/$(basename $backup_file .tar.gz)/postgres_backup.sql"
    
    # Restore configuration files
    cp -r "${temp_dir}/$(basename $backup_file .tar.gz)/"* ./
    
    # Remove temporary directory
    rm -rf "$temp_dir"
    
    # Start services
    docker-compose up -d
    
    echo -e "${GREEN}Backup restored successfully.${NC}"
}

# Function to edit configuration
edit_config() {
    echo -e "${BLUE}Configuration Editor${NC}"
    echo "======================"
    echo ""
    echo "Available configuration files:"
    echo "  1. .env - Environment variables"
    echo "  2. synapse/config/homeserver.yaml - Synapse configuration"
    echo "  3. element/config/config.json - Element X configuration"
    echo "  4. nginx/conf.d/matrix.conf - Nginx configuration"
    echo "  5. coturn/config/turnserver.conf - TURN server configuration"
    echo "  6. livekit/config/config.yaml - LiveKit configuration"
    echo ""
    
    read -p "Select file to edit (1-6): " choice
    
    case $choice in
        1) nano .env ;;
        2) nano synapse/config/homeserver.yaml ;;
        3) nano element/config/config.json ;;
        4) nano nginx/conf.d/matrix.conf ;;
        5) nano coturn/config/turnserver.conf ;;
        6) nano livekit/config/config.yaml ;;
        *) echo -e "${RED}Invalid choice.${NC}" ;;
    esac
}

# Main script logic
case "$1" in
    --setup)
        check_dependencies
        interactive_setup
        ;;
    --start)
        check_dependencies
        start_services
        ;;
    --stop)
        stop_services
        ;;
    --restart)
        restart_services
        ;;
    --down)
        docker-compose down -v
        ;;
    --logs)
        show_logs
        ;;
    --logs-synapse)
        show_logs synapse
        ;;
    --logs-element)
        show_logs element-x
        ;;
    --logs-nginx)
        show_logs nginx
        ;;
    --logs-livekit)
        show_logs livekit
        ;;
    --logs-rtc)
        show_logs matrix-rtc
        ;;
    --update)
        update_containers
        ;;
    --backup)
        create_backup
        ;;
    --restore)
        restore_backup
        ;;
    --config)
        edit_config
        ;;
    --help|-h|--?)
        show_help
        ;;
    *)
        show_help
        ;;
esac