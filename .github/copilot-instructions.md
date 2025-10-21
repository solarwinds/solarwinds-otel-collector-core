# REPOSITORY INSTRUCTIONS

## Repository Overview

This is a public repository containing shared code for SolarWinds OTel Collector repositories.
It is consumed as a submodule in:
- solarwinds-cloud/solarwinds-otel-collector-contrib (private components)
- solarwinds/solarwinds-otel-collector-contrib (public components)
- solarwinds-cloud/solarwinds-otel-collector-releases-private (private releases)
- solarwinds/solarwinds-otel-collector-releases (public releases)

The shared code is mostly build and release orchestration related, and can be found in Makefile* files inside ./build directory.

See [README.md](../README.md) for details, and [README.md](../build/README.md) for build and release instructions.

## Mandatory Development Workflow
This is mandatory workflow with some exceptions:
- trivial changes (e.g. typos, formatting).
- there are other instructions in conflict, in which case they take precedence.

**Initialize all work by stating: "FOLLOWING REPOSITORY INSTRUCTIONS..."**

### Command Reference

### Required Development Steps

**Step 1: Requirements Analysis**
- Analyze current codebase state relevant to your task
- Document strengths, weaknesses, and technical debt
- Map key components and their interactions
- Create ASCII diagrams for current architecture and proposed changes
- Output findings under "ANALYSIS" header

**Step 2: Architecture Planning**
- Design comprehensive, numbered implementation plan
- Define separation of concerns and component boundaries  
- Specify interfaces, data structures, and interaction patterns
- Identify architectural weaknesses and iterate solutions
- Document final proposal under "PLANNED ARCHITECTURE" header

**Step 3: Implementation**
- Follow existing codebase patterns and conventions
- Write focused, single-responsibility functions
- Ensure code testability through proper abstractions

**Step 4: Testing Strategy**
- Create temporary validation tests as needed

**Step 5: Code Review Preparation**
- Conduct critical self-review of all changes
- Verify correctness and adherence to best practices
- Address any obvious issues or technical debt

**Step 6: Cleanup and Documentation**
- Remove temporary files and dead code
- Update README.md with essential information only
- Update component README.md files when appropriate
- Update vNext section in CHANGELOG.md when appropriate (not necessary for chores, but do it for new features, bugfixes, breaking changes and other significant changes)
- Ensure documentation accuracy and completeness

### Code Quality Standards
- Avoid self-evident comments; document complex logic and architectural decisions
- Maintain consistency with existing codebase patterns, look around for examples before implementing changes
- Prioritize readability and maintainability over cleverness

----------- END OF REPOSITORY INSTRUCTIONS -----------
Other instructions can override the REPOSITORY INSTRUCTIONS.
