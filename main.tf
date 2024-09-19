resource "local_file" "private_provider" {
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

resource "terraform_data" "private_provider" {
  provisioner "local-exec" {
    command = "curl --header \"Authorization: Bearer ${var.tfe_token}\" --header \"Content-Type: application/vnd.api+json\" --request POST --data @${path.module}/provider.json https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers"
  }
}