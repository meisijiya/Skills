# supply-chain-risk-auditor

Dependency trustworthiness audit. Evaluates maintainer posture (not CVE database) — single-maintainer risk, abandoned-repo risk, low-popularity risk, maintainer-identity hygiene, social-engineering resistance.

**Output path**: `docs/supply-chain-risk/<repo-hash>-<date>/`
- `dependency-risk-input.yaml` — input config (user-editable)
- `supply-chain-risk.md` — main report
- `supply-chain-risk.csv` / `supply-chain-risk.json` — machine-readable (optional)

**Skill**: `skills/extra/supply-chain-risk-auditor/SKILL.md`
