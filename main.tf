terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0" # Specify a compatible version
    }
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.1.0" # Use the latest version
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

# found at end of url when editing uptime kuma monitor
variable "ip_monitor_id" {
  type        = string
  description = "id of uptime kuma monitor to update"
}

variable "droplet_id" {
  type        = string
  description = "id of droplet to attach to the firewall"
}

variable "kuma_user" {
  type        = string
  description = "user for uptime kuma"
}

variable "kuma_url" {
  type        = string
  description = "url for uptime kuma"
}

variable "kuma_password" {
  type        = string
  description = "password for uptime kuma"
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

provider "uptimekuma" {
  endpoint = var.kuma_url
  username = var.kuma_user
  password = var.kuma_password
}

data "uptimekuma_monitor_group" "ip" {
  name = "ip"
}

import {
    to = uptimekuma_monitor_http_json_query.ip_change_tofu
    id = var.ip_monitor_id
}

resource "uptimekuma_monitor_http_json_query" "ip_change_tofu" {
  name     = "ip change tofu"
  url      = "https://ip-json.andbrant.com"
  json_path = "ip"
  # json_path_expected = var.home_ip
  # json_path_expected = ""
  # expected_value = ""
  expected_value = var.home_ip
  # interval = 600
  # active = true
  notification_ids = [ 1 ] # TODO set up ntfy too, and set this to its value
  parent   = data.uptimekuma_monitor_group.ip.id
  resend_interval = 360
  max_retries = 0
}

output "firewall_id" {
  value = digitalocean_firewall.myfirewall.id
  description = "The unique ID of the managed web firewall."
}

output "ip_monitor_id" {
  value = var.ip_monitor_id
  description = "id of ip monitor tofu is managing"
}

