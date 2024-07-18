[
  {
    "name": "${container_name}-config",
    "image": "public.ecr.aws/compose-x/ecs-files-composer:latest",
    "command": ["--from-ssm", "${ssm_config_parameter}", "--role-arn", "${role_arn}", "--print-generated-config"],
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${aws_region}"
      }
    ],
    "mountPoints": [
        {
            "containerPath": "${flb_config_path}",
            "sourceVolume": "${config_volume_name}",
            "readOnly": false
        }
    ],
    "systemControls": [],
    "volumesFrom": [],
    "portMappings": [],
    "essential": false,
    "cpu": 0,
    "cpuArchitecture": "x86_64",
    "memoryReservation": 10,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/logs/${prefix}/${container_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "${container_name}-config",
        "awslogs-create-group": "true"
      }
    },
    "dockerLabels":
      {
        "name":"${container_name}-config"
      }
  },
  {
    "image": "${image_url}:${image_tag}",
    "name": "${container_name}",
    "networkMode": "awsvpc",
    "privileged": false,
    "essential": true,
    "dependsOn": [
      {
        "containerName": "${container_name}-config",
        "condition": "SUCCESS"
      }
    ],
    "cpu": ${ecs_task_cpu},
    "cpuArchitecture": "x86_64",
    "memory": ${ecs_task_memory_max},
    "memoryReservation": ${ecs_task_memory_reservation},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/logs/${prefix}/${container_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "${container_name}"
      }
    },
    "systemControls": [],
    "volumesFrom": [],
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${aws_region}"
      }
    ],
    "portMappings": [],
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
        },
        {
            "containerPath": "${flb_config_path}",
            "sourceVolume": "${config_volume_name}",
            "readOnly": true
        }
    ],
    "dockerLabels":
      {
        "ContainerName":"${container_name}"
      }
  }
]
