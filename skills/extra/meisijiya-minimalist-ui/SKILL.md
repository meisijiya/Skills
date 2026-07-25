---
name: meisijiya-minimalist-ui
description: "Premium utilitarian minimalist & editorial UI protocol for Linear/Notion-style product surfaces. Enforces high-contrast warm monochrome palette + spot pastels, bespoke typographic hierarchy (sans body + serif display), asymmetric CSS Grid bento layouts, ultra-flat bordered components with crisp 8–12px radius, understated spring motion. Use when the brief names Linear / Notion / editorial / minimalist / premium-utilitarian aesthetic for a product UI. Pairs as the active aesthetic direction under meisijiya-frontend-taste."
---

# meisijiya-minimalist-ui

> **Attribution.** This skill is a meisijiya adaptation of [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)'s `minimalist-skill` (install name `minimalist-ui`), originally written by Leon Linnx and released under MIT License. The aesthetic protocol is preserved; the skill has been rewritten to fit the meisijiya 6-section skill-anatomy format and the OMO collaboration model.

## Overview

When the brief names a Linear / Notion / editorial / utilitarian / premium-product aesthetic, this skill constrains the frontend agent to the discipline that produces that look: warm monochrome neutrals (off-white / bone / charcoal) with a few desaturated pastel accents only for semantic meaning; serif display + sans body + monospace for data and meta; asymmetric bento grids; ultra-flat 8–12px radius bordered components; under-stated motion. The result reads as a high-end product surface, not a template.

This is **not** an entry-level aesthetic for raw greenfield landing pages. It is a specific direction to plug into [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) when the aesthetic family has already been named.

## When to Use

**Use when:**
- Brief names `Linear`, `Notion`, `editorial`, `utilitarian`, `premium utilitarian`, `minimalist`, `document-style`, `calm`, `Notion-vibes`
- Product surface, not a marketing landing (the brief uses words like "app", "interface", "console", "workspace")
- User explicitly wants the high-end feel of `Linear` or `Notion`, not Awwwards / brutalist / playful / agency / dark tech

**NOT for:**
- Landing pages without an explicit aesthetic name → use [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) and infer an aesthetic via its §3 table
- Premium consumer marketing pages (cookware / wellness / luxury / heritage) → those use a different palette rotation per `meisijiya-frontend-taste` §5.2
- Brutalist / dark tech / playful / agency / Awwwards → use a different sub-skill (or future variants)
- Dashboards with high data density → those go past `VISUAL_DENSITY: 7`, where generic card containers are banned

This skill assumes [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) has already been read; this skill **narrows** its dial defaults rather than overriding them.

## Process

### 1. Set the dials for this aesthetic

| Dial | Default for minimalist-ui | Range allowed | Why |
|---|---|---|---|
| `DESIGN_VARIANCE` | `5–6` | 4–7 | Editorial asymmetry without Awwwards chaos |
| `MOTION_INTENSITY` | `3–4` | 2–5 | Under-stated motion; hover + entry reveals, never cinematic |
| `VISUAL_DENSITY` | `3` | 2–5 | Calm / air-by-default; tight grids only for data-dense sections |

### 2. Establish the macro-whitespace first

Before any component, define:

- **Section vertical padding:** `py-24` to `py-32` (`py-40` only for hero). Let the page breathe.
- **Main typography container:** `max-w-4xl` to `max-w-5xl` for reading content.
- **Editorial whitespace:** deliberate asymmetric placement — when content sits left, right side gets negative space, not empty filler.

### 3. Apply the typographic architecture

#### 3.1 Three-tier type system

| Tier | Use | Recommended families |
|---|---|---|
| Primary sans (body, UI, buttons, inputs) | All functional text | `Geist Sans`, `Söhne`, `Inter`, `Switzer`, `Manrope` |
| Editorial serif (hero, quotes, section accents) | Editorial flourishes only | `Newsreader`, `Lyon Text`, `Instrument Serif`, `Tiempos`, `Source Serif 4` |
| Monospace (code, keystrokes, meta, timestamps, IDs) | Technical and meta | `Geist Mono`, `JetBrains Mono`, `IBM Plex Mono`, `SF Mono` |

**Hierarchy requirements:**

- **Display headlines:** `letter-spacing: -0.02em` to `-0.04em`, `line-height: 1.1` for impact.
- **Body text:** never `#000000`. Use `#111111` or `#2F3437` with `line-height: 1.6`. Secondary text `#787774`.
- **Italic display:** mirror §3.1 of [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) — italic descender clearance.

#### 3.2 Banned serifs (apply the same rule as `frontend-taste` §5.1)

- BANNED as default for this aesthetic: `Fraunces`, `Instrument_Serif` — the LLM-favorite display serifs.
- Generic system serifs (`Times New Roman`, `Georgia`) are also banned.
- If the brief genuinely requires serif (named in brand or required by editorial heritage), rotate from the taste-skill acceptable pool:
  `PP Editorial New`, `GT Sectra Display`, `Reckless Neue`, `Tiempos Headline`, `Recoleta`, `Cormorant Garamond`, `Playfair Display`, `EB Garamond`, `IvyPresto`, `Editorial Old`, `Saol Display`, `Canela`, `Schnyder`, `Tobias`.

### 4. Color palette — warm monochrome + spot pastels

#### 4.1 The discipline

Color is **scarce**. It is reserved for semantic meaning or subtle accents — never for decoration. Multiple saturated colors on a single page break the aesthetic.

#### 4.2 The palette

| Role | Hex | Usage |
|---|---|---|
| Canvas / background | `#FFFFFF` or `#F7F6F3` (warm bone) | Page background |
| Primary surface (cards) | `#FFFFFF` or `#F9F9F8` | Bordered components |
| Structural borders / dividers | `#EAEAEA` or `rgba(0,0,0,0.06)` | Card borders, list separators |
| Primary text | `#111111` or `#2F3437` | Body, never pure `#000000` |
| Secondary text | `#787774` | Subtitles, metadata, helper text |
| Inverted surface | `#111111` (filled button) | Primary CTA background |
| Inverted text | `#FFFFFF` | Primary CTA text |

#### 4.3 Spot-pastel accents (semantic only)

Use these exclusively for tags / status / inline code backgrounds / subtle icon backgrounds. Never for sections, buttons, or hero.

| Name | Background | Text |
|---|---|---|
| Pale Red | `#FDEBEC` | `#9F2F2D` |
| Pale Blue | `#E1F3FE` | `#1F6C9F` |
| Pale Green | `#EDF3EC` | `#346538` |
| Pale Yellow | `#FBF3DB` | `#956400` |

**Override:** pastel accents are replaced if a brand color is named. The palette stays monochrome; the accent becomes brand.

#### 4.4 Anti-bans for this aesthetic

- No AI purple / blue neon glows — explicitly broken per [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) §5.2 ("Lila Rule").
- No large-saturated-CTA — primary CTA is `#111111` background or `#FFFFFF` outline on dark sections.
- No gradient on body or accents. Gradient allowed only on a subtle radial hero light spot at `opacity: 0.03`.
- No bright neon — this aesthetic is warm and quiet, not electric.

### 5. Component specifications

#### 5.1 Bento feature grids

- Asymmetric CSS Grid layouts — `grid-cols-2` / `grid-cols-3` with mixed `col-span` / `row-span`.
- Cards: exactly `border: 1px solid #EAEAEA` (or framework token equivalent).
- Border-radius: `8px` or `12px`. **Never `rounded-full` for cards / large containers / primary buttons.** Pill buttons are not part of this aesthetic.
- Internal padding: generous `24px` to `40px`.
- **No empty cells.** Mirror §5.3 of [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) — asymmetric trio (1+2 or 2+1) when content count is 3, etc.

#### 5.2 Primary CTA buttons

- Solid background `#111111`, text `#FFFFFF`.
- Border-radius: `4px` to `6px`. No box-shadow.
- Hover: background shift to `#333333` OR micro-scale `transform: scale(0.98)` on `:active`.
- Never `rounded-full` (pill).
- Never a bright accent color — accent is `#111111`.

#### 5.3 Tags and status badges

- Pill-shaped (`border-radius: 9999px`) — exception to the button rule; small badges are intentionally pill.
- Tiny type: `text-xs`. Uppercase + wide tracking (`letter-spacing: 0.05em`).
- Background: pastel from §4.3.

#### 5.4 Accordion FAQ

- Strip container boxes. Items separated by `border-bottom: 1px solid #EAEAEA`.
- Toggle icon: clean sharp `+` and `-`.

#### 5.5 Keystroke micro-UI

- Render shortcuts as physical keys using `<kbd>`: `border: 1px solid #EAEAEA`, `border-radius: 4px`, `background: #F7F6F3`, monospace font.

#### 5.6 Faux-OS window chrome

When mocking up software, wrap in a minimalist container with a white top bar containing three small light-gray circles (macOS window controls metaphor).

### 6. Iconography

- **System icons:** Phosphor (Bold or Fill) / Radix UI Icons for a technical, slightly thicker-stroke aesthetic. Standardize ONE stroke weight.
- No emojis in code, markup, visible text, or alt text — replace with proper icons.
- Discouraged: standard thin Lucide / Feather / Heroicons unless explicitly required.

### 7. Imagery

| Asset | Recommendation |
|---|---|
| Illustrations | Monochromatic continuous-line ink sketches with one offset muted-pastel shape |
| Photography | High-quality desaturated + warm-tone; subtle `opacity: 0.04` warm grain overlay |
| Placeholders | `https://picsum.photos/seed/{context}/1200/800` (descriptive seed) |
| Hero background | Subtle full-width image at low opacity OR soft radial `opacity: 0.03` OR minimal geometric pattern |

Avoid oversaturated stock photography. Empty flat backgrounds are unfinished — add image moments even for restrained briefs.

### 8. Motion — quiet sophistication

Motion should be **invisible** — present, never distracting.

| Pattern | Implementation |
|---|---|
| Scroll entry | `translateY(12px)` + `opacity: 0` → `translateY(0)` + `opacity: 1` over `600ms` `cubic-bezier(0.16, 1, 0.3, 1)`. Use `IntersectionObserver`, never `window.addEventListener('scroll')`. |
| Hover | Cards lift with ultra-subtle shadow shift (`box-shadow` from `0 0 0` → `0 2px 8px rgba(0,0,0,0.04)` over `200ms`). Buttons respond with `scale(0.98)` on `:active`. |
| Staggered reveals | Cascade delay `animation-delay: calc(var(--index) * 80ms)` for lists and grids. Never mount everything at once. |
| Background ambient | Optional single slow radial gradient blob (`animation-duration: 20s+`, `opacity: 0.02–0.04`). Apply to `position: fixed; pointer-events: none` layer. Never on scrolling containers. |
| Performance | Animate exclusively via `transform` and `opacity`. Never `top` / `left` / `width` / `height`. `will-change: transform` sparingly. |

### 9. Mobile discipline

Universal mobile overrides (mirror the 4.x mobile-collapse rules in the front-end taste skill):

- Asymmetric layouts above `md:` must collapse to single-column below `<768px`.
- `w-full` + `px-4` + `py-8` on sub-768 viewports.
- Typography scales via `clamp()` or framework token equivalents.
- Touch targets minimum `44px × 44px`.
- Section padding reduces proportionally.
- Replace any `h-screen` with `min-h-[100dvh]`.

### 10. Execution protocol

When generating UI code for this aesthetic, follow this exact sequence:

1. Establish macro-whitespace first.
2. Apply typography hierarchy immediately (san-serif body + serif display + mono).
3. Set the monochrome palette as CSS variables / theme tokens.
4. Apply 1px borders + 8–12px radius to every card / divider.
5. Add scroll-entry animations via `IntersectionObserver` or `motion/react`'s `whileInView`.
6. Add ambient visual depth through texture / radial blob / subtle background imagery — never flat.
7. Confirm every line of visible copy against [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) §5.7 (copy self-audit, AI clichés, em-dash ban).

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Editorial design = serif everywhere" | No — serif is reserved for accent moments; sans body is the workhorse |
| "More colors make it feel rich" | Monochrome restraint is what makes it premium; pastels only for semantics |
| "Use a pill button for the primary CTA" | Pill breaks the Linear/Notion geometry; use 4–6px radius |
| "Add a Lucide grid icon" | Lucide = AI-default; Phosphor Bold or Radix is the move |
| "Add a drop-shadow to make the card pop" | Ultra-flat — shadow is `0 2px 8px rgba(0,0,0,0.04)` max |
| "Make the hero full bleed with a saturated photo" | Desaturated, warm-tone, low opacity — that's the rule |
| "Skeletons are too plain, add a spinner" | Skeletons match layout shape; spinner is the AI default |
| "It's a calm design, motion can be skipped" | Motion is invisible, but it must be present — hover, entry, staggered reveals |
| "Use Tailwind's `shadow-md` as the standard" | Banned here; use a custom ultra-diffused shadow or no shadow |

## Red Flags

- `bg-[#000000]` or pure black anywhere on the page.
- Tailwind `shadow-md` / `shadow-lg` / `shadow-xl` (default heavy drop shadow).
- `rounded-full` on primary CTA or on a card.
- Emojis in copy / code / alt text.
- AI copywriting clichés (`Elevate`, `Seamless`, `Unleash`, `Next-Gen`, `Game-changer`, `Delve`).
- Fraunces or Instrument_Serif used unironically as display serif.
- Bordered Bento cell with no content + cream-on-cream background (AI-tell)
- Bento grid using equal-size cards (asymmetric varies; equal reads as template).
- Generic Lucide icons across the whole interface.
- Lucide used at thin stroke while another icon family is mixed in (mix-family failure).
- Hard-coded navy / electric-blue CTA in a brand-default-monochrome context.
- `lucide-react` added with no other reason than "we need an icon".

## Verification

Before declaring implementation complete:

- [ ] Dials set explicitly: variance 5–6, motion 3–4, density 3.
- [ ] Macro-whitespace applied: section vertical padding `py-24`+ ; reading content `max-w-4xl`–`max-w-5xl`.
- [ ] Three-tier typography (sans body + serif display + mono) used consistently.
- [ ] Pure `#000000` absent; primary text `#111111` / `#2F3437`.
- [ ] Card border-radius 8–12px; primary CTA radius 4–6px; **no `rounded-full` on either**.
- [ ] Card border `1px solid #EAEAEA` (or framework equivalent) — single rule everywhere.
- [ ] Bento grids asymmetric; cell count matches content count.
- [ ] Colors restricted to monochrome + the pastel semantic map (or named brand).
- [ ] Icons from a single family (Phosphor / Radix) at single stroke weight.
- [ ] No emojis anywhere.
- [ ] Motion via `IntersectionObserver` / `whileInView` only; never `useState` driving scroll.
- [ ] All ambient motion on `position: fixed; pointer-events: none` layers.
- [ ] Mobile collapse explicit below 768px on every asymmetric component.
- [ ] Copy self-audit done per `meisijiya-frontend-taste` §5.7; em-dashes swept; AI clichés swept.
- [ ] Visual QA via OMO `visual-qa` confirms intent-level match.
- [ ] Lighthouse + axe + WCAG AA contrast pass.

## omo Integration

- **Direction layer.** This skill is loaded AFTER [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md). Frontend-taste provides the anti-slop rules and the active Design Read; this skill narrows the dial defaults, palette, typography, and components to the Linear/Notion editorial family.
- **Renderer.** Visual implementation routes through OMO `frontend` (visual-engineering category, gemini-3.1-pro high) per [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) §6.
- **Dispatch.** [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) for vertical slices; carry `meisijiya-frontend-taste` §1 Design Read + `meisijiya-minimalist-ui` §1 dial triple + the §4 palette + the §3 typographic tier in every brief.
- **Gate.** [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) Stage 1 confirms the verification list above passes; Stage 2 routes to OMO `review-work` (5 parallel lanes) and `visual-qa` (screenshots + pixel diff).
- **Pairing with audit.** When the project is an existing UI being upgraded to this aesthetic, load [`meisijiya-redesign-ui`](~/.agents/skills/meisijiya-redesign-ui/SKILL.md) first to drive the audit, then apply this skill as the active direction during fixes.

## Related Skills

- [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) — anti-slop core rules (load first; this skill narrows it)
- [`meisijiya-redesign-ui`](~/.agents/skills/meisijiya-redesign-ui/SKILL.md) — audit + fix ladder for existing UIs
- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — project-specific design spec contract
- [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) — pre-implementation alignment (Markdown / HTML / teaching)
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical-slice dispatch
- [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — Evidence-based completion gate
