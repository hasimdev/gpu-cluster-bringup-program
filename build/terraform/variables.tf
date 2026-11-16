variable "region" {
  description = "AWS region. Pick one where your G-instance quota has been approved."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "GPU instance type for worker nodes. g5.xlarge has one NVIDIA A10G."
  type        = string
  default     = "g5.xlarge"
}

variable "node_count" {
  description = "Number of GPU nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 4
    error_message = "node_count must be between 1 and 4 to stay inside the program budget."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH in, e.g. your own IP as x.x.x.x/32. Never 0.0.0.0/0."
  type        = string
}

variable "root_volume_gb" {
  description = "Root disk size. Container images for CUDA and PyTorch are large."
  type        = number
  default     = 150
}

variable "monthly_budget_usd" {
  description = "Budget ceiling for the program. Alerts fire at 50, 80 and 100 percent."
  type        = number
  default     = 300
}

variable "budget_alert_email" {
  description = "Email address that receives budget and auto-stop alerts."
  type        = string
}

variable "idle_stop_minutes" {
  description = "Stop an instance after average CPU stays under 5 percent for this many minutes."
  type        = number
  default     = 60
}
