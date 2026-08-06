#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

locals {
  approvers_team_slug = "approvers"
}

resource "github_team" "approvers" {
  name        = local.approvers_team_slug
  description = "Members whose approval satisfies the pull request review requirement"
  privacy     = "closed"
}

resource "github_team_membership" "approvers_melech" {
  team_id  = github_team.approvers.id
  username = "MelechMizrachi"
  role     = "maintainer"
}
