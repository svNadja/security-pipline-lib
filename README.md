# security-pipelines

Zentrales privates Repo mit GitHub-Workflows für Security-Checks.
Die einzelnen Repos sollen sie per `uses:` einbinden und brauchen nur eine kurze `security.yml`.

## Struktur

```text
security-pipelines
├─ .github/workflows/
│  ├─ security.yml      (Pipeline dieses Repos: ruft alle Scans auf)
│  ├─ gitleaks.yml      (Secrets, ganze Historie + Working Tree)
│  ├─ semgrep.yml       (SAST, ganzer Code)
│  ├─ checkov.yml       (IaC: Dockerfile, Compose, GH-Workflows)
│  ├─ cargo-audit.yml   (SCA für Rust, alle Crates)
│  ├─ npm-audit.yml     (SCA für npm, alle Projekte)
│  └─ openbao.yml       (CI für das OpenBao-Setup)
├─ docker/Dockerfile    (OpenBao-Image mit eingebackener Config)
├─ docker-compose.yml   (OpenBao-Container)
├─ config/openbao.hcl   (OpenBao-Serverkonfiguration)
└─ Makefile             (build, run, init, unseal, login)
```

## Workflows

Alle Scan-Workflows sind wiederverwendbar (`workflow_call`), scannen den **gesamten Code** des
aufrufenden Repos und schreiben ihre Reports nach `reports/` (als Artefakt hochgeladen, per
`.gitignore` nicht im Repo). `security.yml` führt mindestens drei Scans aus (Secrets, SAST, IaC,
SCA).

| Workflow          | Zweck                                                         | Blockierend                 | Report                                      |
|-------------------|---------------------------------------------------------------|-----------------------------|---------------------------------------------|
| `gitleaks.yml`    | Secrets in Git-Historie und Dateien (Inputs `config`, `fail-on-leak`) | ja (`fail-on-leak`, Standard `true`) | `reports/gitleaks-*.json`, `gitleaks.sarif` |
| `semgrep.yml`     | SAST (Inputs `rulesets`, `severity`; Standard: default, rust, typescript, python, ab ERROR) | ja (`--error`) | `reports/semgrep-report.json`               |
| `checkov.yml`     | IaC-Scan, SARIF-Upload in Code Scanning                       | ja                          | `reports/checkov/`                          |
| `cargo-audit.yml` | Findet alle `Cargo.toml`, `cargo audit` je Crate              | nein (`continue-on-error`)  | `reports/cargo-audit-<crate>.json`          |
| `npm-audit.yml`   | Findet alle `package-lock.json`, `npm audit` je Projekt       | nein (`continue-on-error`)  | `reports/npm-audit-<projekt>.json`          |
| `openbao.yml`     | CI: OpenBao-Image bauen, Container starten, Health prüfen     | ja                          | –                                           |

## Aufruf aus einem Repo

Datei `.github/workflows/security.yml` im aufrufenden Repo:

```yaml
name: security

on:
  pull_request: {}
  push:
    branches: [main]
  schedule:
    - cron: "0 2 * * *"

permissions:
  contents: read

jobs:
  secrets:
    uses: org/security-pipelines/.github/workflows/gitleaks.yml@<sha>
  sast:
    uses: org/security-pipelines/.github/workflows/semgrep.yml@<sha>
  iac:
    permissions:
      contents: read
      security-events: write
      actions: read
    uses: org/security-pipelines/.github/workflows/checkov.yml@<sha>
  sca-cargo:
    uses: org/security-pipelines/.github/workflows/cargo-audit.yml@<sha>
  sca-npm:
    uses: org/security-pipelines/.github/workflows/npm-audit.yml@<sha>
```

## OpenBao lokal

```bash
make build              # Image bauen
make run                # Container starten (http://localhost:8200)
make openbao-inizilise  # operator init
make openbao-entsperren # operator unseal
make openbao-login      # login
```
