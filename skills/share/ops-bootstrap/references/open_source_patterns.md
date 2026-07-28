# Open Source Ops Patterns

This skill borrows operational structure from mature open-source sysadmin tools:

| Source | URL | Pattern absorbed |
|--------|-----|------------------|
| awesome-sysadmin | https://github.com/awesome-foss/awesome-sysadmin | Ops is broader than install: automation, backups, CMDB/inventory, deployment automation, log management, metrics, monitoring, troubleshooting. |
| awesome-ansible | https://github.com/jdauphant/awesome-ansible | Separate inventory, roles, playbooks, lint/test, and run analysis; service-specific roles exist for Java, MySQL, Nginx, Redis. |
| Dokku deploy systems | https://github.com/signalwire-demos/dokku-deploy-system | Deployment needs locks, release tasks, database backups, rollback, audit log, status checks, scheduled windows, and approval gates. |
| Netdata Agent | https://www.netdata.cloud/open-source/ | Monitoring should work locally/offline and collect metrics close to the host. |
| ansible-redis | https://github.com/DavidWittman/ansible-redis | Service templates need multiple topologies, advanced options, checksum verification, and local tarball/offline install support. |

## Resulting ops-bootstrap design rules

- Every remote operation starts with inventory/target resolution.
- Provisioning uses service modules and profiles; it is not a pile of shell snippets.
- Deployment is a lifecycle: pre-check, render, upload, switch, restart, post-check, rollback, audit.
- Detection and log triage are first-class, read-only workflows.
- Data queries are allowlisted and bounded; write commands are never default.
- Online/offline installation is a first-class branch of the same plan.
