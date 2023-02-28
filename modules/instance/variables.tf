variable "root_block_device" {
  type = object({
    windows_root_volume_size = number
    windows_root_volume_type = string
  })
}
/*
variable "ebs_block_device" {
    type = object({
        windows_data_volume_size = number
        windows_data_volume_type = string        
    })
}
*/

variable "windows_instance_name" {
  type = string
}
variable "windows_instance_type" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "security_groups_ids" {
  type = list(string)
}

variable "is_public_ip" {
  type = bool
}

variable "key_pair_name" {
  type = string
}