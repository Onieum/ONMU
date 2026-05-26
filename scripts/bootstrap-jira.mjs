import process from "node:process";

const baseUrl = mustEnv("JIRA_BASE_URL").replace(/\/$/, "");
const projectKey = mustEnv("JIRA_PROJECT_KEY");
const email = mustEnv("JIRA_EMAIL");
const apiToken = mustEnv("JIRA_API_TOKEN");

const auth = Buffer.from(`${email}:${apiToken}`).toString("base64");

function mustEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function adf(text) {
  return {
    type: "doc",
    version: 1,
    content: [
      {
        type: "paragraph",
        content: [{ type: "text", text }],
      },
    ],
  };
}

async function jira(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Basic ${auth}`,
      ...(options.headers ?? {}),
    },
  });

  const bodyText = await response.text();
  let body = null;
  if (bodyText) {
    try {
      body = JSON.parse(bodyText);
    } catch {
      body = bodyText;
    }
  }

  if (!response.ok) {
    throw new Error(`${options.method ?? "GET"} ${path} failed: ${response.status} ${bodyText}`);
  }
  return body;
}

async function getIssueTypes() {
  const meta = await jira(`/rest/api/3/issue/createmeta/${projectKey}/issuetypes`);
  return meta.issueTypes ?? meta.values ?? [];
}

function findIssueType(issueTypes, names) {
  const normalized = new Map(issueTypes.map((type) => [type.name.toLowerCase(), type]));
  for (const name of names) {
    const hit = normalized.get(name.toLowerCase());
    if (hit) return hit;
  }
  return null;
}

async function createIssue({ issueType, summary, description, parentKey, labels = [] }) {
  const fields = {
    project: { key: projectKey },
    issuetype: { id: issueType.id },
    summary,
    description: adf(description),
    labels,
  };
  if (parentKey) {
    fields.parent = { key: parentKey };
  }

  try {
    return await jira("/rest/api/3/issue", {
      method: "POST",
      body: JSON.stringify({ fields }),
    });
  } catch (error) {
    if (!parentKey) throw error;
    console.warn(`Could not create "${summary}" under ${parentKey}. Retrying without parent.`);
    delete fields.parent;
    return jira("/rest/api/3/issue", {
      method: "POST",
      body: JSON.stringify({ fields }),
    });
  }
}

const epics = [
  ["Platform / Infra", "AKS, Docker, CI/CD, observability, release infrastructure."],
  ["Flutter Mobile", "Flutter app shell, flavors, navigation, API client, realtime client."],
  ["Profile & Preference", "User profile, taste tags, availability, saved places."],
  ["Meetup & Realtime", "Meetup room, participants, schedules, votes, live status."],
  ["Place & External API", "Place search, external APIs, route time, place risk, candidate scoring."],
  ["Memory / Character", "Photo upload, memory cards, character and sticker expression."],
  ["Brand Web", "Public brand and project introduction website."],
  ["QA / Release / Observability", "Device QA, smoke tests, dashboards, alerts, release checklist."],
];

const stories = [
  ["Flutter Mobile", "Build Flutter app skeleton with dev/staging/prod flavors", "The app can launch per flavor and read the correct API base URL."],
  ["Profile & Preference", "Create profile preference input flow", "A user can save taste tags and availability through the API."],
  ["Meetup & Realtime", "Create meetup room and participant join flow", "A room can be created and participants can join with persisted state."],
  ["Place & External API", "Add place candidate search and scoring prototype", "A meetup room can receive place candidates with score and risk data."],
  ["Memory / Character", "Create memory card stub after meetup decision", "A selected meetup can produce a simple memory card result."],
  ["Platform / Infra", "Prepare local Compose and AKS staging baseline", "Local dependencies run with Compose and staging manifests have a baseline layout."],
  ["QA / Release / Observability", "Define vertical prototype smoke test", "The first connected flow has a repeatable smoke checklist."],
];

const tasks = [
  ["Platform / Infra", "Connect GitHub repository to Jira", "Install GitHub for Jira and verify SCRUM issue keys link from PRs."],
  ["Platform / Infra", "Create Notion project hub", "Create Notion pages for decisions, meeting notes, sprint review, and linked Jira database."],
  ["Brand Web", "Draft brand web content structure", "Prepare sections for product concept, architecture, team, demo, and links."],
];

const issueTypes = await getIssueTypes();
const epicType = findIssueType(issueTypes, ["Epic", "에픽"]);
const storyType = findIssueType(issueTypes, ["Story", "스토리"]);
const taskType = findIssueType(issueTypes, ["Task", "작업"]);

if (!epicType) {
  throw new Error("Epic issue type was not found. Add Epic to the Jira project issue types, then rerun this script.");
}
if (!storyType || !taskType) {
  throw new Error("Story or Task issue type was not found. Check Jira project issue types, then rerun this script.");
}

const epicKeysBySummary = new Map();

for (const [summary, description] of epics) {
  const issue = await createIssue({
    issueType: epicType,
    summary,
    description,
    labels: ["onmu", "epic"],
  });
  epicKeysBySummary.set(summary, issue.key);
  console.log(`Created epic ${issue.key}: ${summary}`);
}

for (const [epicSummary, summary, description] of stories) {
  const issue = await createIssue({
    issueType: storyType,
    summary,
    description,
    parentKey: epicKeysBySummary.get(epicSummary),
    labels: ["onmu", "vertical-prototype"],
  });
  console.log(`Created story ${issue.key}: ${summary}`);
}

for (const [epicSummary, summary, description] of tasks) {
  const issue = await createIssue({
    issueType: taskType,
    summary,
    description,
    parentKey: epicKeysBySummary.get(epicSummary),
    labels: ["onmu", "setup"],
  });
  console.log(`Created task ${issue.key}: ${summary}`);
}
