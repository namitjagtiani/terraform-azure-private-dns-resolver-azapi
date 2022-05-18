resource "azurerm_resource_group" "rg" {
  name     = "myfirsttfrg"
  location = "australiaeast"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = "dnsvnet"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "inbounddnssub" {
  name                 = "inbounddns"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}

resource "azurerm_subnet" "outbounddnssub" {
  name                 = "outbounddns"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.64/28"]
}

resource "azapi_resource" "testresolver" {
  type      = "Microsoft.Network/dnsResolvers@2020-04-01-preview"
  name      = "testresolver"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location

  body = jsonencode({
    properties = {
      virtualNetwork = {
        id = azurerm_virtual_network.vnet.id
      }
    }
  })

  response_export_values = ["properties.virtualnetwork.id"]
}

resource "azapi_resource" "inboundendpoint" {
  type      = "Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview"
  name      = "inboundendpoint"
  parent_id = azapi_resource.testresolver.id
  location  = azapi_resource.testresolver.location

  body = jsonencode({
    properties = {
      ipConfigurations = [{ subnet = { id = azurerm_subnet.inbounddnssub.id } }]
    }
  })

  response_export_values = ["properties.ipconfiguration"]
  depends_on = [
    azapi_resource.testresolver
  ]
}

resource "azapi_resource" "outboundendpoint" {
  type      = "Microsoft.Network/dnsResolvers/outboundEndpoints@2020-04-01-preview"
  name      = "outboundendpoint"
  parent_id = azapi_resource.testresolver.id
  location  = azapi_resource.testresolver.location

  body = jsonencode({
    properties = {
      subnet = {
        id = azurerm_subnet.outbounddnssub.id
      }
    }
  })

  response_export_values = ["properties.subnet"]
  depends_on = [
    azapi_resource.testresolver
  ]
}

resource "azapi_resource" "ruleset" {
  type      = "Microsoft.Network/dnsForwardingRulesets@2020-04-01-preview"
  name      = "testruleset"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location

  body = jsonencode({
    properties = {
      dnsResolverOutboundEndpoints = [{
        id = azapi_resource.outboundendpoint.id
      }]
    }
  })
  depends_on = [
    azapi_resource.testresolver
  ]
}

resource "azapi_resource" "resolvervnetlink" {
  type      = "Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2020-04-01-preview"
  name      = "testresolvervnetlink"
  parent_id = azapi_resource.ruleset.id

  body = jsonencode({
    properties = {
      virtualNetwork = {
        id = azurerm_virtual_network.vnet.id
      }
    }
  })
  depends_on = [
    azapi_resource.testresolver
  ]
}


resource "azapi_resource" "forwardingrule" {
  type      = "Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview"
  name      = "testforwardingrule"
  parent_id = azapi_resource.ruleset.id

  body = jsonencode({
    properties = {
      domainName          = "onprem.local."
      forwardingRuleState = "Enabled"
      targetDnsServers = [{
        ipAddress = "10.10.0.1"
        port      = 53
      }]
    }
  })
  depends_on = [
    azapi_resource.testresolver
  ]
}
