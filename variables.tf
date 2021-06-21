variable "domain_name" {
  description = "Used for Active Directory and DNS"
  type        = string
  default     = ""
}

variable "aws_directory_services" {
  description = "Configure AWS active directory services"
  type        = object({ active = bool, type = string, edition = string, enable_sso = bool, alias = string })
  default = {
    active     = false,
    type       = "",
    edition    = "",
    enable_sso = false,
    alias      = ""
  }
}

variable "company_name" {
  description = "Active Directory Alias"
  type        = string
  default     = ""
}

variable "meraki" {
  description = "Set to true to deploy a Meraki vMX100"
  type        = bool
  default     = false
}

variable "meraki_data" {
  description = "Set to true to deploy a Meraki vMX100"
  type        = list(object({ primary = bool, secret = string }))
  default     = [{ primary = true, secret = "default" }]
}

variable "custom_sg" {
  description = "A list of objects for creating SGs. Each object should have a name, and contain additional objects for each rule under egress and ingress."
  type        = list(object({ name = string, egress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) }))
  default     = []
}

variable "default_sg" {
  description = "An object which contains all the rules for the VPC default SG"
  type        = object({ egress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) })
  default = {
    egress = [
      {
        to_port          = 80,
        protocol         = "tcp",
        from_port        = 80,
        self             = null,
        ipv6_cidr_blocks = null,
        cidr_blocks = [
          "0.0.0.0/0"
        ]
      },
      {
        to_port          = 443,
        protocol         = "tcp",
        from_port        = 443,
        self             = null,
        ipv6_cidr_blocks = null,
        cidr_blocks = [
          "0.0.0.0/0"
        ]
      }
    ],
    ingress = [
      {
        to_port          = 0,
        protocol         = "-1",
        from_port        = 0,
        self             = null,
        ipv6_cidr_blocks = null,
        cidr_blocks = [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16"
        ]
      }
    ]
  }
}

variable "vpc_cidr" {
  description = "Single IPv4 address space in CIDR format that will be available for use by subnets within the VPC."
  type        = string
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
}

variable "use_az_ids" {
  description = "Whether to use availability zone ids"
  type        = bool
  default     = false
}

variable "subnets" {
  type = map(list(map(string)))
}

variable "private_inbound_acl_rules" {
  description = "List of maps of ingress rules to set on the Private Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_outbound_acl_rules" {
  description = "List of maps of egress rules to set on the Private Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_inbound_acl_rules" {
  description = "List of maps of ingress rules to set on the Public Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_outbound_acl_rules" {
  description = "List of maps of egress rules to set on the Public Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "aws_fsx" {
  description = "Set to true to deploy AWS fsx windows file share"
  type        = bool
  default     = true
}

variable "fsx_windows_fileshare" {
  description = "List of AWS FSx Windows File Shares to create"
  type        = list(object({ storage_capacity = number, throughput_capacity = number, automatic_backup_retention_days = number }))
  default     = [{ storage_capacity = 300, throughput_capacity = 16, automatic_backup_retention_days = 35 }]
}

variable "merakivmx100_name" {
  description = "Name for Meraki vMX100 resource"
  type        = string
  default     = "Meraki vMX100"
}

variable "namespace" {
  description = "Unique namespace for all resources. Should be PR number or prod"
  type        = string
}
