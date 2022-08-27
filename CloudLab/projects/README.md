# GCP Projects

GCP Projects Project

```bash
PROJECT_ID="$(vault kv get -field=project_id secret/gcp/org/av/projects)"

cat << EOF > backend.conf
bucket = "tf-state-projects-${PROJECT_ID}"
prefix = "terraform/state"
EOF

terraform init -backend-config=backend.conf
terraform plan
terraform apply
```
