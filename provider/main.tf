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

resource "local_file" "file_json" {
  filename = "${path.module}/file.json"
}


resource "terraform_data" "private_provider" {
  provisioner "local-exec" {
    command = "curl --header \"Authorization: Bearer ${var.tfe_token}\" --header \"Content-Type: application/vnd.api+json\" --request POST --data @${path.module}/provider.json https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers"
  }

  provisioner "local-exec" {
    command = "curl --header \"Authorization: Bearer ${var.tfe_token}\" --header \"Content-Type: application/vnd.api+json\" --request POST --data @${path.module}/version.json https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers/${var.provider_name}/versions"
  }
}