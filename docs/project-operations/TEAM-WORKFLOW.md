# Kaizora Team and Specialist Workflow

## Purpose
Coordinate the founder, co-founder/manager specialist plugins and technical/security workflows without claiming a plugin performed work it has not performed.

## Functional responsibilities
- Product owner: final scope, priorities, acceptance and release decisions.
- Co-founder/product strategy function: challenge assumptions, align strategy, identify dependencies and propose trade-offs.
- Manager/delivery function: break approved scope into tasks, track status, dependencies, blockers and evidence.
- Engineering function: inspect repository, implement, test and document changes.
- Security function: threat model, run approved scans, review findings and verify remediation.
- Design function: brand consistency, UX critique, prototypes and visual QA.
- Operations function: preview feedback, release checklist, incidents and change log.

These are functional responsibilities, not claims that a specific named agent is connected or assigned. Confirm exact specialist plugin names, tools and access before using them. Do not grant broader permissions than necessary.

## Working loop
1. Read product plan, division process, acceptance criteria and current decision log.
2. Inspect repository state, migrations, tests and open issues.
3. Consult relevant specialist tools for focused reviews.
4. Separate facts, assumptions, recommendations and decisions.
5. Convert accepted work into tasks with dependencies and measurable criteria.
6. Implement in isolated branch.
7. Run lint, typecheck/build, relevant tests and preview checks.
8. Present preview with change summary and unresolved issues.
9. Capture feedback and update task status only after verification.
10. Run security gate at division end.

## Delegation boundaries
- No external messages, publishing, production deployment, payment, data deletion or access grants without explicit approval.
- Never share secrets or real learner data with agents.
- Do not assign tasks to people based on guessed identity.
- Tool output is evidence to evaluate, not authority to override product-owner decisions.
- Keep GitHub as versioned technical source of truth; use project management tools only after project and member access are confirmed.
