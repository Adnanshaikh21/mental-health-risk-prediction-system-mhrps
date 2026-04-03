#!/bin/bash
sudo apt-get update
sudo apt-get install -y r-base docker.io kubectl
sudo systemctl start docker
sudo systemctl enable docker
Rscript packages.R
docker-compose -f deployment/docker/docker-compose.yml up -d
kubectl apply -f deployment/kubernetes/