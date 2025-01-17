terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.49.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state"
    key    = "databricks/workspace.tfstate"
    region = "ap-southeast-2"
  }

}

provider "aws" {
  region = local.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  profile = var.aws_profile
}

data "terraform_remote_state" "db" {
  backend = "s3"
  workspace = var.workspace
  config = {
    bucket = "terraform-state"
    key    = "databricks/provision.tfstate"
    region = "ap-southeast-2"
  }
}

# data "terraform_remote_state" "db" {
#   backend = "local"

#   config = {
#     path = "../provision/terraform.tfstate.d/${var.workspace}/terraform.tfstate"
#   }
# }

provider "databricks" {
  host  = data.terraform_remote_state.db.outputs.databricks_host
  token = data.terraform_remote_state.db.outputs.databricks_token
}

locals {
  prefix = data.terraform_remote_state.db.outputs.databricks_workspace_name
  private_link = data.terraform_remote_state.db.outputs.databricks_private_link
  allow_outgoing_internet = data.terraform_remote_state.db.outputs.databricks_allow_outgoing_internet
}

output "databricks_host" {
  value = data.terraform_remote_state.db.outputs.databricks_host
}
