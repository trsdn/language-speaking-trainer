---
description: Scaffold a new reusable prompt file (.prompt.md) invoked via / in Copilot Chat
name: New Prompt File
agent: Copilot Customization Builder
tools: ['search', 'edit/editFiles']
---

# New Prompt File

Create a new reusable prompt file in `.github/prompts/`.

## Inputs

- Prompt file slug (filename, without `.prompt.md`): `${input:promptSlug}`
- Prompt display name: `${input:promptName}`
- One-line description: `${input:promptDescription}`
- Agent to run this prompt with (e.g. `agent`, `Copilot Customization Builder`): `${input:promptAgent}`
- Tools list (comma-separated): `${input:promptTools}`

## Requirements

1. Inspect existing prompt files in `.github/prompts/` and match conventions (YAML keys, quoting style).
2. Create the file: `.github/prompts/${input:promptSlug}.prompt.md`
3. Add YAML frontmatter with:
   - `description`, `name`, `agent`, `tools`
4. In the prompt body:
   - Provide a short title
   - Provide clear steps/instructions
   - Use context variables when helpful (examples): `${workspaceFolder}`, `${file}`, `${selectedText}`
   - Use `${input:...}` when you need more user input

When done, explain how to invoke it with `/${input:promptSlug}`.

## Reference docs

- Prompt files (VS Code): https://code.visualstudio.com/docs/copilot/customization/prompt-files
- Customize chat overview (VS Code): https://code.visualstudio.com/docs/copilot/customization/overview
- Copilot Chat context (VS Code): https://code.visualstudio.com/docs/copilot/chat/copilot-chat-context
- Chat sessions (VS Code): https://code.visualstudio.com/docs/copilot/chat/chat-sessions
- Prompt engineering guide: https://code.visualstudio.com/docs/copilot/guides/prompt-engineering-guide
- Context engineering guide: https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide

