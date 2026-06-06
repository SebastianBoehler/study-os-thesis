variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "europe-west3"
}

variable "environment" {
  description = "Deployment environment name, for example staging or prod."
  type        = string
}

variable "image_tag" {
  description = "Container image tag to deploy."
  type        = string
  default     = "latest"
}

variable "jwt_secret" {
  description = "Secret Manager secret name containing JWT_SECRET."
  type        = string
  default     = ""
}

variable "database_url_secret" {
  description = "Secret Manager secret name containing DATABASE_URL."
  type        = string
  default     = ""
}

variable "redis_url_secret" {
  description = "Secret Manager secret name containing REDIS_URL."
  type        = string
  default     = ""
}

variable "azure_openai_api_key_secret" {
  description = "Secret Manager secret name containing AZURE_OPENAI_API_KEY."
  type        = string
  default     = ""
}

variable "deepseek_api_key_secret" {
  description = "Secret Manager secret name containing DEEPSEEK_API_KEY."
  type        = string
  default     = ""
}

variable "llm_chat_provider" {
  description = "Chat provider: ollama, azure, or deepseek."
  type        = string
  default     = "deepseek"
}

variable "llm_embed_provider" {
  description = "Embedding provider: ollama or azure."
  type        = string
  default     = "azure"
}

variable "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint."
  type        = string
  default     = ""
}

variable "azure_chat_deployment" {
  description = "Azure OpenAI chat deployment name."
  type        = string
  default     = ""
}

variable "azure_embed_deployment" {
  description = "Azure OpenAI embedding deployment name."
  type        = string
  default     = ""
}

variable "deepseek_base_url" {
  description = "DeepSeek base URL."
  type        = string
  default     = "https://api.deepseek.com"
}

variable "deepseek_chat_model" {
  description = "DeepSeek chat model."
  type        = string
  default     = "deepseek-chat"
}

variable "cors_origins" {
  description = "Comma-separated CORS origins. If blank, Terraform uses frontend_origin."
  type        = string
  default     = ""
}

variable "frontend_origin" {
  description = "Public frontend origin for CORS before custom domains are attached."
  type        = string
  default     = "*"
}
