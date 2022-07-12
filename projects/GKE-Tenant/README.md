# GKE-Tenat

Conneting Cloud Build to GitHub Needs to be done in the Console First

```bash
PROJECT_ID="$(vault kv get -field=project_id secret/gcp/project/gke_tenant)"

cat << EOF > backend.conf
bucket = "tf-state-${PROJECT_ID}"
prefix = "terraform/state"
EOF

gsutil mb -p ${PROJECT_ID} -c STANDARD -l us-central1 -b on gs://tf-state-${PROJECT_ID}


terraform init -backend-config=backend.conf
terraform plan
terraform apply
```

Output

```log
Already have image (with digest): gcr.io/cloud-builders/gcloud
Fetching cluster endpoint and auth data.
kubeconfig entry generated for gke-autopilot.
NAME                           READY   STATUS    RESTARTS   AGE
smoke-tests-5bb6dc7458-rn69z   1/1     Running   0          14m

% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
{"access_token":"<snipped>","expires_in":650,"token_type":"Bearer"}

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100  1083  100  1083    0     0   352k      0 --:--:-- --:--:-- --:--:--  528k
```
