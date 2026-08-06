#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

# One-time import wiring for repositories that predate this configuration.
# Each repository's pull request adds its entry here together with its entry in
# repos.auto.tfvars. Delete this file once every repository is imported.

locals {
  # Live ruleset ids per repo, keyed by the module's resource names.
  ruleset_ids = {}

  # Repo-specific extra rulesets: repo => ruleset name => live id.
  extra_ruleset_ids = {}

  extra_ruleset_imports = merge([
    for repo, rulesets in local.extra_ruleset_ids : {
      for name, id in rulesets : "${repo}|${name}" => {
        repo = repo
        name = name
        id   = id
      }
    }
  ]...)

  # Repos with a language (needed because required_language_checks uses count).
  lang_repos = { for repo, ids in local.ruleset_ids : repo => ids if contains(keys(ids), "required_language_checks") }
}

# Keyed off ruleset_ids, not var.repos: ruleset_ids holds exactly the repos
# that existed when this configuration was written, so a new repo added to
# var.repos is created rather than imported.
import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_issue_label.claude_review
  id       = "${each.key}:claude-review"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_vulnerability_alerts.this
  id       = each.key
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.force_push_protection
  id       = "${each.key}:${each.value.force_push_protection}"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.protect_master
  id       = "${each.key}:${each.value.protect_master}"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.protect_release_tags
  id       = "${each.key}:${each.value.protect_release_tags}"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.require_pull_request
  id       = "${each.key}:${each.value.require_pull_request}"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.required_default_checks
  id       = "${each.key}:${each.value.required_default_checks}"
}

import {
  for_each = local.ruleset_ids
  to       = module.repo[each.key].github_repository_ruleset.restrict_unsupported_branches
  id       = "${each.key}:${each.value.restrict_unsupported_branches}"
}

import {
  for_each = local.lang_repos
  to       = module.repo[each.key].github_repository_ruleset.required_language_checks[0]
  id       = "${each.key}:${each.value.required_language_checks}"
}

import {
  for_each = local.extra_ruleset_imports
  to       = module.repo[each.value.repo].github_repository_ruleset.extra_checks[each.value.name]
  id       = "${each.value.repo}:${each.value.id}"
}
