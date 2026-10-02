terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.2"
    }
  }

  backend "gcs" {
    bucket = "lunar-works-316500-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "lunar-works-316500"
  region  = "asia-south1"
}

resource "google_artifact_registry_repository" "docker_repo" {
  location      = "asia-south1"
  repository_id = "devops-gcp-repo"
  description   = "Docker repository for DevOps GCP Hello World"
  format        = "DOCKER"
}

resource "google_cloud_run_service" "hello_world" {
  name     = "devops-gcp-hello-world"
  location = "asia-south1"

  template {
    spec {
      containers {
        image = "asia-south1-docker.pkg.dev/lunar-works-316500/devops-gcp-repo/devops-gcp-hello-world:1.0"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image
    ]
  }
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.hello_world.location
  project  = "lunar-works-316500"
  service  = google_cloud_run_service.hello_world.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
