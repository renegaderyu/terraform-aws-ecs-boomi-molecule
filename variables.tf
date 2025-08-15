variable "prefix" {
  type        = string
  description = "A prefix string will be used to structure the ID/Name of resource "
}

variable "project_name" {
  type        = string
  default     = "boomi"
  description = "Project Name . This is used by the local.common_tags to tag the resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to be added to the resources"
  default     = {}
}

variable "bootstrap_deploy" {
  type        = bool
  default     = false
  description = "A boolean value to determine if this is the initial deployment of atom/molecule. Set to true at first deployment and false for subsequent runs."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID, example vpc-1122334455"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of strings contains the IDs of the private subnets in the vpc"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of strings contains the IDs of the public subnets in the vpc"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "A list of strings contains the CIDR blocks e.g. 10.10.10.0/26 which allowed to access the ALB"
}

variable "allowed_prefix_lists" {
  type        = list(string)
  description = "A list of strings contains the prefix lists e.g. pl-123456 which allowed to access the ALB"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster"
}

variable "molecule_deployment" {
  type        = bool
  default     = false
  description = "A boolean value to determine if the deployment is for molecule or atom."
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  default     = 100
  description = "The minimum healthy percent for the ecs deployment. Only valid for molecule deployments. Atom deployments will always have a minimum healthy percent of 0."
}

variable "deployment_maximum_percent" {
  type        = number
  default     = 200
  description = "The maximum healthy percent for the ecs deployment. Only valid for molecule deployments. Atom deployments will always have a maximum percent of 100."
}

variable "boomi_account_id" {
  type        = string
  description = "The Boomi Account ID"
}

variable "boomi_environment_id" {
  type        = string
  description = "The Boomi environment ID to assocaite with the Atom/Molecule"
}

variable "boomi_environment_class" {
  type        = string
  default     = "Test"
  description = "The Boomi environment class to associate with the Atom/Molecule"
}

variable "boomi_install_token" {
  type        = string
  description = "The Boomi Install Token. This is used to install the Atom/Molecule and is only valid for up to 24hrs."
}

variable "desired_count" {
  type        = number
  description = "The number of instances of the task definition to place and keep running."
}

variable "container_name" {
  type        = string
  description = "The Container Name"
  default     = "atom_node"
}

variable "container_efs_mount_point" {
  type        = string
  default     = "/mnt/boomi"
  description = "The EFS mount point for the container"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = "A list of security group IDs to have access to the container"
}

variable "atom_port" {
  type        = number
  description = "The port number for the Atom which is defaulted to 9090"
  default     = 9090
}

variable "healthcheck_interval" {
  type        = number
  description = "The interval between health checks"
  default     = 10
}

variable "healthcheck_timeout" {
  type        = number
  description = "The timeout for the health check"
  default     = 5
}

variable "healthcheck_retries" {
  type        = number
  description = "The number of retries for the health check"
  default     = 6
}

variable "healthcheck_start_period" {
  type        = number
  description = "The start period for the health check"
  default     = 60
}

variable "task_definition_cpu" {
  type        = number
  description = "CPU for the task definition"
  default     = 256
}

variable "task_definition_memory" {
  type        = number
  description = "Memory for the task definition"
  default     = 512
}

variable "task_definition_stop_timeout" {
  type        = number
  description = "The stop timeout for the task definition."
  default     = 30
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "The image tag used by the ECS Task definition to create Atom Container"
}

variable "repository_url" {
  type        = string
  description = "The URL of the ECR repository"
}

variable "logforwarder_s3_destination_folder" {
  type        = string
  default     = "/application_logs"
  description = "The folder in the S3 bucket where the logs will be stored"
}

variable "logforwarder_total_file_size" {
  type        = string
  default     = "4M"
  description = "The total size of files dropped into the S3 log bucket"
}

variable "logforwarder_upload_timeout" {
  type        = string
  default     = "1m"
  description = "The timeout for the log upload to S3"
}

variable "logforwarder_retry_limit" {
  type        = string
  default     = "2"
  description = "The number of retries for the log upload to S3"
}

variable "logforwarder_ecs_task_cpu" {
  type        = number
  default     = 2048
  description = "CPU for the logforwarder ECS task definition"
}

variable "logforwarder_ecs_task_memory" {
  type        = number
  default     = 2048
  description = "Memory for the logforwarder ECS task definition"
}

variable "logging_bucket_name" {
  type        = string
  description = "The name of the S3 bucket to store the logs"
}

variable "r53_zone_id" {
  type        = string
  description = "The Route53 Zone ID to request the certificate and use for DNS validation"
}

variable "cert_domain" {
  type        = string
  description = "A list of strings contains the Subject Alternative Names (SANs) for the certificate"
}

variable "cert_sans" {
  type        = list(string)
  description = "A list of strings contains the Subject Alternative Names (SANs) for the certificate"
}

variable "efs_encrypted" {
  type        = bool
  default     = true
  description = "A boolean value to determine if the EFS should be encrypted"
}

variable "efs_performance_mode" {
  type        = string
  default     = "generalPurpose"
  description = "The performance mode of the EFS"
}

variable "efs_throughput_mode" {
  type        = string
  default     = "elastic"
  description = "The throughput mode of the EFS"
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  default     = 1
  description = "The provisioned throughput of the EFS. Only valid if throughput mode is set to provisioned"
}

variable "efs_creation_token" {
  type        = string
  default     = null
  description = "The creation token of the EFS. If not set, this will default to $prefix-molecule-fs"
}
