# GCP Projects

Contains GCP Projects Terraform & Configurations

```bash
.
├── CloudLab
│   ├── gke-cluster
│   │   ├── autopilot.tf
│   │   ├── backend.conf
│   │   ├── compute.tf
│   │   ├── main.tf
│   │   ├── manifests
│   │   │   ├── deployment.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── namespace.yaml
│   │   │   └── rbac.yaml
│   │   ├── outputs.tf
│   │   ├── policy.yaml
│   │   ├── README.md
│   │   └── standard.tf
│   ├── gke-tenant
│   │   ├── artifactregistry.tf
│   │   ├── cloudbuild.tf
│   │   ├── cloudbuild.yaml
│   │   ├── main.tf
│   │   ├── pubsub.tf
│   │   └── README.md
│   └── network
│       ├── main.tf
│       └── README.md
├── org
│   ├── org
│   │   ├── main.tf
│   │   └── README.md
│   └── projects
│       ├── gke-cluster.tf
│       ├── gke-tenant.tf
│       ├── main.tf
│       ├── network.tf
│       ├── org.tf
│       └── README.md
├── projects
│   └── HomeAssistant
│       ├── main.tf
│       └── README.md
└── README.md
```
