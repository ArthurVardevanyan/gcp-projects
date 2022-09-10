#!/usr/bin/env bash

echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >>/etc/profile
echo "export CLOUDSDK_PYTHON_SITEPACKAGES=1" >>/etc/profile

$(gcloud info --format="value(basic.python_location)") -m pip install numpy

sudo apt-get install kubectl google-cloud-sdk-gke-gcloud-auth-plugin
