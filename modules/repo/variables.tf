#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

variable "name" {
  description = "Repository name."
  type        = string
}

variable "description" {
  description = "Repository description."
  type        = string
  default     = ""
}

variable "homepage" {
  description = "Repository homepage URL."
  type        = string
  default     = ""
}

variable "topics" {
  description = "Repository topics."
  type        = list(string)
  default     = []
}

variable "language" {
  description = "Primary language, selecting the language-specific required-checks ruleset. Must name a key of language_checks. Null for repos with no language CI."
  type        = string
  default     = null
}

variable "language_checks" {
  description = "Per-language required-checks rulesets, keyed by language: { ruleset_name, contexts }."
  type = map(object({
    ruleset_name = string
    contexts     = list(string)
  }))
  default = {}
}

variable "template_repo" {
  description = "Template repository to scaffold from at creation (e.g. project-template-php). Only used when the repository is created; ignored for existing repositories."
  type        = string
  default     = null
}

variable "require_team_approval" {
  description = "Whether the Require Pull Request ruleset demands an approval from the approvers team."
  type        = bool
  default     = false
}

variable "approvers_team_slug" {
  description = "Slug of the team whose approval the Require Pull Request ruleset demands; the team also gets push access so its members' approvals count. Must be a static string (it drives count). Null disables the requirement."
  type        = string
  default     = null
}

variable "approvers_team_id" {
  description = "Numeric id of the approvers team (may be unknown until apply); used inside the ruleset's required_reviewers rule."
  type        = number
  default     = null
}

variable "version_branch" {
  description = "The current-year version branch (the templates' default branch); the source for master on newly created repos."
  type        = string
  default     = "26.x"
}

variable "is_template" {
  description = "Whether the repository is a template repository (starter apps, project templates)."
  type        = bool
  default     = false
}

variable "extra_check_rulesets" {
  description = "Additional repo-specific required-check rulesets, keyed by ruleset name, each a list of check contexts (e.g. the starter apps' Sindri/E2E checks)."
  type        = map(list(string))
  default     = {}
}
