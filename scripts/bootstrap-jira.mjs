import process from "node:process";

const baseUrl = mustEnv("JIRA_BASE_URL").replace(/\/$/, "");
const projectKey = mustEnv("JIRA_PROJECT_KEY");
const email = mustEnv("JIRA_EMAIL");
const apiToken = mustEnv("JIRA_API_TOKEN");

const auth = Buffer.from(`${email}:${apiToken}`).toString("base64");

function mustEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`필수 환경 변수가 없습니다: ${name}`);
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
    throw new Error(`${options.method ?? "GET"} ${path} 실패: ${response.status} ${bodyText}`);
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
    console.warn(`"${summary}" 이슈를 ${parentKey} 아래에 만들 수 없습니다. parent 없이 다시 시도합니다.`);
    delete fields.parent;
    return jira("/rest/api/3/issue", {
      method: "POST",
      body: JSON.stringify({ fields }),
    });
  }
}

const epics = [
  ["Platform / Infra", "AKS, Docker, CI/CD, 관측성, 릴리스 인프라."],
  ["Flutter Mobile", "Flutter 앱 shell, flavor, navigation, API client, realtime client."],
  ["Profile & Preference", "사용자 프로필, 취향 태그, 가능 시간, 저장 장소."],
  ["Meetup & Realtime", "약속 방, 참여자, 일정, 투표, 실시간 상태."],
  ["Place & External API", "장소 검색, 외부 API, 이동 시간, 장소 리스크, 후보 점수화."],
  ["Memory / Character", "사진 업로드, 기억 카드, 캐릭터와 스티커 표현."],
  ["Brand Web", "공개 브랜드 및 프로젝트 소개 웹사이트."],
  ["QA / Release / Observability", "기기 QA, smoke test, dashboard, alert, 릴리스 체크리스트."],
];

const stories = [
  ["Flutter Mobile", "dev/staging/prod flavor를 가진 Flutter 앱 skeleton 구축", "앱이 flavor별로 실행되고 올바른 API base URL을 읽을 수 있습니다."],
  ["Profile & Preference", "프로필 취향 입력 흐름 생성", "사용자가 API를 통해 취향 태그와 가능 시간을 저장할 수 있습니다."],
  ["Meetup & Realtime", "약속 방과 참여자 join 흐름 생성", "방을 생성하고 참여자가 join하면 상태가 저장됩니다."],
  ["Place & External API", "장소 후보 검색과 점수화 prototype 추가", "약속 방이 점수와 리스크 데이터가 포함된 장소 후보를 받을 수 있습니다."],
  ["Memory / Character", "약속 결정 이후 기억 카드 stub 생성", "선택된 약속이 간단한 기억 카드 결과를 만들 수 있습니다."],
  ["Platform / Infra", "로컬 Compose와 AKS staging baseline 준비", "로컬 의존성이 Compose로 실행되고 staging manifest가 기본 구조를 갖습니다."],
  ["QA / Release / Observability", "세로 prototype smoke test 정의", "첫 연결 흐름을 반복 가능한 smoke checklist로 확인할 수 있습니다."],
];

const tasks = [
  ["Platform / Infra", "GitHub 저장소를 Jira에 연결", "GitHub for Jira를 설치하고 PR에서 SCRUM 이슈 키가 연결되는지 확인합니다."],
  ["Platform / Infra", "Notion 프로젝트 허브 생성", "결정 기록, 회의록, sprint review, 연결된 Jira database용 Notion page를 만듭니다."],
  ["Brand Web", "브랜드 웹 콘텐츠 구조 초안 작성", "제품 개념, 아키텍처, 팀, demo, link section을 준비합니다."],
];

const issueTypes = await getIssueTypes();
const epicType = findIssueType(issueTypes, ["Epic", "에픽"]);
const storyType = findIssueType(issueTypes, ["Story", "스토리"]);
const taskType = findIssueType(issueTypes, ["Task", "작업"]);

if (!epicType) {
  throw new Error("Epic issue type을 찾지 못했습니다. Jira project issue type에 Epic을 추가한 뒤 다시 실행합니다.");
}
if (!storyType || !taskType) {
  throw new Error("Story 또는 Task issue type을 찾지 못했습니다. Jira project issue type을 확인한 뒤 다시 실행합니다.");
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
  console.log(`epic 생성: ${issue.key}: ${summary}`);
}

for (const [epicSummary, summary, description] of stories) {
  const issue = await createIssue({
    issueType: storyType,
    summary,
    description,
    parentKey: epicKeysBySummary.get(epicSummary),
    labels: ["onmu", "vertical-prototype"],
  });
  console.log(`story 생성: ${issue.key}: ${summary}`);
}

for (const [epicSummary, summary, description] of tasks) {
  const issue = await createIssue({
    issueType: taskType,
    summary,
    description,
    parentKey: epicKeysBySummary.get(epicSummary),
    labels: ["onmu", "setup"],
  });
  console.log(`task 생성: ${issue.key}: ${summary}`);
}
