module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [
      2,
      "always",
      [
        "mobile",
        "brand-web",
        "api",
        "realtime",
        "worker",
        "place",
        "memory",
        "profile",
        "infra",
        "ci",
        "docs",
        "repo",
      ],
    ],
  },
};
