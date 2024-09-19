resource "terraform_data" "private_provider" {
  provisioner "local-exec" {
    command = "curl --header \"Authorization: Bearer ${var.tfe_token}\" --header \"Content-Type: application/vnd.api+json\" --request POST --data @${data.template_file.provider_json.rendered} https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers"
  }
}

data "template_file" "provider_json" {
  template = <<EOF
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