## Summary

<!-- What changed and why (share scope only unless maintainer PR) -->

## Type

- [ ] Share skill / references
- [ ] Hub scripts
- [ ] Docs / examples
- [ ] Export / CI

## Checklist

- [ ] `check-skill-entrypoints` passes
- [ ] `check-skill-structure -OnlyShare` passes
- [ ] `build-skill-index` run if skills changed
- [ ] No private project names / machine paths in share paths
- [ ] Updated `skills/share/README.md` if skill count or boundaries changed

## Test plan

<!-- Commands you ran -->

```powershell
pwsh -File scripts/check-skill-entrypoints.ps1
pwsh -File scripts/check-skill-structure.ps1 -OnlyShare
```
