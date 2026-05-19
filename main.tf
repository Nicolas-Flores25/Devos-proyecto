
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}


resource "digitalocean_ssh_key" "proyecto_final" {
  name       = "clave-automatizacion-nicolas"
  
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+w6Vy7NnIBqNfFpW18TR+X6vpKFD+mTrY1V0vn9JSw nicolas.flores25002@gmail.com"
}



resource "digitalocean_droplet" "jenkins" {
  name   = "jenkins-server"
  region = "nyc1"
  size   = "s-2vcpu-2gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.proyecto_final.id]

  user_data = templatefile("scripts/install_jenkins.sh", {
    registry_ip = digitalocean_droplet.registry.ipv4_address_private
    repo_url    = "https://github.com/Nicolas-Flores25/app-spingboot"
    
    git_user    = "Nicolas-Flores25"
    git_token   = var.github_token 
  })
}


resource "digitalocean_droplet" "registry" {
  name   = "docker-registry"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.proyecto_final.id]

  user_data = file("scripts/install_registry.sh")
}


resource "digitalocean_droplet" "app_server_dev" {
  name   = "app-server-dev"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.proyecto_final.id]
  
  user_data = templatefile("scripts/install_docker.sh", {
    registry_ip         = digitalocean_droplet.registry.ipv4_address_private
    github_repo_url     = "https://github.com/Nicolas-Flores25/app-spingboot"
    github_runner_token = var.github_runner_token
    runner_label        = "dev"
  })
}

resource "digitalocean_droplet" "app_server_prod" {
  name   = "app-server-prod"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.proyecto_final.id]
  
  user_data = templatefile("scripts/install_docker.sh", {
    registry_ip         = digitalocean_droplet.registry.ipv4_address_private
    github_repo_url     = "https://github.com/Nicolas-Flores25/app-spingboot"
    github_runner_token = var.github_runner_token
    runner_label        = "prod"
  })
}

# --- FIREWALL ---
resource "digitalocean_firewall" "devops_firewall" {
  name = "devops-firewall"

  droplet_ids = [
    digitalocean_droplet.jenkins.id,
    digitalocean_droplet.registry.id,
    digitalocean_droplet.app_server_dev.id,
    digitalocean_droplet.app_server_prod.id
  ]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8081"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "5000"
    source_droplet_ids = [
      digitalocean_droplet.jenkins.id,
      digitalocean_droplet.app_server_dev.id,
      digitalocean_droplet.app_server_prod.id
    ]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# --- OUTPUTS ---
output "jenkins_ip" {
  value = digitalocean_droplet.jenkins.ipv4_address
}

output "app_server_dev_ip" {
  value = digitalocean_droplet.app_server_dev.ipv4_address
}

output "app_server_prod_ip" {
  value = digitalocean_droplet.app_server_prod.ipv4_address
}

output "registry_ip" {
  value = digitalocean_droplet.registry.ipv4_address
}