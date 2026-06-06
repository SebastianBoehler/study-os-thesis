output "artifact_registry_repository" {
  description = "Docker repository for app images."
  value       = google_artifact_registry_repository.app.name
}

output "backend_url" {
  description = "Backend Cloud Run URL."
  value       = google_cloud_run_v2_service.backend.uri
}

output "frontend_url" {
  description = "Frontend Cloud Run URL."
  value       = google_cloud_run_v2_service.frontend.uri
}

output "migration_job_name" {
  description = "Cloud Run job that applies Alembic migrations."
  value       = google_cloud_run_v2_job.migrate.name
}
