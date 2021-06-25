variable "vm_name" {
  type    = string
  default = "ubuntu-packer"
}

variable boot_command {
  type        = string
  description = "Specifies the keys to type when the virtual machine is first booted in order to start the OS installer. This command is typed after boot_wait, which gives the virtual machine some time to actually load."
  default     = <<-EOF
  <enter><wait2><enter><wait><f6><esc><wait>
   autoinstall ds=nocloud;
  <enter>
  EOF
}
variable "guest_os_type" {
  type    = string
  default = "ubuntu64Guest"
}

variable "client_id" {
  type = string
  sensitive = true
}

variable "client_secret" {
  type = string
  sensitive = true
}

variable "resource_group_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "shared_image_gallery_resource_group_name" {
  type = string
}

variable "shared_image_gallery_name" {
  type = string
}

locals {
  image_name = "chia-${formatdate("DDMMMYYYYhhmm", timestamp())}"
}

source "azure-arm" "ubuntu" {
  client_id     = var.client_id
  client_secret = var.client_secret

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.resource_group_name

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-focal"
  image_sku       = "20_04-lts"

  azure_tags = {
    customer = "internal"
    owner    = "facundo@boxboat.com"
  }

  location = "East US"
  vm_size  = "Standard_DS2_v2"

  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.shared_image_gallery_resource_group_name
    gallery_name         = var.shared_image_gallery_name
    image_name           = "chia"
    image_version        = "1.0.1"
    replication_regions = ["eastus"]
  }
}

build {
  sources = [
    "sources.azure-arm.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "./ansible/playbook.yml"
  }

  # de-provision process, should be at the end, only for azure
  provisioner "shell" {
    only            = ["sources.azure-arm.ubuntu"]
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }
}