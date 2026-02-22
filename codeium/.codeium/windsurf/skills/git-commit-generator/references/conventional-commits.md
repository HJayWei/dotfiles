# Conventional Commits Specification

Reference: https://www.conventionalcommits.org/en/v1.0.0/

## Summary

The Conventional Commits specification is a lightweight convention on top of commit messages. It provides an easy set of rules for creating an explicit commit history, which makes it easier to write automated tools on top of.

## Commit Message Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

### Primary Types

- **feat**: A new feature for the user
- **fix**: A bug fix for the user

### Additional Types (from Angular convention)

- **build**: Changes that affect the build system or external dependencies
- **chore**: Changes to the build process or auxiliary tools
- **ci**: Changes to CI configuration files and scripts
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **revert**: Reverts a previous commit

## Scope

The scope provides additional contextual information and is contained within parentheses:

```
feat(parser): add ability to parse arrays
fix(api): resolve null pointer exception
```

Common scopes:
- Component/module names: `auth`, `api`, `database`, `ui`
- File/directory names: `config`, `middleware`, `utils`
- Feature areas: `login`, `checkout`, `search`

## Description

The description is a short summary of the code changes:

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No dot (.) at the end
- Maximum 72 characters

### Good Examples

```
add user authentication
fix memory leak in event handler
update API documentation
remove deprecated methods
```

### Bad Examples

```
Added user authentication (past tense)
Fix Memory Leak In Event Handler (capitalized)
update API documentation. (period at end)
changes (not descriptive enough)
```

## Body

The body should include the motivation for the change and contrast this with previous behavior:

- Use imperative, present tense
- Wrap at 72 characters
- Separate from subject with a blank line
- Can include multiple paragraphs
- Use bullet points with `-` or `*` for lists

### Example

```
refactor(database): optimize query performance

The previous implementation was making N+1 queries for each
user record. This change introduces eager loading to reduce
database calls from O(n) to O(1).

Performance improvements:
- User list page: 2000ms -> 150ms
- Dashboard load: 1500ms -> 200ms
- API response time: 800ms -> 100ms
```

## Footer

The footer should contain any information about Breaking Changes and is also the place to reference issue tracker IDs.

### Breaking Changes

Breaking changes must be indicated at the very beginning of the footer or body section with `BREAKING CHANGE:` followed by a description.

Alternatively, append `!` after the type/scope:

```
feat(api)!: change authentication endpoint

BREAKING CHANGE: The /auth endpoint now requires OAuth2 tokens
instead of API keys. All clients must update their authentication
method before the next release.
```

### Issue References

Reference issues using keywords:

```
Fixes #123
Closes #456
Refs #789
Resolves #234
```

Multiple references:

```
Fixes #123, #456
Closes #789
```

### Co-authors

```
Co-authored-by: John Doe <john@example.com>
Co-authored-by: Jane Smith <jane@example.com>
```

## Complete Examples

### Simple Feature

```
feat: add email notifications
```

### Feature with Scope

```
feat(auth): implement two-factor authentication
```

### Bug Fix with Body

```
fix(api): prevent race condition in user creation

When multiple requests tried to create the same user simultaneously,
the application would crash due to a unique constraint violation.
Now uses database-level locking to ensure atomic operations.

Fixes #234
```

### Breaking Change

```
refactor(api)!: restructure response format

BREAKING CHANGE: API responses now return data in a `data` field
instead of at the root level. Update all API clients:

Before: { "id": 1, "name": "John" }
After: { "data": { "id": 1, "name": "John" } }

Migration guide: https://docs.example.com/migration/v2
```

### Revert

```
revert: feat(auth): implement two-factor authentication

This reverts commit 667ecc1654a317a13331b17617d973392f415f02.

Reverting due to production issues with SMS provider integration.
Will re-implement after resolving provider API stability.
```

### Multiple Changes

```
chore: update project dependencies

- Upgrade React from 17.0.2 to 18.2.0
- Update TypeScript to 5.0
- Bump ESLint and related plugins
- Remove unused dependencies

All tests passing. No breaking changes in dependencies.
```

## Best Practices

### DO

- ✅ Keep subject line under 72 characters
- ✅ Use imperative mood in subject line
- ✅ Separate subject from body with blank line
- ✅ Wrap body at 72 characters
- ✅ Use body to explain what and why vs. how
- ✅ Reference issues and pull requests
- ✅ Mark breaking changes clearly
- ✅ Make atomic commits (one logical change)

### DON'T

- ❌ Use past tense ("added" instead of "add")
- ❌ Capitalize first letter of description
- ❌ End description with period
- ❌ Be vague ("fix bug", "update code")
- ❌ Mix multiple unrelated changes
- ❌ Include implementation details in subject
- ❌ Forget to mark breaking changes
- ❌ Use generic messages ("WIP", "fix", "update")

## Type Selection Guide

| Scenario | Type | Example |
|----------|------|---------|
| New user-facing feature | `feat` | `feat: add dark mode` |
| User-facing bug fix | `fix` | `fix: resolve login redirect` |
| Internal refactoring | `refactor` | `refactor: simplify parser logic` |
| Performance improvement | `perf` | `perf: optimize image loading` |
| Documentation update | `docs` | `docs: add API examples` |
| Code formatting | `style` | `style: apply prettier formatting` |
| Test addition/update | `test` | `test: add user service tests` |
| Build/dependency change | `build` | `build: upgrade webpack to v5` |
| CI/CD configuration | `ci` | `ci: add GitHub Actions workflow` |
| Maintenance task | `chore` | `chore: update .gitignore` |

## Scope Examples by Project Type

### Web Application

```
feat(auth): add OAuth2 support
fix(ui): resolve button alignment
refactor(api): simplify error handling
perf(database): optimize user queries
```

### Library/Package

```
feat(parser): support nested objects
fix(validator): handle edge cases
docs(readme): add usage examples
test(utils): increase coverage
```

### Mobile App

```
feat(camera): add photo filters
fix(navigation): resolve back button
style(theme): update color palette
perf(rendering): reduce frame drops
```

## Automation Benefits

Following Conventional Commits enables:

1. **Automatic versioning**: Determine semantic version bumps
2. **Changelog generation**: Auto-generate CHANGELOG.md
3. **Release notes**: Create release notes automatically
4. **CI/CD triggers**: Run specific pipelines based on type
5. **Code review**: Quickly understand change impact

## Tools

- **commitlint**: Lint commit messages
- **semantic-release**: Automate versioning and releases
- **conventional-changelog**: Generate changelogs
- **commitizen**: Interactive commit message creator
