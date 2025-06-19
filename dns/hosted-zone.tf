resource "aws_route53_zone" "hosted_zone" {
  name = "${terraform.workspace}.${local.domain}"
}