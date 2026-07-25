---
name: meisijiya-frontend-taste
description: "Anti-slop frontend rules for landing pages, portfolios, redesigns. Reads the brief, infers the design language, tunes three dials (variance/motion/density), enforces hard non-default rules on typography, color, layout, CTA, eyebrows, zigzag, motion, and image strategy to keep AI-generated UI from collapsing into AI-default templates. Use when the frontend agent is about to write UI code (React/Vue/Svelte/Tailwind) for marketing-grade frontends. NOT for dashboards, data tables, multi-step product UI. Pairs with designer-handoff as the second contract layer on top of project-specific design specs."
---

# meisijiya-frontend-taste

> **Attribution.** This skill is a meisijiya adaptation of [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)'s `taste-skill` (now v2), originally written by Leon Linnx and released under MIT License. Core anti-slop rules are preserved; structure has been rewritten to fit the meisijiya 6-section skill-anatomy format and the OMO collaboration model.

## Overview

LLM-written marketing frontend collapses into a small number of recognizable defaults: centered hero on dark mesh with AI-purple glow, three equal feature cards, generic glassmorphism everywhere, Inter + slate-900, Inter Display + Geist emoji micro-labels, fake screenshot previews. This skill enforces hard non-default rules at the moment the frontend agent begins writing UI code, so the output reads as designed, not generated.

Two layers of design contract stack: [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) provides the project-specific design spec (colors / type / component); this skill provides the second-layer anti-slop rules (anti-default commitments, anti-tell discipline, pre-flight gate).

## When to Use

**Use when:**
- Frontend agent is about to write UI code for landing pages / portfolios / marketing sites / redesigns
- Brief is for a "marketing-grade" frontend (a v1 SaaS landing, a designer portfolio, an editorial site, an agency site, a premium consumer product page)
- You want hard, named, mechanical enforcement against the LLM-default look (inter-purple-centered-glass slop)
- Working with React / Next.js / Vue / Svelte and Tailwind v4 (or vanilla CSS, shadcn/ui, Radix Themes)
- The brief is ambiguous but you trust the agent to declare a `Design Read` rather than be told by you

**NOT for:**
- Dashboards, data tables, admin UIs, multi-step product flows → those have different rules (use [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md))
- One-off mockups / spikes where the user explicitly says "anything goes"
- Sites already locked to a specific framework where the user explicitly bans this skill
- Tasks that only add a single component to an existing typed design system (no design language to infer)
- Image-generation-only output (no code) — see taste-skill's `imagegen-frontend-web` if you need that

This skill does **not** generate spec documents. It is the contract the frontend agent reads when starting to write code. Stack it with [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) when a project-specific spec exists.

## Process

### 1. Read the room — emit a `Design Read`

Before any code, state one line. Read **all six** signals:

1. **Page kind** — landing (SaaS / consumer / agency / event), portfolio (dev / designer / creative studio), redesign (preserve vs overhaul), editorial / blog.
2. **Vibe words** the user used — "minimalist", "calm", "Linear-style", "Awwwards", "brutalist", "premium consumer", "Apple-y", "playful", "serious B2B", "editorial", "agency-y", "glassy", "dark tech".
3. **Reference signals** — URLs they linked, screenshots they pasted, products they named, brands they're competing with.
4. **Audience** — B2B procurement panel vs. design-conscious consumer vs. recruiter scanning a portfolio.
5. **Brand assets that already exist** — logo, color, type, photography. For redesigns, these are starting material, not optional input.
6. **Quiet constraints** — accessibility-first audiences, public-sector, regulated industries, trust-first commerce, kids' products. **These OVERRIDE aesthetic preference.**

> **Design Read:** `<page kind>` for `<audience>` [overridden by `<quiet constraint>` if present], with `<vibe>` language, leaning toward `<design system or aesthetic family>`.

Examples:
- *"SaaS landing for technical buyers, with a Linear-style minimalist language, leaning toward Tailwind utilities + Geist + restrained motion."*
- *"Solo designer portfolio for hiring managers, with an editorial / kinetic-type language, leaning toward native CSS + scroll-driven animation."*
- *"Premium consumer site for an artisan cookware brand, with a Forest palette (deep green + bone + amber accent). Beats the AI-default beige+brass trap."*
- *"US public-sector service portal, **accessibility-critical audience**, leaning toward USWDS — overrides the brief's 'modern minimalist' ask."*

If vibe, audience, or aesthetic are genuinely divergent in the brief, ask exactly **one** clarifying question and stop. Do not dump a multi-question form.

### 2. Set three dials

| Dial | Default | Range | Meaning |
|---|---|---|---|
| `DESIGN_VARIANCE` | `8` | 1–10 | 1 = symmetric, 10 = artsy asymmetric |
| `MOTION_INTENSITY` | `6` | 1–10 | 1 = static, 10 = cinematic / physics |
| `VISUAL_DENSITY` | `4` | 1–10 | 1 = art gallery airy, 10 = cockpit dense |

Use the Dial Inference table below to override defaults based on the brief.

| Brief reads as… | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| minimalist / clean / calm / editorial / Linear-style | 5–6 | 3–4 | 2–3 |
| premium consumer / Apple / luxury / brand | 7–8 | 5–7 | 3–4 |
| playful / wild / Awwwards / experimental / agency | 9–10 | 8–10 | 3–4 |
| landing / portfolio / marketing (default) | 7–9 | 6–8 | 3–5 |
| trust-first / public-sector / regulated / a11y | 3–4 | 2–3 | 4–5 |
| redesign — preserve | match existing | +1 | match existing |
| redesign — overhaul | +2 | +2 | match existing |

Use these as global variables. Do not invent aliases like `LAYOUT_VARIANCE`.

### 3. Pick the design system or aesthetic

**When to reach for a real design system (install official package, do not re-CSS by hand):**

| Brief reads as… | Use | Why |
|---|---|---|
| Microsoft / enterprise SaaS | `@fluentui/react-components` or `@fluentui/web-components` | Official, MS tokens, accessibility done |
| Material-flavored product | `@material/web` + Material 3 tokens | Themeable |
| IBM-style / enterprise analytics | `@carbon/react` | Official Carbon, mature data density |
| Shopify admin | `polaris.js` / Polaris React | Required for Shopify |
| Atlassian / Jira | `@atlaskit/*` | Official |
| GitHub-style devtool | `@primer/react-brand` | Official; brand variant for marketing |
| UK public sector | `govuk-frontend` | Regulated |
| US public sector | `uswds` | Regulated |
| Fast agency / local-business MVP | Bootstrap 5.3 | Boring and works |
| Modern accessible React | `@radix-ui/themes` | Primitives + polished theme |
| Modern SaaS where you own components | shadcn/ui (`npx shadcn@latest add ...`) | You own the code; never ship default state |
| Tailwind-based modern SaaS / AI marketing | Tailwind v4 utilities + `dark:` | Default for indie |

**One system per project.** Never mix Fluent with Carbon in the same tree. Never import shadcn components into a Material 3 app.

**When the brief is an aesthetic (no single official package):** build with native CSS + Tailwind + a maintained component library. Label borrowed-inspiration clearly in code comments.

| Aesthetic | Honest implementation |
|---|---|
| Glassmorphism | `backdrop-filter`, layered borders, highlight overlays; provide solid fill for `prefers-reduced-transparency` |
| Bento | CSS Grid mixed cell sizes; no library owns this |
| Brutalism | Native CSS, monospace, raw borders |
| Editorial / magazine | Serif type, asymmetric grid, generous whitespace |
| Dark tech / hacker | Mono + accent neon, terminal motifs |
| Aurora / mesh gradients | SVG or layered radial gradients |
| Kinetic typography | Native CSS animations + GSAP for hijacks |
| Apple Liquid Glass | Apple docs this for Apple platforms only — **no** official `liquid-glass.css`. Web is `backdrop-filter` approximations; label as such |

### 4. Default stack conventions

- **Framework:** React / Next.js. Server Components by default. Any component using Motion, scroll listeners, or pointer physics MUST be an isolated leaf with `"use client"`.
- **Styling:** Tailwind v4 by default. Tailwind v3 only if existing project demands it. For v4: do NOT use `tailwindcss` plugin in `postcss.config.js`; use `@tailwindcss/postcss` or the Vite plugin.
- **Animation:** `motion/react` (the library formerly known as Framer Motion; `framer-motion` is a legacy alias).
- **Fonts:** Always `next/font` or self-host `@font-face` with `font-display: swap`. Never Google Fonts via `<link>` in production.
- **Icons (priority order):** `@phosphor-icons/react`, `hugeicons-react`, `@radix-ui/react-icons`, `@tabler/icons-react`. Discouraged: `lucide-react` unless user asks. **Never hand-roll SVG icons.** Standardize `strokeWidth` globally.
- **State:** Local `useState` / `useReducer` for isolated UI. Global state only for prop-drilling avoidance — Zustand / Jotai / Context. **Never `useState` to track continuous pointer / scroll / magnetic physics values** — use Motion's `useMotionValue` / `useTransform` / `useScroll`.
- **Emojis:** Discouraged. Replace with icon-library glyphs.
- **Responsiveness:** Standard breakpoints `sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536`. Contain page layouts at `max-w-[1400px]` or `max-w-7xl`.
- **Viewport stability:** **Never** use `h-screen` for full-height Hero. Always `min-h-[100dvh]` (iOS Safari bug).
- **Grid over flex math:** Never `w-[calc(33%-1rem)]`. Always CSS Grid (`grid grid-cols-1 md:grid-cols-3 gap-6`).
- **Dependency verification:** Before importing any 3rd-party, check `package.json`. Output install command first.

### 5. Design engineering directives (the anti-slop core)

These are the hard rules. Adapt to context, never silence them.

#### 5.1 Typography

- **Display headlines:** Default `text-4xl md:text-6xl tracking-tighter leading-none`.
- **Body:** Default `text-base text-gray-600 leading-relaxed max-w-[65ch]`.
- **Sans font choice:** Discouraged default = `Inter`. Reach for `Geist`, `Outfit`, `Cabinet Grotesk`, `Satoshi`, or a brand-appropriate serif first. Inter is acceptable only when the brief explicitly asks for neutral / Linear-style, or for public-sector / a11y.
- **Sans pairings to know:** `Geist + Geist Mono`, `Satoshi + JetBrains Mono`, `Cabinet Grotesk + Inter Tight`, `GT America + IBM Plex Mono`.
- **SERIF DISCIPLINE — very discouraged as default.** "It feels creative / premium" is NOT a reason to reach for serif. Sans display fonts (`Geist Display`, `ABC Diatype`, `Söhne Breit`, `Cabinet Grotesk Display`, `Migra Sans`, `GT Walsheim`, `Inter Display`, `PP Neue Montreal`) are the default for the same reason black is the default in fashion.
- **When serif is acceptable:** only when the brief literally names a serif OR the aesthetic is genuinely editorial / heritage / publication AND you can articulate the reason. Acceptable rotation: `PP Editorial New`, `GT Sectra Display`, `Cardinal Grotesque`, `Reckless Neue`, `Tiempos Headline`, `Recoleta`, `Cormorant Garamond`, `Playfair Display`, `EB Garamond`, `IvyPresto`, `Migra`, `Editorial Old`, `Saol Display`, `Söhne Breit Kursiv`, `Domaine Display`, `Canela`, `Schnyder`, `Tobias`, `NB Architekt`, `ITC Galliard`.
- **Specifically BANNED as defaults:** `Fraunces` and `Instrument_Serif` — the two LLM-favorite display serifs that scream "AI default".
- **Emphasis rule:** in headlines, use italic or bold of the **same** font. Never inject a random serif word into a sans headline or vice versa.
- **Italic descender clearance:** when italic is used in display type and the word contains `y g j p q`, `leading-[1]` clips the descender. Use `leading-[1.1]` minimum and add `pb-1` or `mb-1` reserve on the wrapping element.

#### 5.2 Color calibration

- Max 1 accent color. Saturation < 80% by default.
- **The Lila Rule:** the "AI Purple / Blue glow" is discouraged as default. No automatic purple button glows, no random neon gradients. Use neutral bases (`Zinc / Slate / Stone`) with high-contrast singular accents (`Emerald, Electric Blue, Deep Rose, Burnt Orange`, etc.).
- **Premium-consumer palette rotation (mandatory).** The LLM default for premium / artisan / DTC briefs is warm beige + brass/oxblood + espresso. Concrete banned hex families as defaults:

  | Role | Banned hex examples |
  |---|---|
  | Backgrounds | `#f5f1ea`, `#f7f5f1`, `#fbf8f1`, `#efeae0`, `#ece6db`, `#faf7f1`, `#e8dfcb` |
  | Accents | `#b08947`, `#b6553a`, `#9a2436`, `#9c6e2a`, `#bc7c3a`, `#7d5621` |
  | Text | `#1a1714`, `#1a1814`, `#1b1814` |

- **Rotation rule:** if the previous premium-consumer project used beige+brass, this one uses Cold Luxury (silver/grey/chrome/smoke) / Forest (deep green + bone + amber) / Black-and-Tan (true off-black + warm tan) / Cobalt + Cream / Terracotta + Slate / Olive + Brick + Paper / Pure mono + single saturated pop. Do not ship the same warm-craft palette twice in a row.
- **Override:** beige+brass+espresso is allowed only when the brand brief explicitly names those colors OR when the brand is genuinely vintage / artisan / warm-craft AND you can articulate why.
- **Color consistency lock:** once an accent is chosen, it is used on the WHOLE page. Pick one accent, lock it, audit every component.
- **One palette per project:** do not mix warm and cool grays within the same project.

#### 5.3 Layout diversification — the AI-tell breakers

- **Anti-center bias:** centered Hero / H1 sections are avoided when `DESIGN_VARIANCE > 4`. Force Split Screen (50/50), Left-aligned content / Right-aligned asset, Asymmetric white-space, or scroll-pinned structures. Override: centered is OK for editorial / manifesto / launch-announcement.
- **Section-layout-rotation ban.** Once a layout family is used (3-col-image-cards, full-width-quote, split-text-image), that family appears at most ONCE on the page. A landing page with 8 sections must use at least 4 different layout families.
- **Zigzag alternation cap (mandatory).** "Left-image + right-text" then "left-text + right-image" zigzag is Banal. Max 2 sections in a row with this image+text-split pattern. The 3rd consecutive is a Pre-Flight Fail. Break the pattern with a full-width section, vertical stack, bento grid, marquee, or another family.
- **Bento cell count rule (mandatory).** A bento grid has EXACTLY as many cells as you have content for. 3 items → 3 cells (1+2 or 2+1, or asymmetric trio). 5 items → 5 cells. If your grid has an empty cell, you planned wrong.
- **Bento background diversity (mandatory).** Bento and feature-grid sections cannot be 6 white-on-white cards. At least 2–3 cells need real visual variation: a real image, a brand-appropriate gradient (not AI-purple), a pattern, a tinted background.
- **Eyebrow restraint (mandatory, the #1 violated rule in production tests).** "Eyebrow" = small uppercase wide-tracking label sitting above a section headline (e.g., `FOUR COLORWAYS`, `SELECTED WORK`).
  - **Maximum 1 eyebrow per 3 sections.** Hero counts as 1. A 9-section page may use at most 3 eyebrows total.
  - If section A has an eyebrow, the next 2 sections cannot.
  - **Pre-Flight Check:** count instances of `uppercase tracking` across section components. If `count > ceil(sectionCount / 3)`, the output fails.
  - Alternative: drop the eyebrow. The headline alone is enough.
- **Split-header ban (mandatory).** "Left big headline + right small explainer paragraph" pattern is BANNED as default. Stack vertically (headline on top, body below, max-width 65ch) by default. Reach for split-header only when the right column carries a visual or interactive element.
- **Mobile collapse must be explicit per section.** Declare `< 768px` fallback in the same component. No "Tailwind handles it" assumptions.

#### 5.4 Shape / shadow / card discipline

- **Shape consistency lock:** pick ONE corner-radius scale and stick to it. Options: all-sharp (radius 0), all-soft (12–16px), all-pill (full). Mixed is broken design.
- **When a shadow is used, tint it to the background hue.** No pure-black drop shadows on light backgrounds.
- **For `VISUAL_DENSITY > 7`:** generic card containers are banned. Data metrics breathe in plain layout.
- **Use cards ONLY when elevation communicates real hierarchy.** Otherwise group with `border-t`, `divide-y`, or negative space.

#### 5.5 Interactive states

- **Loading:** Skeletal loaders matching the final layout's shape. Never generic circular spinners.
- **Empty / Error states:** Beautifully composed; indicate how to populate / handle inline.
- **Tactile feedback:** On `:active`, `-translate-y-[1px]` or `scale-[0.98]` to simulate physical push.
- **BUTTON CONTRAST (mandatory, a11y).** White text on white, transparent button on page bg with no border, ghost button on photo with no scrim → all BANNED. Audit every CTA: WCAG AA (4.5:1 body, 3:1 large text 18px+).
- **CTA WRAP BAN (mandatory).** Button text MUST fit on one line at desktop. If `VIEW SELECTED WORK` wraps to 2–3 lines, the button is broken. Fix by shortening the label (3 words max for primary CTAs, ideally 1–2) or widening the button.
- **NO DUPLICATE CTA INTENT (mandatory).** "Get in touch" + "Contact us" + "Let's talk" + "Start a project" = all "contact" intent. Pick ONE label and use it everywhere. Same for "Try free" + "Get started" + "Sign up free" (signup intent) and "View work" + "See selected work" + "Browse projects" (portfolio intent). One label per intent.
- **FORM CONTRAST (mandatory, a11y).** Inputs, placeholder text, focus rings, helper text, error text all pass WCAG AA against the section background. Light placeholders on near-white form → banned.

#### 5.6 Data & form patterns

- **Label ABOVE input.** Helper text optional but present in markup. Error text BELOW input. Standard `gap-2` for input blocks.
- **No placeholder-as-label.** Ever. Placeholders are placeholder content; labels are labels. This is the AI-default shortcut to avoid.

#### 5.6 Layout discipline (failing any = shipping broken work)

- **Hero MUST fit in the initial viewport.** Headline max 2 lines on desktop, subtext max **20 words** AND max 3–4 lines, CTAs visible without scroll. Reduce font scale or cut copy; never scroll the page to find the CTA.
- **Hero font-scale discipline.** Plan font size and image size together. Default `text-4xl md:text-5xl lg:text-6xl`; `text-6xl md:text-7xl` only when headline is 3–5 words. A 4-line hero headline is always a font-size error, never a copy-length error.
- **HERO TOP PADDING CAP (mandatory).** Hero top padding max `pt-24` (≈6rem) at desktop. More means content floats halfway down — a layout bug. Increase font scale or asset size instead.
- **HERO STACK DISCIPLINE (max 4 text elements).** Eyebrow (zero or one), headline (≤2 lines), subtext (≤20 words / ≤4 lines), CTAs (1 primary + max 1 secondary). Banned in hero: tiny tagline under CTAs, trust micro-strip, pricing teaser, feature bullets, social-proof avatar row.
- **"Used by" / "Trusted by" logo wall belongs UNDER the hero,** never inside it.
- **Navigation MUST render on a single line on desktop.** Two-line nav at desktop = broken.
- **Navigation height cap: 80px max desktop, default 64–72px.**

#### 5.7 Content density & copy

- **Default content shape per section:** short headline (≤8 words) + short sub-paragraph (≤25 words) + one visual or one CTA.
- **No data-dump sections.** A 20-row publication table, 30-row award list, giant pricing matrix on a marketing page = wrong layout. Use Top 3–5 highlights + "View full list", marquee/carousel, or a different page entirely.
- **Long lists need a different UI component.** A `<ul>` with `border-b` on every row is the lazy choice. If you have >5 items, reach for: 2-column grouped, card grid with image+label, tabs/accordion, horizontal scroll-snap pills, carousel, marquee.
- **Spec sheets specifically (Marrow-cookware pattern)** are banned: long product specification table with `border-b` every row. Use 2-col card grid, scroll-snap horizontal pills, grouped chunks (2–3 logical clusters with sparse dividers), or featured-vs-rest.
- **COPY SELF-AUDIT (mandatory before ship).** Re-read every visible string. Flag grammatically broken, AI-hallucinated wordplay, LLM-trying-to-sound-thoughtful, passive-aggressive humility, mock-poetic micro-meta. Rewrite every flag.
- **Fake-precise numbers are flagged.** `92%`, `4.1×`, `48k`, `5.8 mm`, `13.4 lb` either come from real data (brief, public metrics), are explicitly labeled mock, or are banned (AI-invented "spec aesthetic").
- **Banned AI copywriting clichés:** `Elevate`, `Seamless`, `Unleash`, `Next-Gen`, `Game-changer`, `Delve`, `Tapestry`, `In the world of`. Write plain, specific language.
- **One copy register per page.** Don't mix technical mono + editorial prose + marketing punch unless the brand voice explicitly calls for it.

#### 5.8 Image & visual asset strategy

- **Priority:** (1) Image-generation tool if available — generate section-specific assets at the right aspect ratio. (2) Real web images — `https://picsum.photos/seed/{descriptive-seed}/{w}/{h}` for placeholders (e.g., `marrow-cookware-kitchen`). (3) Last resort — tell the user what's missing, leave labeled placeholders.
- **Even minimalist sites need real images.** Editorial Linear-style needs ≥2–3 real images (hero + product/lifestyle + supporting). Don't skip images because the dial is low.
- **Real logos for social proof.** Use real SVG logos: `https://cdn.simpleicons.org/{slug}/ffffff` or `simple-icons` npm package. Make-up brand? Make-up an SVG mark (monogram in circle, two-letter ligature).
- **Logo-only rule:** logo wall = logos + nothing else. Don't print category labels below (`Vercel + hosting`, `Stripe + payments`). Optional alt text and link.
- **Hand-rolled illustrations:** discouraged except: brief calls for it, single geometric mark, or you are confident in quality.
- **Div-based fake screenshots are banned.** A hand-built product preview with `<div>` rectangles and fake task lists is a Tell. Use a real screenshot URL, generate one, use a real component preview, or skip the preview.
- **Hero needs a real visual.** Text + gradient blob is not a hero; it's a placeholder.

#### 5.9 Motion

- **Motion must be motivated.** Before adding any animation, ask "what does this communicate?" Valid: hierarchy / storytelling / feedback / state transition. Invalid: "it looked cool". GSAP everywhere because it's available is amateur.
- **Implementation:** Motion exclusively with `useMotionValue` / `useTransform` outside the React render cycle. Never `useState` for pointer physics / scroll / magnetic.
- **Marquee max 1 per page.** Horizontal scrolling text marquees at most ONCE per page. Two or more reads as lazy filler.
- **Motion claimed, motion shown.** If `MOTION_INTENSITY > 4`, the page must actually move: entry transitions on hero, scroll-reveal on key sections, hover physics on CTAs. Static page claiming `MOTION_INTENSITY: 7` is broken. If you can't ship working motion in scope, drop the dial to 3 and ship static.

#### 5.10 Quote / testimonial / theme lock

- **Max 3 lines of quote body.** Never 6. Attribution: name + role + (optionally) company.
- **No em-dashes (`—`) in text.** Hard rule, applies to user-visible copy, headlines, subheads, body. Use `,` `:` `(` `)` — even `–` is borderline. Em-dash in test mode = AI fingerprint.
- **The page has ONE theme.** Sections do not invert mid-scroll. Theme switch is allowed once per page with a strong transition, not random alternation.
- **No pure-black backgrounds.** Use off-black / dark charcoal / tinted dark (`#0a0a0a`, `#121212`, dark navy). Same ban applies to text colors.

### 6. Pre-flight check

Before declaring the slice done, run mechanically:

- [ ] Design Read emitted in one line.
- [ ] Three dials set explicitly (variance / motion / density).
- [ ] Eyebrow count ≤ ceil(sections / 3).
- [ ] No CTA wraps to 2+ lines at desktop.
- [ ] No duplicate CTA intent on the page (one label per intent).
- [ ] Max 2 consecutive image+text-split sections.
- [ ] Bento / feature-grid has real visual variation in 2–3 cells.
- [ ] Hero fits in initial viewport (headline ≤2 lines, subtext ≤20 words / ≤4 lines, CTAs visible).
- [ ] Hero top padding ≤ `pt-24` at desktop.
- [ ] Navigation on a single line at desktop; height ≤ 80px.
- [ ] All interactive states implemented (loading / empty / error / hover / active / focus).
- [ ] Button & form contrast WCAG AA.
- [ ] Section-layout-rotation ban: at least 4 layout families for 8 sections.
- [ ] Premium-consumer palette rotation: not the same warm-craft family twice in a row.
- [ ] No banned AI fonts (Inter as default, `Fraunces`, `Instrument_Serif`).
- [ ] No em-dash in visible copy.
- [ ] No `h-screen` for hero; always `min-h-[100dvh]`.
- [ ] No `lucide-react` (unless explicitly asked). Phosphor / Hugeicons / Radix / Tabler preferred.
- [ ] No pure `#000` background; off-black or tinted dark.
- [ ] No hand-built fake screenshots; real images / real component preview / skip.
- [ ] COPY SELF-AUDIT done; no AI-hallucinated wordplay, mock-poetic micro-meta, banned clichés.
- [ ] At least 2–3 real images on the page even for minimalist briefs.
- [ ] Motion motivated; implements `useMotionValue` for pointer physics.
- [ ] One palette / one theme / one shape scale per page.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "The brief didn't specify, so I'll go safe" | "Safe" = AI default. Declare a Design Read explicitly. |
| "It's just a landing page, I'll keep it simple centered" | Centered hero on `> variance 4` = AI tell. Use split / asymmetric. |
| "Inter is the modern default, why not?" | Inter is the AI default. Reach for Geist / Outfit / Satoshi / Cabinet Grotesk first. |
| "I added an eyebrow on every section for hierarchy" | Eyes-tripping. Max 1 eyebrow per 3 sections. |
| "Premium-feeling = warm beige + brass accents" | Banned as default for premium briefs. Rotate palette family. |
| "I made a fake product screenshot with divs" | Tell. Use real image or skip. |
| "The button wraps on mobile, that's responsive" | Wrapped CTA at desktop is broken. Shorten label. |
| "lucide-react is fine, everyone uses it" | Discouraged unless user asked. Reach for Phosphor / Hugeicons first. |
| "It's fine to use `h-screen` on hero" | iOS Safari bug. `min-h-[100dvh]` always. |
| "Two `Let's talk` CTAs are clearer" | Two CTAs with the same intent = broken. Pick one label. |
| "I copy-pasted the section layout family three times" | Section-layout-rotation ban: each family max once per page. |
| "I'll add `bg-[#000]` for max contrast" | Pure black is a default. Use `#0a0a0a` / `#121212` / tinted dark. |
| "Em-dash adds rhythm" | Em-dash is the AI tell for LLMs. Use `,` `:` `(` `)`. |

## Red Flags

- "I'll just use the same default I always do" — emit a Design Read first.
- `tracking-tighter` + `Inter` + `slate-900` + centered hero + 3-col feature cards all in one page — the LLM-default stack.
- Same layout family appears 3+ times on a single page.
- Eyebrow tag sits above every section headline.
- Image+text-split sections zigzagging for 3+ consecutive rows.
- Bento grid with one cream-on-cream blank cell in the middle.
- "Easy-to-grow" SaaS sites where every section uses the same muted palette as the previous one.
- "Premium consumer" defaulting to cream / brass / oxblood without brief explicitly asking for it.
- `text-8xl text-center` hero with 5-line headline.
- `bg-[#000]` "for max contrast".
- `lucide-react` + `lg:w-[calc(33%-1rem)]` + `shadow-md` everywhere.
- `useState` driving scroll / pointer / magnetic physics.
- A page where `MOTION_INTENSITY > 4` but no actual motion ships.
- Em-dashes in visible copy (`—`).
- `Fraunces` or `Instrument_Serif` displayed unironically.

## Verification

Before declaring the implementation complete, confirm:

- [ ] Design Read line emitted and matches brief.
- [ ] Three dials set; design system / aesthetic family chosen via §3.
- [ ] Pre-flight checklist all green.
- [ ] Designer-handoff spec (if project has one) read and respected.
- [ ] Stack conventions followed (RSC isolation, Tailwind v4, `motion/react`, fonts loaded once).
- [ ] All 5.x rules applied with documented overrides where taken.
- [ ] Acceptance criteria from the upstream plan / spec met.
- [ ] Visual QA via OMO `visual-qa` (screenshots + pixel diff) confirms intent-level match.
- [ ] Accessibility audit (WCAG AA contrast, focus rings, `prefers-reduced-motion` honored) passes.
- [ ] Copy self-audit done; em-dashes swept, fake-precision numbers labeled.

## omo Integration

- **Handoff chain.** Stack with [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) (project-specific spec) — both contracts are read by the frontend agent before any UI code, in that order. `designer-handoff` provides color / type / component; this skill provides anti-slop enforcement on top.
- **Renderer.** Visual implementation runs through OMO `frontend` (visual-engineering category, gemini-3.1-pro high) per [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) §6.
- **Pre-implementation alignment.** Use [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) when the user wants a Design Read → spec → alignment before coding.
- **Implementation dispatch.** Wrap the build in [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) for vertical slices; include the active Design Read + dials in each slice brief.
- **Completion gate.** Use [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) Stage 1 + the Pre-flight checklist; Stage 2 routes to OMO `review-work` (5 parallel lanes) and `visual-qa` (Playwright screenshots + pixel diff).
- **Specific-page-overhaul mode.** Stack with [`meisijiya-redesign-ui`](~/.agents/skills/meisijiya-redesign-ui/SKILL.md) when the task is audit-existing-UIs-then-fix, not greenfield.
- **Specific aesthetic direction.** When the brief names a known aesthetic, stack the matching subskill first (`meisijiya-minimalist-ui` for Linear/Notion; add new variants as needed).

## Related Skills

- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — project-specific design spec contract (precedes this skill)
- [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) — intent-gated pre-implementation alignment (Markdown / HTML / teaching)
- [`meisijiya-redesign-ui`](~/.agents/skills/meisijiya-redesign-ui/SKILL.md) — scan / diagnose / fix for existing UI code
- [`meisijiya-minimalist-ui`](~/.agents/skills/meisijiya-minimalist-ui/SKILL.md) — Linear/Notion editorial aesthetics (one specific direction)
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical-slice dispatch for the implementation phase
- [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — Evidence-based completion gate
- [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md) — for dashboards / data tables / product UI (where this skill explicitly does NOT apply)
