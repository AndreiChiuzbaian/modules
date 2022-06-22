data "azurerm_client_config" "current" {}

data "azurerm_function_app" "apps" {
  for_each       = {
    for app in [
      for item in setproduct(var.client_apps, var.client_envs) : 
        {
        name  = item.0
        env   = item.1
      }
    ] : "${app.name}${app.env}" => app 
  }
  provider            = azurerm.BankingCircle-EA-Sub
  name                = "${each.value.name}-${each.value.env}"
  resource_group_name = "${var.client_project_code}-${each.value.env}-rg"
}

resource "azurerm_key_vault_access_policy" "policy" {
  for_each       = {
    for app in [
      for item in setproduct(var.client_apps, var.client_envs, var.key_vault_ids) : 
        {
        name  = item.0
        env   = item.1
        kv    = item.2
      }
    ] : "${app.name}${app.env}${app.kv}" => app 
  }
  key_vault_id       = each.value.kv
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_function_app.apps["${each.value.name}${each.value.env}"].identity.0.principal_id
  secret_permissions = ["Get"]
}

resource "azurerm_servicebus_topic" "topics" {
  for_each              = toset(var.topics_to_create)
  name                  = each.key
  namespace_id          = var.service_bus.id
  max_size_in_megabytes = 1024
}

data "azurerm_servicebus_topic" "topics" {
  for_each            = toset([ for topic in var.topics : topic.name if !contains(var.topics_to_create, topic.name) ])
  name                = each.key
  namespace_name      = var.service_bus.name
  resource_group_name = var.service_bus.resource_group_name
}

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each            = { for subscription in local.subscriptions : "${subscription.topic}${subscription.name}" => subscription }
  name                = each.value.name
  topic_id            = contains(var.topics_to_create, each.value.topic) ? azurerm_servicebus_topic.topics[each.value.topic].id : data.azurerm_servicebus_topic.topics[each.value.topic].id
  max_delivery_count  = 10
  auto_delete_on_idle = "P14D"
  default_message_ttl = "P14D"
  lock_duration       = "PT30S"
}
