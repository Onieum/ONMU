(function () {
  "use strict";

  var config = window.ONMU_BRAND_CONFIG || {};
  var dsn = valueAsString(config.sentryDsn);

  if (!dsn) {
    return;
  }

  var sdkUrl =
    valueAsString(config.sentrySdkUrl) ||
    "https://browser.sentry-cdn.com/10.59.0/bundle.min.js";
  var environment =
    valueAsString(config.sentryEnvironment) ||
    valueAsString(config.environment) ||
    "production";
  var release = valueAsString(config.sentryRelease) || "brand-web-static";
  var errorSampleRate = valueAsRate(config.sentryErrorSampleRate, 1);
  var tracesSampleRate = valueAsRate(config.sentryTracesSampleRate, 0);
  var safeTagKeys = {
    endpoint_template: true,
    environment: true,
    feature: true,
    kind: true,
    method: true,
    page: true,
    retryable: true,
    statusCode: true
  };
  var sensitiveHeaders = {
    authorization: true,
    cookie: true,
    "set-cookie": true,
    "x-api-key": true,
    "x-csrf-token": true
  };

  loadSentrySdk(sdkUrl, function () {
    if (!window.Sentry || typeof window.Sentry.init !== "function") {
      return;
    }

    window.Sentry.init({
      dsn: dsn,
      environment: environment,
      release: release,
      sampleRate: errorSampleRate,
      sendDefaultPii: false,
      tracesSampleRate: tracesSampleRate,
      beforeSend: scrubEvent,
      beforeBreadcrumb: scrubBreadcrumb
    });

    if (typeof window.Sentry.setTag === "function") {
      window.Sentry.setTag("feature", "brand-web");
      window.Sentry.setTag("page", window.location.pathname || "/");
    }
  });

  function loadSentrySdk(url, onload) {
    if (window.Sentry) {
      onload();
      return;
    }

    var script = document.createElement("script");
    script.src = url;
    script.async = true;
    script.crossOrigin = "anonymous";
    script.onload = onload;
    document.head.appendChild(script);
  }

  function scrubEvent(event) {
    if (!event || typeof event !== "object") {
      return event;
    }

    if (event.request) {
      event.request = scrubRequest(event.request);
    }
    event.user = undefined;
    event.extra = undefined;
    event.contexts = undefined;
    event.tags = scrubTags(event.tags || {});

    if (Array.isArray(event.breadcrumbs)) {
      event.breadcrumbs = event.breadcrumbs
        .map(scrubBreadcrumb)
        .filter(Boolean);
    }

    return event;
  }

  function scrubRequest(request) {
    var headers = request.headers || {};
    var safeHeaders = {};

    Object.keys(headers).forEach(function (key) {
      if (!sensitiveHeaders[key.toLowerCase()]) {
        safeHeaders[key] = headers[key];
      }
    });

    return Object.assign({}, request, {
      url: stripUrl(request.url),
      query_string: undefined,
      cookies: undefined,
      data: undefined,
      headers: safeHeaders
    });
  }

  function scrubBreadcrumb(breadcrumb) {
    if (!breadcrumb || typeof breadcrumb !== "object") {
      return breadcrumb;
    }

    if (breadcrumb.category === "console") {
      return null;
    }

    var next = Object.assign({}, breadcrumb);
    if (next.data) {
      next.data = scrubBreadcrumbData(next.data);
    }
    if (next.message) {
      next.message = trimString(next.message, 160);
    }
    return next;
  }

  function scrubBreadcrumbData(data) {
    var safe = {};

    Object.keys(data).forEach(function (key) {
      if (key === "url" || key === "from" || key === "to") {
        safe[key] = stripUrl(data[key]);
        return;
      }
      if (key === "method" || key === "status_code") {
        safe[key] = String(data[key]);
      }
    });

    return safe;
  }

  function scrubTags(tags) {
    var safe = {};

    Object.keys(tags).forEach(function (key) {
      if (safeTagKeys[key]) {
        safe[key] = trimString(String(tags[key]), 80);
      }
    });

    safe.feature = safe.feature || "brand-web";
    safe.environment = safe.environment || environment;
    safe.page = safe.page || window.location.pathname || "/";
    return safe;
  }

  function stripUrl(url) {
    try {
      var parsed = new URL(String(url || ""), window.location.href);
      return parsed.origin + parsed.pathname;
    } catch (_) {
      return window.location.origin + window.location.pathname;
    }
  }

  function valueAsString(value) {
    return typeof value === "string" ? value.trim() : "";
  }

  function valueAsRate(value, fallback) {
    var parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      return fallback;
    }
    return Math.min(1, Math.max(0, parsed));
  }

  function trimString(value, maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.slice(0, maxLength - 3) + "...";
  }
})();
