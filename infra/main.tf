terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Configuration pour Linux (DÉSACTIVÉE)
# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

# Configuration pour macOS avec Docker Desktop (Décommentez si besoin et remplacez VOTRE_USER)
# provider "docker" {
#   host = "unix:///Users/VOTRE_USER/.docker/run/docker.sock"
# }

# Configuration pour Windows avec Docker Desktop (ACTIVÉE ENFIN !)
provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

# Suite de infra/main.tf
# Reseau Docker partage Jenkins / SonarQube / SentimentAI
# Ce reseau existe deja depuis le TP2/TP3 -- voir Partie 3.1
resource "docker_network" "cicd" {
  name = "cicd-network"
}

# Image Docker SentimentAI -- image LOCALE buildee par Jenkins
resource "docker_image" "sentiment" {
  name         = "sentiment-ai:${var.image_tag}"
  keep_locally = true
}

# Conteneur staging
resource "docker_container" "sentiment_staging" {
  name    = var.container_name
  image   = docker_image.sentiment.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = var.app_port
  }

  env = [
    "ENV=staging",
    "LOG_LEVEL=INFO",
  ]

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}