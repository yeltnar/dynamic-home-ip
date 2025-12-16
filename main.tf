terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0" # Specify a compatible version
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  # The token can be set via the DO_PAT environment variable or passed explicitly
  # using a variable (as shown here for best practice in HCL)
  token = var.do_token
}

# Define the variable to hold the token value
variable "do_token" {
  type        = string
  description = "DigitalOcean Personal Access Token"
}

variable "home_ip" {
  type        = string
  description = "public ip address of the house"
}

variable "firewall_id" {
  type        = string
  description = "id of firewall to be used"
}

variable "droplet_id" {
  type        = string
  description = "id of droplet to attach to the firewall"
}

import {
    to = digitalocean_firewall.myfirewall
    id = var.firewall_id
}

resource "digitalocean_firewall" "myfirewall" {
  name = "firewall"

  # Attach the firewall to all resources with the "web-tier" tag
  # tags = ["web-tier"] 
  droplet_ids = [
    var.droplet_id
  ]
  
  inbound_rule {
    # Allow SSH from anywhere (your local machine)
    protocol              = "tcp"
    port_range            = "22"
    source_addresses      = [var.home_ip] 
  }

  inbound_rule {
    # Allow HTTP from anywhere
    protocol              = "tcp"
    port_range            = "80"
    source_addresses      = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    # Allow HTTPS from anywhere
    protocol              = "tcp"
    port_range            = "443"
    source_addresses      = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    # Allow HTTPS from anywhere
    protocol              = "udp"
    port_range            = "4242"
    source_addresses      = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    # Allow HTTPS from anywhere
    protocol              = "udp"
    port_range            = "51820"
    source_addresses      = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol              = "icmp"
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

output "firewall_id" {
  value = digitalocean_firewall.myfirewall.id
  description = "The unique ID of the managed web firewall."
}

