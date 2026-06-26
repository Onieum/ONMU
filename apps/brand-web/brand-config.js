window.ONMU_BRAND_CONFIG = Object.assign(
  {
    sentryDsn: "",
    sentryEnvironment: "production",
    sentryRelease: "brand-web-static",
    sentryErrorSampleRate: 1,
    sentryTracesSampleRate: 0,
    sentrySdkUrl: "https://browser.sentry-cdn.com/10.59.0/bundle.min.js",
    downloads: {
      iosUrl: "https://stonmustagingkrc001.blob.core.windows.net/tiles/downloads/mobile/latest/onmu-ios-unsigned-xcarchive.zip",
      androidUrl: "https://stonmustagingkrc001.blob.core.windows.net/tiles/downloads/mobile/latest/onmu-android-arm64.apk",
      checksumsUrl: "https://stonmustagingkrc001.blob.core.windows.net/tiles/downloads/mobile/latest/SHA256SUMS.txt",
      iosLabel: "iOS archive 다운로드",
      androidLabel: "Android APK 다운로드",
      iosStatus: "iOS archive 연결됨 · 코드서명 필요",
      androidStatus: "Android APK 연결됨 · arm64"
    }
  },
  window.ONMU_BRAND_CONFIG || {}
);
