locals {
  # Extracting the URL for registering the SHA256 value.
  version_output = jsondecode(data.http.version.response_body)
  shasums_upload_url = local.version_output.data.links["shasums-upload"]
  shasums_sig_upload_url = local.version_output.data.links["shasums-sig-upload"]
}

resource "local_file" "provider_json" {
    filename = "${path.module}/provider.json"
    content = <<EOF
{
  "data": {
    "type": "registry-providers",
    "attributes": {
      "name": "${var.provider_name}",
      "namespace": "${var.organization_name}",
      "registry-name": "private"
    }
  }
}
EOF
}

resource "local_file" "version_json" {
  filename = "${path.module}/version.json"
  content = <<EOF
{
  "data": {
    "type": "registry-provider-versions",
    "attributes": {
      "version": "${var.provider_version}",
      "key-id": "34365D9472D7468F",
      "protocols": ["5.0"]
    }
  }
}
EOF
}

resource "local_file" "sha256_json" {
  filename = "${path.module}/provider_sha256"
  content = <<EOF
${var.provider_sha256_value}
EOF
}

resource "local_file" "sha256sig_json" {
  filename = "${path.module}/provider_sha256.sig"
  content = <<EOF
${var.provider_sha256_sig_value}
EOF
}

resource "local_file" "file_json" {
  filename = "${path.module}/file.json"
  content = <<EOF
{
  "data": {
    "type": "registry-provider-version-platforms",
    "attributes": {
      "os": "linux",
      "arch": "amd64",
      "shasum": ${var.provider_binary_shasum},
      "filename": ${var.provider_binary_name}
    }
  }
}
EOF
}

data "http" "provider" {
  url    = "https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers"
  method = "POST"

  request_body = local_file.provider_json.content

  request_headers = {
    Authorization = "Bearer ${var.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

data "http" "version" {
  url    = "https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers/private/${var.organization_name}/${var.provider_name}/versions"
  method = "POST"

  request_body = local_file.sha256_json

  request_headers = {
    Authorization = "Bearer ${var.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

data "http" "sha256" {
  url    = local.shasums_upload_url
  method = "POST"

  request_body = local_file.sha256sig_json
}

data "http" "sha256_sig" {
  url    = local.shasums_sig_upload_url
  method = "POST"

  request_body = local_file.version_json.content
}