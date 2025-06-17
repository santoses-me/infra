resource "aws_iam_role" "codecatalyst_deployer" {
  name = "CodeCatalystDeployer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codecatalyst.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_admin" {
  role       = aws_iam_role.codecatalyst_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

