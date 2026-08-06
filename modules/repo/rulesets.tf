#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

locals {
  # GitHub App used by org automation (bypass actor on most rulesets).
  automation_app_id = 2462900

  # GitHub Actions integration id, required alongside each status-check context.
  github_actions_integration_id = 15368

  # One entry per language: { ruleset_name, contexts }. Each language's pull
  # request adds its entry, and a repo may only declare a language that is here.
  language_checks = {}

  default_check_contexts = [
    "Commit Message Check / Check Commit Message",
    "Copyright Header Check / Check Copyright Header",
    "Markdown Check / Check Markdown",
    "Trailing Newline Check / Check Trailing Newline",
  ]
}

resource "github_repository_ruleset" "force_push_protection" {
  repository  = github_repository.this.name
  name        = "Protect Against Force Pushes and Deletion"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/??.x"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "protect_master" {
  repository  = github_repository.this.name
  name        = "Protect Master At All Times"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/master"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}

resource "github_repository_ruleset" "protect_release_tags" {
  repository  = github_repository.this.name
  name        = "Protect Release Tags"
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/tags/*.*.*"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "require_pull_request" {
  repository  = github_repository.this.name
  name        = "Require Pull Request"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/??.x", "refs/heads/master"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = true
      require_last_push_approval        = false
      required_review_thread_resolution = false
      allowed_merge_methods             = ["squash"]

      dynamic "required_reviewers" {
        for_each = var.approvers_team_slug == null ? [] : [var.approvers_team_id]
        content {
          file_patterns     = ["**"]
          minimum_approvals = 1
          reviewer {
            id   = required_reviewers.value
            type = "Team"
          }
        }
      }
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = local.automation_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "required_default_checks" {
  repository  = github_repository.this.name
  name        = "Required Default PR Checks"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/??.x"]
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = false

      dynamic "required_check" {
        for_each = local.default_check_contexts
        content {
          context        = required_check.value
          integration_id = local.github_actions_integration_id
        }
      }
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = local.automation_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "restrict_unsupported_branches" {
  repository  = github_repository.this.name
  name        = "Restrict Changes to Unsupported Branches"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/??.x-backup", "refs/heads/master-backup"]
      exclude = []
    }
  }

  rules {
    creation         = true
    update           = true
    deletion         = true
    non_fast_forward = true
  }

  bypass_actors {
    actor_id    = local.automation_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "extra_checks" {
  for_each = var.extra_check_rulesets

  repository  = github_repository.this.name
  name        = each.key
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/??.x"]
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = false

      dynamic "required_check" {
        for_each = each.value
        content {
          context        = required_check.value
          integration_id = local.github_actions_integration_id
        }
      }
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = local.automation_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "required_language_checks" {
  count = var.language == null ? 0 : 1

  repository  = github_repository.this.name
  name        = local.language_checks[var.language].ruleset_name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/??.x"]
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = false

      dynamic "required_check" {
        for_each = local.language_checks[var.language].contexts
        content {
          context        = required_check.value
          integration_id = local.github_actions_integration_id
        }
      }
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = local.automation_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}
