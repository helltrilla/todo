# GIT_CONVENTIONS.md

You are an autonomous AI software engineer. When interacting with Git, creating commits, or preparing releases in this repository, you MUST follow these rules strictly.

## 1. Commit Messages (Conventional Commits)
All commit messages must follow the Conventional Commits standard in English, using the imperative mood (e.g., "add" not "added").

**Format:**
`<type>(<optional scope>): <description>`

**Allowed Types:**
- `feat:` - A new feature
- `fix:` - A bug fix
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `chore:` - Build process, dependencies, or auxiliary tool changes
- `docs:` - Documentation only changes
- `style:` - UI tweaks, formatting, missing semi-colons, etc.

**Examples:**
- `feat: add google maps integration`
- `fix: resolve crash on empty search result`
- `chore: update flutter version to 3.19`

## 2. Commit Strategy (Atomic Commits)
- **One logical change per commit:** Do not mix new features, bug fixes, and refactoring into a single massive commit.
- **Review before commit:** Always check `git status` and `git diff` before committing. Never commit unintended files, secrets, or debug logs.

## 3. Branching Strategy (GitHub Flow)
- Do not commit complex features directly to the `main` branch.
- Create a specific feature or bugfix branch: `git checkout -b feature/<name>` or `bugfix/<name>`.
- Once changes are complete and tested, they should be merged via a Pull Request.

## 4. Versioning and Releases (SemVer)
We follow Semantic Versioning (`MAJOR.MINOR.PATCH`).

- **PATCH (`x.x.1`):** For backwards-compatible bug fixes (mostly `fix:`).
- **MINOR (`x.1.x`):** For new backwards-compatible features (mostly `feat:`).
- **MAJOR (`1.x.x`):** For incompatible API changes, massive refactoring, or major rewrites.

**Release Process:**
When instructed to prepare a release:
1. Update the version in configuration files (e.g., `pubspec.yaml`).
2. Commit the version bump: `git commit -m "chore: release vX.Y.Z"`.
3. Create a Git tag matching the version exactly: `git tag vX.Y.Z`.
4. Push the commit and the tag to origin: `git push origin main && git push origin vX.Y.Z`.
5. Note: CI/CD pipelines (GitHub Actions) will automatically intercept the tag to build artifacts and publish the GitHub Release. Do not manually upload artifacts.