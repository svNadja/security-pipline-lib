Zentrales privates Repo: security-pipelines
 └─ .github/workflows/
    ├─ secrets.yml        (Gitleaks)
    ├─ sast-python.yml    (Bandit + Semgrep)
    ├─ sast-generic.yml   (Semgrep, Regeln per Parameter)
    ├─ sca-*.yml          (pip-audit / cargo-audit / Dependency-Check)
    ├─ container.yml      (Hadolint, Docker-Build, Trivy, Syft, Cosign)
    ├─ iac.yml            (Checkov: Dockerfile, Compose, GH-Workflows)
    ├─ dast.yml           (docker compose up → ZAP)
    └─ upload-dojo.yml    (Reports → DefectDojo API)
        ▲ uses:
Repo 1 / 2 / 3 → jeweils nur eine kurze security.yml





---
## Aufruf Repo1
`yaml .github/workflows/security.yml
name: security
on: { pull_request: {}, push: { branches: [main] }, schedule: [{ cron: "0 2 * * *" }] }
permissions: { contents: read }
jobs:
  secrets:  { uses: org/security-pipelines/.github/workflows/secrets.yml@<sha>, secrets: inherit }
  sast:     { uses: org/security-pipelines/.github/workflows/sast-python.yml@<sha>, secrets: inherit }
  sca:      { uses: org/security-pipelines/.github/workflows/sca-python.yml@<sha>, secrets: inherit }
  iac:      { uses: org/security-pipelines/.github/workflows/iac.yml@<sha>, secrets: inherit }
  container:
    if: github.event_name != 'pull_request'
    uses: org/security-pipelines/.github/workflows/container.yml@<sha>
    secrets: inherit
  dast:
    if: github.event_name == 'schedule'
    uses: org/security-pipelines/.github/workflows/dast.yml@<sha>
    with: { mode: api, spec: openapi.yaml }
    secrets: inherit