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

# One file per repository and one file per language, so a pull request that
# adds a repository or a language touches no shared file and never conflicts.
locals {
  repos = {
    for f in fileset("${path.root}/repos", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.root}/repos/${f}"))
  }

  languages = {
    for f in fileset("${path.root}/languages", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.root}/languages/${f}"))
  }
}

module "repo" {
  source   = "./modules/repo"
  for_each = local.repos

  name                  = each.key
  description           = try(each.value.description, "")
  homepage              = try(each.value.homepage, "")
  topics                = try(each.value.topics, [])
  language              = try(each.value.language, null)
  template_repo         = try(each.value.template_repo, null)
  is_template           = try(each.value.is_template, false)
  extra_check_rulesets  = try(each.value.extra_check_rulesets, {})
  language_checks       = local.languages
  approvers_team_slug   = local.approvers_team_slug
  approvers_team_id     = tonumber(github_team.approvers.id)
  require_team_approval = var.require_team_approval
}
