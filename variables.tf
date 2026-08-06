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
