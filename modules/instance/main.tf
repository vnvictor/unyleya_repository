data "template_file" "windows-userdata" {
  template = <<EOF
<powershell>
# Rename Machine
Rename-Computer -NewName "${var.windows_instance_name}" -Force;
# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools;
# Restart machine
shutdown -r -t 10;
</powershell>
EOF
}

data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}

resource "aws_instance" "windows-server" {
  ami                    = data.aws_ami.windows-2019.id
  instance_type          = var.windows_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = var.security_groups_ids
  source_dest_check      = false
  key_name               = var.key_pair_name
  user_data                   = data.template_file.windows-userdata.rendered
  associate_public_ip_address = var.is_public_ip

  # root disk
  root_block_device {
    volume_size           = var.root_block_device.windows_root_volume_size
    volume_type           = var.root_block_device.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }
  # extra disk
  /*  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = var.ebs_block_device.windows_data_volume_size
    volume_type           = var.ebs_block_device.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
*/

}