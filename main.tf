
module "provider" {
  source = "./provider"

  tfe_token = var.tfe_token
  organization_name = var.organization_name
  provider_name = var.provider_name
  provider_version = var.provider_version
}

# module "cleanup" {
#   depends_on = [ module.provider ]
#   source = "./cleanup"


# }