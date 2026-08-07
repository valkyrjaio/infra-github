# infra-github

Declarative GitHub organization configuration for Valkyrja, managed with
OpenTofu. Replaces `enforce-repo-settings.sh` and `create-repo.yml` in
`.github`. This repo manages every repo in the org — including itself.

Naming: first repo of the `infra-{product}` category — operational
infrastructure per product, never a language suffix (an infra repo is
language-agnostic by definition; language-specific tooling belongs in
`ci-{tool}-{lang}`).

## Layout

- `main.tf` — backend (local, `state/terraform.tfstate`), provider, module fan-out.
- `variables.tf` — the shape of a repo entry.
- `repos/<name>.yaml` — one file per repository; each declares its `language`
  explicitly.
- `languages/<lang>.yaml` — one file per language: the required-checks ruleset
  name and its contexts.
- `teams.tf` — org teams and memberships.
- `modules/repo/` — one repo's full desired state: settings, vulnerability
  alerts, the `claude-review` label, the six shared rulesets, the per-language
  required-checks ruleset, repo-specific extra rulesets, and the approvers grant.
- `.github/workflows/` — draft plan/apply workflows (see CI below).

## Running

```sh
GITHUB_TOKEN=$(gh auth token) tofu plan
```

Never run `tofu apply` locally — the Apply workflow owns every apply, and a
local apply races it for the state file.

## How to

### Add a new repo (creates it on apply)

Add `repos/<name>.yaml` with `template_repo` set, open a PR, read the plan,
merge. The apply creates the repo from the template, then applies settings,
rulesets, label, alerts, and the team grant in the same run.

```yaml
description: Shared toolname configuration for Valkyrja Lang projects
language: lang
template_repo: project-template-lang
```

The template copy brings only the template's default branch (the current ??.x,
which stays the new repo's default); a `github_branch` resource creates `master`
from it. Old ??.x branches, `master-backup`, and stray branches never come along.
`template_repo` is explicit, so future starter-* templates (components, modules,
tools) plug in without new machinery.

Warning: the template copy is asynchronous. The first apply can fail on the
master branch resource before the copy lands — re-run the Apply workflow and it
completes. Post-create steps that stay outside Terraform: the copyright package
identifier rewrite (Go also rewrites its module path) and the immutable-releases
API call.

### Change a repo's settings

Edit the repo's file under `repos/` (description, homepage, topics,
`is_template`). Org-wide settings (merge policy, features) are constants in
`modules/repo/main.tf` — changing one there changes all 36 repos in one PR, and
the plan shows every affected repo.

### Add a team

Declare the team and its members in `teams.tf`:

```hcl
resource "github_team" "release_managers" {
  name        = "release-managers"
  description = "…"
  privacy     = "closed"
}

resource "github_team_membership" "release_managers_melech" {
  team_id  = github_team.release_managers.id
  username = "MelechMizrachi"
  role     = "maintainer"
}
```

Grant repo access with `github_team_repository` (see the approvers grant in
`modules/repo/main.tf` for the pattern). Warning: anything driving a `count` or
a `dynamic for_each` must key off the team's static slug, never
`github_team.*.id` — the numeric id is unknown until the team exists and the
plan fails with "Invalid count argument". The id is only legal inside a
resource body.

### Add or change a ruleset

Three kinds, three places:

- **Shared (all repos)** — add a `github_repository_ruleset` resource next to
  the existing six in `modules/repo/rulesets.tf`. Every repo gets it on the
  next apply.
- **Language required checks** — edit the `contexts` list in the language's
  `languages/<lang>.yaml`. Adding a language means one new file
  (`ruleset_name` + `contexts`) and `language: <lang>` in its repos' files.
- **Repo-specific** — add `extra_check_rulesets` to the repo's file under
  `repos/`; the key is the ruleset name, the value the check contexts:

```yaml
extra_check_rulesets:
  Required Starter App PR Checks:
    - Sindri Go Test
```

To retire a ruleset, delete it from config — the apply deletes it from every
repo (this is the never-deletes gap in the old sweep, closed). The plan shows
the deletion before anything happens; read it.

### Add a label

`modules/repo/main.tf` — copy the `claude-review` `github_issue_label` resource.
Singular resources are ensure-only (GitHub's default labels stay untouched);
the plural `github_issue_labels` is authoritative and would delete undeclared
labels — decide before switching.

### Change a required check's name

The rename dance from `.github/workflows/README.md` still applies: the checks
must report under the new name before the ruleset requires it. Sequence the
two PRs (workflow rename first, ruleset update second) instead of commenting
out a cron.

### Yearly version branch

Bump the `version_branch` variable default in `modules/repo/variables.tf`
(e.g. `"26.x"` → `"27.x"`) when the new year's branches are cut — it is the
source branch for `master` on newly created repos.

## CI

- `plan.yml` — plan on every pull request, output in the job summary. The
  `Config Plan` context is required on this repo through its own
  `extra_check_rulesets` entry — the ruleset matches the job-name chain, so
  the job name is the context and the workflow name is only a display prefix.
  No `paths:` filter — a skipped required check drops its context and blocks
  merges.
- `apply.yml` — apply on every push to the default branch, weekly as the drift
  reverter, and on dispatch. Applies serialize through a concurrency group;
  each run pulls before applying so a queued apply starts from the state its
  predecessor committed. A job guard skips pushes authored by the Völundr bot
  (its only push here is the state commit, and re-applying it would loop) —
  deliberate choice over the `[skip ci]` tag. Völundr's ruleset bypass is what
  lets the state commit land on the protected default branch.
- Auth is the provider's own `app_auth` via `GITHUB_APP_*` env vars (no
  create-github-app-token step for tofu itself; the apply workflow mints a
  token only for the git push). Needs the org secret
  `VALKYRJA_GHA_INSTALLATION_ID` alongside the existing app secrets — a
  secret by choice, so every Völundr credential sits together in the secrets
  tab. Do not set `GITHUB_OWNER` — a documented provider bug lets it override
  the `owner` argument.

## Findings baked into the model

- The PHP/Java/TS starter apps each carry a live "Required Starter App PR
  Checks" ruleset that exists nowhere in `.github/rulesets/` (hand-applied; the
  sweep can't see it). Modeled via `extra_check_rulesets`. Go/Python starters
  get theirs once their Sindri tests exist.
- Starter apps and project templates are template repositories (`is_template`),
  EXCEPT `valkyrja-starter-app-go` — mirrored as-is; likely an oversight to fix
  as its own PR.
- Repos generated from a template permanently record the origin; the module
  ignores the `template` block via `lifecycle` or every such repo shows a
  phantom diff.
- Völundr (Integration 2462900) is the org's only GitHub App — sweeps,
  auto-merge, reviews, and bypass actors are all the same app. Its APPROVE
  verdicts count toward required approvals; accepted (kept for the verdict
  checkmark UI).
- Approvals only count from users with write access, hence the team push grant
  on every repo.

## Deliberate scope decisions

- Secret _values_ are never managed here (they would land in plaintext in
  state). Terraform manages the infrastructure around secrets, never their
  contents.
- Not modeled, kept as script remnants: immutable releases (no provider
  support), the Dependabot security-updates toggle (409s as already
  org-enforced today), the copyright identifier rewrite on new repos.
- The workflow-file sweeps (`ensure-workflows`, SHA repinning,
  `auto-merge-bot-prs`) stay in `.github` — content and PR workflows, not
  declarative resources.
