# This configures the firelens sidecar container for the ECS task definition
# We do not want to use this to collect runtime and app/process logs from the EFS volume
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "template_file" "firelens-config" {
  template = file("${path.module}/firelens.conf.tpl")

  vars = {
    aws_region         = data.aws_region.current.name
    bucket_name        = var.logging_bucket_name
    efs_mount_point    = var.container_efs_mount_point
    total_file_size    = var.firelens_total_file_size
    upload_timeout     = var.firelens_upload_timeout
    retry_limit        = var.firelens_retry_limit
    destination_folder = var.firelens_s3_destination_folder
  }
}

data "template_file" "logforwarder-config" {
  template = file("${path.module}/logforwarder.conf.tpl")

  vars = {
    prefix             = var.prefix
    aws_region         = data.aws_region.current.name
    role_arn           = aws_iam_role.role.arn
    bucket_name        = var.logging_bucket_name
    efs_mount_point    = var.container_efs_mount_point
    total_file_size    = var.firelens_total_file_size
    upload_timeout     = var.firelens_upload_timeout
    retry_limit        = var.firelens_retry_limit
    destination_folder = var.firelens_s3_destination_folder
  }
}

data "template_file" "logforwarder-startup-script" {
  template = file("${path.module}/logforwarder-start.json.tpl")

  vars = {
    #file_destination   = "/etc/fluent-bit/fluent.conf"
    flb_config_destination = "/fluent-bit/etc/fluent-bit.conf"
    flb_config_key         = aws_s3_object.logforwarder-config.key
    flb_parser_destination = "/fluent-bit/etc/parsers_multiline.conf"
    flb_parser_key         = aws_s3_object.logforwarder-parser.key
    bucket_name            = aws_s3_object.logforwarder-config.bucket
  }
}

data "template_file" "task-definition-atom" {
  count    = var.molecule_deployment == true ? 0 : 1
  template = file("${path.module}/task-definition-atom.json.tpl")

  vars = {
    aws_region                  = data.aws_region.current.name
    atom_name                   = "atom-${var.prefix}-${data.aws_region.current.name}"
    boomi_account_id            = var.boomi_account_id
    boomi_install_token         = var.boomi_install_token
    container_name              = var.container_name
    ecs_task_cpu                = var.task_definition_cpu
    ecs_task_memory_max         = var.task_definition_memory
    ecs_task_memory_reservation = floor(abs(var.task_definition_memory - var.firelens_ecs_task_memory))
    ecs_task_stop_timeout       = var.task_definition_stop_timeout
    efs_mount_point             = var.container_efs_mount_point
    environment_id              = var.boomi_environment_id
    environment_class           = var.boomi_environment_class
    firelens_ecs_task_memory    = var.firelens_ecs_task_memory
    firelens_ecs_task_cpu       = var.firelens_ecs_task_cpu
    firelens_image_url          = "${var.firelens_container_image_url}:${var.firelens_container_version}"
    firelens_s3_config          = "arn:aws:s3:::${var.logging_bucket_name}/fluent-bit-${var.prefix}.conf"
    healthcheck_interval        = var.healthcheck_interval
    healthcheck_retries         = var.healthcheck_retries
    healthcheck_start_period    = var.healthcheck_start_period
    healthcheck_timeout         = var.healthcheck_timeout
    image_tag                   = var.image_tag
    prefix                      = var.prefix
    repository_url              = var.repository_url
    volume_name                 = local.volume_name
  }
}

data "template_file" "task-definition-molecule" {
  count    = var.molecule_deployment == true ? 1 : 0
  template = file("${path.module}/task-definition-molecule.json.tpl")

  vars = {
    aws_region                  = data.aws_region.current.name
    atom_name                   = "molecule-${var.prefix}-${data.aws_region.current.name}"
    boomi_account_id            = var.boomi_account_id
    boomi_install_token         = var.boomi_install_token
    container_name              = var.container_name
    ecs_task_cpu                = var.task_definition_cpu
    ecs_task_memory_max         = var.task_definition_memory
    ecs_task_memory_reservation = floor(abs(var.task_definition_memory - var.firelens_ecs_task_memory))
    ecs_task_stop_timeout       = var.task_definition_stop_timeout
    efs_mount_point             = var.container_efs_mount_point
    environment_id              = var.boomi_environment_id
    environment_class           = var.boomi_environment_class
    firelens_ecs_task_memory    = var.firelens_ecs_task_memory
    firelens_ecs_task_cpu       = var.firelens_ecs_task_cpu
    firelens_image_url          = "${var.firelens_container_image_url}:${var.firelens_container_version}"
    firelens_s3_config          = "arn:aws:s3:::${var.logging_bucket_name}/fluent-bit-${var.prefix}.conf"
    healthcheck_interval        = var.healthcheck_interval
    healthcheck_retries         = var.healthcheck_retries
    healthcheck_start_period    = var.healthcheck_start_period
    healthcheck_timeout         = var.healthcheck_timeout
    image_tag                   = var.image_tag
    prefix                      = var.prefix
    repository_url              = var.repository_url
    volume_name                 = local.volume_name
  }
}

data "template_file" "log-forwarder-task-definition" {
  template = file("${path.module}/task-definition-log-forwarder.json.tpl")

  vars = {
    aws_region                  = data.aws_region.current.name
    config_volume_name          = "${var.prefix}-fluent-config"
    container_name              = "${var.prefix}-log-forwarder"
    ecs_task_cpu                = var.logforwarder_ecs_task_cpu
    ecs_task_memory_max         = var.logforwarder_ecs_task_memory
    ecs_task_memory_reservation = var.logforwarder_ecs_task_memory - 10
    efs_mount_point             = "/var/log"
    flb_config_path             = "/fluent-bit/etc"
    image_url                   = "public.ecr.aws/aws-observability/aws-for-fluent-bit"
    image_tag                   = "2.32.2"
    prefix                      = var.prefix
    role_arn                    = aws_iam_role.role.arn
    ssm_config_parameter        = aws_ssm_parameter.logforwarder.name
    volume_name                 = local.volume_name
  }
}
