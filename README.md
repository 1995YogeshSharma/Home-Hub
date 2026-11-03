# Manual Entry follows below this line, should not be modified by any agent

## Product outline

**One shared place to run a household, or a small team.**

Families and small teams spread their coordination across chat threads, personal notes apps, password managers and cloud drives. Home Hub brings this into one private space. Each group has its own members and its own data, and every member gets the same view.

## Principles

- **The group comes first.** Data belongs to the group, not to any single user. This lets the same platform serve a household or a team.
- **Roles within a group.** Members are either Admins or Members. Admins manage the group and hold extra permissions, for example access to sensitive Vault items.
- **Private by design.** Sensitive data is encrypted, and access is limited to the people who need it.
- **Built to extend.** Every module plugs into a common core (identity, groups, roles, audit), so new modules are cheap to add.
- **Reliable from day one.** Concurrent edits are detected rather than lost, changes are audited, and backups are built in.

## Platforms

Web, iOS and Android from a single Flutter client, backed by a FastAPI and PostgreSQL server.

## Modules (initial)

| Module        | Purpose                                                                 |
| ------------- | ----------------------------------------------------------------------- |
| **Notes**     | Collaborative documents any member can edit, with revision history.     |
| **Reminders** | Shared, assignable reminders for bills, renewals, chores and appointments. |
| **Vault**     | Encrypted storage for sensitive items: streaming logins, account details, financial statements. |
| **Pictures**  | A shared album for group photos, organised for easy reference.          |
| **Files**     | Shared storage for documents such as warranties, manuals, IDs and contracts. |


## Technical Decisions
