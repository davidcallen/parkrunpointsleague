# ---------------------------------------------------------------------------------------------------------------------
# ECS Container Instance (on EC2)
# 1) Grant Service Role AmazonEC2ContainerServiceforEC2Role
# 2) Grant logging to CloudWatch
# 3) Grant access to the Tasks Secrets in SSM ParameterStore
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs-ec2-container-instance" {
  name               =  "${var.environment.resource_name_prefix}-ecs-ec2-container-instance"
  assume_role_policy = data.aws_iam_policy_document.ecs-ec2-container-instance.json
}

# 1) Grant Service Role AmazonEC2ContainerServiceforEC2Role
data "aws_iam_policy_document" "ecs-ec2-container-instance" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "ecs-ec2-container-instance" {
  role       = aws_iam_role.ecs-ec2-container-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# 2) Grant logging to CloudWatch
resource "aws_iam_policy" "ecs-ec2-container-instance-cloudwatch" {
  name        = "${var.environment.resource_name_prefix}-ecs-ec2-container-instance-cloudwatch"
  description = "Allow ECS EC2 Container Instance to write its logs to Cloudwatch"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ecs-ec2-container-instance-cloudwatch" {
  role      = aws_iam_role.ecs-ec2-container-instance.name
  policy_arn = aws_iam_policy.ecs-ec2-container-instance-cloudwatch.arn
}

# 3) Grant access to the Tasks Secrets in SSM ParameterStore
resource "aws_iam_policy" "ecs-ec2-container-instance-ssm" {
  name        = "${var.environment.resource_name_prefix}-ecs-ec2-container-instance-ssm"
  description = "Allow ECS Agent to read SSM Parameter values for Secrets"
  policy      = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "ssm:DescribeParameters"
           ],
           "Resource": "*"
       },
       {
           "Sid": "AllowSSMGetParams",
           "Effect": "Allow",
           "Action": [
               "ssm:GetParameters"
           ],
           "Resource": [
              "arn:aws:ssm:eu-west-1:597767386394:parameter/prpl/database/admin/prpl/password",
              "arn:aws:ssm:eu-west-1:597767386394:parameter/prpl/database/user/prpl/password"
           ]
       },
       {
           "Sid": "AllowSSMDecryptParams",
           "Effect": "Allow",
           "Action": [
               "kms:Decrypt"
           ],
           "Resource": [
              "arn:aws:ssm:eu-west-1:597767386394:parameter/prpl/database/admin/prpl/password",
              "arn:aws:ssm:eu-west-1:597767386394:parameter/prpl/database/user/prpl/password"
           ]
       }
   ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ecs-ec2-container-instance-ssm" {
  role       = aws_iam_role.ecs-ec2-container-instance.name
  policy_arn = aws_iam_policy.ecs-ec2-container-instance-ssm.arn
}

resource "aws_iam_instance_profile" "ecs_ec2_container_instance" {
  name =  "${var.environment.resource_name_prefix}-ecs-cluster-agent"
  role = aws_iam_role.ecs-ec2-container-instance.name
}


# ---------------------------------------------------------------------------------------------------------------------
# ECS Container Agent  (as used on Task Execution role) - may need to create a Task specific role e.g. for get SSM Params
# 1) Grant Service Role AmazonECSTaskExecutionRolePolicy
# 2) Grant logging to CloudWatch
# 3) Grant access to the Tasks Secrets in SSM ParameterStore
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs-container-agent" {
  name               =  "${var.environment.resource_name_prefix}-ecs-container-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs-container-agent.json
}

# 1) Grant Service Role AmazonECSTaskExecutionRolePolicy
data "aws_iam_policy_document" "ecs-container-agent" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "ecs-container-agent" {
  role       = aws_iam_role.ecs-container-agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2) Grant logging to CloudWatch
resource "aws_iam_policy" "ecs-container-agent-cloudwatch" {
  name        = "${var.environment.resource_name_prefix}-ecs-container-agent-cloudwatch"
  description = "Allow ECS Container Agent to write its logs to Cloudwatch"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ecs-container-agent-cloudwatch" {
  role       = aws_iam_role.ecs-container-agent.name
  policy_arn = aws_iam_policy.ecs-container-agent-cloudwatch.arn
}
