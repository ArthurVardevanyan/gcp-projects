# GCP Projects

Contains GCP Projects Terraform & Configurations

```bash
.
├── CloudLab
│   ├── gke-cluster
│   │   ├── main.tf
│   │   ├── manifests
│   │   │   ├── deployment.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── namespace.yaml
│   │   │   └── rbac.yaml
│   │   ├── policy.yaml
│   │   └── README.md
│   ├── gke-tenant
│   │   ├── cloudbuild.yaml
│   │   ├── main.tf
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
