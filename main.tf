terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
  sensitive = true
}

variable "pub_key_path" {
  description = "Ssh public key path"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "nexcloud" {
  name   = "nextcloud-terroform-network"
  region = "fra1"
}

resource "digitalocean_ssh_key" "nextcloud" {
  name       = "nextcloud"
  public_key = file(var.pub_key_path)
}

resource "digitalocean_droplet" "nextcloud" {
  image      = "debian-11-x64"
  name       = "nextcloud"
  region     = "fra1"
  size       = "s-1vcpu-2gb"
  backups    = true
  monitoring = true
  tags       = ["terraform", "production"]
  ssh_keys   = [digitalocean_ssh_key.nextcloud.fingerprint]
  vpc_uuid   = digitalocean_vpc.nexcloud.id
}


resource "digitalocean_project" "nextcloud" {
  name        = "nextcloud"
  description = "A nexcloud serveur lauched using terraform."
  purpose     = "Web Application"
  environment = "Production"
  resources = [
    digitalocean_droplet.nextcloud.urn,
  ]
}

output "server_ip" {
  value = digitalocean_droplet.nextcloud.ipv4_address
}
