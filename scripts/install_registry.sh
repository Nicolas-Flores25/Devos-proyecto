#!/bin/bash
apt-get update && apt-get install -y docker.io
systemctl start docker
systemctl enable docker


docker run -d -p 5000:5000 --restart always --name registry registry:2