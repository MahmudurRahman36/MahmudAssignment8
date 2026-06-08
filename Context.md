# SYSTEM CONTEXT & DIRECTIVE
You are operating as an expert DevOps Engineering AI. Your objective is to build a "complete DevOps monitoring and deployment solution" fulfilling all Module 8 Assignment requirements exactly as specified.

## 1. ARCHITECTURAL BASELINE & DNA REFERENCE
Target Directory: `D:\1_Office_Document\4. Training\DevOps\Ostad\Assignment8\ReferenceProjects\`

* Primary Baseline: Analyze `mahmud_assignment_7`. Extract core architectural DNA (directory structure, naming conventions, coding standards, abstraction levels).
* Secondary Synthesis: Scan all parallel reference projects in the directory. Extract supplementary configurations and optimizations.
* Execution Constraint: Strictly mirror this synthesized pattern for all generated code.

## 2. CORE TECHNICAL REQUIREMENTS
Execute the following implementation phases sequentially:

### Phase A: Infrastructure as Code (IaC)
* Use Terraform to provision a cloud server.
* Output connection strings and IP addresses upon successful apply.

### Phase B: CI/CD Pipeline
* Create a CI/CD pipeline (GitHub Actions/GitLab CI) for automated deployment.
* Pipeline must validate configurations and automate the deployment lifecycle.

### Phase C: Observability Stack Configuration
* Install and configure the following services on the provisioned server:
  * Node Exporter
  * Promtail
  * Loki
  * Grafana
* Ensure correct metric/log scraping configurations between endpoints.

### Phase D: Dashboards & Visualization
* Create a Grafana dashboard explicitly displaying:
  * CPU
  * Memory
  * Disk
  * Network metrics
  * System logs
* Export this dashboard configuration as a JSON file.

## 3. CONTINUOUS VALIDATION PROTOCOL (CRITICAL)
* Zero-regression tolerance.
* Every time a change is made, you must automatically perform checking of all its features again.
* Validate syntax (`terraform validate`), lint configurations, and simulate deployment pipelines before proceeding. Halt on major faults.

## 4. SUBMISSION REQUIREMENTS & DELIVERABLES PREPARATION
Upload and stage all work for a GitHub repository submission, including:
* `terraform/` (Terraform configuration files)
* `.github/workflows/` or `.gitlab-ci.yml` (CI/CD pipeline configuration files)
* `monitoring/` (Grafana dashboard configuration/export JSON and stack configs)
* `README.md` (Documentation detailing setup and architecture)

Create a `screenshots/` directory placeholder and instruct the user precisely to capture screenshots of:
1. Successful CI/CD pipeline execution
2. Terraform deployment
3. Grafana dashboards
4. Loki log visualization

## 5. FINAL DELIVERABLE
Initiate the project by analyzing the reference directories and outputting the proposed structure. Upon completion of all phases, output the final instruction to the user:
"Submit the GitHub repository link as the final deliverable."