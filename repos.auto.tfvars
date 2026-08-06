#
# This file is part of the Valkyrja GitHub Infra package.
#
# Copyright (c) 2016-present Melech Mizrachi
#
# Released under the MIT License. See LICENSE.md for details.
#

repos = {
  "infra-github" = {
    description = "Declarative GitHub organization configuration"
    extra_check_rulesets = {
      "Required Infra PR Checks" = ["Config Plan"]
    }
  }
}
