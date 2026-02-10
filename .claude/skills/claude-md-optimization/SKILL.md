---
name: claude-md-optimization
description: Use this skill when CLAUDE.md files exceed 150-200 lines or need optimization. Helps maintain concise project documentation while preserving essential context for AI agents. Apply when creating new CLAUDE.md files, optimizing verbose documentation, or restructuring project guides.
metadata:
  version: "1.0.0"
  author: yyh-gl
---

# CLAUDE.md Optimization Skill

Optimize CLAUDE.md files to 150 lines or less while preserving essential project context for AI agents.

## When to Use

- CLAUDE.mdが200行を超えている
- プロジェクトドキュメントが冗長で読みにくい
- 新規プロジェクトでCLAUDE.mdを作成する
- プロジェクト構造が変わり、ドキュメントを更新する

## Optimization Strategy

### Priority 1: Must Include (High Priority)

1. **Project Overview** (2-3 lines)
   - Tech stack in one line: `React 19 + Next.js 14 + TypeScript | pnpm | Vitest`
   - Brief project description

2. **Directory Structure** (10-20 lines)
   - Only 2-3 levels deep
   - Mark critical files with ★
   - Use inline comments instead of separate explanations

3. **Authentication/Authorization Architecture** (if security-critical)
   - Flow diagram (5-10 lines)
   - Token structure summary
   - Role definitions

4. **Development Commands** (5-10 lines)
   ```bash
   pnpm dev          # Dev server
   pnpm build        # Build
   pnpm typecheck    # Type check
   ```

5. **Development Workflow** (10-15 lines)
   - New feature flow (3-5 steps)
   - Bug fix flow (3-5 steps)

6. **Critical Design Patterns** (10-15 lines)
   - Project-specific decisions
   - Common pitfalls
   - Important constraints

7. **File Pointers** (5-10 lines)
   - Links to detailed docs
   - Important file paths with line counts

### Priority 2: Remove or Simplify

❌ **Remove**:
- Detailed file trees with every file
- Long code snippets (>10 lines)
- Redundant explanations
- "This project uses..." preambles
- Obvious information ("package.json defines dependencies")

✂️ **Simplify**:
- Tables → Bullet lists
- Multiple sections → Combined sections
- Detailed procedures → "See docs/xxx.md"

## Optimization Techniques

### 1. Convert Tables to Lists
Tables → Bullet lists (9 lines → 2 lines)

### 2. Inline Multiple Items
Separate lines → Single line with pipes (3 lines → 1 line)

### 3. Replace Details with Links
Long procedures → File references (15+ lines → 1 line)

### 4. Merge Related Sections
Multiple sections → Combined section with subheadings

## Quality Checklist

When optimizing CLAUDE.md, ensure:

- [ ] Total lines ≤ 150
- [ ] Project overview is 2-3 lines and clear
- [ ] Directory structure is scannable at a glance
- [ ] All dev commands are listed
- [ ] Feature addition flow is 3-5 steps
- [ ] Critical design patterns are documented
- [ ] Links to detailed docs are provided
- [ ] Project-specific gotchas are noted
- [ ] No duplicate information
- [ ] Code snippets are minimal

## Recommended Sections

Include these sections for Claude Code behavior guidance:

```markdown
## Working Style

**Planning Mode**: Only for 5+ file changes or architectural decisions. Skip for single-file changes.

**Implementation**: Brief explanation (2-3 sentences) then start coding immediately.

## Debugging

**Bug Fixes**: Try most likely fix first, verify, then proceed. Re-analyze root cause instead of adding debug logs.

## Documentation

**Updates**: Only modify requested sections. Don't refactor unless explicitly asked.
```

## Examples

### ✅ Good (Concise)

```markdown
# CLAUDE.md - Project Guide

## Overview
Next.js + Supabase full-stack app.

**Stack**: Next.js 14, TypeScript, Supabase, Tailwind CSS

## Key Directories
- `app/` - Frontend (App Router)
- `supabase/functions/` - Edge Functions
- `docs/` - Detailed docs (★ read first)

## Commands
```bash
npm run dev    # Dev server
npm run build  # Build
```

## New Feature Flow
1. Create Edge Function → `supabase/functions/<name>/`
2. Add API function → `lib/api.ts`
3. Implement UI → `app/components/`

**Details**: `/docs/development.md`
```

### ❌ Bad (Verbose)

```markdown
# CLAUDE.md - Project Documentation

This document provides a comprehensive guide...

## Project Overview
This project is a modern full-stack web application...
Technology Stack:
- Frontend: Next.js 14
  - Uses React 18
  - Adopts App Router
- Backend: Supabase
  - PostgreSQL database
  - Edge Functions (Deno runtime)
[100+ more lines...]
```

## Execution Workflow

When optimizing CLAUDE.md:

1. **Read current CLAUDE.md**
2. **Analyze line count and content**
3. **Identify Priority 1 sections** (must keep)
4. **Remove/simplify Priority 2 content**
5. **Apply optimization techniques**
6. **Add Working Style/Debugging/Documentation sections if missing**
7. **Verify final line count ≤ 150**
8. **Write optimized version**

**Context-Specific Adjustments:**
- Security-critical projects: Retain auth/authz details
- Migration-heavy projects: Keep migration strategies
- Complex architectures: Prioritize design patterns section
