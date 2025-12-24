---
description: Scaffold a new scoped custom instructions file (*.instructions.md)
name: New Instructions File
agent: Copilot Customization Builder
tools: ['search', 'edit/editFiles']
---
# New Instructions File

Create a new `*.instructions.md` file with an `applyTo` glob.

## Inputs

- Instructions file slug (filename, without `.instructions.md`): `${input:instructionsSlug}`
- applyTo glob (example: `**/*.py`): `${input:applyToGlob}`
- Short purpose line (what it enforces): `${input:instructionsPurpose}`

## Requirements

1. Create the file at the repo root (or an existing instructions folder if the repo uses one): `${input:instructionsSlug}.instructions.md`
2. Use YAML frontmatter with:

```yaml
---
applyTo: '${input:applyToGlob}'
---
```

3. Write concise, actionable rules aligned to the purpose: `${input:instructionsPurpose}`
4. Avoid duplicating rules already present in `.github/copilot-instructions.md` unless you are specializing for a file pattern.

When done, mention how this file interacts with `.github/copilot-instructions.md`.

## Reference docs

- Custom instructions (VS Code): https://code.visualstudio.com/docs/copilot/customization/custom-instructions
- Customize chat overview (VS Code): https://code.visualstudio.com/docs/copilot/customization/overview
- Security considerations (VS Code): https://code.visualstudio.com/docs/copilot/security
