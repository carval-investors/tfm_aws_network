locals {
  ds_sso_alias      = var.aws_directory_services.alias != "" && length(regexall("prod", var.namespace)) > 0 ? var.aws_directory_services.alias : "${var.namespace}-${var.aws_directory_services.alias}"
  public_subnets    = lookup(var.subnets, "public", null) != null ? var.subnets.public.*.cidr : null
  dmz_subnets       = lookup(var.subnets, "dmz", null) != null ? var.subnets.dmz.*.cidr : null
  workspace_subnets = lookup(var.subnets, "workspace", null) != null ? var.subnets.workspace.*.cidr : null
  private_subnets   = lookup(var.subnets, "private", null) != null ? var.subnets.private.*.cidr : null
  fsx_subnet        = element(coalescelist(module.vpc.workspace_subnets, module.vpc.private_subnets), 0)
  ds_subnets        = coalescelist(module.vpc.workspace_subnets, module.vpc.private_subnets)
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [for item in var.default_sg.ingress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self

    }
  }
  dynamic "egress" {
    for_each = [for item in var.default_sg.egress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
}

resource "aws_security_group" "dynamic" {
  count  = length(var.custom_sg)
  name   = "${var.namespace}-${var.custom_sg[count.index].name}"
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [for item in var.custom_sg[count.index].ingress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self

    }
  }
  dynamic "egress" {
    for_each = [for item in var.custom_sg[count.index].egress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
}

module "vpc" {
  source = "git::https://github.com/carval-investors/tfm_aws_vpc.git?ref=v0.0.3"

  name       = "${var.namespace}-${var.company_name}"
  cidr       = var.vpc_cidr
  use_az_ids = var.use_az_ids
  azs        = var.azs

  private_subnets   = local.private_subnets
  public_subnets    = local.public_subnets
  workspace_subnets = local.workspace_subnets
  dmz_subnets       = local.dmz_subnets

  private_dedicated_network_acl = true
  private_outbound_acl_rules    = var.private_outbound_acl_rules
  private_inbound_acl_rules     = var.private_inbound_acl_rules
  public_dedicated_network_acl  = true
  public_outbound_acl_rules     = var.public_outbound_acl_rules
  public_inbound_acl_rules      = var.public_inbound_acl_rules

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  enable_dhcp_options              = var.aws_directory_services.active == true ? true : false
  dhcp_options_domain_name         = var.aws_directory_services.active == true ? var.domain_name : null
  dhcp_options_domain_name_servers = var.aws_directory_services.active == true && length(aws_directory_service_directory.default) > 0 ? aws_directory_service_directory.default[0].dns_ip_addresses : null
  dhcp_options_ntp_servers         = var.aws_directory_services.active == true && length(aws_directory_service_directory.default) > 0 ? aws_directory_service_directory.default[0].dns_ip_addresses : null

  propagate_private_route_tables_vgw = true
  propagate_public_route_tables_vgw  = true

  # VPC endpoint for Secrets Manager
  enable_secretsmanager_endpoint              = true
  secretsmanager_endpoint_private_dns_enabled = true
  secretsmanager_endpoint_security_group_ids  = [aws_default_security_group.default.id]

  # VPC Endpoint for EC2
  enable_ec2_endpoint              = true
  ec2_endpoint_private_dns_enabled = true
  ec2_endpoint_security_group_ids  = [aws_default_security_group.default.id]

  # VPC Endpoint for EC2MESSAGES
  enable_ec2messages_endpoint              = true
  ec2messages_endpoint_private_dns_enabled = true
  ec2messages_endpoint_security_group_ids  = [aws_default_security_group.default.id]

  # VPC endpoint for KMS
  enable_kms_endpoint              = true
  kms_endpoint_private_dns_enabled = true
  kms_endpoint_security_group_ids  = [aws_default_security_group.default.id]

  tags = {
    Terraform = "true"
  }
}

# Get Meraki AMI
data "aws_ami" "meraki_vmx100" {
  count       = var.meraki == true ? 1 : 0
  most_recent = true

  filter {
    name   = "product-code"
    values = ["9s6guq20ffzxnhhylhjbself6"]
  }

  owners = ["679593333241"] # Cisco
}

# If Meraki true, then create vMX100 instances
resource "aws_instance" "meraki_vmx100" {
  count                       = var.meraki == true ? length(var.meraki_data) : 0
  ami                         = data.aws_ami.meraki_vmx100[0].id
  instance_type               = "m4.large"
  source_dest_check           = false
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[count.index]
  user_data                   = var.meraki_data[count.index].secret != "" ? var.meraki_data[count.index].secret : null

  tags = {
    Name      = "${var.namespace}-${var.merakivmx100_name}"
    Terraform = "true"
    Primary   = "${var.meraki_data[count.index].primary}"
  }
}

# If Meraki true, then point all class a RFC1918 traffic at the primary vMX100
resource "aws_route" "class_a" {
  count                  = var.meraki == true ? length(module.vpc.private_route_table_ids) : 0
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  instance_id            = aws_instance.meraki_vmx100[index(aws_instance.meraki_vmx100.*.tags.Primary, "true")].id
}

# If Meraki true, then point all class b RFC1918 traffic at the primary vMX100
resource "aws_route" "class_b" {
  count                  = var.meraki == true ? length(module.vpc.private_route_table_ids) : 0
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "172.16.0.0/12"
  instance_id            = aws_instance.meraki_vmx100[index(aws_instance.meraki_vmx100.*.tags.Primary, "true")].id
}

# If Meraki true, then point all class c RFC1918 traffic at the primary vMX100
resource "aws_route" "class_c" {
  count                  = var.meraki == true ? length(module.vpc.private_route_table_ids) : 0
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "192.168.0.0/16"
  instance_id            = aws_instance.meraki_vmx100[index(aws_instance.meraki_vmx100.*.tags.Primary, "true")].id
}

resource "aws_kms_key" "fsx" {
  count = var.aws_fsx == true ? 1 : 0
}

resource "random_password" "password" {
  count   = var.aws_directory_services.active == true ? 1 : 0
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "ad_administrator" {
  count                   = var.aws_directory_services.active == true ? 1 : 0
  name                    = "${var.namespace}_ad_admin"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ad_admin_password" {
  count         = var.aws_directory_services.active == true ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ad_administrator[count.index].id
  secret_string = random_password.password[count.index].result
}

# Create AWS Directory Services
resource "aws_directory_service_directory" "default" {
  count      = var.aws_directory_services.active == true ? 1 : 0
  name       = var.domain_name
  password   = random_password.password[count.index].result
  alias      = var.aws_directory_services.enable_sso == true ? local.ds_sso_alias : null
  type       = var.aws_directory_services.type
  edition    = var.aws_directory_services.edition
  enable_sso = var.aws_directory_services.enable_sso

  vpc_settings {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = local.ds_subnets
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_fsx_windows_file_system" "default" {
  count = var.aws_fsx && var.aws_directory_services.active == true ? length(var.fsx_windows_fileshare) : 0

  active_directory_id               = aws_directory_service_directory.default[count.index].id
  kms_key_id                        = aws_kms_key.fsx[count.index].arn
  storage_capacity                  = var.fsx_windows_fileshare[count.index].storage_capacity
  subnet_ids                        = [local.fsx_subnet]
  throughput_capacity               = var.fsx_windows_fileshare[count.index].throughput_capacity
  automatic_backup_retention_days   = var.fsx_windows_fileshare[count.index].automatic_backup_retention_days
  daily_automatic_backup_start_time = "02:00"
  security_group_ids                = [aws_default_security_group.default.id]
  weekly_maintenance_start_time     = "7:03:00"
}
