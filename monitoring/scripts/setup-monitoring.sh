#!/bin/bash
# ==============================================================================
# DevOps Monitoring Solution - Automated Setup Script (Module 8 Assignment)
#
# This script automates the installation and configuration of:
#   - Prometheus (Metrics collection)
#   - Node Exporter (System metrics exporter)
#   - Loki (Log aggregation)
#   - Promtail (Log shipper)
#   - Grafana (Visualization UI)
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Versions
PROMETHEUS_VERSION="2.48.0"
NODE_EXPORTER_VERSION="1.7.0"
LOKI_VERSION="2.9.3"
PROMTAIL_VERSION="2.9.3"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/monitoring"

log_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root or with sudo."
    exit 1
fi

log_header "Step 1: System Package Update"
log_info "Updating system package index..."
apt-get update -qq
log_info "Installing required utility packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget curl unzip tar jq software-properties-common apt-transport-https ca-certificates ufw
log_success "Prerequisites installed successfully."

log_header "Step 2: Configuring Security Group & Firewall"
log_info "Enabling UFW and configuring port accessibility..."
ufw --force enable
ufw allow 22/tcp comment 'SSH'
ufw allow 3001/tcp comment 'Grafana'
ufw allow 9090/tcp comment 'Prometheus'
ufw allow 3100/tcp comment 'Loki'
ufw reload
log_success "Firewall (UFW) updated successfully."

log_header "Step 3: Installing Prometheus v${PROMETHEUS_VERSION}"
if systemctl is-active --quiet prometheus 2>/dev/null; then
    log_info "Prometheus service is already running. Stopping it for setup..."
    systemctl stop prometheus
fi

useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
mkdir -p /etc/prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cd /tmp
log_info "Downloading Prometheus package..."
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

cp -f prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
cp -rf consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus/consoles /etc/prometheus/console_libraries

# Copy config file
if [ -f "$CONFIG_DIR/prometheus/prometheus.yml" ]; then
    cp -f "$CONFIG_DIR/prometheus/prometheus.yml" /etc/prometheus/prometheus.yml
else
    log_warning "Local prometheus.yml config not found, creating a default one..."
    cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF
fi
chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create Systemd Unit
cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --storage.tsdb.retention.time=15d \
  --web.enable-lifecycle

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
log_success "Prometheus installed and started successfully."

log_header "Step 4: Installing Node Exporter v${NODE_EXPORTER_VERSION}"
if systemctl is-active --quiet node_exporter 2>/dev/null; then
    log_info "Node Exporter service is already running. Stopping it for setup..."
    systemctl stop node_exporter
fi

useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
cd /tmp
log_info "Downloading Node Exporter package..."
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp -f node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Systemd Unit
cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
log_success "Node Exporter installed and started successfully."

log_header "Step 5: Installing Loki v${LOKI_VERSION}"
if systemctl is-active --quiet loki 2>/dev/null; then
    log_info "Loki service is already running. Stopping it for setup..."
    systemctl stop loki
fi

useradd --no-create-home --shell /bin/false loki 2>/dev/null || true
mkdir -p /etc/loki /var/lib/loki
chown -R loki:loki /etc/loki /var/lib/loki

cd /tmp
log_info "Downloading Loki binary..."
wget -q https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
unzip -o -q loki-linux-amd64.zip
mv -f loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki
chown loki:loki /usr/local/bin/loki

# Copy config file
if [ -f "$CONFIG_DIR/loki/loki-config.yml" ]; then
    cp -f "$CONFIG_DIR/loki/loki-config.yml" /etc/loki/loki-config.yml
else
    log_warning "Local loki-config.yml not found, creating default..."
    cat > /etc/loki/loki-config.yml <<EOF
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF
fi
chown loki:loki /etc/loki/loki-config.yml

# Create Systemd Unit
cat > /etc/systemd/system/loki.service <<'EOF'
[Unit]
Description=Loki Log Aggregation System
After=network.target

[Service]
Type=simple
User=loki
Group=loki
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable loki
systemctl start loki
log_success "Loki installed and started successfully."

log_header "Step 6: Installing Promtail v${PROMTAIL_VERSION}"
if systemctl is-active --quiet promtail 2>/dev/null; then
    log_info "Promtail service is already running. Stopping it for setup..."
    systemctl stop promtail
fi

useradd --no-create-home --shell /bin/false promtail 2>/dev/null || true
mkdir -p /etc/promtail /var/lib/promtail
chown -R promtail:promtail /etc/promtail /var/lib/promtail

# Allow promtail to read system logs
usermod -aG adm promtail || true
usermod -aG systemd-journal promtail || true

cd /tmp
log_info "Downloading Promtail binary..."
wget -q https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip -o -q promtail-linux-amd64.zip
mv -f promtail-linux-amd64 /usr/local/bin/promtail
chmod +x /usr/local/bin/promtail
chown promtail:promtail /usr/local/bin/promtail

# Copy config file
if [ -f "$CONFIG_DIR/promtail/promtail-config.yml" ]; then
    cp -f "$CONFIG_DIR/promtail/promtail-config.yml" /etc/promtail/promtail-config.yml
else
    log_warning "Local promtail-config.yml not found, creating default..."
    cat > /etc/promtail/promtail-config.yml <<EOF
server:
  http_listen_port: 9080
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://localhost:3100/loki/api/v1/push
scrape_configs:
  - job_name: syslog
    static_configs:
      - targets: [localhost]
        labels:
          job: syslog
          __path__: /var/log/syslog
EOF
fi
chown promtail:promtail /etc/promtail/promtail-config.yml

# Create Systemd Unit
cat > /etc/systemd/system/promtail.service <<'EOF'
[Unit]
Description=Promtail Log Shipper
After=network.target

[Service]
Type=simple
User=promtail
Group=promtail
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable promtail
systemctl start promtail
log_success "Promtail installed and started successfully."

log_header "Step 7: Installing and Configuring Grafana"
if systemctl is-active --quiet grafana-server 2>/dev/null; then
    log_info "Grafana service is running. Stopping for reconfiguration..."
    systemctl stop grafana-server
fi

# Add Grafana GPG key and repository
log_info "Adding Grafana repository..."
if [ ! -f /etc/apt/sources.list.d/grafana.list ]; then
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /usr/share/keyrings/grafana.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
    apt-get update -qq
fi

log_info "Installing Grafana package..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq grafana

log_info "Configuring Grafana to listen on port 3001..."
sed -i 's/;http_port = 3000/http_port = 3001/' /etc/grafana/grafana.ini
sed -i 's/http_port = 3000/http_port = 3001/' /etc/grafana/grafana.ini

log_info "Setting up auto-provisioning for datasources and dashboards..."
mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/grafana/dashboards

# Write datasources
cat > /etc/grafana/provisioning/datasources/datasources.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: false
  - name: Loki
    type: loki
    access: proxy
    url: http://localhost:3100
    editable: false
EOF

# Write dashboard provider
cat > /etc/grafana/provisioning/dashboards/dashboards.yml <<'EOF'
apiVersion: 1
providers:
  - name: 'System Monitoring'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Copy dashboard JSON
if [ -f "$CONFIG_DIR/dashboards/system-observability-dashboard.json" ]; then
    cp -f "$CONFIG_DIR/dashboards/system-observability-dashboard.json" /var/lib/grafana/dashboards/system-observability-dashboard.json
    log_success "Copied system observability dashboard configuration."
else
    log_warning "System observability dashboard JSON not found."
fi

chown -R grafana:grafana /etc/grafana/provisioning /var/lib/grafana/dashboards

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
log_success "Grafana service started and configured successfully."

# Final Verification
log_header "Step 8: Verifying Service Statuses"
STATUS_FAILURES=0

check_service() {
    if systemctl is-active --quiet "$1"; then
        log_success "Service $1 is ACTIVE"
    else
        log_error "Service $1 is INACTIVE"
        STATUS_FAILURES=$((STATUS_FAILURES + 1))
    fi
}

check_service prometheus
check_service node_exporter
check_service loki
check_service promtail
check_service grafana-server

# Clean up temporary files
cd /tmp
rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64* node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64* loki-linux-amd64* promtail-linux-amd64*

if [ $STATUS_FAILURES -eq 0 ]; then
    log_header "Observability Stack Installed Successfully!"
    log_success "Access Grafana at http://YOUR_SERVER_PUBLIC_IP:3001"
    log_info "Default login: admin / admin (you will be prompted to change it on first login)"
else
    log_header "Setup Completed with $STATUS_FAILURES Warnings/Failures"
    log_warning "Please inspect failed services logs using: journalctl -u <service_name> --no-pager"
fi
