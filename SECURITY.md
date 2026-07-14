# Security Policy

## Supported Versions

Security fixes are applied to the latest version on the `main` branch. `v0.1.3` is a personal-Mac preview and is not notarized for broad distribution.

## Reporting A Vulnerability

Do not open a public issue for a potential security vulnerability. Use [GitHub private vulnerability reporting](https://github.com/ZOB2077/Gridnote/security/advisories/new) with:

- A concise description and affected version or commit.
- Reproduction steps or proof of concept.
- Impact assessment and any suggested mitigation.

Please avoid attaching private books, real security-scoped bookmarks, or credentials. You will receive an acknowledgment when the report can be reviewed. Public disclosure should wait until a fix or mitigation is available.

## Scope

Relevant reports include arbitrary code execution, unsafe archive handling, unintended file access, local-data disclosure, and dependency or signing issues. Feature requests and unsupported DRM or monitoring-bypass behavior are not security reports.

## Repository Data Policy

- Never commit production spreadsheets, order exports, customer data, private books, or screenshots containing them.
- Built-in office tables may contain public product names, but all identifiers, specifications, dates, statuses, amounts, and relationships must be synthetic.
- Spreadsheet and database file extensions are ignored, checked by `Scripts/check_repository_hygiene.sh`, and rejected by CI.
- Run `git config core.hooksPath .githooks` after cloning so the same check runs before local commits.
