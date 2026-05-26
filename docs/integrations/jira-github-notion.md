# Jira, GitHub, Notion Integration Guide

## Current Project Choices

| Tool | Role |
| --- | --- |
| Jira | Sprint planning, backlog, epics, stories, tasks, bugs |
| GitHub | Code, pull requests, reviews, CI/CD |
| Notion | Product docs, meeting notes, decisions, research, sprint review notes |

Jira should remain the source of truth for delivery status. Notion should provide context and documentation, not replace the Jira board.

## Jira Project Setup

Recommended issue types:

- Epic
- Story
- Task
- Bug

Recommended epics:

- Platform / Infra
- Flutter Mobile
- Profile & Preference
- Meetup & Realtime
- Place & External API
- Memory / Character
- Brand Web
- QA / Release / Observability

Recommended statuses:

- Backlog
- To Do
- In Progress
- In Review
- Blocked
- Done

## Jira Bootstrap Script

This repo includes:

```bash
scripts/bootstrap-jira.mjs
```

Required environment:

```bash
export JIRA_BASE_URL="https://onmu.atlassian.net"
export JIRA_PROJECT_KEY="SCRUM"
export JIRA_EMAIL="your-atlassian-email@example.com"
export JIRA_API_TOKEN="your-api-token"
npm run jira:bootstrap
```

The script creates recommended epics, first vertical prototype stories, and setup tasks. It does not store credentials.

If API authentication is not available yet, use the CSV seed file instead:

```text
docs/integrations/jira-seed-backlog.csv
```

Import it from Jira using project import/CSV import, then map:

| CSV column | Jira field |
| --- | --- |
| `Issue Type` | Issue Type |
| `Summary` | Summary |
| `Description` | Description |
| `Labels` | Labels |
| `Epic Name` | Epic Name |
| `Epic Link` | Parent/Epic Link, depending on project type |

## GitHub For Jira

Install the official GitHub for Jira app from Atlassian Marketplace and connect the `Onieum/ONMU` repository.

After linking, Jira can show related branches, commits, PRs, deployments, and build information when issue keys appear in branch names, commit messages, or PR bodies.

Recommended branch/PR format:

```text
feat/SCRUM-12-place-candidate-score
feat(place): SCRUM-12 add place candidate score
```

## Smart Commits

When enabled in Jira, commits can update issues using commands:

```text
SCRUM-12 #comment implemented first API contract
SCRUM-12 #time 1h 30m
SCRUM-12 #transition "In Review"
```

Use Smart Commits carefully. For the team, the safest first rule is:

- Always include the Jira issue key.
- Do not auto-transition to Done from commits.
- Use PR merge and review status as the primary workflow signal.

## GitHub Automation

This repo includes `.github/workflows/jira-sync.yml`, which warns when a PR does not include a `SCRUM-123` style Jira key.

Recommended future automation:

| Trigger | Automation |
| --- | --- |
| PR opened with Jira key | Add comment to Jira issue |
| PR merged | Transition Jira issue to Done or In Review depending on team rule |
| Release tag pushed | Create Jira release version and attach linked issues |
| GitHub Actions failed | Add Jira comment or Slack alert |

## Notion Integration

Recommended Notion structure:

```text
ONMU Home
  - Product brief
  - Release architecture
  - Sprint dashboard
  - Decisions
  - Meeting notes
  - Research
  - Jira synced database
  - GitHub PR/release links
```

Best connection pattern:

1. Use Notion Jira Sync to mirror Jira issues into a Notion database.
2. Keep Jira as the editable sprint board.
3. Use Notion for docs, decisions, meeting notes, and sprint review summaries.
4. Link Notion decision pages back to Jira epics.
5. Link Jira epics to GitHub milestones or labels.

Do not manually duplicate every Jira task in Notion. That creates drift. Instead, sync Jira into Notion and add product/context docs around it.

## What Needs Manual Authorization

The following steps require an authenticated Jira/Notion admin in the browser or CLI:

- Install GitHub for Jira.
- Authorize access to the GitHub organization.
- Generate a Jira API token or login through `acli`.
- Enable Notion Jira Sync.
- Invite team members and set permissions.

## Useful References

- Atlassian CLI installation: https://developer.atlassian.com/cloud/acli/guides/install-acli/
- Jira Cloud REST API: https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/
- Jira Smart Commits: https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/
- GitHub for Jira: https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-github/
- Notion Jira integration: https://www.notion.com/integrations/jira
