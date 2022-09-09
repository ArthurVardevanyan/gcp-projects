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
BUCKET_ID="$(vault kv get -field=bucket_id secret/gcp/org/av/projects)"

cat << EOF > backend.conf
bucket = "tf-state-gke-cluster-${BUCKET_ID}"
prefix = "terraform/state"
EOF

# Comment GKE Part
terraform init -backend-config=backend.conf
terraform plan
terraform apply

gcloud container clusters create-auto "gke-autopilot" \
  --project "gke-cluster-${PROJECT_ID}" \
  --region "us-central1" \
  --release-channel "rapid" \
  --master-ipv4-cidr 10.9.0.0/28 \
  --network "projects/network-${PROJECT_ID}/global/networks/vpc-network" \
  --subnetwork "projects/network-${PROJECT_ID}/regions/us-central1/subnetworks/gke-autopilot" \
  --cluster-secondary-range-name gke-autopilot-pod \
  --services-secondary-range-name gke-autopilot-svc \
  --enable-master-authorized-networks \
  --enable-private-nodes \
  --enable-private-endpoint \
  --service-account="gke-autopilot@gke-cluster-${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes="https://www.googleapis.com/auth/cloud-platform","https://www.googleapis.com/auth/cloud-platform","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/trace.append"

gcloud container --project "gke-cluster-${PROJECT_ID}" clusters describe "gke-autopilot" --region "us-central1"

gcloud container --project "gke-cluster-${PROJECT_ID}" clusters update "gke-autopilot" --region "us-central1" --enable-master-global-access

# UnComment GKE Part
terraform init -backend-config=backend.conf -upgrade
terraform import google_container_cluster.gke-autopilot projects/"gke-cluster-${PROJECT_ID}"/locations/us-central1/clusters/gke-autopilot

terraform plan
terraform apply

export KUBECONFIG=~/.kube/gke
gcloud container clusters get-credentials gke-autopilot --region us-central1 --project="gke-cluster-${PROJECT_ID}"
kubectl kustomize projects/GKE-Autopilot/manifests | argocd-vault-plugin generate - | kubectl apply -f -
```

Compute VM SSH

```bash
gcloud compute ssh --project "gke-cluster-${PROJECT_ID}" --zone "us-central1-a" "gce-micro" --tunnel-through-iap --ssh-key-expire-after=120m
```

Cost Allocation

```bash
gcloud beta container clusters update gke-standard --project "gke-cluster-${PROJECT_ID}" --region us-central1 --enable-cost-allocation
```
