# Dispatcher Rationalizations & Red Flags

Anti-rationalization reference for the `using-meisijiya-skills` dispatcher
(loaded from SKILL.md §Process). Read when tempted to skip skill invocation.

## Common Rationalizations

| Thought | Reality |
|---|---|
| "This is just a simple question" / "Let me explore first" / "I can check files quickly" | Questions are tasks. Skills tell you HOW to explore. Files lack conversation context. |
| "This doesn't need a formal skill" / "I remember this skill" / "The skill is overkill" | If a Skill exists, use it. Skills evolve — read current version. Simple things become complex. |
| "I'll just do this one thing first" / "This feels productive" | Check BEFORE doing anything. Undisciplined action wastes time. |
| "1% chance applies, must load" | Only invoke when description matches; "not sure" still requires checking the catalog, but not loading every adjacent Skill. |
| "The sub-agent will figure it out from `<available_skills>`" | It won't. Description triggers are too weak for narrow skills. Explicit `load_skills=[...]` is the contract. |
| "I'll just dispatch without `load_skills`, simpler" | Sub-agent drifts toward generic output without the discipline anchor. Your dispatch is wasted. |

## Red Flags

- Invoking `using-meisijiya-skills` from a sub-agent (means the controller forgot to filter — see `<SUBAGENT-STOP>`).
- Reading skill SKILL.md files when the description alone would suffice (wastes tokens — read on demand after description match).
- Treating the Priority table as authoritative (it's a hint accelerator; the `description` field wins).
- Skipping the announce step — without "Using [skill] to [purpose]" the user can't see the routing.
- **Dispatching without `load_skills=[...]`** — sub-agent may miss the skill's discipline or skip its constraints.
- **Overloading `load_skills` (>3 skills per dispatch)** — context bloat kills quality; load only what's strictly needed.
- **Loading conflicting skills** — `meisijiya-frontend-taste` + `meisijiya-minimalist-ui` together is intentional pairing (minimalist-ui narrows frontend-taste); `meisijiya-frontend-taste` + `meisijiya-redesign-ui` is NOT (frontend-taste = greenfield; redesign-ui = existing UI audit-fix).
