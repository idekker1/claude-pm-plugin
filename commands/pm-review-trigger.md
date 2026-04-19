Trigger a targeted code review on recently changed files using the code-reviewer skill.

Run this after a significant merge, or when the project-manager recommends a review.

The skill will:
1. Identify changed files: `git diff main...HEAD --name-only`
2. Filter to code files (exclude migrations, lock files, generated files)
3. Assemble context: branch name, feature description from commits, affected area
4. Pass file list + context to the code-reviewer skill
5. Output: issue counts by severity + verdict: SAFE TO MERGE | REVIEW SUGGESTED | DO NOT MERGE

$ARGUMENTS may be:
- Empty: review all changed files on current branch
- A path: `src/api/` — review only files under that path
