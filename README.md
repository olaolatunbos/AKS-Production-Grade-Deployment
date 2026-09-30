# AKS-Production-Grade-Deployment

A Flask bank-statement categoriser deployed to **Azure Kubernetes Service (AKS)** behind an NGINX ingress, with TLS from **cert-manager**, DNS records managed by **ExternalDNS**, and GitOps delivery through **Argo CD**. The cluster and its platform add-ons are provisioned with **Terraform**, and the pipelines run on **GitHub Actions**. Everything runs as a single production environment in `UK South`.

## Architecture

![AKS architecture](https://github.com/user-attachments/assets/83dd7e37-e6ae-49a5-8234-227a6e724a2e)

- **Application**: [app2/](app2/) is a Flask app that takes an uploaded Lloyds PDF statement, extracts the transactions with `pdfplumber`, categorises each one with the OpenAI API, and offers the results as an Excel download. The last result is held **in memory**, so it resets on restart and is not shared across replicas. There is no database.
- **Infrastructure**: [terraform/](terraform/) defines the AKS cluster directly in [main.tf](terraform/main.tf) and uses the `dns_zone` and `container_registry` modules under [terraform/modules/](terraform/modules/). The `virtual_network` module exists, but its call is commented out. The cluster joins an existing subnet by resource ID.
- **Platform add-ons**: cert-manager, ExternalDNS, and Argo CD are installed as Helm releases from [helm-charts.tf](terraform/helm-charts.tf), with values in [terraform/helm-values/](terraform/helm-values/).
- **Workload manifests**: [k8s-specifications/](k8s-specifications/) contains the Deployment, Service, Ingress, and Let's Encrypt `ClusterIssuer`. Argo CD keeps these in sync with the cluster.

### Request path

Public DNS (`www.olaolat.com`, an A record that ExternalDNS writes into the Azure DNS zone) → NGINX ingress controller `LoadBalancer` → TLS terminated with a Let's Encrypt certificate issued by cert-manager (HTTP-01) → `app-service` (ClusterIP, port `80`) → Flask container on port `3000`.

### GitOps flow

The [argocd/apps-argocd.yml](argocd/apps-argocd.yml) `Application` watches `k8s-specifications/` on `HEAD` of this repository and syncs it into the `apps` namespace, with automated **prune** and **self-heal** turned on. The Argo CD UI is exposed at `argocd.olaolat.com` through its own ingress.

## Application

Routes: `GET /` shows the upload form, `POST /` uploads a PDF and returns a spending summary by category, and `GET /download` returns an Excel workbook with `Transactions` and `Summary` sheets.

### Run locally

```bash
cd app2
pip install -r requirements.txt
python app.py            # serves on http://localhost:3000
```

The OpenAI client in [app.py](app2/app.py) is created with an empty `api_key`. You need to supply a key before categorisation will work. Without one, every transaction is labelled `Uncategorized`.

### Container

[app2/Dockerfile](app2/Dockerfile) builds from `python:3.11-slim`, runs as a non-root `appuser`, and exposes port `3000`.

```bash
docker build -t statement-smart ./app2
docker run -p 3000:3000 statement-smart
```

> [app/](app/) holds a static 2048 game served with `python -m http.server`. No pipeline or manifest deploys it. Note that the Kubernetes Deployment is named `2048-game` but runs the `statement-smart` image.

## Infrastructure (Terraform)

Run these commands from inside [terraform/](terraform/). State is stored in an Azure Storage backend (`tfstate-rg` / `tfstatestorageacct12` / `tfstate`), configured in [providers.tf](terraform/providers.tf). The storage account must exist before the first `init`.

```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
terraform fmt -check                  # formatting gate used by the plan workflow
```

`terraform.tfvars` is git-ignored. It must set `dns_zone_name`, `location`, `resource_group_name`, `container_registry_name`, `virtual_network_name`, `subnet_name`, and `environment`. In CI it is written from the `PROD_TFVARS` secret.

> The AKS cluster's name, resource group, region, Kubernetes version (`1.32.5`), node sizing (`Standard_DS2_v2`, autoscaling 2 to 5 nodes), and subnet ID are **hard-coded** in [main.tf](terraform/main.tf) rather than read from variables. To change them, edit that file.

### Pre-requisites not managed by Terraform

- **NGINX ingress controller**: the `helm_release` for it is commented out in [helm-charts.tf](terraform/helm-charts.tf), so install it separately. [nginx-ingress-values.yaml](terraform/helm-values/nginx-ingress-values.yaml) is available for that.
- **ExternalDNS credentials**: create a secret named `azure-config-file` in the `default` namespace so ExternalDNS can write to the `olaolat.com` zone.
- **Argo CD Application**: apply it once with `kubectl apply -f argocd/apps-argocd.yml`. After that, Argo CD manages everything in `k8s-specifications/`.

> The Argo CD ingress references a cluster issuer named `issuer`, but the only `ClusterIssuer` defined in this repo is `letsencrypt-prod`. Align these names, or the Argo CD certificate will not be issued.

## CI/CD

All workflows live in [.github/workflows/](.github/workflows/) and authenticate to Azure with service-principal credentials stored as repository secrets (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`).

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [push-image.yml](.github/workflows/push-image.yml) | Push on `main` for `app2/**` | Builds the Docker image, runs a Trivy scan (CRITICAL/HIGH, report-only with `exit-code: 0`), and pushes `statement-smart:latest` to ACR |
| [terraform-plan-and-apply.yml](.github/workflows/terraform-plan-and-apply.yml) | PR to `main` for `terraform/**`, or manual dispatch | Runs fmt check, validate, a Checkov scan (soft-fail), and plan, then posts the plan as a PR comment. On manual dispatch it also applies the saved plan |
| [terraform-destroy.yml](.github/workflows/terraform-destroy.yml) | Manual dispatch | Destroys all Terraform-managed resources |

Deployment is **pull-based**: CI pushes a new `:latest` image, and the Deployment references `olaolat.azurecr.io/statement-smart:latest`. Argo CD only syncs when the manifests change, so a new image with the same tag is not rolled out automatically. Run `kubectl rollout restart deployment/2048-game -n apps` to pick it up.

## Repository layout

```
app2/                      Flask statement categoriser (deployed app), Dockerfile
  templates/, static/      Server-rendered UI
app/                       Static 2048 game (not deployed)
terraform/
  main.tf                  AKS cluster, DNS zone, and ACR
  helm-charts.tf           cert-manager, ExternalDNS, Argo CD releases
  helm-values/             Helm values per release
  modules/                 dns_zone, container_registry, virtual_network
k8s-specifications/        Deployment, Service, Ingress, ClusterIssuer (synced by Argo CD)
argocd/                    Argo CD Application pointing at k8s-specifications/
.github/workflows/         Image build, Terraform plan/apply, and destroy
```
