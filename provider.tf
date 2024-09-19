terraform {
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.58.1"
    }
  }
}

provider "tfe" {
  token = var.tfe_token
}
