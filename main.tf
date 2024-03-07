terraform {
  required_version = ">=1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Owner     = "devops-team"
      ManagedBy = "Terraform"
    }
  }
}

resource "aws_instance" "cert_script_example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data                   = data.cloudinit_config.cert_script.rendered
  user_data_replace_on_change = true

  tags = {
    Name = "cert-script-example"
  }
}

locals {
  cloud_init_config = <<-END
    #cloud-config
    ${jsonencode({
  write_files = [
    {
      path        = "/opt/check-cert.bash"
      permissions = "0740"
      owner       = "root:root"
      encoding    = "b64"
      content     = filebase64("../cert-check-example/check-cert.bash")
    },
    {
      path  = "/etc/cron.d/check-cert"
      owner = "root:root"
      content : "0 0 */3 * * root /opt/check-cert.bash"
    }
  ]
})}
  END
}

data "cloudinit_config" "cert_script" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    filename     = "check-cert.bash"
    content      = local.cloud_init_config
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
