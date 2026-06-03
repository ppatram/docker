# Production-Ready API Application Requirements

**Audience:** DevOps engineers building and deploying a containerized API application across development, QA, and production environments on AWS using Kubernetes.

---

## 1. Application Overview

A REST API application deployed as a containerized workload on Amazon EKS. All configuration is externalized so the same container image promotes through environments without rebuilding.

---

## 2. Environment Tiers

| Environment | Purpose | Resource Profile |
|---|---|---|
| Development | Local iteration, feature testing | Minimal (single replica, low CPU/memory) |
| QA | Integration testing, validation | Moderate (2 replicas, mid-tier resources) |
| Production | Live traffic | Full (3+ replicas, auto-scaling, multi-AZ) |

---

## 3. Application Requirements

### 3.1 API Design

- RESTful JSON API with versioned endpoints (`/api/v1/...`)
- Health check endpoints:
  - `/health/live` — liveness (returns 200 if process is running)
  - `/health/ready` — readiness (returns 200 if dependencies are reachable)
- Structured JSON logging with configurable log level per environment
- Graceful shutdown handling (SIGTERM, drain in-flight requests)
- Request ID propagation via headers for distributed tracing

### 3.2 Configuration

All settings externalized via environment variables or mounted config files. No hardcoded values for:

| Setting | Example Values by Environment |
|---|---|
| `APP_ENV` | `development`, `qa`, `production` |
| `LOG_LEVEL` | `debug`, `info`, `warn` |
| `PORT` | `8080` |
| `DB_HOST` | varies per environment |
| `DB_NAME` | varies per environment |
| `CACHE_TTL_SECONDS` | `10`, `60`, `300` |
| `RATE_LIMIT_RPS` | `100`, `500`, `2000` |
| `CORS_ORIGINS` | `*`, `https://qa.example.com`, `https://app.example.com` |

Secrets (DB credentials, API keys, TLS certs) stored in **AWS Secrets Manager** and injected at runtime — never in source control, environment files, or container images.

### 3.3 Security

- TLS 1.2 minimum for all ingress traffic (terminated at ALB or Ingress controller)
- Input validation on all endpoints (reject invalid input, parameterized queries)
- No sensitive data in logs, error responses, or URL parameters
- Container runs as non-root user with read-only filesystem where possible
- Network policies restricting pod-to-pod traffic to only required paths

---

## 4. Kubernetes Deployment Requirements

### 4.1 Resource Allocation (Per Pod)

| Resource | Development | QA | Production |
|---|---|---|---|
| CPU request | 100m | 250m | 500m |
| CPU limit | 250m | 500m | 1000m |
| Memory request | 128Mi | 256Mi | 512Mi |
| Memory limit | 256Mi | 512Mi | 1024Mi |
| Replicas | 1 | 2 | 3 (min) |

### 4.2 Auto-Scaling (Production Only)

- Horizontal Pod Autoscaler (HPA) with:
  - Min replicas: 3
  - Max replicas: 10
  - Target CPU utilization: 70%
  - Target memory utilization: 80%

### 4.3 Deployment Strategy

- **Development/QA:** `RollingUpdate` (maxUnavailable: 1, maxSurge: 1)
- **Production:** `RollingUpdate` (maxUnavailable: 0, maxSurge: 1) — zero downtime

### 4.4 Probes

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

### 4.5 Configuration Management

- **ConfigMaps** for non-sensitive, environment-specific values (log level, feature flags, rate limits)
- **Secrets** (via AWS Secrets Manager with External Secrets Operator or Secrets Store CSI Driver) for credentials
- Namespace-per-environment isolation: `api-dev`, `api-qa`, `api-prod`

### 4.6 Ingress

- AWS ALB Ingress Controller for external traffic
- Path-based routing to the API service
- TLS termination at the ALB using ACM certificates
- WAF rules for production (rate limiting, IP allow/deny)

---

## 5. AWS Infrastructure Requirements

### 5.1 EKS Cluster

| Component | Development | QA | Production |
|---|---|---|---|
| Node instance type | t3.medium | t3.large | m5.xlarge |
| Node count (min) | 1 | 2 | 3 |
| Node count (max) | 2 | 3 | 6 |
| Availability Zones | 1 | 2 | 3 |
| Cluster autoscaler | Disabled | Enabled | Enabled |

### 5.2 Networking

- VPC with public and private subnets (nodes in private subnets)
- NAT Gateway for outbound internet from private subnets
- VPC Endpoints for ECR, Secrets Manager, CloudWatch, S3 (avoid public internet traversal)
- Security groups per tier: ingress (ALB), application (nodes), data (RDS/ElastiCache)

### 5.3 Data Layer

| Component | Development | QA | Production |
|---|---|---|---|
| Database | RDS PostgreSQL (db.t3.micro, single-AZ) | RDS PostgreSQL (db.t3.small, single-AZ) | RDS PostgreSQL (db.r5.large, multi-AZ) |
| Cache | None or ElastiCache (cache.t3.micro) | ElastiCache (cache.t3.small) | ElastiCache (cache.r5.large, multi-AZ) |
| Storage encryption | AWS managed KMS key | AWS managed KMS key | AWS managed KMS key |
| Automated backups | 1 day retention | 7 day retention | 30 day retention |

### 5.4 Container Registry

- Amazon ECR for container images
- Image scanning enabled on push
- Lifecycle policies to expire untagged images after 7 days
- Immutable tags for production images

### 5.5 Observability

| Component | Tool | Purpose |
|---|---|---|
| Metrics | CloudWatch Container Insights + Prometheus | CPU, memory, request rate, error rate, latency (p50, p95, p99) |
| Logging | CloudWatch Logs (structured JSON) | Centralized log aggregation with retention policies |
| Tracing | AWS X-Ray or OpenTelemetry | Distributed request tracing |
| Alerting | CloudWatch Alarms → SNS | Error rate > 1%, latency p99 > 2s, pod restarts > 3 in 5min |

### 5.6 CI/CD Pipeline

| Stage | Action |
|---|---|
| Build | Compile, unit tests, lint, SAST scan |
| Package | Build container image, push to ECR, image vulnerability scan |
| Deploy Dev | Auto-deploy on merge to main |
| Deploy QA | Auto-deploy after dev smoke tests pass |
| Deploy Prod | Manual approval gate, then rolling deploy |

Single image built once, promoted through environments by changing configuration only.

---

## 6. Non-Functional Requirements

| Requirement | Development | QA | Production |
|---|---|---|---|
| Availability target | Best effort | 99% | 99.9% |
| Response time (p99) | < 2s | < 1s | < 500ms |
| RTO | N/A | 4 hours | 1 hour |
| RPO | N/A | 24 hours | 1 hour |
| Max monthly cost target | ~$50-100 | ~$200-400 | $1000+ (scales with traffic) |

---

## 7. File Structure (Kubernetes Manifests)

```
k8s/
├── base/                    # Shared manifests (Kustomize base)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── hpa.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── patch-resources.yaml
│   │   └── configmap-values.yaml
│   ├── qa/
│   │   ├── kustomization.yaml
│   │   ├── patch-resources.yaml
│   │   └── configmap-values.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── patch-resources.yaml
│       ├── patch-hpa.yaml
│       └── configmap-values.yaml
```

Uses **Kustomize** overlays so the base manifests stay identical and only environment-specific patches differ.

---

## 8. Acceptance Criteria

GIVEN the API container image is built from main branch
WHEN it is deployed to the development namespace with dev overlay
THEN it runs with 1 replica, 100m CPU request, debug logging, and connects to the dev database

GIVEN the same container image promoted to QA
WHEN deployed with the QA overlay
THEN it runs with 2 replicas, 250m CPU request, info logging, and connects to the QA database

GIVEN the same container image promoted to production
WHEN deployed with the prod overlay
THEN it runs with 3+ replicas, HPA enabled, warn logging, multi-AZ, and connects to the production database

GIVEN the application receives a SIGTERM signal
WHEN in-flight requests are processing
THEN it completes current requests within 30 seconds before shutting down

GIVEN an invalid request body is sent to any endpoint
WHEN the API processes the request
THEN it returns HTTP 400 with a structured error response and does not expose internal details
