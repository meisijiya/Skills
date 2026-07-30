---
name: meisijiya-redesign-ui
description: "Audit-then-fix workflow for existing web/mobile UI in any framework. Layered audit (typography / color / layout / interactivity / content / components / icons / code / a11y / strategic omissions); fixes highest-leverage items in priority order without breaking functionality or migrating frameworks. Use to upgrade existing UI to premium quality. NOT for greenfield designs (meisijiya-frontend-taste), dashboards / data tables, or bug fixes."
---

# meisijiya-redesign-ui

> **Attribution.** This skill is a meisijiya adaptation of [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)'s `redesign-skill` (install name `redesign-existing-projects`), originally written by Leon Linnx and released under MIT License. The audit structure and fix-priority ladder are preserved; the skill has been rewritten to fit the meisijiya 6-section skill-anatomy format and the OMO collaboration model.

## Overview

UI redesigns that work are not rewrites — they are targeted upgrades on top of what already ships. This skill enforces the scan → diagnose → fix sequence: identify the framework + styling system + current patterns, run a layered audit against a checklist of common AI-default and cheap-default tells, then apply fixes in a priority order that maximizes visual impact with minimum risk. The codebase stays in its existing framework and styling system; functionality does not break.

For brand-new designs with no existing UI to honor, use [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) instead. This skill is built for code that already ships.

## When to Use

**Use when:**
- The project already has UI (web / mobile / desktop) that ships or is about to ship
- The user wants the UI to look "premium", "expensive", "not obviously AI", "more like [Linear/Vercel/Apple/Notion]", "less generic"
- The codebase already has framework choices (React/Vue/Svelte) and styling choices (Tailwind/Styled Components/CSS modules) — we respect them
- The user describes symptoms ("looks templated", "AI purple gradient shows up", "honest about pricing needs work", "the FAQ accordion is awful") without asking for a full rewrite
- Major refactors that touch the styling system (token rename, theme change) — this is a redesign-without-feature-change

**NOT for:**
- Greenfield projects with no existing UI → [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md)
- Dashboards, data tables, multi-step product UI → [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md)
- Pure bug fixes (state management, accessibility regressions) → [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) instead
- Backend / API redesign with no UI change
- User explicitly says "rewrite it from scratch"
- Image-generation-only deliverables (no code to scan)

## Process

### 1. Scan — map the codebase

Before touching anything, identify the existing skeleton:

- **Framework:** React / Next.js / Vue / Svelte / Angular / Solid / vanilla. Server-render vs client-only.
- **Styling method:** Tailwind v3 vs v4, CSS modules, Styled Components, Emotion, Sass, vanilla CSS. Theme tokens (CSS variables, `theme.colors`, Tailwind config).
- **Component library:** shadcn/ui / Radix Themes / Material / Fluent / Carbon / Polaris / Mantine / custom-only.
- **State management:** useState / Zustand / Jotai / Redux / Vuex / Svelte stores.
- **Animation library:** motion / framer-motion / GSAP / Lottie / CSS-only.
- **Icons:** Phosphor / Hugeicons / Radix / Lucide / Tabler / Heroicons / custom SVG.
- **Existing routes / pages / sections** — build a mental inventory before changing any.
- **Test setup:** Vitest / Jest / Playwright / Cypress / none. Critical for "do not break existing functionality".

**Output:** a 5–10 line inventory written above the diagnosis. Without this, fixes drift from the framework's conventions.

### 2. Diagnose — run the audit

Run the following audit layers. List every finding with file:line. Do not fix yet.

#### 2.1 Typography (highest-leverage first)

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Browser default fonts or `Inter` everywhere | Inter is the LLM default | `Geist`, `Outfit`, `Cabinet Grotesk`, `Satoshi` for display; pair with a system mono |
| Headlines lack presence | Modest scale breaks hierarchy | Increase size; tighten `letter-spacing`; reduce `line-height` |
| Body text too wide | Hurts readability | Cap `max-width` at `65ch`; `line-height: 1.6` |
| Only Regular (400) and Bold (700) used | Crushed hierarchy | Add Medium (500) / SemiBold (600) |
| Numbers in proportional font | Tabular figures expected for data | Monospace font or `font-variant-numeric: tabular-nums` |
| All-caps subheaders everywhere | Lazy typographic separator | Lowercase italics, sentence case, or small-caps |
| Orphaned words on last line | Bad text wrap | `text-wrap: balance` or `text-wrap: pretty` |
| Default sans-serif body in editorial / premium brief | Wrong family | Editorial sans + serif pairing |
| Generic serif ("Times New Roman", "Georgia") — banned by [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) §5.1 for marketing / dashboard contexts | AI-tell banned serif | If serif is genuinely needed, rotate from `PP Editorial New`, `GT Sectra Display`, `Reckless Neue`, `Tiempos Headline`, `Recoleta`, `Cormorant Garamond`, `Playfair Display`, `EB Garamond`, `IvyPresto`, `Editorial Old`, `Saol Display`, `Canela`, `Schnyder`, `Tobias` |

#### 2.2 Color and surfaces

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Pure `#000000` background | Default-reach | Off-black / dark charcoal / tinted dark (`#0a0a0a`, `#121212`) |
| Oversaturated accent colors (>80% saturation) | Hurt the page | Desaturate; blend with neutrals |
| More than one accent color | Identity confusion | Pick ONE. Consistency beats variety. |
| Mixing warm and cool grays within a project | Inconsistency | One family; tint consistently |
| Purple / blue "AI gradient" aesthetic | The single most common AI fingerprint | Neutral bases + one considered accent |
| Generic `box-shadow` (pure black at low opacity) | Generic | Tint shadows to background hue; use colored shadows |
| Flat design with zero texture | Sterile | Subtle noise / grain / micro-patterns |
| Perfectly even gradients | Lazy backdrop | Radial / noise / mesh gradient instead of linear 45° |
| Inconsistent lighting direction | Shadow soup | Audit all shadows to a single virtual light source |
| Random dark section in a light mode page | Copy-paste accident | Commit to one full theme OR vary with shade of the same palette, not jumps to `#111` |
| Empty, flat sections with no visual depth | Feels unfinished | Subtle background imagery / patterns / ambient gradients — even at low opacity adds presence |

#### 2.3 Layout

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Everything centered and symmetrical | Lazy default | Offset margins / mixed aspect ratios / left-aligned headers over centered content |
| Three equal card columns as feature row | The most generic AI layout | 2-column zig-zag / asymmetric grid / horizontal scroll / masonry |
| `height: 100vh` for full-screen sections | iOS Safari viewport jump | `min-height: 100dvh` |
| Complex flexbox percentage math (`w-[calc(33%-1rem)]`) | Fragile across viewports | CSS Grid for multi-column |
| No max-width container | Content stretches on wide screens | Container constraint 1200–1440px with auto margins |
| Cards of equal height forced by flexbox | Variable content | Masonry or variable heights |
| Uniform border-radius on everything | Repetition | Tighter on inner elements, softer on containers |
| No overlap or depth | Flat | Negative margins for layering |
| Symmetrical vertical padding | Mathematically-centered but optically wrong | Bottom padding often needs to be slightly larger |
| Dashboard with always-left sidebar | Default-reach | Top nav / floating command menu / collapsible panel |
| Missing whitespace | Cramped | Double the spacing. Dense layouts are for data dashboards. |
| Buttons not bottom-aligned in card groups | Misaligned CTAs across heights | Pin buttons to the bottom of each card |
| Feature lists starting at different vertical positions in pricing/compare cards | Misaligned baselines | Consistent spacing above lists OR fixed-height title/price blocks |
| Inconsistent vertical rhythm in side-by-side elements | Broken visual lattice | Align shared elements (titles, descriptions, prices, buttons) across items |
| Mathematical alignment that looks optically wrong | Math-correct / eye-wrong | 1–2px optical adjustment |

#### 2.4 Interactivity and states

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| No hover states on buttons | Static | Background shift / slight scale / translate on hover |
| No active / pressed feedback | Static | `scale(0.98)` or `translateY(1px)` |
| Instant transitions with zero duration | Jarring | 200–300ms smooth transitions |
| Missing focus ring | A11y violation | Visible focus indicator for keyboard |
| Generic circular loaders | Lazy default | Skeleton loaders matching layout shape |
| No empty states | Missed opportunity | Composed "getting started" view |
| No error states | UX failure | Clear, inline errors (no `window.alert`) |
| Dead `#` links | Lying CTAs | Link to real destinations OR visually disable |
| No current-page indicator in nav | Disorienting | Style active nav differently |
| Scroll jumping on anchor clicks | Rough | `scroll-behavior: smooth` |
| Animations using `top` / `left` / `width` / `height` | GPU-killing | `transform` + `opacity` only |

#### 2.5 Content

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Generic names ("John Doe", "Jane Smith") | Lazy placeholder | Diverse, realistic-sounding |
| Fake round numbers (`99.99%`, `50%`, `$100.00`) | Suspicious | Organic, messy data (`47.2%`, `$99.00`, `+1 (312) 847-1928`) |
| Placeholder companies ("Acme Corp", "Nexus", "SmartFlow") | Lazy | Invent contextual, believable names |
| AI copywriting clichés (`Elevate`, `Seamless`, `Unleash`, `Next-Gen`, `Game-changer`, `Delve`, `Tapestry`, `In the world of`) | AI-tell | Write plain, specific language |
| Exclamation marks in success messages | Loud, not confident | Remove them |
| `Oops!` error messages | Passé-aggressive | "Connection failed. Please try again." |
| Passive voice | Soft / evasive | Active voice |
| All blog dates identical | Looks fake | Randomize dates |
| Same avatar image for multiple users | Deception | Unique assets per person |
| Lorem Ipsum | Lazy | Real draft copy |
| Title Case On Every Header | Old-school copywriting | Sentence case |
| Em-dashes (`—`) in user-visible copy | AI fingerprint for LLMs; explicitly banned by [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) §5.10 | Use `,` `:` `(` `)` — even `–` is borderline |

#### 2.6 Component patterns

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Generic card look (border + shadow + white) | AI default triple | Remove the border OR use only background OR use only spacing |
| Always filled button + ghost button pair | Lazy CTA taxonomy | Add text links or tertiary styles |
| Pill-shaped `New` / `Beta` badges | Default-reach | Square badges / flags / plain text |
| Accordion FAQ section | Lazy default | Side-by-side list / searchable help / inline progressive disclosure |
| 3-card carousel testimonials with dots | Generic | Masonry wall / embedded social posts / single rotating quote |
| Pricing table with 3 towers | Default-shape | Highlight recommended tier with color + emphasis, not extra height alone |
| Modals for everything | Modals are disruptive | Inline editing / slide-over / expandable sections |
| Avatar circles exclusively | Same-shape fatigue | Squircles or rounded squares |
| Light/dark toggle always a sun/moon switch | Lazy | Dropdown / system-pref / settings integration |
| Footer link farm with 4 columns | Lazy structure | Simplify. Focus on main nav paths + legally required links. |
| Bento grid with one empty cream-on-cream cell in the middle | Wasted slot | Re-shape grid; don't paste blank tile |
| Zigzag image+text-split for 3+ consecutive sections | Banal pattern | Break with full-width / vertical / bento / marquee |
| Eyebrow tag (`uppercase tracking-[0.18em]`) above every section headline | AI tell; explicitly banned by [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) §5.3 | Max 1 eyebrow per 3 sections; drop the rest |

#### 2.7 Iconography

| Pattern | Why it screams "AI default" | Replace with |
|---|---|---|
| Lucide or Feather icons exclusively | The default AI icon choice | Phosphor / Hugeicons / Heroicons / custom set |
| Rocketship for `Launch`, shield for `Security` | Cliche metaphors | Less-obvious icons (bolt / fingerprint / spark / vault) |
| Inconsistent stroke widths | Visual noise | Standardize to ONE stroke weight |
| Missing favicon | Feels unfinished | Always include a branded favicon |
| Stock "diverse team" photos | Uncanny valley | Real team photos / candid shots / consistent illustration style |

#### 2.8 Code quality (HTML / CSS / framework)

| Pattern | Replace with |
|---|---|
| Div soup | Semantic HTML (`<nav>`, `<main>`, `<article>`, `<aside>`, `<section>`) |
| Inline styles mixed with CSS classes | Project's styling system only |
| Hardcoded pixel widths | Relative units (`%`, `rem`, `em`, `max-width`) |
| Missing alt text on images | Descriptive alt text; never `alt=""` or `alt="image"` on meaningful images |
| Arbitrary z-index values (`9999`) | Clean theme / variable scale |
| Commented-out dead code | Remove all debug artifacts |
| Import hallucinations | Check `package.json` before every import |
| Missing meta tags | `<title>`, `description`, `og:image`, social sharing meta |

#### 2.9 Strategic omissions (what AI typically forgets)

| Pattern | Replace with |
|---|---|
| No legal links | Privacy policy + terms of service in footer |
| No "back" navigation | Every page needs a way back |
| No custom 404 page | Branded, helpful "page not found" |
| No form validation | Client-side: emails / required fields / format checks |
| No "skip to content" link | Hidden skip-link for keyboard users |
| No cookie consent (jurisdiction-dependent) | Compliant consent banner |

### 3. Fix in priority order

Apply fixes in this order for max visual impact with min risk:

1. **Font swap** — biggest instant improvement, lowest risk
2. **Color palette cleanup** — remove clashing / oversaturated / multi-accent
3. **Hover and active states** — interface comes alive
4. **Layout and spacing** — proper grid, max-width, consistent padding
5. **Replace generic components** — swap cliche patterns for modern alternatives
6. **Add loading / empty / error states** — feels finished
7. **Polish typography scale and spacing** — premium final touch

**Hard fix rules:**

- Work with the existing tech stack. Never migrate frameworks or styling libraries mid-redesign.
- Never break existing functionality. Test after every change.
- If adding a new dependency, check `package.json` first.
- If Tailwind is in use, check version (v3 vs v4) before modifying config (v4 has different PostCSS plugin).
- If vanilla CSS, respect the existing BEM / ITCSS / cascading layer choices.
- Keep changes reviewable and focused: small, targeted improvements over big rewrites.
- Document each fix with a one-line note (commit message or PR body) so the team can review.

### 4. Upgrade techniques (when "fix" is not enough)

For high-impact resurfacing that goes beyond removing defaults:

#### Typography upgrades
- Variable font animation (interpolate weight/width on scroll/hover).
- Outlined-to-fill transitions (text starts as stroke, fills on scroll/hover).
- Text-mask reveals (large type acting as a window to video behind it).

#### Layout upgrades
- Broken grid / asymmetry (elements deliberately ignoring columns — overlap, bleed off-screen, offset).
- Whitespace maximization (aggressive negative space to force focus).
- Parallax card stacks (sections that stick and physically stack over each other).
- Split-screen scroll (two halves sliding opposite directions).

#### Motion upgrades
- Smooth scroll with inertia (decoupled from browser defaults).
- Staggered entry (cascade delays, Y-axis translation + opacity fade).
- Spring physics (replace linear easing with spring).
- Scroll-driven reveals (expanding masks, wipes, draw-on SVG paths).

#### Surface upgrades
- True glassmorphism (beyond `backdrop-filter: blur` — 1px inner border + inner shadow for edge refraction).
- Spotlight borders (card borders that illuminate dynamically under the cursor).
- Grain and noise overlays (fixed pointer-events-none overlay).
- Colored, tinted shadows (carry the background hue, not generic black).

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "I'll just rewrite everything for clean code" | Risk of breaking functionality. Respect the existing stack. |
| "Inter is the modern default and looks fine" | Inter is the AI default. Swap to Geist / Outfit / Satoshi. |
| "The page already looks fine, just minor polish" | Run the audit; "fine" usually has 5–10 cheap-default items hiding. |
| "Lucide icons match the design" | Lucide = AI default. Phosphor / Hugeicons is the upgrade. |
| "Hover states are nice-to-haves" | States are how the interface feels alive. Required for premium. |
| "I'll add a new component library" | Not in scope for a redesign. Respect existing stacks. |
| "I don't want to add new dependencies" | Don't — almost every fix in this audit uses native HTML/CSS / Tailwind utilities / existing tokens. |
| "Three feature cards is the standard layout" | It's the most generic AI layout. 2-col zig-zag / asymmetric / horizontal scroll replace it. |
| "Pricing needs three tiers for comparison" | Tier count is fine; the issue is "towers of equal height with random emphasis". Highlight one, vary heights. |
| "The accent color is just to match the logo" | One accent. Lock it. Audit every component before ship. |
| "Em-dash flows better than comma" | Em-dash is an LLM fingerprint. Banned in user-visible copy. |
| "Eyebrows help users navigate" | Tropism. Max 1 per 3 sections; default to no eyebrow. |

## Red Flags

- Migrating frameworks or styling libraries mid-redesign (React → Vue, Tailwind → Styled Components).
- Editing tokens that affect more than the section being redesigned (changes bleed).
- Adding dependencies that existing tests don't cover.
- "I'll just use Inter, it's safe" — Inter is the AI default.
- Adding a Lucide-everywhere pattern to a design that was using Phosphor inconsistently — pick one icon family globally.
- Dropping accessibility (focus rings, contrast) because it's "visually noisy".
- The "fix" silently changes user-visible functionality (route name, copy, alt text, form validation).
- Sending a redesigned page without running tests / visiting routes manually.
- Calling the redesign "done" without running the audit a second time on the post-fix code.

## Verification

Before declaring the redesign complete:

- [ ] Scan inventory documented (framework, styling, components, animation, icons, state, tests).
- [ ] Audit findings listed with file:line per layer (§2.1 — §2.9).
- [ ] Fix priority ladder applied (fonts → color → states → layout → components → states → polish).
- [ ] No framework or styling library migration occurred.
- [ ] Existing tests pass; new tests added for new interactivity (no regressions).
- [ ] Lighthouse + axe-core + WCAG AA contrast pass on the redesigned page.
- [ ] Visual regression sweep on adjacent pages (token rename can ripple).
- [ ] All 2.5 content clichés swept, including em-dashes in user-visible copy.
- [ ] Second-pass audit: re-run the §2 audit on the post-fix state. Findings from pass 1 must be gone.
- [ ] Acceptance criteria from the upstream plan / change request satisfied.

## omo Integration

- **Stack.** Pair with [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) when you also need the anti-slop input-side rules during the fix; redesign-ui provides the audit + fix ladder, frontend-taste provides the active rules the agent should follow while fixing.
- **Handoff.** When the redesign introduces a new aesthetic direction (e.g., moves to Linear-style), load [`meisijiya-minimalist-ui`](~/.agents/skills/meisijiya-minimalist-ui/SKILL.md) as the active aesthetic family contract.
- **Dispatch.** Vertical-slice the fixes via [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — one slice per audit layer or per page, not all-at-once. Each slice carries the relevant audit findings as `must_fix` in the brief.
- **Completion.** [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) Stage 1 confirms the test + Lighthouse + axe + visual-regression passes; Stage 2 routes to OMO `review-work` (5 parallel lanes) and `visual-qa` (screenshots + pixel diff) for evidence.
- **Knowledge reuse.** Run [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) on the project's styling system before launching a redesign that touches tokens; reusable design debt lowers the redesign cost.

## Related Skills

- [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) — anti-slop input-side rules (active during the fix)
- [`meisijiya-minimalist-ui`](~/.agents/skills/meisijiya-minimalist-ui/SKILL.md) — Linear/Notion aesthetic direction (when direction is named)
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical-slice dispatch for the audit fixes
- [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — completion gate
- [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md) — for dashboards / data tables (where this skill does NOT apply)
- [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — for pure-bug fixes (where this skill does NOT apply)
- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — when the redesign should mirror a fresh design spec
