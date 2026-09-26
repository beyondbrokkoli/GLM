-- ghost_scope.lua — the "Ghost Scope" demo: a poisoned block no longer
-- aborts the compiler. Each failure below is ledgered and scope-tagged
-- (GHOST_BAIL, slot 68) and its own block is skipped, while sibling
-- blocks keep analyzing — their signals land on the plate as usual.
--
-- Run from the repo root:
--   cargo build --release
--   ./target/release/glm trace/ghost_scope.lua   # exits 1, ledger on stderr
--   python3 plate.py                              # per-scope attribution:
--     scope 1: INFER_TBL_MISMATCH + DECIDE_CONFLICT — block A's
--              heterogeneous table
--     scope 2: GHOST_BAIL + CHK_TBL_NIL — block B bailed at the nil read;
--              the two statements after it never fired (ghosted)
--     scope 3: STMT_DO/BIND_HEAP/STMT_IDX_*/STMT_PRINT — block C, intact
--   ./target/release/glm trace/ghost_scope.lua && xxd -a .glm_trace.bin
--     # run twice; the plates must be byte-identical (determinism)

-- Block A: heterogeneous table — the conflict is ledgered at elem
-- resolution, but the WALK completed, so the plate localizes it here.
do
  local bad = {}
  bad[0] = 1
  bad[1] = "mismatch"
  print(bad[0])
end

-- Block B: the nil read poisons THIS block only. The GHOST_BAIL fires
-- inside this scope and the two trailing statements are ghosted.
do
  local dead
  dead[0] = 1
  local never_analyzed = 5
  print(never_analyzed)
end

-- Block C: healthy sibling — fully analyzed despite A and B.
do
  local ok = {}
  ok[0] = 42
  print(ok[0])
end
