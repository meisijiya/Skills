---
name: stack-security-coder
description: "Layered security-coding guardrails for the three surfaces where AI-generated code most often drifts from secure defaults: frontend (XSS / unsafe-DOM / CSP gaps / cross-origin), backend (parameterized queries / authz checks / rate-limit / safe redirects / SSRF), mobile (WebView hardening / certificate pinning / secure storage / biometric handling). Each layer is a checklist of checkpoints with file:line evidence. Use when writing or reviewing code in any of these three layers (especially AI-generated code that hasn't been hardened against the OWASP-class defaults for the layer), or when a per-line audit reveals gaps specific to a layer. Distinct from security-and-hardening (cross-cutting trust-boundary audit): this skill is per-stack — it knows the stack-specific landmines and enumerates them concretely."
allowed-tools: "Read Bash Glob Grep"
---

# stack-security-coder

## Overview

`security-and-hardening` audits cross-cutting trust boundaries (input validation, auth, OWASP) across all code. This skill goes one level **deeper into the stack** — for each of the three surfaces where AI-generated code most often drifts from secure defaults, what does the "secure default" actually look like?

The three surfaces:

| Surface | Common drift |
|---|---|
| **Frontend** (DOM-touching code: React / Vue / Svelte / vanilla TS) | `dangerouslySetInnerHTML` with unsanitized input, missing CSP nonce, eval / Function from string, missing cross-origin checks on postMessage, missing Subresource Integrity on third-party scripts |
| **Backend** (HTTP-handling code: Node / Go / Python / Java) | String concatenation in SQL, missing authz check (after authn), webhook payloads trusted, SSRF on URL params, redirect to attacker-controlled host |
| **Mobile** (iOS / Android / RN / Flutter) | WebView addJavascriptInterface exposed to remote URLs, certificate validation skipped in NSURLSession / OkHttp, EncryptedSharedPreferences with hardcoded key, biometric fallback to insecure PIN, deep-link handler trusting query params |

These are **not** the same as the cross-cutting checks (input / auth / integration). They are layer-specific landmines that the general audit forgets because the surface code doesn't look "insecure" on first read.

This skill is a peer / complement to `security-and-hardening` and `ai-code-blindspots`:

| Skill | Focus | When |
|---|---|---|
| `security-and-hardening` | Cross-cutting trust boundary | Per-PR / per-release audit |
| `ai-code-blindspots` | AI-generated-code blind spots (cross-cutting) | Post-edit review |
| `stack-security-coder` | Stack-specific landmines (this skill) | Per-PR / per-release, **especially when AI wrote the code** |
| `security-threat-model` | Adversarial boundary, system-level | Pre-design / pre-refactor |

When to load this skill: when you know the layer (frontend / backend / mobile) and want the layer-specific 30-point checklist to verify against. When to load security-and-hardening instead: when the layer is mixed or you're auditing trust boundaries in general.

## When to Use

**Use when:**

- Reviewing AI-generated frontend code (React / Vue / Svelte / TS) for the XSS / unsafe-DOM / CSP layer of risks
- Reviewing AI-generated backend code (Node / Go / Python / Java) for the OWASP-class defaults the cross-cutting audit might miss (SSRF, redirects, webhook trust)
- Reviewing AI-generated mobile code (RN / Flutter / iOS / Android) for the WebView / cert-pinning / secure-storage landmines
- Building a per-stack coding checklist for your team (SOP for which checks run per layer)
- After a security incident in any of the three layers (postmortem found a layer-specific gap; update this skill with the new pattern)
- Onboarding a new engineer who is layer-rotating — "here's what to look for in our frontend code"

**NOT for:** (scenario description — let description match decide)

- Per-PR cross-cutting trust-boundary audit (input / auth / integration) → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- Adversarial boundary modeling (system-level threat model) → [`security-threat-model`](~/.agents/skills/security-threat-model/SKILL.md)
- Supply chain / dep audit → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- AI-generated diff blindspot review (cross-cutting) → [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md)
- Infra / IaC / pre-deploy audit → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)

## Process

### 1. Identify the layers in scope

For each file under review, name its layer:

- Frontend → DOM-touching code in `web/`, `client/`, `src/components/`, `app/`
- Backend → HTTP-handling code in `server/`, `api/`, `controllers/`, `routes/`
- Mobile → `ios/`, `android/`, `mobile/`, `app/` (RN/Flutter shared)

For mixed-layer code (e.g. a Next.js app where `/pages/api/*` is backend and `/pages/*` is frontend), audit each layer's checks per file.

### 2. Per-layer checkpoint enumeration

#### Layer: Frontend (DOM-touching code)

**Checkpoint F-1**: Sanitization at every HTML interpolation point
- grep for `dangerouslySetInnerHTML`, `innerHTML`, `outerHTML`, `v-html`, `[innerHTML]`, `bypassSecurityTrustHtml`, `unsafeHTML`
- For each: confirm the value is sanitized (DOMPurify / Sanitize-html / Angular's `DomSanitizer`) OR is a constant + origin is trusted
- **Severity if violated**: HIGH if user-controlled, CRITICAL if reached from URL params / query / message events

**Checkpoint F-2**: CSP headers + nonces
- Read `<meta http-equiv="Content-Security-Policy">` AND response headers for `Content-Security-Policy`
- If using nonces: every `<script>` and `<style>` has `nonce="<random>"` matching the response nonce
- If not using nonces: confirm `unsafe-inline` is NOT in CSP for script-src
- **Severity if violated**: HIGH if any inline-script present without nonce; MEDIUM if relying on `unsafe-inline`

**Checkpoint F-3**: URL handling
- `href`, `src`, `action` set to a user-controlled value with the wrong protocol → javascript: URI
- Use `URL` parsing with explicit `protocol === 'https:'` check OR allow-list
- Don't trust `window.location` for routing decisions (open redirect / DOM XSS)
- **Severity if violated**: HIGH if user-controlled; CRITICAL if `javascript:` exec reached

**Checkpoint F-4**: postMessage handling
- Every `window.addEventListener('message', ...)` MUST `event.origin` allow-list
- MUST `event.source !== window` check (or explicit origin match) to prevent spoofing
- **Severity if violated**: HIGH (cross-origin execution)

**Checkpoint F-5**: Subresource Integrity on third-party scripts
- For `<script src="https://cdn.example.com/lib.js">`: include `integrity="sha384-..."` + `crossorigin`
- For CSS imports of third-party: less critical but recommended
- **Severity if violated**: MEDIUM (CDN compromise → XSS)

**Checkpoint F-6**: eval / Function / setTimeout / setInterval with string
- grep for `eval(`, `new Function(`, `setTimeout('...', `, `setInterval('...', `
- For each: confirm the string is constant (not user-controlled) or refactor
- **Severity if violated**: CRITICAL (direct code exec)

**Checkpoint F-7**: Cookie security flags
- For Set-Cookie: confirm `Secure`, `HttpOnly`, `SameSite` flags
- If JS-readable (HttpOnly missing): check why; document the read path; flag as MEDIUM
- **Severity if violated**: HIGH for session cookies missing HttpOnly

**Checkpoint F-8**: Token storage
- Access tokens in localStorage: HIGH risk (XSS-readable) — prefer HttpOnly cookie
- Service-worker-side auth: leak via DevTools; document and accept
- **Severity if violated**: MEDIUM-HIGH depending on threat model

#### Layer: Backend (HTTP-handling code)

**Checkpoint B-1**: SQL queries — parameterized / no concatenation
- grep for SQL strings with `+`, `${`, `f-string`, `format`, `.replace`
- For each: confirm the value flows through `?` placeholder / `:param` / ORM
- Watch for `.raw()`, `sql.raw()`, raw queries that bypass the safety layer
- **Severity if violated**: CRITICAL (SQL injection)

**Checkpoint B-2**: NoSQL queries — operator injection
- For MongoDB / DynamoDB / Elasticsearch / Redis: confirm query inputs are coerced to expected types (`parseInt`, `typeof === 'string'`)
- Watch for `req.body.username` passed directly to `db.findOne` — operator injection with `{"$gt":""}`
- **Severity if violated**: CRITICAL (auth bypass via NoSQL injection)

**Checkpoint B-3**: Authz after authn
- After every authenticated request: confirm there's a per-resource authz check, not just "user is logged in"
- Look for `req.user` reading without `if (record.ownerId === req.user.id)` or similar
- Watch for IDOR (Insecure Direct Object Reference) patterns
- **Severity if violated**: HIGH (multi-tenant data leak)

**Checkpoint B-4**: SSRF on URL params
- For "fetch from this URL" endpoints (image proxy, webhook handler, OAuth callback): the URL flows from user input
- Validate: protocol is `https:` (or your allow-list), host NOT in private IP ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `127.0.0.0/8`)
- Resolve the host and re-check after DNS resolution (TOCTOU)
- **Severity if violated**: HIGH (cloud metadata service exposure / internal network probe)

**Checkpoint B-5**: Open redirect
- For "redirect to this URL after login" / SSO / OAuth callback flows: validate the URL is on the allow-list
- Don't trust `Location: <user-controlled>` without an allow-list or same-origin check
- **Severity if violated**: MEDIUM (phishing chain)

**Checkpoint B-6**: Webhook payload trust
- Endpoint receives signed webhooks from a third-party (Stripe, GitHub, etc.): verify signature BEFORE parsing payload
- Use the provider's signature-verification helper; don't write your own
- Constant-time comparison for signature checks (`crypto.timingSafeEqual` / `hmac.compare_digest`)
- **Severity if violated**: HIGH (attacker can impersonate webhook source)

**Checkpoint B-7**: Rate limiting & resource bounds
- Login / password reset / signup / anything sensitive: rate-limited per IP + per account
- File upload: max size enforced before parsing body
- API endpoints: timeouts enforced (read / write / total)
- **Severity if violated**: MEDIUM (DoS / credential stuffing)

**Checkpoint B-8**: Body size + JSON parsing limits
- Express body-parser: confirm `limit` set (e.g. `'100kb'`)
- JSON.parse on user input: confirm no unbounded recursion / large arrays
- **Severity if violated**: MEDIUM (DoS via large body)

**Checkpoint B-9**: Error responses leak no internals
- 5xx responses don't include stack traces, query strings, internal paths
- Custom error handlers wrap production errors
- **Severity if violated**: LOW (info leak, but cumulative)

#### Layer: Mobile (iOS / Android / RN / Flutter)

**Checkpoint M-1**: WebView javascriptInterface + loadUrl allow-list
- `addJavascriptInterface(...)` + `loadUrl(*)` = JS bridge exposed to attacker-controlled URL = RCE on Android
- For each `addJavascriptInterface`: confirm `loadUrl` is allow-listed or uses file:// from app bundle only
- **Severity if violated**: CRITICAL

**Checkpoint M-2**: Certificate pinning or trusted CA validation
- For OkHttp / NSURLSession / urlSession: confirm certificate validation enabled (default; rare to disable intentionally)
- If pinning is desired: implement via Network Security Config (Android) / `URLSessionDelegate.urlSession(_:didReceive:completionHandler:)` (iOS); do NOT trust any cert
- **Severity if violated**: MEDIUM-HIGH (MITM)

**Checkpoint M-3**: Secure storage
- For sensitive data (tokens, PII): use EncryptedSharedPreferences (Android) / Keychain (iOS), never SharedPreferences / NSUserDefaults as sole storage
- Keys in source code: never — use Keystore / keychain
- For React Native: AsyncStorage is NOT secure storage
- **Severity if violated**: HIGH

**Checkpoint M-4**: Biometric handling
- `LAContext` (iOS) / `BiometricPrompt` (Android): require strong auth (Class 3 / BIOMETRIC_STRONG) for sensitive operations
- Fallback to PIN/passcode should be opt-in, not default
- **Severity if violated**: MEDIUM-HIGH

**Checkpoint M-5**: Deep-link handler trust
- URL schemes + Universal Links / App Links handlers MUST validate input
- Example: `myapp://reset-password?token=...` — verify the token is from your server, not attacker-controlled
- **Severity if violated**: HIGH (session takeover)

**Checkpoint M-6**: Background-task limitations
- iOS Background Tasks: don't process sensitive data in BG unless encrypted
- Android Foreground Services for long ops: don't leak credentials in pendingIntent
- **Severity if violated**: LOW-MEDIUM

**Checkpoint M-7**: Logging of sensitive data
- grep for `console.log`, `NSLog`, `print`, `Log.*`, `Timber.*`, `Log.d` etc., in code path that handles tokens / passwords / PII
- For each: confirm the value is masked / not logged
- **Severity if violated**: MEDIUM (info leak via device logs)

**Checkpoint M-8**: Code obfuscation + binary hardening
- Mobile binaries are reverse-engineerable; sensitive logic should be server-side or use native code with encryption
- Detect debug builds: enforce `kReleaseOnly` checks for sensitive ops
- **Severity if violated**: LOW (depends on threat model)

### 3. Output per layer

For each layer's checkpoints, emit:

```markdown
## Layer: <Frontend|Backend|Mobile>
- File count in scope: <N>
- Checkpoints run: <list, e.g. F-1 through F-8>
- Findings: <number per severity>
- Output evidence: file:line + code snippet + remediation

### Findings table
| Severity | Checkpoint | File:line | Snippet | Remediation |
|---|---|---|---|---|
| CRITICAL | B-1 | src/api/users.go:42 | `db.Query("... WHERE id=" + req.ID)` | use parameterized query `?` |
```

End with severity-totals + recommendations.

### 4. Anti-patterns

- Treating "we use an ORM" as "no SQL injection possible" — ORMs can still have raw query methods
- "HTTPS only" as sufficient — transport security ≠ app security
- "SameSite cookies" as sufficient — cookie attributes are a defense-in-depth layer, not a primary control
- "Node.js doesn't have SQL injection" — depends on driver; node-ibm_db / `pg` raw queries still vulnerable
- Mobile "we use HTTPS" ignores cert-pinning, attacker-MITM via cert-install, OS-level threat models

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "We don't write frontend XSS-prone code" | Every interpolation point is potentially XSS-prone. The question is sanitization, not whether the framework allows it. |
| "ORM means no SQL injection" | ORM default is safe. Raw queries / `.raw()` / SQL strings are not. Look for the bypass. |
| "We rate-limit at the load balancer" | LB-level is IP-based + coarse; per-account rate-limiting at the app catches credential-stuffing that LB allows through. |
| "Webhooks are only from trusted providers" | Trust on first contact + signature verification on each request. Providers get compromised too (see Codecov / SolarWinds class). |
| "Mobile apps can be reverse-engineered so why bother" | The attacker cost matters; obfuscation + keychain + cert-pinning raise cost vs. no defense. |
| "This skill is a lot; the cross-cutting audit is enough" | Cross-cutting catches ~80%; the layer-specific landmines are the other 20% that cause incidents. |

## Red Flags

The layer audit is going wrong if:

- Identifies "the layer" by directory name without checking that the file actually does I/O on that layer (e.g. flagged as "frontend" but file is pure utils, no DOM)
- Skips checkpoint categories marked as "rarely useful" without justification — a CHECKPOINT was here for a reason; cite its triggers before dropping
- Reports ZERO findings on a layer with 50+ files — either the layer's checkpoints are too lax or the audit missed something
- "We use framework-X which prevents this" without checking the bypass paths (.raw(), disable-protection, custom-config)
- Output omits file:line — without code citation, the finding is just an opinion
- Severity calibration ignores reachability (a SQL injection in an unused-by-production endpoint = MEDIUM; in a hit-by-every-query endpoint = CRITICAL)
- Report doesn't distinguish layer from cross-cutting findings — security-and-hardening should be run alongside; this skill's findings should be layer-specific

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | Severity calibration: "Is this SQL finding actually exploitable through the framework's parameter binding?" / "Is this WebView hardcoded-cert bypass reachable in prod?" (oracle is read-only) |
| `security-research` mode (omo) | Cross-cutting audit run alongside this layer audit (`security-and-hardening` for app-layer trust boundaries, this skill for layer-specific coding landmines); `meisijiya-review-router` reminds both |
| [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) | If the layer code is AI-generated, run blindspots for boundary / env-compat / hardcoded-config checks that layer checkers may miss (stack-security-coder = pattern-aware, blindspots = AI-failure-mode-aware) |
| `meisijiya-review-router` plugin | Auto-loads this skill on `Edit` of `.tsx` / `.jsx` / `.vue` / `.svelte` / `.swift` / `.dart` files (per `matchPath` policy in `.opencode/plugins/meisijiya-review-router.js`) |

## Verification

Before claiming the layer audit is done, produce evidence:

- [ ] §1 Layer(s) in scope identified per file
- [ ] §2 All relevant checkpoints run per layer (cite which were skipped and why)
- [ ] §3 Output saved per layer; findings table with severity + file:line + snippet + remediation
- [ ] Severity calibrated against reachability (not just pattern presence)
- [ ] Cross-cutting audit (`security-and-hardening`) run separately for the same files; layer-vs-cross-cutting boundary explicit
- [ ] Output reviewed by a layer-aware engineer (not just the original author)

**Acceptance criterion**: A layer-aware second reviewer re-running the checkpoints on the same files reaches the same findings (or flags and resolves disagreements); the team has a checklist to repeat this audit on subsequent changes.
