# Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Develop and verify

Run the local build and test suite from the repository root:

```powershell
./build.ps1
```

See [BUILDING.md](../BUILDING.md) for build and test commands, dependency version pins, and release conventions.

Use Conventional Commit messages and squash-merge PR titles, such as `fix: handle empty messages` or `chore: enable prerelease`. The shared [Copilot instructions](copilot-instructions.md) guide both chat and VS Code's commit-message generator through the workspace settings; they do not enforce commit validation.
