Run a full codebase audit using the code-reviewer skill, then generate an issue report.

The audit will:
1. Run all four analysis passes across the entire codebase
2. Classify every finding by severity (Critical, Major, Minor, Roadmap)
3. Apply safe minor fixes directly
4. Generate a report file at issues/reports/Report_YYYY-MM-DD.md

After the audit, run /pm-sync to push the report to Notion (if configured).

$ARGUMENTS may be:
- Empty: audit the entire codebase
- A path: `src/api/` — audit only files under that path
