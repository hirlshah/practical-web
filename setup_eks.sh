#!/bin/bash

# Update AWS CLI
curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update

# Install kubectl
curl --silent -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin

# Install eksctl
curl --silent -LO "https://github.com/weaveworks/eksctl/releases/download/v0.186.0/eksctl_Linux_amd64.tar.gz" # Ensure you are downloading the latest version
tar xzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin
chmod +x /usr/local/bin/eksctl

# Generate kubeconfig
eksctl utils write-kubeconfig --region=ap-south-1 --cluster=eks-cluster

# Verify
kubectl get nodes
