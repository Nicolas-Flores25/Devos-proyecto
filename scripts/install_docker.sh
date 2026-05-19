#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Configurar Insecure Registry
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["${registry_ip}:5000"]
}
EOF

systemctl restart docker

echo "REGISTRY_IP=${registry_ip}" >> /etc/environment
echo "export REGISTRY_IP=${registry_ip}" > /etc/profile.d/registry_env.sh
chmod +x /etc/profile.d/registry_env.sh

useradd -m github-runner
usermod -aG docker github-runner

# Descargamos el runner
sudo -u github-runner mkdir -p /home/github-runner/actions-runner
cd /home/github-runner/actions-runner
sudo -u github-runner curl -o actions-runner-linux-x64-2.316.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
sudo -u github-runner tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz

# Configuramos el runner
sudo -u github-runner ./config.sh --url "${github_repo_url}" --token "${github_runner_token}" --unattended --replace --name "runner-${runner_label}" --labels "${runner_label}"

sudo -u github-runner bash -c 'echo "REGISTRY_IP=${registry_ip}" >> /home/github-runner/actions-runner/.env'
./svc.sh install github-runner
./svc.sh start