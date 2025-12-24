# BDD Features (Gherkin)

This folder contains product-level acceptance criteria written in BDD/Gherkin so they can be used later for automated testing.

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
