# CLAUDE.md

## Purpose

This document defines how Claude should behave when working in this repository.  
Claude must follow these rules unless explicitly instructed otherwise.

The goal is to ensure that contributions remain:

- predictable
- safe
- easy to review
- consistent with the project's structure

---

# Git Guidelines

## Commit Messages

When generating git commit messages:

- Do **not** add credits or references to Claude, AI, or assistants.
- Only summarize the changes that were made.
- Keep the message concise and informative.

Use a structured commit format.

Example:

```
feat: add visitor load aggregation for weekly report

- Added aggregation function for daily gym data
- Added weekly summary endpoint
- Updated API route structure
```

Claude **must not run the `git commit` command** unless given permission from the user.  
Only output the commit message in the chat.

---

## Branching

If starting a **new major implementation**, such as:

- a new module
- a large feature
- a structural refactor
- a new service or subsystem

Claude should **ask whether a new git branch should be created before proceeding**.

Example prompt:

> "This looks like a major feature. Should we create a new branch for this work?"

---

## Git Safety Rules

Claude must **never perform destructive git operations** unless explicitly instructed.

Forbidden commands include:

- `git reset --hard`
- `git push --force`
- `git rebase` on shared branches
- `git branch -D`
- deleting remote branches

Claude should **prefer safe workflows** that preserve history.

---

# Code Generation Guidelines

## General Principles

Generated code must aim to be:

- clear
- minimal
- maintainable
- consistent with the existing codebase

Code should favor **modularity and separation of concerns**.

Claude should avoid creating **large files containing many unrelated functions**.

If a file becomes difficult to navigate or contains multiple responsibilities,  
Claude should split it into **smaller, modular files** with clear purposes.

As a general guideline, Claude should consider splitting files when:

- a file exceeds roughly **300–400 lines**
- the file contains **multiple distinct responsibilities**
- functions logically belong to **separate modules**

---

Claude should:

- follow existing patterns in the repository
- avoid introducing unnecessary dependencies
- prefer readable solutions over clever ones
- avoid large rewrites unless requested

Claude should avoid generating **placeholder implementations**, including:

- TODO-only functions
- empty stubs
- placeholder return values

If a full implementation cannot be completed, Claude should clearly explain the limitation instead of leaving incomplete code.

---

## Incremental Development

Claude should prefer **small, incremental improvements** instead of large sweeping changes.

When a task is complex:

1. Propose a short implementation plan
2. Confirm with the user if needed
3. Implement step-by-step

---

## Editing Existing Files

When modifying files:

- change **only what is necessary**
- preserve formatting and style
- avoid unrelated refactoring
- do not rename files unless requested

Claude should avoid silently changing **public APIs**.

If a change would modify:

- function signatures
- return types
- API endpoints
- database schemas

Claude should **explain the change and confirm with the user first**.

---

# Architecture Awareness

Claude should always attempt to:

- understand the existing project structure
- follow existing conventions
- avoid introducing new architectural patterns unless justified

If a structural change seems necessary, Claude should **explain why before implementing it**.

---

# Dependency Rules

Claude should **not introduce new dependencies** unless necessary.

Before suggesting a new dependency:

1. Check if the functionality already exists in the project
2. Prefer standard library solutions
3. Explain why the dependency is justified

---

# Security Guidelines

Claude should avoid introducing security risks.

Examples include:

- exposing secrets
- unsafe shell commands
- insecure API usage
- writing credentials to files
- disabling authentication mechanisms

If a task could impact security, Claude should **flag the risk first**.

---

# Testing

When adding significant logic, Claude should:

- suggest appropriate tests
- ensure edge cases are considered
- avoid breaking existing tests

Claude should not remove tests unless explicitly instructed.

---

# Plugins - Playwright

- If Claude has opened the browser to verify and/or test, do not close the browser unless told so.
- When taking screenshots, Claude should:
- Create a directory called "screenshots" if it does not exist.
- Place all screenshots taken, in this directory.

# User Verification

Before requesting user verification, Claude should:

- check for obvious syntax errors
- ensure code compiles or runs where applicable
- verify imports and dependencies are correct

When implementation changes are complete and ready for user verification:

- If the changes affect a **web UI**, ask the user whether Claude should open the browser to preview the result.
- If a browser instance was previously opened by Claude, ask whether the user would like that session to be closed before opening a new one.

Claude should **not automatically open or close browser sessions** without asking the user first.

---

# Documentation & Changelog

After the user has **verified that a change or implementation works successfully**, Claude should ask whether documentation should be updated.

Claude should ask:

- whether the **README.md** should be updated to reflect the new feature or change
- whether any usage examples or instructions should be added or modified

Claude should also maintain a **standalone changelog file**.

Rules for the changelog:

- The changelog must exist as a file named **CHANGELOG.md**
- Claude should **create the file if it does not exist**
- Claude should **add a new entry for every change or feature implemented**

Changelog entries should include:

- the date
- the type of change (feature, fix, improvement, refactor, etc.)
- a short description of what was implemented or modified

Example entry:

```
## 2026-03-14

### Added
- Visitor load aggregation for weekly reports

### Improved
- Modularized API logic into smaller service files
```

---

# Planning Mode

For complex tasks, Claude should:

1. briefly analyze the problem
2. propose a short plan
3. confirm with the user
4. implement the solution

When presenting a plan, Claude should:

- start the plan with a **clear ordered list summarizing the steps**
- keep the steps concise
- use the ordered list as a **quick overview of the implementation strategy**

Example structure:

1. Create new API endpoint
2. Implement service logic
3. Add database query
4. Add tests
5. Update documentation

After the ordered list overview, Claude may provide additional explanation if needed.

---

# Communication Style

Claude should:

- keep explanations concise
- clearly explain trade-offs when relevant
- ask clarifying questions when requirements are ambiguous

Claude should **not make assumptions about missing requirements** without asking.

---

# Summary

Claude should behave like a **careful senior developer contributing to a shared repository**:

- safe git usage
- incremental changes
- minimal dependencies
- modular code structure
- consistent architecture
- clear communication
- updated documentation
- maintained changelog
