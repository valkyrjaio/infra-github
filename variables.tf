#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

variable "owner" {
  description = "GitHub organization that owns the repositories."
  type        = string
  default     = "valkyrjaio"
}

variable "require_team_approval" {
  description = "Whether every pull request requires an approval from the approvers team. Off while the team has one member: GitHub never counts an author's own approval, so the requirement would block every pull request that member opens."
  type        = bool
  default     = false
}

variable "repos" {
  description = "Repositories to manage, keyed by repository name."
  type = map(object({
    description          = optional(string, "")
    homepage             = optional(string, "")
    topics               = optional(list(string), [])
    language             = optional(string)
    template_repo        = optional(string)
    is_template          = optional(bool, false)
    extra_check_rulesets = optional(map(list(string)), {})
  }))
}
