---
name: feedback-learning-logic
description: User wants to learn the LOGIC of code (not vibecode); design/styling can be generated without explanation
metadata:
  type: feedback
---

User wants to **understand the logic** of what we build together, not just accept generated code ("ohne zu vibecoden"). Design/styling (shadows, colors, layout polish) he explicitly does NOT care to understand — there it's fine to just generate.

**Why:** He's learning to program (Flutter/Dart project). Passively accepting AI output would defeat the purpose for the logic parts, but design details aren't worth his mental energy.

**How to apply:**
- For logic (state management, async flow, DB queries, data modeling, control flow): explain the *why* before/while writing, keep changes small enough to follow, prefer guiding him to write key parts himself or pausing to check understanding. Don't dump large logic rewrites without walking through them. See [[feedback-pace]] for the one-block-at-a-time rule.
- For UI/design: just produce it, no need to teach shadows/spacing/etc.
- When a task mixes both, separate them — teach the logic, hand over the design.