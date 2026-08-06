#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

terraform {
  required_version = ">= 1.10"

  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

provider "github" {
  owner = var.owner
  # Auth: GITHUB_TOKEN env var locally; app_auth via GITHUB_APP_* env vars in CI.
}

module "repo" {
  source   = "./modules/repo"
  for_each = var.repos

  name                 = each.key
  description          = each.value.description
  homepage             = each.value.homepage
  topics               = each.value.topics
  language             = each.value.language
  template_repo        = each.value.template_repo
  is_template          = each.value.is_template
  extra_check_rulesets = each.value.extra_check_rulesets
  approvers_team_slug  = local.approvers_team_slug
  approvers_team_id    = tonumber(github_team.approvers.id)
}
