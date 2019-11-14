kind = "service-resolver"
name = "api"
connect_timeout = "15s"


subsets = {
  v1 = {
    filter = "Service.Meta.version == 1"
  }

  v2 = {
    filter = "Service.Meta.version == 2"
  }
}
failover = {
  "*" = {
    datacenters = [ "dc-1", "dc-2"]
  }
}
