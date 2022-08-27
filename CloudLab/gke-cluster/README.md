# GKE Cluster

Installing GKE AutoPilot

1. Create Bucket Manually
2. Comment Out GKE Portion of Terraform
3. Run Terraform Init/Plan/Apply
4. Create GKE AutoPilot Cluster Manually
5. UnComment GKE Portion of Terraform
6. Run Terraform Init/Import
7. Run Terraform Plan/Apply

```bash
PROJECT_ID="$(vault kv get -field=project_id secret/gcp/org/av/projects)"

cat << EOF > backend.conf
bucket = "tf-state-gke-cluster-${PROJECT_ID}"
prefix = "terraform/state"
EOF

# Comment GKE Part
terraform init -backend-config=backend.conf
terraform plan
terraform apply

gcloud container clusters create-auto "gke-autopilot" \
  --project "${PROJECT_ID}" \
  --region "us-central1" \
  --release-channel "rapid" \
  --network "projects/${PROJECT_ID}/global/networks/default" \
  --subnetwork "projects/${PROJECT_ID}/regions/us-central1/subnetworks/default" \
  --cluster-ipv4-cidr "/21"\
  --services-ipv4-cidr "/27" \
  --enable-master-authorized-networks \
  --enable-private-nodes \
  --enable-private-endpoint \
  --service-account="gke-autopilot@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes="https://www.googleapis.com/auth/cloud-platform"

gcloud container --project "${PROJECT_ID}" clusters describe "gke-autopilot" --region "us-central1"

# UnComment GKE Part
terraform init -backend-config=backend.conf -upgrade
terraform import google_container_cluster.gke-autopilot projects/${PROJECT_ID}/locations/us-central1/clusters/gke-autopilot

terraform plan
terraform apply

export KUBECONFIG=~/.kube/gke
gcloud container clusters get-credentials gke-autopilot --region us-central1 --project=${PROJECT_ID}
kubectl kustomize projects/GKE-Autopilot/manifests | argocd-vault-plugin generate - | kubectl apply -f -
```
