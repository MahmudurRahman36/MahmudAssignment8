# 🚀 DevOps Monitoring and Deployment Solution

### Course Reference: Ostad DevOps Batch 11 — Assignment Module 8
**Engineer**: Mahmudur Rahman  
**Key Pair Reference**: `ostad_batch_11_mahmud`
**AWS Region**: `ap-south-1`

---

## 📂 1. Directory Structure

This repository contains all IaC code, observability configurations, automation scripts, and workflows needed to deploy and monitor a cloud server on AWS.

```
MahmudAssignment8/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD Pipeline (Lint, Deploy, Verify)
├── terraform/
│   ├── modules/
│   │   ├── vpc/                # Custom VPC with single public subnet
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── security-group/     # Security Group for ports (22, 3001, 9090, 3100)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── ec2/                # Generic EC2 compute instance builder
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       └── prod/
│           ├── main.tf         # Master orchestrator combining modules
│           ├── outputs.tf      # Deployment results (Host IP, SSH commands)
│           ├── variables.tf    # Environmental variables configuration
│           └── terraform.tfvars# Parameter definitions
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml      # Prometheus configuration (Node Exporter scrape target)
│   ├── loki/
│   │   └── loki-config.yml     # Loki configuration (Filesystem storage)
│   ├── promtail/
│   │   └── promtail-config.yml # Promtail configuration (syslog & auth log scraping)
│   ├── dashboards/
│   │   └── system-observability-dashboard.json # Grafana system dashboard JSON model
│   └── scripts/
│       └── setup-monitoring.sh # Automated stack installer (Prometheus/Grafana/Loki/Exporters)
├── screenshots/                # Directory placeholder for verification images
└── README.md                   # Complete architectural and setup documentation
```

---

## 📐 2. System Architecture Topology

The infrastructure deploys a single monitoring and compute server inside a custom VPC. All telemetry components run as native OS-level services managed by `systemd`.

```mermaid
graph TD
    User([🌐 End Users / Admin]) -->|HTTP Port 3001| Grafana[📊 Grafana - Port 3001]
    Developer([💻 DevOps / Developers]) -->|SSH Port 22| EC2[🖥️ Ubuntu EC2 Server - ap-south-1]

    subgraph VPC ["AWS Custom VPC (10.0.0.0/16)"]
        subgraph Public_Subnet ["Public Subnet (10.0.1.0/24)"]
            EC2
        end
    end

    subgraph Telemetry_Stack ["Observability Suite (Local Service Loop)"]
        Prom[🔥 Prometheus - Port 9090]
        Loki[🪵 Grafana Loki - Port 3100]
        Promtail[🦎 Promtail - Port 9080]
        NodeExporter[🔌 Node Exporter - Port 9100]
    end

    %% Scrape Loop
    Prom -.->|Scrapes Metrics :9100| NodeExporter
    Prom -.->|Scrapes Self :9090| Prom

    %% Logs Shipping
    Promtail -.->|Tails syslog & auth.log| Loki
    
    %% Visualization
    Grafana -->|Queries Metrics| Prom
    Grafana -->|Queries Logs| Loki
```

---

## 💻 3. Provisioning Infrastructure (Terraform)

Follow these steps to provision the cloud server using Terraform.

### Prerequisites
- **Terraform**: `>= 1.5.0` installed.
- **AWS CLI**: Configured with valid IAM credentials.

### Step 1: Deploy Infrastructure
1. Navigate to the production environment directory:
   ```bash
   cd terraform/environments/prod
   ```
2. Initialize, validate, and apply the configuration:
   ```bash
   terraform init
   terraform validate
   terraform apply -auto-approve
   ```
3. Copy the outputs. Note down the public IP address of the server.

---

## 🚀 4. CI/CD Deployment Pipeline (GitHub Actions)

The repository automated pipeline validates configuration syntax and deploys the observability stack to the server via SSH.

### Secrets Configuration
Go to your GitHub repository under **Settings > Secrets and Variables > Actions > Secrets** and save these 2 repository secrets:

| Secret Name | Value |
|-------------|-------|
| `EC2_SSH_KEY` | Paste the *entire* raw text content of your `ostad_batch_11_mahmud.pem` private key. |
| `EC2_MONITORING_HOST` | The public IP address of the provisioned EC2 server. |

### Triggering Deployments
Push code to the repository on the `main` branch:
```bash
git add .
git commit -m "feat: complete observability stack configuration"
git push origin main
```
The automated runner will execute `.github/workflows/deploy.yml` to:
1. Run Terraform formatting and validation tests.
2. Connect to the EC2 server using SSH.
3. Sync the configurations and run the `setup-monitoring.sh` installation script.
4. Verify that Prometheus, Loki, and Grafana endpoints respond with healthy status codes.

---

## 📊 5. Observability Stack Details & Port Reference

The installation script configures all services as native systemd units. Ports exposed:

| Port | Service | Role | Notes |
|---|---|---|---|
| `3001` | Grafana | Visualization UI | Access dashboard via browser |
| `9090` | Prometheus | Metrics Engine | Scrapes Node Exporter and self |
| `3100` | Loki | Log Aggregator | Receives log streams from Promtail |
| `9080` | Promtail | Log Shipper | Ships syslog & auth logs to Loki |
| `9100` | Node Exporter | System Metrics | Exposes CPU, Memory, Disk, Network |

### Auto-Provisioned Dashboards
Grafana is pre-configured with a datasource pointing to local Prometheus and Loki services. The **System Observability Dashboard** is imported automatically:
- **Stat Panels**: Real-time CPU usage, memory utilization, disk space, and server UP/DOWN state.
- **Trend Charts**: High-resolution timeseries graphs for CPU/RAM and Network RX/TX metrics.
- **Logs Stream**: Live terminal logs streamed directly from syslog and system auth services.

---

## 📸 6. Verification & Evidence Catalog

Please capture and place screenshots in the `screenshots/` folder:
1. **Terraform deployment**: Output showing successful resource provisioning.
2. **CI/CD execution**: Successful GitHub Actions run showing complete setup and health validation.
3. **Grafana dashboards**: Node Exporter metrics populated inside the Grafana UI.
4. **Loki log visualization**: System logs panel populated with active server logs.

---

## 🧹 7. Project Clean Up (Destruction)

To clean up resources and prevent AWS costs after review:
```bash
cd terraform/environments/prod
terraform destroy -auto-approve
```
