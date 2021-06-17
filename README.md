## Getting Started

CentOS
``` pwsh
PS:/> packer build -force -var-file .\vcenter.centos.pkrvars.hcl .\vsphere-centos7.pkr.hcl
```


``` pwsh
PS:/> packer build -force -var-file .\vcenter.ubuntu.pkrvars.hcl .\vsphere-ubuntu2004.pkr.hcl
```