resource "terraform_data" "private_provider" {
  provisioner "local-exec" {
    command = "curl --header \"Authorization\": Bearer ${var.tfe_token}\" --header \"Content-Type: application/vnd.api+json\" --request POST --data @${var.provider_json} https://app.terraform.io/api/v2/organizations/${var.organization_name}/registry-providers"
  }
}
