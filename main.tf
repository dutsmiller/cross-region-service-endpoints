data "azurerm_subscription" "current" {}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

# Random string for resource group
resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

locals {
  regions = ["eastus", "westus"]

  authorized_ips = distinct(concat([data.http.my_ip.body], var.authorized_ips))
}

resource "azurerm_resource_group" "example" {
  for_each = toset(local.regions)

  name     = "${random_string.random.result}-${each.value}"
  location = each.value
  tags     = var.tags
}

resource "azurerm_virtual_network" "example" {
  for_each = toset(local.regions)

  name                = "${random_string.random.result}-${each.value}"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.example[each.value].name
  location            = azurerm_resource_group.example[each.value].location

  tags = var.tags
}

resource "azurerm_subnet" "example" {
  for_each = toset(local.regions)

  name                 = "${each.value}-subnet"
  resource_group_name  = azurerm_resource_group.example[each.value].name
  virtual_network_name = azurerm_virtual_network.example[each.value].name

  address_prefixes = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_storage_account" "example" {
  name                     = "${random_string.random.result}${local.regions.0}"
  resource_group_name      = azurerm_resource_group.example[local.regions.0].name
  location                 = azurerm_resource_group.example[local.regions.0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = local.authorized_ips
    virtual_network_subnet_ids = [azurerm_subnet.example[local.regions.1].id]
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}
