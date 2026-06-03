# --- ACM Private Certificate Authority ---

resource "aws_acmpca_certificate_authority" "main" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"
    subject {
      common_name  = var.domain_name
      organization = var.project
    }
  }

  tags = local.common_tags
}

# Self-sign the root CA certificate
resource "aws_acmpca_certificate" "root" {
  certificate_authority_arn = aws_acmpca_certificate_authority.main.arn
  signing_algorithm         = "SHA256WITHRSA"
  template_arn              = "arn:aws:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 10
  }
}

resource "aws_acmpca_certificate_authority_certificate" "root" {
  certificate_authority_arn = aws_acmpca_certificate_authority.main.arn
  certificate              = aws_acmpca_certificate.root.certificate
  certificate_chain        = aws_acmpca_certificate.root.certificate_chain
}

# --- ACM Certificate for kubestuff.hakerie.fyi ---

resource "aws_acm_certificate" "api" {
  domain_name               = var.api_subdomain
  certificate_authority_arn = aws_acmpca_certificate_authority.main.arn

  tags = local.common_tags

  depends_on = [aws_acmpca_certificate_authority_certificate.root]
}

# --- Route 53 Hosted Zone ---

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = local.common_tags
}

# --- DNS Record (points to ALB created by ingress controller) ---

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.api_subdomain
  type    = "CNAME"
  ttl     = 300
  records = ["placeholder-alb.us-east-1.elb.amazonaws.com"]

  lifecycle {
    ignore_changes = [records]
  }
}
