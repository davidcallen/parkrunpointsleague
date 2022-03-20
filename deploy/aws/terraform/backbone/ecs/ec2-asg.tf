resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.environment.resource_name_prefix}-ecs-cluster-asg"
  vpc_zone_identifier       = var.vpc_private_subnet_ids
  launch_configuration      = aws_launch_configuration.ecs.name
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 60
  health_check_type         = "EC2"
  tag {
    key                 = "Name"
    value               = "${var.environment.resource_name_prefix}-ecs-cluster-node"
    propagate_at_launch = true
  }
}
resource "aws_launch_configuration" "ecs" {
  name_prefix          = "${var.environment.resource_name_prefix}-ecs-cluster-node-"
  image_id             = data.aws_ami.ecs-node.id
  iam_instance_profile = aws_iam_instance_profile.ecs_ec2_container_instance.name
  security_groups      = [aws_security_group.ecs.id, aws_security_group.ecs-efs.id]
  # See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
  user_data            = <<EOF
#!/bin/bash
# Standard configuring of /etc/ecs/ecs.config.
#   See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
echo ECS_CLUSTER=${aws_ecs_cluster.ecs.name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config
# Below required for EC2 container instance so can use SSM Params for Secrets.
echo ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true >> /etc/ecs/ecs.config
echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
# Install Cloudwatch agent
yum install -y amazon-cloudwatch-agent
cat > /etc/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.d/ecs-container-instance.json <<ENDJSON
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "system",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%b %-d %H:%M:%S"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "cloud-init",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "cloud-init-output",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y%m%d %H:%M:%S"
          },
          {
            "file_path": "/var/log/ecs/audit.log",
            "log_group_name": "ecs-container-instance-audit",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "ecs-container-instance-agent",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/ecs/ecs-init.log",
            "log_group_name": "ecs-container-instance-init",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/ecs/ecs-volume-plugin.log",
            "log_group_name": "ecs-container-instance-volume-plugin",
            "log_stream_name": "{local_hostname}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          }
        ]
      }
    }
  }
}
ENDJSON
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
EOF
  instance_type        = "t3a.small"
  key_name             = var.cluster_node_ssh_key_name
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for Amazon Linux 2 ECS Container Instance
#     See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
#     Source code here : https://github.com/aws/amazon-ecs-ami
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "ecs-node" {
  most_recent       = true
  filter {
    name            = "name"
    values          = ["amzn2-ami-ecs-hvm-*"]
  }
  filter {
    name            = "virtualization-type"
    values          = ["hvm"]
  }
  owners            = ["591542846629"] # Amazon
}