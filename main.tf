
module "provider" {
  source = "./provider"

  tfe_token = var.tfe_token
  organization_name = var.organization_name
  provider_name = var.provider_name
  provider_version = var.provider_version
  provider_binary_shasum = var.provider_binary_shasum
  provider_binary_name = var.provider_binary_name
  provider_sha256_value = var.provider_sha256_value
  provider_sha256_sig_value = var.provider_sha256_sig_value
}

# module "cleanup" {
#   depends_on = [ module.provider ]
#   source = "./cleanup"


# }