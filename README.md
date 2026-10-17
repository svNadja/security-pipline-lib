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
│  ├─ trivy.yml         (SCA/Misconfig, Dateisystem)
│  ├─ build-scan.yml    (Docker-Image bauen + Trivy Image-Scan)
│  ├─ bandit.yml        (SAST für Python)
│  └─ openbao.yml       (CI für das OpenBao-Setup)
├─ docker/Dockerfile    (OpenBao-Image mit eingebackener Config)
├─ docker-compose.yml   (OpenBao-Container)
├─ config/openbao.hcl   (OpenBao-Serverkonfiguration)
└─ Makefile             (build, run, init, unseal, login)
```

## Workflows
```text
Trigger: push / pull_request / schedule (nightly) / workflow_dispatch
│
├─ Stufe 1: Secrets (Gate, schnell, blockiert alles)
│     └─ gitleaks
│
├─ Stufe 2: Statische Analyse (parallel)
│     ├─ semgrep           (SAST)
│     ├─ cargo-audit       (SCA Rust)
│     ├─ npm-audit         (SCA npm)
│     └─ checkov           (IaC)
│
├─ Stufe 3: Build-nahe Prüfung (braucht Image)
│     ├─ docker build
│     └─ trivy (Image-Scan + fs/config)
│
├─ Stufe 4: Integration
│     └─ openbao.yml
│
└─ Stufe 5: Gate / Zusammenfassung
      └─ security-gate (needs: alle) → required check für Branch Protection
```

Alle Workflows sind wiederverwendbar (`workflow_call`) und per `workflow_dispatch` einzeln testbar.
Die Scans prüfen den **gesamten Code** des aufrufenden Repos und schreiben ihre Reports nach
`reports/` (als Artefakt hochgeladen, per `.gitignore` nicht im Repo).

`security.yml` läuft in Stufen (über `needs`):

1. `secrets` (Gitleaks) – Gate, blockiert alle folgenden Stufen
2. Statische Analyse parallel: Semgrep, Bandit, Checkov, cargo-audit, npm-audit, Trivy fs
3. `build` (Docker-Image bauen + Trivy Image-Scan)
4. `openbao` (Integrationstest)
5. `security-gate` – Zusammenfassung; als **required check** in der Branch Protection eintragen

Trigger und Scope:

| Event | Gitleaks | Übrige Scans |
|-------|----------|--------------|
| Pull Request | nur Diff der PR-Commits | alle |
| Push auf `main` | volle Historie (`--all`) | alle |
| Nightly (`schedule`) | volle Historie + Working Tree | alle (SCA und Trivy erkennen neue CVEs) |

Schweregrad-Policy: blockierend sind Gitleaks (alle Funde), Semgrep (ERROR), Trivy fs und Image
(HIGH/CRITICAL mit verfügbarem Fix), cargo-audit (jeder Advisory), npm-audit (ab `high`) und
Bandit (HIGH). Warnend: MEDIUM/LOW und Semgrep-Hinweise (nur Report).

| Workflow          | Zweck                                                         | Blockierend                 | Report                                      |
|-------------------|---------------------------------------------------------------|-----------------------------|---------------------------------------------|
| `gitleaks.yml`    | Secrets in Git-Historie und Dateien (Inputs `config`, `fail-on-leak`) | ja (`fail-on-leak`, Standard `true`) | `reports/gitleaks-*.json`, `gitleaks.sarif` |
| `semgrep.yml`     | SAST (Inputs `rulesets`, `severity`; Standard: default, rust, typescript, python, ab ERROR) | ja (`--error`) | `reports/semgrep-report.json`               |
| `checkov.yml`     | IaC-Scan, SARIF-Upload in Code Scanning                       | ja                          | `reports/checkov/`                          |
| `bandit.yml`      | SAST für Python                                               | ja (nur HIGH)               | `reports/bandit/bandit-report.json`         |
| `cargo-audit.yml` | Findet alle `Cargo.toml`, `cargo audit` je Crate              | ja                          | `reports/cargo-audit-<crate>.json`          |
| `npm-audit.yml`   | Findet alle `package-lock.json`, `npm audit` je Projekt       | ja (ab `high`)              | `reports/npm-audit-<projekt>.json`          |
| `trivy.yml`       | Trivy Dateisystem: Vulnerabilities + Misconfigurations, SARIF | ja (HIGH/CRITICAL, mit Fix) | `reports/trivy/`                            |
| `build-scan.yml`  | Docker-Image bauen, Trivy Image-Scan, SARIF-Upload            | ja (HIGH/CRITICAL, mit Fix) | `reports/trivy-image/`                      |
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
    needs: secrets
    permissions:
      contents: read
      security-events: write
      actions: read
    uses: org/security-pipelines/.github/workflows/semgrep.yml@<sha>
  iac:
    needs: secrets
    permissions:
      contents: read
      security-events: write
      actions: read
    uses: org/security-pipelines/.github/workflows/checkov.yml@<sha>
  sca-cargo:
    needs: secrets
    uses: org/security-pipelines/.github/workflows/cargo-audit.yml@<sha>
  sca-npm:
    needs: secrets
    uses: org/security-pipelines/.github/workflows/npm-audit.yml@<sha>
```

Der `needs: secrets` ist Absicht: Gitleaks ist das Gate, Funde stoppen die übrigen Scans.
`security-gate` (siehe `security.yml` dieses Repos) lässt sich analog als required check einbinden.

## OpenBao lokal

```bash
make build              # Image bauen
make run                # Container starten (http://localhost:8200)
make openbao-inizilise  # operator init
make openbao-entsperren # operator unseal
make openbao-login      # login
```
