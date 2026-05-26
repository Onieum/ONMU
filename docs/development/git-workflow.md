# Git Workflow

## Branch Strategy

```text
main  -> stable release branch
dev   -> integration branch
feat/*, fix/*, docs/*, chore/* -> working branches
```

Rules:

- `dev` is the default working branch.
- `main` receives release PRs only.
- No direct push to `dev` or `main`.
- Create a Jira issue before creating a branch.
- Include the Jira key in branch names, commits, or PR body whenever possible.

## Branch Naming

```text
type/short-description
```

Allowed types:

- `feat`
- `fix`
- `hotfix`
- `docs`
- `chore`
- `refactor`
- `test`
- `set`

Examples:

```text
feat/flutter-room-shell
feat/place-candidate-score
docs/jira-notion-automation
chore/ci-baseline
```

## Commit Convention

```text
type(scope): short description
```

Examples:

```text
feat(mobile): add room tab shell
feat(place): add candidate risk model
docs(infra): describe aks baseline
ci(repo): add flutter workflow
```

## PR Convention

PR title:

```text
[Feat] 장소 후보 점수 모델 추가
```

PR body must include:

- Summary
- Changes
- Test
- Related
