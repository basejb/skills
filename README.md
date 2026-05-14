# basejb/skills

Personal Claude Code skills, synced between work and home machines via plugin marketplace.

## Install

```
/plugin marketplace add basejb/skills
/plugin install basejb@skills
```

After install, skills are invoked as `/basejb:<skill-name>`.

## Update

```
/plugin marketplace update skills
/plugin update basejb@skills
```

## Skills

| Name | Invocation | Description |
|------|------------|-------------|
| hello | `/basejb:hello` | Sanity check that the plugin loaded |
| producthunt | `/basejb:producthunt` | Product Hunt GraphQL API wrapper (posts, topics, users, collections). Originally by [ReScienceLab](https://github.com/ReScienceLab/opc-skills), MIT. |

## Local development

Load this repo directly without installing through the marketplace:

```
claude --plugin-dir ~/Repositories/skills
```

After editing a skill, run `/reload-plugins` to pick up changes.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`description:` required).
2. Bump `version` in `.claude-plugin/plugin.json`.
3. `git add -A && git commit -m "add <name>" && git push`.
4. On other machines: `/plugin marketplace update skills && /plugin update basejb@skills`.
