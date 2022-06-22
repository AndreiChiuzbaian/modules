locals {
  subscriptions = flatten([
    for topic in var.topics : [
      for subscription in topic.subscriptions : {
        topic = topic.name
        name  = subscription
      }
    ]
  ])
}
