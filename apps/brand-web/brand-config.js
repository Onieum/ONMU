window.ONMU_BRAND_CONFIG = Object.assign(
  {
    sentryDsn: "",
    sentryEnvironment: "production",
    sentryRelease: "brand-web-static",
    sentryErrorSampleRate: 1,
    sentryTracesSampleRate: 0,
    sentrySdkUrl: "https://browser.sentry-cdn.com/10.59.0/bundle.min.js",
    downloads: {
      iosUrl: "",
      androidUrl: ""
    }
  },
  window.ONMU_BRAND_CONFIG || {}
);
