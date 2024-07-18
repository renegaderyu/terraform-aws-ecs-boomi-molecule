[
  {
    "image": "${repository_url}:${image_tag}",
    "name": "${container_name}",
    "networkMode": "awsvpc",
    "entryPoint": ["entrypoint.sh"],
    "command": ["init"],
    "privileged": false,
    "essential": true,
    "cpu": ${ecs_task_cpu},
    "cpuArchitecture": "x86_64",
    "memory": ${ecs_task_memory_max},
    "memoryReservation": ${ecs_task_memory_reservation},
    "user": "1000:1000",
    "pseudoTerminal": true,
    "interactive": true,
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {}
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:9090/_admin/liveness || exit 1"],
      "interval": ${healthcheck_interval},
      "timeout": ${healthcheck_timeout},
      "retries": ${healthcheck_retries},
      "startPeriod": ${healthcheck_start_period}
    },
    "systemControls": [],
    "volumesFrom": [],
    "environment": [
      {
        "name": "INSTALL_TOKEN",
        "value": "${boomi_install_token}"
      },
      {
        "name": "ATOM_VMOPTIONS_OVERRIDES",
        "value": "-Xmx${ecs_task_memory_reservation}m|-Dfile.encoding=UTF-8"
      },
      {
        "name": "BOOMI_ACCOUNTID",
        "value": "${boomi_account_id}"
      },
      {
        "name": "BOOMI_ATOMNAME",
        "value": "${atom_name}"
      },
      {
        "name": "BOOMI_ENVIRONMENT_ID",
        "value": "${environment_id}"
      },
      {
        "name": "BOOMI_ENVIRONMENT_CLASS",
        "value": "${environment_class}"
      },
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${aws_region}"
      },
      {
        "name": "KUBERNETES_SERVICE_HOST",
        "value": "TRUE"
      }
    ],
    "portMappings": [
      {
        "name": "boomi_molecule-9090-tcp",
        "protocol": "tcp",
        "containerPort": 9090,
        "hostPort": 9090,
        "appProtocol": "http"
      }
    ],
    "linuxParameters": {
      "tmpfs": [
        {
          "containerPath": "/tmp",
          "size": 128,
          "mountOptions": [
            "rw",
            "exec"
          ]
        },
        {
          "containerPath": "/run",
          "size": 128
        }
      ]
    },
    "mountPoints": [
        {
            "containerPath": "${efs_mount_point}",
            "sourceVolume": "${volume_name}",
            "readOnly": false
        }
    ],
    "dockerLabels":
      {
        "ContainerName":"${container_name}"
      }
  },
  {
    "name": "${prefix}_log_router",
    "image": "${firelens_image_url}",
    "firelensConfiguration": {
      "type": "fluentbit",
      "options": {
        "config-file-type": "s3",
        "config-file-value": "${firelens_s3_config}",
        "enable-ecs-log-metadata": "true"
      }
    },
    "cpu": ${firelens_ecs_task_cpu},
    "systemControls": [],
    "volumesFrom": [],
    "portMappings": [],
    "user": "0",
    "environment": [
      {
        "name": "APP_NAME",
        "value": "${prefix}"
      }
    ],
    "mountPoints": [
        {
            "containerPath": "${efs_mount_point}",
            "sourceVolume": "${volume_name}"
        }
    ],
    "essential": true,
    "privileged": false,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "firelens-container",
        "awslogs-region": "${aws_region}",
        "awslogs-create-group": "true",
        "awslogs-stream-prefix": "${prefix}-firelens"
      }
    },
    "memoryReservation": ${firelens_ecs_task_memory},
    "dockerLabels":
      {
        "name":"${prefix}_log_router"
      }
  }
]
