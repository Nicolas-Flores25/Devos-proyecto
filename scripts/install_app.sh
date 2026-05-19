#!/bin/bash

apt-get update
apt-get install -y docker.io docker-compose
systemctl start docker
systemctl enable docker


mkdir /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner


curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz


tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz




sudo chown -R ubuntu:ubuntu /home/ubuntu/actions-runner
sudo -u ubuntu ./config.sh --url https://github.com/Nicolas-Flores25/app-spingboot --token TU_TOKEN_DE_RUNNER_AQUI --unattended


sudo ./svc.sh install
sudo ./svc.sh start