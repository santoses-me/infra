resource "aws_ses_domain_identity" "ses_domain" {
  domain = local.domain
}

resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.ses_domain.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.ses_domain.verification_token]
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.ses_domain.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.ses_domain.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = local.domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "_dmarc.${local.domain}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=none; rua=mailto:postmaster@${local.domain}"]
}

resource "aws_route53_record" "workmail_mx" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = local.domain
  type    = "MX"
  ttl     = 300
  records = ["10 inbound-smtp.${local.region}.amazonaws.com"]
}

resource "aws_ses_domain_mail_from" "mail_from" {
  domain                 = aws_ses_domain_identity.ses_domain.domain
  mail_from_domain       = "bounce.vadev.santoses.me"
  behavior_on_mx_failure = "UseDefaultValue"
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = aws_ses_domain_mail_from.mail_from.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${local.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = aws_ses_domain_mail_from.mail_from.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}
