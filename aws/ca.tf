# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.rsa-4096-key.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 11160 # one year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "public-key" {
  content  = tls_private_key.rsa-4096-key.public_key_pem
  filename = "public.pem"
}

resource "local_file" "certificate" {
  content  = tls_self_signed_cert.cert.cert_pem
  filename = "cert.pem"
}

resource "local_file" "private-key" {
  content  = tls_private_key.rsa-4096-key.private_key_pem
  filename = "private.pem"
}