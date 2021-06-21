output "vpc_outputs" {
  value = module.vpc
}
output "meraki_outputs" {
  value = var.meraki == true ? aws_instance.meraki_vmx100 : null
}
output "ad_sg_id" {
  value = var.aws_directory_services == true ? aws_directory_service_directory.default[0].security_group_id : null
}
output "default_sg" {
  value = aws_default_security_group.default[*]
}
output "custom_sg" {
  value = aws_security_group.dynamic[*]
}
output "private_subnets" {
  value = zipmap(module.vpc.private_subnets_cidr_blocks, module.vpc.private_subnets)
}
output "public_subnets" {
  value = zipmap(module.vpc.public_subnets_cidr_blocks, module.vpc.public_subnets)
}
output "custom_sg_id_map" {
  value = zipmap(aws_security_group.dynamic.*.name, aws_security_group.dynamic.*.id)
}
output "directory_info" {
  value = var.aws_directory_services.active == true && length(aws_directory_service_directory.default) > 0 ? aws_directory_service_directory.default[0] : null
}
