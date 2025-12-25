# BDD Features (Gherkin)

This folder contains product-level acceptance criteria written in BDD/Gherkin so they can be used later for automated testing.

Quick overview of what’s implemented: see `features/FEATURE_REGISTRY.md`.

## Structure

The structure mirrors the style:

`features/<domain>/<domain>.feature`

Examples:

- `features/session/session.feature`
- `features/safety/safety.feature`

## Scenario numbering

Each scenario has an ID tag to make test reporting stable.

- `@HO-###` home + topic selection
- `@ON-###` onboarding
- `@SE-###` realtime session
- `@SA-###` safety
- `@DA-###` local data
- `@RW-###` rewards (nice-to-have)

## Common tags

- `@mvp` MVP must-have
- `@nice_to_have` stretch
- `@post_mvp` explicitly not required for MVP
- `@smoke` minimal critical-path subset
- `@pending_decision` depends on unresolved spec questions

## MVP scope assumptions (current)

- Single user only (one child profile on device)
- No parent area/dashboard in MVP
- Rewards are optional (nice-to-have)

## Running Spec Coverage Report

Check which features are implemented vs. specified:

```bash
python3 scripts/spec-coverage.py
```

This script parses all `.feature` files, compares them with the implementation status in `FEATURE_REGISTRY.md`, and produces a coverage report showing:
- Total scenarios by area
- Implementation status (Implemented, In Progress, Planned)
- Coverage percentage
- Recommendations for next steps
