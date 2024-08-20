## Overview 

This is a terraform module to deploy a Boomi Atom/Molecule on an existing AWS ECS::EC2 cluster.

There are other "full solutions" that exist such as [obytes/terraform-aws-ecs-boomi](https://github.com/obytes/terraform-aws-ecs-boomi) and [aws-ia/cfn-ps-boomi-molecule](https://github.com/aws-ia/cfn-ps-boomi-molecule). While those solutions are good for immediate deployment they are not as flexible as this module. This module allows you to deploy the Boomi Atom/Molecule on an existing ECS::EC2 cluster. It also omits a bastion deployment and configures logging to an S3 bucket from a secondary logforwarding service deployed.

### What this module does

- Deploys a Boomi Atom/Molecule on an existing ECS::EC2 cluster as a service
    - Creates and configures an EFS mount point for the Atom/Molecule to store data
    - Configures a firelens container to forward stdout/stderr logs to the S3 bucket (`logging_bucket_name`)
- Creates and configures a secondary logforwarding service based on fluent-bit
    - Creates configuration files in the S3 bucket (`logging_bucket_name`) for the logforwarding service
    - logforwading service mounts the EFS volume and tails the runtime and app/process logs to the S3 bucket

#### References

- [Boomi Atom/Molecule Installation on AWS::ECS](https://community.boomi.com/s/article/integration-runtime-installation-molecule-on-aws-ecs)
- [Consuming Process Logs](https://community.boomi.com/s/article/Consume-Process-Logs-with-Fluentd)

## Usage

1. Create the ECR repository for the Boomi Atom/Molecule
2. Build and push the docker conatiner to the ECR repository
```bash
# Build atom container
docker build -t boomi-atom:latest .
# Build molecule container
docker build --build-arg="DEPLOY_TYPE=molecule" -t boomi-molecule:latest .
```
3. Deploy the Boomi Atom/Molecule using this module.
    - This module defaults to deploying an Atom so if deploying a molecule set the `molecule_deployment` variable to `true`.
    - You need to first bootstrap the deployment by setting the `bootstrap_deploy` variable to `true`. After the initial deployment is sucessful, set `bootstrap_deploy` to `false` and re-run terraform to scale out and finish creating the logforwarding service.


### For Boomi Atom Deployment
```hcl
module "boomi_atom_service" {
  source                     = "git::https://github.com/renegaderyu/terraform-aws-ecs-boomi-molecule.git?ref=main"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnets
  allowed_cidr_blocks        = [trusted_cidr_block1, trusted_cidr_block2]
  ecs_cluster_name           = "your-ecs-cluster-name"
  desired_count              = 1
  task_definition_cpu        = 4096
  task_definition_memory     = 15657
  allowed_security_group_ids = [aws_security_group.trusted-sources.id]
  prefix                     = "boomi-dev"
  repository_url             = aws_ecr_repository.boomi-atom.repository_url
  logging_bucket_name        = aws_s3_bucket.logs.id
  container_name             = "boomi-atom"
  boomi_account_id           = "your-boomi-account-id"
  boomi_environment_id       = "your-boomi-environment-id"
  boomi_install_token        = "your-boomi-install-token"
}
```

### For Boomi Molecule Deployment
```hcl
module "boomi_molecule_service" {
  source                     = "git::https://github.com/renegaderyu/terraform-aws-ecs-boomi-molecule.git?ref=main"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnets
  allowed_cidr_blocks        = [trusted_cidr_block1, trusted_cidr_block2]
  ecs_cluster_name           = "your-ecs-cluster-name"
  desired_count              = length(module.vpc.private_subnets)
  task_definition_cpu        = 4096
  task_definition_memory     = 15657
  allowed_security_group_ids = [aws_security_group.trusted-sources.id]
  prefix                     = "boomi-dev"
  repository_url             = aws_ecr_repository.boomi-molecule.repository_url
  logging_bucket_name        = aws_s3_bucket.logs.id
  container_name             = "boomi-molecule"
  boomi_account_id           = "your-boomi-account-id"
  boomi_environment_id       = "your-boomi-environment-id"
  boomi_install_token        = "your-boomi-install-token"
  molecule_deployment        = true
  bootstrap_deploy           = true # This can be set to false after the initial deployment
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.35 |
| <a name="requirement_template"></a> [template](#requirement\_template) | >= 2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.35 |
| <a name="provider_template"></a> [template](#provider\_template) | >= 2.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_alb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb) | resource |
| [aws_alb_listener.front_end_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener) | resource |
| [aws_alb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) | resource |
| [aws_ecs_service.log-forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.log-forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_efs_access_point.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_file_system_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system_policy) | resource |
| [aws_efs_mount_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_object.firelens-config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.logforwarder-config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.logforwarder-parser](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.svc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_api_between_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_multicast_between_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_sgs_to_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_svc_to_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_unicast_between_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.logforwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.firelens-config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.log-forwarder-task-definition](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.logforwarder-config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.logforwarder-startup-script](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.task-definition-atom](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.task-definition-molecule](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | A list of strings contains the CIDR blocks e.g. 10.10.10.0/26 which allowed to access the ALB | `list(string)` | n/a | yes |
| <a name="input_allowed_security_group_ids"></a> [allowed\_security\_group\_ids](#input\_allowed\_security\_group\_ids) | A list of security group IDs to have access to the container | `list(string)` | `[]` | no |
| <a name="input_atom_port"></a> [atom\_port](#input\_atom\_port) | The port number for the Atom which is defaulted to 9090 | `number` | `9090` | no |
| <a name="input_boomi_account_id"></a> [boomi\_account\_id](#input\_boomi\_account\_id) | The Boomi Account ID | `string` | n/a | yes |
| <a name="input_boomi_environment_class"></a> [boomi\_environment\_class](#input\_boomi\_environment\_class) | The Boomi environment class to associate with the Atom/Molecule | `string` | `"Test"` | no |
| <a name="input_boomi_environment_id"></a> [boomi\_environment\_id](#input\_boomi\_environment\_id) | The Boomi environment ID to assocaite with the Atom/Molecule | `string` | n/a | yes |
| <a name="input_boomi_install_token"></a> [boomi\_install\_token](#input\_boomi\_install\_token) | The Boomi Install Token. This is used to install the Atom/Molecule and is only valid for up to 24hrs. | `string` | n/a | yes |
| <a name="input_bootstrap_deploy"></a> [bootstrap\_deploy](#input\_bootstrap\_deploy) | A boolean value to determine if this is the initial deployment of atom/molecule. Set to true at first deployment and false for subsequent runs. | `bool` | `false` | no |
| <a name="input_cert_domain"></a> [cert\_domain](#input\_cert\_domain) | A list of strings contains the Subject Alternative Names (SANs) for the certificate | `string` | n/a | yes |
| <a name="input_cert_sans"></a> [cert\_sans](#input\_cert\_sans) | A list of strings contains the Subject Alternative Names (SANs) for the certificate | `list(string)` | n/a | yes |
| <a name="input_container_efs_mount_point"></a> [container\_efs\_mount\_point](#input\_container\_efs\_mount\_point) | The EFS mount point for the container | `string` | `"/mnt/boomi"` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | The Container Name | `string` | `"atom_node"` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | The maximum healthy percent for the ecs deployment. Only valid for molecule deployments. Atom deployments will always have a maximum percent of 100. | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | The minimum healthy percent for the ecs deployment. Only valid for molecule deployments. Atom deployments will always have a minimum healthy percent of 0. | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of instances of the task definition to place and keep running. | `number` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | The name of the ECS cluster | `string` | n/a | yes |
| <a name="input_firelens_container_image_url"></a> [firelens\_container\_image\_url](#input\_firelens\_container\_image\_url) | Docker image URL for the firelens container | `string` | `"amazon/aws-for-fluent-bit"` | no |
| <a name="input_firelens_container_version"></a> [firelens\_container\_version](#input\_firelens\_container\_version) | Docker image tag for the firelens container | `string` | `"latest"` | no |
| <a name="input_firelens_ecs_task_cpu"></a> [firelens\_ecs\_task\_cpu](#input\_firelens\_ecs\_task\_cpu) | CPU for the firelens ECS task definition | `number` | `0` | no |
| <a name="input_firelens_ecs_task_memory"></a> [firelens\_ecs\_task\_memory](#input\_firelens\_ecs\_task\_memory) | Memory for the firelens ECS task definition | `number` | `50` | no |
| <a name="input_firelens_retry_limit"></a> [firelens\_retry\_limit](#input\_firelens\_retry\_limit) | The number of retries for the log upload to S3 | `string` | `"2"` | no |
| <a name="input_firelens_s3_destination_folder"></a> [firelens\_s3\_destination\_folder](#input\_firelens\_s3\_destination\_folder) | The folder in the S3 bucket where the logs will be stored | `string` | `"/application_logs"` | no |
| <a name="input_firelens_total_file_size"></a> [firelens\_total\_file\_size](#input\_firelens\_total\_file\_size) | The total size of files dropped into the S3 log bucket | `string` | `"8M"` | no |
| <a name="input_firelens_upload_timeout"></a> [firelens\_upload\_timeout](#input\_firelens\_upload\_timeout) | The timeout for the log upload to S3 | `string` | `"1m"` | no |
| <a name="input_healthcheck_interval"></a> [healthcheck\_interval](#input\_healthcheck\_interval) | The interval between health checks | `number` | `10` | no |
| <a name="input_healthcheck_retries"></a> [healthcheck\_retries](#input\_healthcheck\_retries) | The number of retries for the health check | `number` | `6` | no |
| <a name="input_healthcheck_start_period"></a> [healthcheck\_start\_period](#input\_healthcheck\_start\_period) | The start period for the health check | `number` | `60` | no |
| <a name="input_healthcheck_timeout"></a> [healthcheck\_timeout](#input\_healthcheck\_timeout) | The timeout for the health check | `number` | `5` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The image tag used by the ECS Task definition to create Atom Container | `string` | `"latest"` | no |
| <a name="input_logforwarder_ecs_task_cpu"></a> [logforwarder\_ecs\_task\_cpu](#input\_logforwarder\_ecs\_task\_cpu) | CPU for the logforwarder ECS task definition | `number` | `0` | no |
| <a name="input_logforwarder_ecs_task_memory"></a> [logforwarder\_ecs\_task\_memory](#input\_logforwarder\_ecs\_task\_memory) | Memory for the logforwarder ECS task definition | `number` | `50` | no |
| <a name="input_logging_bucket_name"></a> [logging\_bucket\_name](#input\_logging\_bucket\_name) | The name of the S3 bucket to store the logs | `string` | n/a | yes |
| <a name="input_molecule_deployment"></a> [molecule\_deployment](#input\_molecule\_deployment) | A boolean value to determine if the deployment is for molecule or atom. | `bool` | `false` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix string will be used to structure the ID/Name of resource | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | A list of strings contains the IDs of the private subnets in the vpc | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project Name . This is used by the local.common\_tags to tag the resources | `string` | `"boomi"` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | A list of strings contains the IDs of the public subnets in the vpc | `list(string)` | n/a | yes |
| <a name="input_r53_zone_id"></a> [r53\_zone\_id](#input\_r53\_zone\_id) | The Route53 Zone ID to request the certificate and use for DNS validation | `string` | n/a | yes |
| <a name="input_repository_url"></a> [repository\_url](#input\_repository\_url) | The URL of the ECR repository | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to be added to the resources | `map(string)` | `{}` | no |
| <a name="input_task_definition_cpu"></a> [task\_definition\_cpu](#input\_task\_definition\_cpu) | CPU for the task definition | `number` | `256` | no |
| <a name="input_task_definition_memory"></a> [task\_definition\_memory](#input\_task\_definition\_memory) | Memory for the task definition | `number` | `512` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID, example vpc-1122334455 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | n/a |
| <a name="output_aws_efs_access_point"></a> [aws\_efs\_access\_point](#output\_aws\_efs\_access\_point) | n/a |
| <a name="output_file_system_id"></a> [file\_system\_id](#output\_file\_system\_id) | n/a |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | n/a |
| <a name="output_task_security_group_id"></a> [task\_security\_group\_id](#output\_task\_security\_group\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
