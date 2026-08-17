# OpenTenBase TAP Compatibility Baseline

## Scope

This baseline ran pgvector's unmodified `prove_installcheck` entry point against
the OpenTenBase PG10-based source tree on 2026-08-18. The source tree exposes 44
TAP scripts under `contrib/pgvector/test/t/`.

```bash
cd /opt/opentenbase/src/OpenTenBase/contrib/pgvector
make prove_installcheck 2>&1 | tee /root/tap_0818.log
```

## Result

| Measure | Count |
|---|---:|
| TAP scripts discovered | 44 |
| Scripts passed | 0 |
| Scripts failed before assertions | 1 |
| Scripts not run after bailout | 43 |
| TAP assertions executed | 0 |

This is not evidence that all 44 scripts are incompatible. The first script
bailed out during temporary-node initialization, so the remaining 43 scripts
were never evaluated.

## Failure progression

1. The initial run stopped before loading any script because `IPC::Run` was
   absent. The environment was repaired with `perl-IPC-Run-0.92-2.el7`.
2. The second run stopped before loading any script because `Test::More` was
   absent. The environment was repaired with `perl-Test-Simple-0.98-243.el7`.
3. The final unmodified run reached `test/t/001_ivfflat_wal.pl`, but
   `test/perl/PostgreSQL/Test/Cluster.pm` called `get_new_node($name)` without a
   node type. OpenTenBase requires `initdb --nodetype` to be `datanode` or
   `coordinator`; the generated command supplied an empty value and the suite
   bailed out.

No compatibility shim was applied for this baseline. A follow-up run must first
make the OpenTenBase test adapter pass an explicit node type, then report the
remaining per-script compatibility results separately.

## Raw evidence

| File | SHA256 | Meaning |
|---|---|---|
| `tap_20260818_attempt1_missing-ipc-run.log` | `c4c65b2305cb65d9bd517eb1938dbbc70508c5a050b569d9862932bcba6aeb8e` | Initial dependency failure |
| `tap_20260818_attempt2_missing-test-more.log` | `ed9cb3833e02966838cda73c8920763b5249531508bfc7b3f017276a674308ee` | Second dependency failure |
| `tap_20260818_attempt3_initdb-node-type.log` | `8657a56d4706576b067a522fce5cf2a882dd469b39ea09b83cffc6fc00b2f615` | Final unmodified baseline |

