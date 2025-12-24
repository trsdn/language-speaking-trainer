---
description: Scaffold a new custom agent (.agent.md) for VS Code and/or GitHub Copilot
name: New Custom Agent
agent: Copilot Customization Builder
tools: ['search', 'edit/editFiles']
---

# New Custom Agent

Create a new custom agent profile in this repository.

## Inputs

- Agent file slug (filename, without `.agent.md`): `${input:agentSlug}`
- Agent display name: `${input:agentName}`
- One-line description: `${input:agentDescription}`
- Target environment (`vscode`, `github-copilot`, or `both`): `${input:agentTarget}`
- Tools list (comma-separated, or leave blank to propose a minimal set): `${input:agentTools}`

## Requirements

1. Inspect existing agents in `.github/agents/` and match conventions (YAML keys, quoting style).
2. Create the agent file at: `.github/agents/${input:agentSlug}.agent.md`
3. In YAML frontmatter:
   - Set `description` and `name`.
   - Set `tools` explicitly (prefer minimal).
   - If `${input:agentTarget}` is `vscode` or `github-copilot`, set `target` accordingly. If `both`, omit `target`.
4. In the Markdown body, include:
   - What the agent does
   - A default workflow (how it operates)
   - Guardrails (safety + scope boundaries)
5. Don’t add repo-specific behavior unless requested.

When done, list the created file path and how to select the agent in the VS Code agent picker.

## Reference docs

- Custom agents (VS Code): https://code.visualstudio.com/docs/copilot/customization/custom-agents
- Agents overview (local/background/cloud): https://code.visualstudio.com/docs/copilot/agents/overview
- Background agents: https://code.visualstudio.com/docs/copilot/agents/background-agents
- Cloud agents: https://code.visualstudio.com/docs/copilot/agents/cloud-agents
- Tools & approvals (VS Code): https://code.visualstudio.com/docs/copilot/chat/chat-tools
- Security considerations (VS Code): https://code.visualstudio.com/docs/copilot/security

GitHub Copilot (cloud) custom agents:
- Creating custom agents (GitHub docs): https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
