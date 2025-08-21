############################################
# Minimal IAM for SSM
############################################
resource "aws_iam_role" "bastion" {
  name               = "${var.bastion_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-profile"
  role = aws_iam_role.bastion.name
}

############################################
# EC2 – no public IP, no KMS, tiny gp3 root
############################################
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t4g.nano"
  subnet_id                   = module.vpc.private_subnet_objects[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.bastion.name

  # Enforce IMDSv2; cheap monitoring
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  monitoring = false

  # Ubuntu often includes SSM agent; ensure it's present & updated
  user_data = <<BASH
#!/bin/bash
set -euxo pipefail
apt-get update -y
apt-get install -y snapd jq
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service || true
# optional client tools
apt-get install -y mysql-client
BASH

  # Root volume: smallest practical, NO KMS encryption
  root_block_device {
  volume_size = 8
  volume_type = "gp3"
  encrypted   = false           # relies on account setting; if default encryption is enforced, AWS may still encrypt
  delete_on_termination = true
  }

  tags = merge(local.tags, { name = var.name })
}