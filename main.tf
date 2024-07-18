terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.35"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2"
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    { project_name = var.project_name },
    var.tags
  )
  volume_name = "${var.prefix}-molecule-storage"
}

resource "aws_s3_object" "firelens-config" {
  bucket  = var.logging_bucket_name
  key     = "fluent-bit-${var.prefix}.conf"
  content = data.template_file.firelens-config.rendered
}

resource "aws_ssm_parameter" "logforwarder" {
  name  = "/${var.prefix}/logforwarder-start-config"
  type  = "String"
  value = data.template_file.logforwarder-startup-script.rendered
}

resource "aws_s3_object" "logforwarder-config" {
  bucket  = var.logging_bucket_name
  key     = "logforwarder-${var.prefix}.conf"
  content = data.template_file.logforwarder-config.rendered
}

resource "aws_s3_object" "logforwarder-parser" {
  bucket = var.logging_bucket_name
  key    = "logforwarder-parser-${var.prefix}.conf"
  source = "${path.module}/logforwarder-parser.conf"
  etag   = filemd5("${path.module}/logforwarder-parser.conf")
}

resource "aws_security_group" "svc" {
  name        = "${var.prefix}-svc-sg"
  description = "${var.prefix} ECS service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.prefix}-svc-sg"
    },
  )
}

# https://help.boomi.com/bundle/integration/page/c-atm-Cluster_monitoring_for_Molecules_and_Atom_Clouds.html
# https://community.boomi.com/s/article/moleculesetupformulticastbydefaultisnotclusteringcommunicatingwithothermoleculenodesproblemmultipleheadnodes
resource "aws_security_group_rule" "allow_multicast_between_nodes" {
  self              = true
  description       = "Allow MULTICAST clustering between nodes"
  security_group_id = aws_security_group.svc.id
  type              = "ingress"
  protocol          = "UDP"
  from_port         = 45588
  to_port           = 45588
}

# https://help.boomi.com/bundle/integration/page/t-atm-Setting_up_unicast_support.html
resource "aws_security_group_rule" "allow_unicast_between_nodes" {
  self              = true
  description       = "Allow UNICAST clustering between nodes"
  security_group_id = aws_security_group.svc.id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 7800
  to_port           = 7800
}

resource "aws_security_group_rule" "allow_alb" {
  description              = "Allow Traffic from ALB"
  security_group_id        = aws_security_group.svc.id
  source_security_group_id = aws_security_group.alb.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = var.atom_port
  to_port                  = var.atom_port
}


resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg"
  description = "${var.prefix} Load balancer security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.prefix}-alb-sg"
    },
  )
}

resource "aws_security_group_rule" "allow_security_groups" {
  count                    = length(var.allowed_security_group_ids)
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  type                     = "ingress"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_security_group_rule" "allow_cidr_blocks" {
  count             = length(var.allowed_cidr_blocks) == 0 ? 0 : 1
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = var.allowed_cidr_blocks
}

resource "aws_security_group" "efs" {
  name        = "${var.prefix}-efs-sg"
  description = "${var.prefix} EFS service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.prefix}-efs-sg"
    },
  )
}

resource "aws_security_group_rule" "allow_svc_to_efs" {
  description              = "Allow Traffic from Service nodes to EFS"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.svc.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
}

resource "aws_security_group_rule" "allow_sgs_to_efs" {
  count             = length(var.allowed_cidr_blocks) == 0 ? 0 : 1
  description       = "Allow cidr blocks to EFS"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = var.allowed_cidr_blocks
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 2049
  to_port           = 2049
}

resource "aws_efs_file_system" "this" {
  creation_token = "${var.prefix}-molecule-fs"

  encrypted        = false
  throughput_mode  = "bursting"
  performance_mode = "maxIO"

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.prefix}-molecule-fs"
    }
  )
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
}

resource "aws_efs_mount_target" "this" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.efs.json
}

data "aws_iam_policy_document" "efs" {
  statement {

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]

    resources = [
      aws_efs_file_system.this.arn
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "true"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        aws_efs_access_point.this.arn
      ]
    }
  }
}

resource "aws_ecs_service" "this" {
  name            = var.prefix
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "EC2"

  # Ignore the variable overrides for atom deployments, which should only have 1 task running at a time
  desired_count                      = var.molecule_deployment ? var.desired_count : 1
  deployment_minimum_healthy_percent = var.molecule_deployment ? var.deployment_minimum_healthy_percent : 0
  deployment_maximum_percent         = var.molecule_deployment ? var.deployment_maximum_percent : 100

  network_configuration {
    security_groups = [
      aws_security_group.svc.id,
    ]
    subnets = var.private_subnet_ids
  }

}

resource "aws_ecs_task_definition" "this" {
  family                   = var.prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  task_role_arn            = aws_iam_role.role.arn
  execution_role_arn       = aws_iam_role.role.arn

  container_definitions = var.molecule_deployment ? data.template_file.task-definition-molecule[0].rendered : data.template_file.task-definition-atom[0].rendered

  volume {
    name = local.volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.this.id
      root_directory = "/"

      transit_encryption = "ENABLED"
      # Disable the transit encryption port for now as it was causing task launch failures
      # Let ECS determine the port automatically
      #transit_encryption_port = 2999

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.prefix
  description        = "${var.prefix} Role"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  force_detach_policies = true
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "policy" {
  path        = "/"
  description = "${var.prefix} Policy"
  policy      = data.aws_iam_policy_document.policy.json
  name        = var.prefix
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutMultiPartUpload",
      "s3:abortMultipartUpload",
    ]

    resources = [
      "arn:aws:s3:::${var.logging_bucket_name}/*",
      "arn:aws:s3:::${var.logging_bucket_name}",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/*",
    ]
  }

}

resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.role.id
  policy_arn = aws_iam_policy.policy.arn
}


resource "aws_ecs_service" "log-forwarder" {
  name            = "${var.prefix}-log-forwarder"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.log-forwarder.arn
  launch_type     = "EC2"

  # Ignore the variable overrides for atom deployments, which should only have 1 task running at a time
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets = var.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "log-forwarder" {
  family                   = "${var.prefix}-log-forwarder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.role.arn
  execution_role_arn       = aws_iam_role.role.arn

  container_definitions = data.template_file.log-forwarder-task-definition.rendered

  volume {
    name = local.volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.this.id
      root_directory = "/"

      transit_encryption = "ENABLED"
      # Disable the transit encryption port for now as it was causing task launch failures
      # Let ECS determine the port automatically
      #transit_encryption_port = 2999

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "${var.prefix}-fluent-config"
    docker_volume_configuration {
      scope  = "task"
      driver = "local"
    }
  }
}
