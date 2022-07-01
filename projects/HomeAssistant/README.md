# HomeAssistant

<https://www.home-assistant.io/integrations/nest/>

```bash
PROJECT_ID=""

cat << EOF > backend.conf
bucket = "tf-state-${PROJECT_ID}"
prefix = "terraform/state"
EOF

gsutil mb -p ${PROJECT_ID} -c STANDARD -l us-central1 -b on gs://tf-state-${PROJECT_ID}

terraform init -backend-config=backend.conf
terraform plan
terraform apply
```
