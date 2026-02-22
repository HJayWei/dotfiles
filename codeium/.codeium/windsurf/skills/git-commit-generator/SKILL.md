---
name: Git Commit Message Generator
description: Generate Conventional Commits compliant commit messages based on git staged changes and conversation context. Use when the user asks to create a commit message, generate a commit, or review staged changes for committing. Analyzes git diff --staged output and conversation history to produce structured commit messages in English following the Conventional Commits specification (https://www.conventionalcommits.org/).
---

# Git Commit Message Generator

Generate commit messages following Conventional Commits specification based on staged changes and conversation context.

## When to Use

- User asks to generate a commit message
- User asks to create/write a commit
- User requests review of staged changes for committing
- User mentions "commit message" or "git commit"

## Workflow

### 1. Analyze Staged Changes

First, check git status and staged diff:

```bash
git status
git diff --staged
```

### 2. Review Conversation Context

If there's conversation history in this session, review it to understand:
- What feature/fix was being worked on
- Why changes were made
- Any important context or decisions

### 3. Generate Commit Message

Follow this structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**All content must be in English.**

#### Type Selection

Choose the most appropriate type:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semi-colons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or external dependencies
- `ci`: CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

#### Subject Line (<type>[optional scope]: <description>)

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
```

#### Body (optional)

Include body when:
- Changes need explanation beyond the subject
- Multiple related changes were made
- Context about "why" is important

Guidelines:
- Wrap at 72 characters
- Explain what and why, not how
- Use bullet points for multiple items
- Separate from subject with blank line

#### Footer (optional)

Use for:
- Breaking changes: `BREAKING CHANGE: <description>`
- Issue references: `Closes #123`, `Fixes #456`, `Refs #789`
- Co-authors: `Co-authored-by: Name <email>`

### 4. Present Options

Provide 2-3 commit message options:
1. **Concise**: Subject line only
2. **Detailed**: Subject + body
3. **Comprehensive**: Subject + body + footer (if applicable)

## Examples

### Simple Feature Addition

```
feat: add dark mode toggle to settings
```

### Bug Fix with Context

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

## Reference

For detailed Conventional Commits specification, see [references/conventional-commits.md](references/conventional-commits.md).
