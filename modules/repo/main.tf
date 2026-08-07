#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage
  topics       = var.topics
  visibility   = "public"
  is_template  = var.is_template

  has_issues      = true
  has_discussions = false
  has_projects    = false
  has_wiki        = false

  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_auto_merge            = false
  allow_update_branch         = false
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  web_commit_signoff_required = false

  dynamic "template" {
    for_each = var.template_repo == null ? [] : [var.template_repo]
    content {
      owner      = "valkyrjaio"
      repository = template.value
      # The template's default branch is the current version branch, and master
      # is created from it below. include_all_branches would also copy backup,
      # old version, and stray work branches.
      include_all_branches = false
    }
  }

  lifecycle {
    # A repo generated from a template records that origin forever; the template
    # block only matters at creation and the API cannot unset it.
    ignore_changes = [template]
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
}

# Approvals only count toward a review requirement from users with write
# access, so the approvers team gets push on every repo.
resource "github_team_repository" "approvers" {
  count = var.approvers_team_slug == null ? 0 : 1

  team_id    = var.approvers_team_slug
  repository = github_repository.this.name
  permission = "push"
}

# The template copy brings the version branch alone, and every repo also needs
# master. Warning: the copy is asynchronous, so the first apply can fail here
# before the source branch exists — re-run the Apply workflow.
resource "github_branch" "master" {
  count = var.template_repo == null ? 0 : 1

  repository    = github_repository.this.name
  branch        = "master"
  source_branch = var.version_branch
}

resource "github_issue_label" "claude_review" {
  repository  = github_repository.this.name
  name        = "claude-review"
  color       = "5319e7"
  description = "Ask Claude to review this pull request"
}
