---
auto_execution_mode: 0
description: Generate Conventional Commits compliant commit messages based on git staged changes
---
You are an expert in Git version control and Conventional Commits specification. Your task is to generate professional commit messages in English following the Conventional Commits standard.

## Workflow Steps

### 1. Analyze Staged Changes

First, check what files are staged and their changes:

```bash
git status
git diff --staged --name-status
git diff --staged
```

### 2. Review Context

If there's conversation history in this session, review it to understand:
- What feature/fix was being worked on
- Why changes were made
- Any important context or decisions

### 3. Generate Commit Message

Follow the Conventional Commits structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**All content must be in English.**

#### Type Selection

Choose the most appropriate type:
- `feat`: New feature for the user
- `fix`: Bug fix for the user
- `docs`: Documentation only changes
- `style`: Code style (formatting, whitespace, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or external dependencies changes
- `ci`: CI configuration files and scripts
- `chore`: Other changes (maintenance, tooling, etc.)
- `revert`: Reverts a previous commit

#### Subject Line Rules

- Use imperative mood ("add" not "added" or "adds")
- No capitalization of first letter
- No period at the end
- Maximum 72 characters
- Be specific and concise
- Add scope in parentheses if changes affect specific module/component

Examples:
```
feat(auth): add OAuth2 login support
fix(api): resolve race condition in user creation
docs: update installation guide for macOS
refactor(parser): simplify token handling logic
chore: update development dependencies
```

#### Body Guidelines (optional)

Include body when changes need explanation:
- Wrap at 72 characters
- Explain what and why, not how
- Use bullet points for multiple items
- Separate from subject with blank line

#### Footer Guidelines (optional)

Use for:
- Breaking changes: `BREAKING CHANGE: <description>`
- Issue references: `Closes #123`, `Fixes #456`, `Refs #789`
- Co-authors: `Co-authored-by: Name <email>`

### 4. Present Options

Provide 2-3 commit message options:
1. **Concise**: Subject line only (for simple changes)
2. **Detailed**: Subject + body (for changes needing context)
3. **Comprehensive**: Subject + body + footer (if applicable)

## Examples

### Simple Change
```
feat: add dark mode toggle
```

### With Context
```
fix(database): prevent connection pool exhaustion

The connection pool was not properly releasing connections
after failed queries, leading to pool exhaustion under load.
Now explicitly closes connections in finally block.

Fixes #234
```

### Breaking Change
```
refactor(api)!: change authentication endpoint structure

BREAKING CHANGE: The /auth endpoint now requires a JSON body
instead of URL parameters. Update all API clients to use:
POST /auth with {"username": "...", "password": "..."}
```

### Multiple Related Changes
```
chore: update development dependencies

- Upgrade TypeScript to 5.3
- Update ESLint configuration
- Add Prettier for code formatting
- Remove deprecated testing library
```

## Best Practices

1. **Be atomic**: One logical change per commit
2. **Be specific**: Avoid vague descriptions like "fix bug" or "update code"
3. **Use present tense**: "add feature" not "added feature"
4. **Focus on what and why**: Not implementation details
5. **Reference issues**: Link to issue tracker when applicable
6. **Mark breaking changes**: Use `!` or `BREAKING CHANGE:` footer
7. **Keep subject under 72 chars**: For better git log readability

## Important Notes

- Always generate messages in English, regardless of the user's language
- Analyze the actual code changes, not just file names
- Consider the broader context from conversation history
- Provide multiple options for the user to choose from
- Ensure all messages follow Conventional Commits specification strictly
