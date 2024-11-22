resource "auth0_connection" "idp-init-saml" {

  name           = "idp-init-lambda"
  strategy       = "samlp"
  display_name   = "SAML for SSO"
  show_as_button = false

  options {
    debug               = true
    signature_algorithm = "rsa-sha256"
    digest_algorithm    = "sha256"
    sign_saml_request   = true

    set_user_root_attributes = "on_each_login"
    protocol_binding         = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

    signing_cert = tls_self_signed_cert.cert.cert_pem
    issuer = "urn:${var.cf_worker_name}.${var.cf_workers_subdomain}"

    sign_in_endpoint = "https://example.com" // placeholder, we don't really use this

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oauth2"
      client_authorize_query = "response_type=id_token&timeout=30"
    }
  }
}

resource "auth0_client" "jwt-io" {
  name = "JWT.io"

  description     = "JWT.io SPA"
  app_type        = "spa"
  oidc_conformant = true
  is_first_party  = true

  callbacks = [
    "https://jwt.io"
  ]

  allowed_logout_urls = [
    "https://jwt.io"
  ]

  grant_types = [
    "implicit",
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_connection_clients" "saml-clients" {
  connection_id = auth0_connection.idp-init-saml.id
  enabled_clients = [
    auth0_client.jwt-io.client_id
  ]
}