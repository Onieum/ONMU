const API_PREFIX = "/api/v1";

function notFound(path) {
  return {
    statusCode: 404,
    body: {
      ok: false,
      error: "not_found",
      path,
    },
  };
}

function methodNotAllowed(allowed) {
  return {
    statusCode: 405,
    body: {
      ok: false,
      error: "method_not_allowed",
      allowed,
    },
  };
}

function badRequest(message) {
  return {
    statusCode: 400,
    body: {
      ok: false,
      error: "bad_request",
      message,
    },
  };
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString("utf8").trim();
  if (!raw) {
    return {};
  }

  try {
    return JSON.parse(raw);
  } catch {
    throw new Error("Request body must be valid JSON.");
  }
}

function splitApiPath(pathname) {
  return pathname
    .slice(API_PREFIX.length)
    .split("/")
    .filter(Boolean)
    .map(decodeURIComponent);
}

function ok(body, statusCode = 200) {
  return { statusCode, body };
}

function homeRoutes(store, method, segments) {
  if (segments.length === 2 && segments[0] === "home" && segments[1] === "summary") {
    return method === "GET" ? ok(store.fetchHomeSummary()) : methodNotAllowed(["GET"]);
  }
  return null;
}

async function groupRoutes(store, req, method, segments) {
  if (segments[0] !== "groups") {
    return null;
  }

  if (segments.length === 1) {
    if (method === "GET") {
      return ok(store.fetchGroups());
    }
    if (method === "POST") {
      return ok(store.createGroup(await readJson(req)), 201);
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  const groupId = segments[1];

  if (segments.length === 2) {
    return method === "GET" ? ok(store.fetchGroup(groupId)) : methodNotAllowed(["GET"]);
  }

  if (segments.length === 3 && segments[2] === "summary") {
    if (method !== "GET") {
      return methodNotAllowed(["GET"]);
    }
    return ok({
      group: store.fetchGroup(groupId),
      pinnedPlan: store.fetchPinnedPlan(groupId),
      plans: store.fetchGroupPlans(groupId),
      recentMemories: store.fetchMemories(groupId).slice(0, 3),
      recentMessage: store.fetchMessages(groupId).at(-1) || null,
    });
  }

  if (segments.length === 3 && segments[2] === "members") {
    return method === "GET" ? ok(store.fetchMembers(groupId)) : methodNotAllowed(["GET"]);
  }

  if (segments.length === 3 && segments[2] === "messages") {
    return method === "GET" ? ok(store.fetchMessages(groupId)) : methodNotAllowed(["GET"]);
  }

  if (segments.length === 3 && segments[2] === "memories") {
    return method === "GET" ? ok(store.fetchMemories(groupId)) : methodNotAllowed(["GET"]);
  }

  if (segments.length === 4 && segments[2] === "memories") {
    return method === "GET"
      ? ok(store.fetchMemory({ groupId, memoryId: segments[3] }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 3 && segments[2] === "votes") {
    if (method === "GET") {
      return ok(store.fetchVotes(groupId));
    }
    if (method === "POST") {
      return ok(store.createVote({ ...(await readJson(req)), groupId }), 201);
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  if (segments.length === 4 && segments[2] === "votes") {
    return method === "GET"
      ? ok(store.fetchVoteCard({ groupId, voteId: segments[3] }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 5 && segments[2] === "votes" && segments[4] === "voters") {
    return method === "GET"
      ? ok(store.fetchVoteVoters({ groupId, voteId: segments[3] }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 3 && segments[2] === "plans") {
    if (method === "GET") {
      return ok(store.fetchGroupPlans(groupId));
    }
    if (method === "POST") {
      return ok(store.createPlan({ ...(await readJson(req)), groupId }), 201);
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  if (segments[2] === "plans" && segments.length >= 4) {
    return planRoutes(store, req, method, groupId, segments.slice(3));
  }

  return null;
}

async function planRoutes(store, req, method, groupId, segments) {
  const planId = segments[0];

  if (segments.length === 1) {
    if (method === "GET") {
      return ok(store.fetchPlan({ groupId, planId }));
    }
    if (method === "PATCH") {
      return ok(store.updatePlan({ groupId, planId, input: await readJson(req) }));
    }
    return methodNotAllowed(["GET", "PATCH"]);
  }

  if (segments.length === 2 && segments[1] === "itinerary") {
    return method === "GET"
      ? ok(store.fetchVisitPlansByDate({ groupId, planId }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 2 && segments[1] === "place-candidates") {
    if (method === "GET") {
      return ok(store.fetchPlaceCandidates({ groupId, planId }));
    }
    if (method === "POST") {
      return ok(store.addPlaceCandidate({ groupId, planId, input: await readJson(req) }), 201);
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  if (segments.length === 3 && segments[1] === "place-candidates") {
    return method === "GET"
      ? ok(store.fetchPlaceCandidate({ groupId, planId, candidateId: segments[2] }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 2 && segments[1] === "schedule-places") {
    if (method === "POST") {
      return ok(store.addSchedulePlace({ groupId, planId, input: await readJson(req) }), 201);
    }
    return methodNotAllowed(["POST"]);
  }

  if (segments.length === 2 && segments[1] === "votes") {
    if (method === "GET") {
      return ok(store.fetchVotes(groupId));
    }
    if (method === "POST") {
      return ok(
        store.createVote({
          ...(await readJson(req)),
          groupId,
          planId,
          targetType: "PLAN",
          targetId: planId,
          compatibilityRoute: true,
          canonicalPath: `/api/v1/groups/${groupId}/votes`,
        }),
        201,
      );
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  if (segments.length === 3 && segments[1] === "votes") {
    return method === "GET"
      ? ok(store.fetchVoteCard({ groupId, voteId: segments[2] }))
      : methodNotAllowed(["GET"]);
  }

  if (segments.length === 2 && segments[1] === "settlement-draft") {
    if (method === "GET") {
      return ok(store.fetchSettlementDraft({ groupId, planId }));
    }
    if (method === "PATCH") {
      return ok(store.updateSettlementDraft({ groupId, planId, input: await readJson(req) }));
    }
    return methodNotAllowed(["GET", "PATCH"]);
  }

  if (segments.length === 5 && segments[1] === "settlement-draft" && segments[2] === "items" && segments[4] === "targets") {
    return method === "PATCH"
      ? ok(store.updateSettlementDraftTargets({ groupId, planId, itemId: segments[3], input: await readJson(req) }))
      : methodNotAllowed(["PATCH"]);
  }

  if (segments.length === 2 && segments[1] === "settlements") {
    if (method === "GET") {
      return ok(store.fetchSettlement({ groupId, planId }));
    }
    if (method === "POST") {
      return ok(store.createSettlement({ groupId, planId, input: await readJson(req) }), 201);
    }
    return methodNotAllowed(["GET", "POST"]);
  }

  if (segments.length === 3 && segments[1] === "settlements" && segments[2] === "preview") {
    return method === "POST"
      ? ok(store.previewSettlement({ groupId, planId, input: await readJson(req) }))
      : methodNotAllowed(["POST"]);
  }

  if (segments.length === 3 && segments[1] === "settlements") {
    return method === "GET"
      ? ok(store.fetchSettlement({ groupId, planId, settlementId: segments[2] }))
      : methodNotAllowed(["GET"]);
  }

  return null;
}

async function placeSearchRoutes(store, req, method, segments, url) {
  if (segments.length === 1 && segments[0] === "place-search") {
    if (method !== "GET" && method !== "POST") {
      return methodNotAllowed(["GET", "POST"]);
    }
    if (method === "POST") {
      const input = await readJson(req);
      return ok({
        canonicalRoute: true,
        query: input.query || input.keyword || "",
        filters: input.filters || {},
        context: {
          groupId: input.groupId || null,
          planId: input.planId || null,
          bounds: input.bounds || null,
        },
        results: store.searchPlaces(input.query || input.keyword || ""),
      });
    }
    return ok({
      compatibilityRoute: true,
      canonicalPath: "POST /api/v1/place-search",
      query: url.searchParams.get("query") || "",
      results: store.searchPlaces(url.searchParams.get("query") || ""),
    });
  }
  return null;
}

export function createDevContractRouter(store) {
  return async function handleDevContractRoute(req, url) {
    if (!url.pathname.startsWith(`${API_PREFIX}/`)) {
      return { handled: false };
    }

    const method = req.method || "GET";
    const segments = splitApiPath(url.pathname);

    try {
      const result =
        homeRoutes(store, method, segments) ||
        (await groupRoutes(store, req, method, segments)) ||
        (await placeSearchRoutes(store, req, method, segments, url));

      return { handled: true, ...(result || notFound(url.pathname)) };
    } catch (error) {
      return {
        handled: true,
        ...badRequest(error.message),
      };
    }
  };
}
