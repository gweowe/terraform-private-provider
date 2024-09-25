terraform {
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.58.1"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.5"
    }
  }
}

provider "tfe" {
  token = var.tfe_token
}
