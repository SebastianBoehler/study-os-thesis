provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  name_prefix                 = "study-os-thesis-${var.environment}"
  backend_image               = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}/backend:${var.image_tag}"
  worker_image                = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}/worker:${var.image_tag}"
  frontend_image              = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}/frontend:${var.image_tag}"
  database_url_secret         = var.database_url_secret == "" ? "${local.name_prefix}-database-url" : var.database_url_secret
  redis_url_secret            = var.redis_url_secret == "" ? "${local.name_prefix}-redis-url" : var.redis_url_secret
  jwt_secret                  = var.jwt_secret == "" ? "${local.name_prefix}-jwt-secret" : var.jwt_secret
  azure_openai_api_key_secret = var.azure_openai_api_key_secret == "" ? "${local.name_prefix}-azure-openai-api-key" : var.azure_openai_api_key_secret
  deepseek_api_key_secret     = var.deepseek_api_key_secret == "" ? "${local.name_prefix}-deepseek-api-key" : var.deepseek_api_key_secret
  runtime_secret_names        = toset([local.database_url_secret, local.redis_url_secret, local.jwt_secret, local.azure_openai_api_key_secret, local.deepseek_api_key_secret])
}

resource "google_project_service" "required" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "${local.name_prefix}-containers"
  description   = "Container images for ${local.name_prefix}"
  format        = "DOCKER"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "runtime" {
  account_id   = "${local.name_prefix}-runtime"
  display_name = "${local.name_prefix} Cloud Run runtime"
}

data "google_secret_manager_secret" "runtime" {
  for_each = local.runtime_secret_names

  secret_id = each.key
}

resource "google_secret_manager_secret_iam_member" "runtime_secret_access" {
  for_each = data.google_secret_manager_secret.runtime

  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_cloud_run_v2_service" "backend" {
  name     = "${local.name_prefix}-backend"
  location = var.region

  template {
    service_account = google_service_account.runtime.email

    containers {
      image = local.backend_image

      ports {
        container_port = 8080
      }

      env {
        name  = "CORS_ORIGINS"
        value = var.cors_origins == "" ? var.frontend_origin : var.cors_origins
      }
      env {
        name  = "LLM_CHAT_PROVIDER"
        value = var.llm_chat_provider
      }
      env {
        name  = "LLM_EMBED_PROVIDER"
        value = var.llm_embed_provider
      }
      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = var.azure_openai_endpoint
      }
      env {
        name  = "AZURE_CHAT_DEPLOYMENT"
        value = var.azure_chat_deployment
      }
      env {
        name  = "AZURE_EMBED_DEPLOYMENT"
        value = var.azure_embed_deployment
      }
      env {
        name  = "DEEPSEEK_BASE_URL"
        value = var.deepseek_base_url
      }
      env {
        name  = "DEEPSEEK_CHAT_MODEL"
        value = var.deepseek_chat_model
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = local.database_url_secret
            version = "latest"
          }
        }
      }
      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = local.redis_url_secret
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.jwt_secret
            version = "latest"
          }
        }
      }
      env {
        name = "AZURE_OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = local.azure_openai_api_key_secret
            version = "latest"
          }
        }
      }
      env {
        name = "DEEPSEEK_API_KEY"
        value_source {
          secret_key_ref {
            secret  = local.deepseek_api_key_secret
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime_secret_access]
}

resource "google_cloud_run_v2_service" "worker" {
  name     = "${local.name_prefix}-worker"
  location = var.region

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = 1
      max_instance_count = 2
    }

    containers {
      image = local.worker_image

      env {
        name  = "LLM_CHAT_PROVIDER"
        value = var.llm_chat_provider
      }
      env {
        name  = "LLM_EMBED_PROVIDER"
        value = var.llm_embed_provider
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = local.database_url_secret
            version = "latest"
          }
        }
      }
      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = local.redis_url_secret
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.jwt_secret
            version = "latest"
          }
        }
      }
      env {
        name = "AZURE_OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = local.azure_openai_api_key_secret
            version = "latest"
          }
        }
      }
      env {
        name = "DEEPSEEK_API_KEY"
        value_source {
          secret_key_ref {
            secret  = local.deepseek_api_key_secret
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime_secret_access]
}

resource "google_cloud_run_v2_job" "migrate" {
  name     = "${local.name_prefix}-migrate"
  location = var.region

  template {
    template {
      service_account = google_service_account.runtime.email

      containers {
        image   = local.backend_image
        command = ["alembic"]
        args    = ["upgrade", "head"]

        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = local.database_url_secret
              version = "latest"
            }
          }
        }
        env {
          name = "REDIS_URL"
          value_source {
            secret_key_ref {
              secret  = local.redis_url_secret
              version = "latest"
            }
          }
        }
        env {
          name = "JWT_SECRET"
          value_source {
            secret_key_ref {
              secret  = local.jwt_secret
              version = "latest"
            }
          }
        }
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime_secret_access]
}

resource "google_cloud_run_v2_service" "frontend" {
  name     = "${local.name_prefix}-frontend"
  location = var.region

  template {
    service_account = google_service_account.runtime.email

    containers {
      image = local.frontend_image

      ports {
        container_port = 8080
      }

      env {
        name  = "API_BASE_URL"
        value = google_cloud_run_v2_service.backend.uri
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_backend" {
  name     = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "public_frontend" {
  name     = google_cloud_run_v2_service.frontend.name
  location = google_cloud_run_v2_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
