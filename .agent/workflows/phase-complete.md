---
description: Push and merge current branch into main after completing a phase
---

# Phase Complete — Push & Merge

Run this workflow after completing a phase in any tasks.md file.

## Steps

// turbo-all

1. Stage all changes on the current branch:
   ```
   git add -A
   ```

2. Commit with a descriptive message including the phase and feature name:
   ```
   git commit -m "<feature-name> Phase <N>: <phase-title> complete"
   ```
   Example: `git commit -m "001-workspace-foundation Phase 3: Auth/Register complete"`

3. Push the current branch to origin:
   ```
   git push origin HEAD
   ```

4. Switch to main:
   ```
   git checkout main
   ```

5. Pull latest main from origin:
   ```
   git pull origin main --no-edit
   ```

6. Merge the feature branch into main:
   ```
   git merge <branch-name> --no-edit
   ```

7. Push main to origin:
   ```
   git push origin main
   ```

8. Switch back to the feature branch to continue work:
   ```
   git checkout <branch-name>
   ```
