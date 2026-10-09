Sync issue reports from the issues/ folder to Notion using the project-manager skill.

Only runs if `plugin-config.yaml` has `notion.enabled: true` and valid workspace/database IDs.

The skill will:
1. Check plugin-config.yaml for Notion configuration
2. Read unsynced issue reports from issues/reports/
3. Dedup-check each issue against existing Notion pages
4. Create or update Notion pages for each issue
5. Delete synced report files from issues/ (Notion becomes single source of truth)

$ARGUMENTS may be:
- Empty: sync all unsynced reports
- A report filename: sync only that specific report
