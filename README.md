# tfm_aws_network

## Usage

```hcl

variable "json" {
  type = any
}

module "test_vpc" {
  source = "git::https://github.com/carval-investors/tfm_azu_network.git"

  company_name = var.json.client.company_name
  domain_name  = var.json.client.domain_name

  meraki                 = var.json.network.meraki
  meraki_data            = var.json.network.meraki_data
  aws_directory_services = var.json.network.aws_directory_services
  generate_password      = true
  aws_fsx                = var.json.network.aws_fsx

  vpc_cidr        = var.json.network.vpc_cidr
  private_subnets = var.json.network.private_subnets
  public_subnets  = var.json.network.public_subnets
  azs             = var.json.network.azs
  custom_sg       = var.json.network.custom_sg
}
```

Terraform.tfvars.json

```json
{
    "json":{
      "client":{
        "company_name":"devtest",
        "domain_name":"devtest.com"
      },
      "network":{
        "vpc_cidr":"172.31.0.0/16",
        "azs":[
          "us-east-1a",
          "us-east-1b"
        ],
        "private_subnets":[
          "172.31.0.0/24",
          "172.31.1.0/24"
        ],
        "public_subnets":[
          "172.31.254.0/24",
          "172.31.255.0/24"
        ],
        "aws_directory_services":true,
        "generate_password":true,
        "aws_fsx":true,
        "meraki":true,
        "meraki_data":[
          {
            "primary":false,
            "secret":"node1"
          },
          {
            "primary":true,
            "secret":"node2"
          }
        ],
        "custom_sg":[
          {
            "name":"web",
            "egress":[
              {
                "to_port":0,
                "protocol":-1,
                "from_port":0,
                "self":null,
                "ipv6_cidr_blocks":null,
                "cidr_blocks":[
                  "0.0.0.0/0"
                ]
              }
            ],
            "ingress":[
              {
                "to_port":80,
                "protocol":"tcp",
                "from_port":80,
                "self":null,
                "ipv6_cidr_blocks":null,
                "cidr_blocks":[
                  "0.0.0.0/0"
                ]
              },
              {
                "to_port":443,
                "protocol":"tcp",
                "from_port":443,
                "self":null,
                "ipv6_cidr_blocks":null,
                "cidr_blocks":[
                  "0.0.0.0/0"
                ]
              }
            ]
          }
        ]
      }
    }
  }
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| domain_name | Used for Active Directory and DNS | string | "" | yes |
| company_name | Active Directory Alias | string | "" | yes |
| aws_directory_services | Deploy AWS AD Services to the VPC | bool | true | yes |
| generate_password | Set this to true if you want Terraform to generate the AD services password and store it in AWS Secrets Manager | bool | false | no |
| password_secret_name | Use this to grab a secret in AWS Secrets Manager as the AD services password instead of generating one. This can also be used to specify the name of the generated password to store in AWS Secrets Manager. | string | ad_admin | no |
| aws_fsx | Deploy AWS FSX to the VPC | bool | true | yes |
| meraki | Deploy single or multiple vMX100 appliances to public subnets in VPC | bool | false | yes |
| meraki_data | Meraki device priority and authentication token per device | list(object({ primary = bool, secret = string })) | { primary = true, secret = "default" } | only when meraki is true |
| vpc_cidr | Single IPv4 address space in CIDR format that will be available for use by subnets within the VPC | string | "" | yes |
| azs | A list of availability zones in the region | list(string) | [] | yes |
| use_azs_ids | Whether to use availability zone ids | bool | false | no
| private_subnets | A list of private subnets inside the VPC | list(string) | [] | yes |
| public_subnets | A list of public subnets inside the VPC | list(string) | [] | yes |
| default_network_acl_ingress | List of maps of ingress rules to set on the Default Network ACL | list(map(string)) | [{rule_no = 100, action = "allow", from_port = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"}, {rule_no = 101, action = "allow", from_port = 0, to_port = 0, protocol = "-1", ipv6_cidr_block = "::/0"}] | no |
| default_network_acl_egress | List of maps of egress rules to set on the Default Network ACL | list(map(string)) | [{rule_no = 100, action = "allow", from_port  = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"}, {rule_no = 101, action = "allow", from_port = 0, to_port = 0, protocol = "-1", ipv6_cidr_block = "::/0"}] | no |
| custom_sg | List of security group names to create besides default SG | list(string) | [] | no |
| default_sg | List of rules to assign to the security groups | list(object({ type = string, to_port = number, protocol = string, from_port = number, cidr_blocks = list(string), source_security_group_id = string, self = bool, ipv6_cidr_blocks = list(string), security_group_id = string })) | Egress: 80,443 Ingress: All RFC1918 | no |
| fsx_windows_fileshare | List of AWS FSx Windows File Shares to create | list(object({ storage_capacity = number, throughput_capacity = number, automatic_backup_retention_days = number })) | [{ storage_capacity = 300, throughput_capacity = 16, automatic_backup_retention_days = 35 }] | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_outputs | Dictionary of all available VPC outputs [AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.17.0) |
| meraki_outputs | List of all params for vMX100 instances deployed |
| ad_sg_id | AWS Active Directory Service Security Group ID |
| default_sg | List of all params for the default security group |
| custom_sg | List of all custom security groups with their params |
