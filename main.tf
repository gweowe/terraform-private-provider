locals {
  # tfe address
  tfe_api_address = "https://${var.tfe_hostname}/api/v2"

  #create provider
  provider_zips   = fileset("${path.module}/providers", "**/*.zip")
  provider_names  = distinct([for path in local.provider_zips : split("_", split("-", basename(path))[2])[0]])
  provider_map = {
    for name in local.provider_names : name => [
      for path in local.provider_zips : split("/", path)[2] if split("_", split("-", basename(path))[2])[0] == name
    ]
  }
  provider_zip_list = [
    for path in local.provider_zips : split("/", path)[2]
  ]
  provider_info = {
    for zip in local.provider_zip_list : split("-", zip)[2] => {
      name = split("-", split("_",zip)[0])[2]
      version = split("_",zip)[1]
      binary = one(fileset("providers", "**/*${zip}"))
      sig = one(fileset("providers", "**/*${split("_",zip)[0]}_${split("_",zip)[1]}_SHA256SUMS.sig"))
      sha256 = one(fileset("providers", "**/*${split("_",zip)[0]}_${split("_",zip)[1]}_SHA256SUMS"))
    }
  }

  # delete provider
  existing_versions = {
    for provider in local.provider_names : provider => 
      try(
        jsondecode(data.http.get_versions[provider].response_body).data != null ? [for item in jsondecode(data.http.get_versions[provider].response_body).data : item.attributes.version]: [],[]
      )
  }
  versions_to_delete = {
    for provider, versions in local.existing_versions :
    provider => setsubtract(toset(versions), toset([for info in local.provider_info : info.version if info.name == provider]))
  }
}

resource "tfe_registry_provider" "private" {
  for_each = toset(local.provider_names)

  organization = var.tfe_organization

  registry_name = "private"
  name          = each.key
}

data "http" "version" {
  depends_on = [tfe_registry_provider.private]
  for_each   = local.provider_info

  url    = "${local.tfe_api_address}/organizations/${var.tfe_organization}/registry-providers/private/${var.tfe_organization}/${each.value.name}/versions"
  method = "POST"

  request_body = <<-EOF
  {
    "data": {
      "type": "registry-provider-versions",
      "attributes": {
        "version": "${split("_", each.key)[1]}",
        "key-id": "34365D9472D7468F",
        "protocols": ["5.0"]
      }
    }
  }
  EOF

  request_headers = {
    Authorization = "Bearer ${var.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

resource "terraform_data" "sha256" {
  depends_on = [ data.http.version ]
  for_each = local.provider_info

  provisioner "local-exec" {
    command = "cat ./providers/${each.value.sha256} | curl -T - ${jsondecode(data.http.version[each.key].response_body).data.links["shasums-upload"]}"
  }
  provisioner "local-exec" {
    command = "cat ./providers/${each.value.sig} | curl -T - ${jsondecode(data.http.version[each.key].response_body).data.links["shasums-sig-upload"]}"
  }
}

data "http" "file" {
  depends_on = [ terraform_data.sha256 ]
  for_each   = local.provider_info

  url = "${local.tfe_api_address}/organizations/${var.tfe_organization}/registry-providers/private/${var.tfe_organization}/${each.value.name}/versions/${each.value.version}/platforms"
  method = "POST"

  request_body = jsonencode(
  {
    "data" = {
      "type" = "registry-provider-version-platforms",
      "attributes" = {
        "os" = "linux",
        "arch" = "amd64",
        "shasum" = filesha256("./providers/${each.value.binary}")
        "filename" = "${split("/", each.value.binary)[2]}"
      }
    }
  }
  )

  request_headers = {
    Authorization = "Bearer ${var.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

resource "terraform_data" "file_upload" {
  depends_on = [ data.http.file ]
  for_each = local.provider_info

  provisioner "local-exec" {
    command = "cat ./providers/${each.value.binary} | curl -T - ${jsondecode(data.http.file[each.key].response_body).data.links["provider-binary-upload"]}"
  }
}

data "http" "get_versions" {
  for_each = toset(local.provider_names)

  url = "${local.tfe_api_address}/organizations/${var.tfe_organization}/registry-providers/private/${var.tfe_organization}/${each.key}/versions"
  
  request_headers = {
    Authorization = "Bearer ${var.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

resource "terraform_data" "delete_versions" {
  for_each = {
    for pair in flatten([
      for provider, versions in local.versions_to_delete :
      [for version in versions : "${provider}/${version}"]
    ]) : pair => split("/", pair)
  }

  provisioner "local-exec" {
    command = <<EOT
      curl -X DELETE \
        ${local.tfe_api_address}/organizations/${var.tfe_organization}/registry-providers/private/${var.tfe_organization}/${each.value[0]}/versions/${each.value[1]} \
        -H "Authorization: Bearer ${var.tfe_token}" \
        -H "Content-Type: application/vnd.api+json"
    EOT
  }
  triggers_replace = each.value
}