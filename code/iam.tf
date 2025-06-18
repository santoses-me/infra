resource "aws_iam_role" "codecatalyst_deployer" {
  name = "CodeCatalystDeployer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codecatalyst-runner.amazonaws.com",
          "codecatalyst.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": [
            "arn:aws:codecatalyst:::space/e3420072-d71e-40bd-a987-5e4910cc94cd",
            "arn:aws:codecatalyst:::space/e3420072-d71e-40bd-a987-5e4910cc94cd/project/*"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_admin" {
  role       = aws_iam_role.codecatalyst_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

