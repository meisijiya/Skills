# Verification Backends (research reference)

> **Guidance, not an instruction or permission to install.** This document is a routing aid for the `contract-strengthening` skill. It does **not** authorize, recommend, or imply installation of any tool. Loading the parent skill must never install or run a verifier. Every backend below has tradeoffs that depend on the actual environment of the project under review — apply only after measuring CPU, memory, disk, permissions, expected duration, concurrency, test/mutation counts, state-space bounds, timeout, and cleanup (parent skill step 5).

## How to read this table

Two columns matter for routing and are independent:
- **Install footprint** — none / dev-dependency / project-local / environment / system.
- **Execution cost** — what running it actually costs in CPU, memory, time, mutation/state-space budget. A small install can have large execution cost (model checking); a large install can have tiny execution cost (a CLI invoked once).

## Lightweight families (dev-dependency, project-local)

### Property-based testing
- **Need:** state/timing/range invariants across many inputs.
- **Backends:** Hypothesis (Python), fast-check (JS/TS), jqwik (Java), QuickCheck (Haskell), proptest (Rust).
- **Primary docs:** https://hypothesis.readthedocs.io/ · https://fast-check.dev/ · https://jqwik.net/ · https://hackage.haskell.org/package/QuickCheck · https://github.com/AltSysrq/proptest
- **Footprint:** project-language dev-dependency; no system install.
- **Execution cost:** scales with `max_examples` × shrinking; set a per-example timeout and total budget.

### Schema / contract testing
- **Need:** API boundary / message / request-response contracts.
- **Backends:** Pact (consumer-driven), Specmatic (OpenAPI / async specs as tests), JSON Schema validators (ajv, jsonschema).
- **Primary docs:** https://docs.pact.io/ · https://github.com/specmatic/specmatic · https://ajv.js.org/ · https://python-jsonschema.readthedocs.io/
- **Footprint:** dev-dependency + (Pact broker | Specmatic spec file).
- **Execution cost:** bounded by contract count; provider verification can fan out.

## Heavier families (resource-bounded execution only)

### Mutation testing
- **Need:** discriminate test-suite strength beyond coverage.
- **Backends:** mutmut (Python), Stryker (JS/TS), PIT (Java), cargo-mutants (Rust), go-mutesting (Go).
- **Primary docs:** https://github.com/boxed/mutmut · https://stryker-mutator.io/ · https://pitest.org/ · https://github.com/sourcefrog/cargo-mutants · https://github.com/avito-tech/go-mutesting
- **Footprint:** dev-dependency; runs against existing test suite.
- **Execution cost:** mutation count × test-suite runtime; budget before run; can dominate CI minutes.

### Model checking / state-space exploration
- **Need:** full state-machine coverage for small bounded models.
- **Backends:** TLA+ (PlusCal/TLC), Alloy, SPIN.
- **Primary docs:** https://github.com/tlaplus/tlaplus · https://alloytools.org/ · https://spinroot.com/spin/
- **Footprint:** standalone tools (Java for TLA+/Alloy, C for SPIN); project isolation preferred.
- **Execution cost:** exponential in state space; bounded only by the model — measure reachable-state count on a sample first.

### SMT solvers / deductive verification
- **Need:** discharge proof obligations, bounded verification of invariants.
- **Backends:** Z3, CVC5, Dafny (verification-aware language + Z3 backend).
- **Primary docs:** https://github.com/Z3Prover/z3 · https://cvc5.github.io/ · https://github.com/dafny-lang/dafny
- **Footprint:** standalone binaries or language toolchain; project isolation preferred.
- **Execution cost:** depends on quantifier depth and uninterpreted functions; can diverge — set a timeout; `(unknown)` is **no evidence**, not evidence of correctness.

## Choosing order

Apply the parent skill's step 5 decision order before picking a backend from this table. The lightest backend that addresses the gap is preferred. If its measured execution cost exceeds the project's available resources, escalate to a heavier family **only with an explicit resource reassessment** (re-running the parent's resource check). **Never** install a backend solely because this skill was loaded.

## Traps

- Property tests with very high `max_examples` and aggressive shrinking dominate CI minutes — set a total budget.
- Mutation testing on a slow suite compounds: estimate mutation count × average test time before enabling.
- Model checkers hide state-space explosion behind "BFS" / "DFS" — measure reachable-state count on a sample first.
- SMT solvers may emit `(unknown)` on non-linear arithmetic; treat that as **no evidence**.
- A bare property test that never finds a counterexample is **not** a discriminator; pair with mutation or a hand-written oracle for the gap.
- This reference cites **no benchmark numbers**. Check the primary docs for the tool's current performance characteristics before committing to a CI run.