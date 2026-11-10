# Building and releasing PSMQTT

## Develop and verify

From the repository root, run the full build and test suite:

```powershell
./build.ps1
```

The default `Verify` task builds the module from `source/` and runs tests from `tests/`. To run one task:

```powershell
./build.ps1 -Task Build
./build.ps1 -Task Test
./build.ps1 -Task Package
```

Import the generated module from `output/PSMQTT/<version>/` to try it locally. Make changes in `source/`, not generated output under `output/`.

Local tests run all suites by default. Use `-Task Test -TestSuite Module` for unit/QA tests or `-Task Test -TestSuite Infrastructure` for build/release tests. CI runs module tests with coverage across all supported platforms, and infrastructure tests once on Linux PowerShell 7 without coverage. Release publishing runs the module suite.

Coverage instruments the built module that the tests execute, then uses ModuleBuilder's source mappings to report the original `source/public` and `source/private` files in `output/testResults/JaCoCo_coverage.xml`. The module test run fails if coverage is below the configured target (currently 1%).

The QA suite in `tests/QA/module.tests.ps1` reports each file-quality check separately. It discovers source files and reads unit-test files once per run, and parses each function file once in its context's `BeforeAll`. Keep these shared inputs read-only so individual checks remain independent.

Stable-promotion tests mock Git and the GitHub API. They use temporary release-metadata files without initializing repositories or creating commits and tags; these are unit tests, not Git integration tests.

### VS Code shortcuts

- **Ctrl+Shift+B** runs `Verify` (build and tests). **Tasks: Run Task** also offers `build`, `test`, and `package`; `test` rebuilds first.
- Select **PowerShell Debug Module (build first)** and press **F5**. It builds, then runs [ModuleDebug.ps1](ModuleDebug.ps1) in a temporary PowerShell console, avoiding stale module state. Keep manual end-user scenarios and breakpoints in that script.
- To step into module functions, set breakpoints in the generated `output/PSMQTT/<version>/PSMQTT.psm1` after building. Rebuilds replace this file; edit only `source/`.

Tasks require PowerShell 7 (`pwsh` on PATH). Debugging requires the VS Code PowerShell extension and uses its selected PowerShell session.

## Submit a change

1. Make and test your change on a branch.
2. Open a pull request against `main`. CI runs for pull requests and pushes to `main`. Pushes that only change release metadata (`.release-please-manifest.json`, `version.txt`, `CHANGELOG.md`), such as merged release PRs, skip CI on `main` because the PR and the release workflow already test them.
3. Use a Conventional Commit title for changes that should trigger a release. `feat:` requests a minor release; `fix:` and `perf:` request a patch; `!` or a `BREAKING CHANGE:` footer requests a major release. `docs:`, `test:`, and `chore:` do not trigger releases.
4. Squash-merge using the PR title as the commit message so Release Please can determine the correct version and generate release notes.

## Release channel cheat sheet

| How it starts | Channel | What happens |
| --- | --- | --- |
| Ordinary PR or push to `main` | None | CI only; no release preparation or PR refresh. |
| **Actions → Prepare release → Run workflow → `beta`** (from `main`) | Beta | Opens or explicitly refreshes the beta release PR when conventional commits warrant one; never creates a tag or release. |
| **Actions → Prepare release → Run workflow → `stable`** (from `main`) | Stable promotion | Opens a stable promotion PR for the latest published beta, including with zero new commits. |
| Merge the release PR | Its recorded channel | Finalizes the tag/GitHub release only; never prepares another PR. |

Review the release PR version and notes, wait for CI, and merge it to publish. The release PR remains the gate for both channels. A stable promotion requires the latest beta to be published and `main` to have no commits after that beta; merge any pending beta release first. It creates a metadata-only release PR, so no config toggle or dummy fix commit is needed. Stable notes roll up beta entries since the previous stable release; beta entries remain in the changelog. Missing or unrecognized release boundaries fail the workflow instead of silently omitting notes.

Keep `main` at that beta until the stable promotion merges, using squash or a merge commit (not rebase). Finalization rechecks the merge's first parent against the published beta tag; intervening changes fail closed instead of silently releasing untested changes as stable.

An open stable promotion blocks manual beta preparation. Re-running stable preparation leaves an existing promotion unchanged; close it to start over. Ordinary pushes never rewrite release PRs.

Merged-PR finalization requires the same-repository release branch, pending label, generated bot metadata, and the author matching the dedicated `RELEASE_PLEASE_TOKEN` owner's login (a user/PAT token). Only the three release metadata files may change. The title, body, immutable head/merge manifests and `stable-promotion` label must agree before selecting the checked-in channel configuration. Do not edit channel labels or release metadata by hand. Finalization checks out trusted `main`, never the PR head, and refuses other merged pending releases rather than publishing them in the wrong channel. Resolve stale pending labels before retrying a failed finalization.

`RELEASE_PLEASE_TOKEN` needs repository contents, issues and pull-request write access. It creates release PRs and releases so their events can trigger CI and publishing (unlike the default Actions token). The workflow has no default token permissions; its gated jobs grant the Actions token only contents-read access for checkout.

The release workflow checks that the immutable tag, tracked version, GitHub prerelease flag, and built module manifest agree before publishing.

The release workflow builds and tests the tag, attaches a ZIP to the GitHub release, and publishes the module to the PowerShell Gallery. Do not edit `.release-please-manifest.json` or toggle release configuration during routine development.

Prereleases use padded labels such as `beta001`. Users must opt in when installing, for example:

```powershell
Install-Module PSMQTT -AllowPrerelease
```

## Documentation publishing

Stable releases update getps.dev through `scripts/Update-Docs.ps1`. Generated command help, README and changelog belong in `modules/<ModuleName>` at the documentation repository root. The site's separate module-docs plugin reads this folder; `docs/modules` belongs to the Knowledge Base instead.

## Update build dependencies

1. Change the intended module version in [RequiredModules.psd1](RequiredModules.psd1).
2. Restore the pinned dependencies and verify the build:

```powershell
./build.ps1 -Task InstallDependencies
./build.ps1
```

The build uses these pinned dependencies from `output/RequiredModules`; you do not need to install them separately.

Pipeline kit: hanpq/PSLogs@ca723099f0daee74603a2168df589e95f07bed34
