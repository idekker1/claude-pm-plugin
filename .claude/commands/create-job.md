Queue a new unit of work into jobs/pending/ using the create-job skill.

$ARGUMENTS: description of the work to be done

The skill will:
1. Read ROADMAP.md and all job folders to understand current state
2. Validate dependency order, roadmap alignment, and acceptance criteria specificity
3. Assign the next available job_id (zero-padded, e.g. 027)
4. Write a well-formed job file to jobs/pending/
5. Confirm: job_id, type, dependencies, acceptance criteria, suggested branch name

Does NOT execute work — only produces the job file.
Run /run-jobs to pick it up.
