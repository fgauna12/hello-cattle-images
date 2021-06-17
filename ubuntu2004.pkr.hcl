variable "vcenter_server" {
  type    = string
  default = "192.168.1.183"
}

variable "esxi_host" {
  type    = string
  default = "esxi-host"
}

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

variable "iso_path" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "vcenter_username" {
  type = string
}

variable "vcenter_password" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type = string
}

variable "datastore" {
  type = string
}

variable "guest_os_type" {
  type    = string
  default = "ubuntu64Guest"
}

variable "network_name" {
  type = string
}

source "vsphere-iso" "ubuntu" {
  iso_paths    = [var.iso_path]
  iso_checksum = var.iso_checksum

  //connection
  vcenter_server      = var.vcenter_server
  host                = var.esxi_host
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  convert_to_template = false

  export {
    force            = true
    output_directory = "./output_vsphere"
  }

  vm_name              = var.vm_name
  guest_os_type        = var.guest_os_type
  CPUs                 = 2
  RAM                  = 2048
  disk_controller_type = ["pvscsi"]
  usb_controller       = ["xhci"] //usb 3.0
  notes                = "Created by Packer. SSH user is ${var.ssh_username}"
  datastore            = var.datastore

  network_adapters {
    network      = var.network_name
    network_card = "vmxnet3"
  }

  storage {
    disk_size             = 20000
    disk_thin_provisioned = true
  }

  ssh_timeout            = "20m"
  ssh_handshake_attempts = 100

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password

  boot_order = "disk,cdrom"

  floppy_files = [
    "./http/meta-data",
    "./http/user-data"
  ]
  floppy_label = "cidata"

  boot_wait = "2s"
  boot_command = [
    var.boot_command
  ]

  shutdown_command = "sudo -S shutdown -P now"
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
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

source "azure-arm" "ubuntu" {
  client_id           = var.client_id
  client_secret       = var.client_secret
  
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id

  managed_image_name = "chia-{{isotime \"200601020304\"}}"
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
}

build {
  sources = [
    #"sources.vsphere-iso.ubuntu",
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