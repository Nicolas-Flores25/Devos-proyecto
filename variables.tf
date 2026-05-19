variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "github_runner_token" {
  description = "GitHub Actions Runner Registration Token"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token for Jenkins Webhook/Auth"
  type        = string
  sensitive   = true
}
