
/******************************************
	VPC configuration
 *****************************************/
module "vpc" {
  source                                    = "./modules/vpc"
  network_name                              = var.network_name
  auto_create_subnetworks                   = var.auto_create_subnetworks
  routing_mode                              = var.routing_mode
  project_id                                = var.project_id
  description                               = var.description
  shared_vpc_host                           = var.shared_vpc_host
  delete_default_internet_gateway_routes    = var.delete_default_internet_gateway_routes
  mtu                                       = var.mtu
  network_firewall_policy_enforcement_order = var.network_firewall_policy_enforcement_order
}

/******************************************
	Subnet configuration
 *****************************************/
module "subnets" {
  source           = "./modules/subnets"
  project_id       = var.project_id
  network_name     = module.vpc.network_name
  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
}


/******************************************
	Firewall rules
 *****************************************/
locals {
  rules = [
    for f in var.firewall_rules : {
      name                    = f.name
      direction               = f.direction
      priority                = lookup(f, "priority", null)
      description             = lookup(f, "description", null)
      ranges                  = lookup(f, "ranges", null)
      source_tags             = lookup(f, "source_tags", null)
      source_service_accounts = lookup(f, "source_service_accounts", null)
      target_tags             = lookup(f, "target_tags", null)
      target_service_accounts = lookup(f, "target_service_accounts", null)
      allow                   = lookup(f, "allow", [])
      deny                    = lookup(f, "deny", [])
      log_config              = lookup(f, "log_config", null)
    }
  ]
}
module "firewall_rules" {
  source        = "./modules/firewall-rules"
  project_id    = var.project_id
  network_name  = module.vpc.network_name
  # rules         = local.rules
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules
}

data "template_file" "init" {
  template = "${file("${path.module}/scripts/initscript.sh")}"
  vars = {
    user = "${var.content_user}"
    user_access = "${var.content_user_access}"
    address = "${var.content_url}"
  }
}
module "instance_template" {
  source          = "./modules/instance_template"
  region          = var.region
  project_id      = var.project_id
  subnetwork      = module.subnets.subnets_self_links[0]
  service_account = var.service_account
  machine_type    = var.machine_type 
  source_image    = var.source_image
  source_image_family = var.source_image_family
  source_image_project = var.source_image_project
  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
  startup_script = data.template_file.init.rendered
}

module "cp" {
  source              = "./modules/compute_instance"
  region              = var.region
  zone                = var.zone
  subnetwork          = module.subnets.subnets_self_links[0]
  num_instances       = var.num_instances
  hostname            = "cp"
  instance_template   = module.instance_template.self_link
  deletion_protection = false

  access_config = [{
    nat_ip       = var.nat_ip
    network_tier = var.network_tier
  }, ]
}

module "worker" {
  source              = "./modules/compute_instance"
  region              = var.region
  zone                = var.zone
  subnetwork          = module.subnets.subnets_self_links[0]
  num_instances       = var.num_instances
  hostname            = "worker"
  instance_template   = module.instance_template.self_link
  deletion_protection = false

  access_config = [{
    nat_ip       = var.nat_ip
    network_tier = var.network_tier
  }, ]
}