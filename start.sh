#!/usr/bin/env bash
# start.sh — the one-button check. Run from the repo root after any change.
# Stops at the first failing layer so a problem surfaces where it starts.
set -e

# 1. Verify documentation is in sync with source
docs/query.sh --check

# 2. Run the full invariant suite (cargo build + clippy + corpus + codegen lock)
lua lua/test.lua run

# 3. Run the fuzzer to confirm no regressions
python3 python/fuzz.py run --seeds 75

# 4. Run the benchmark to confirm performance
./target/release/glm glm/main.lua
./measure.sh ./glm_out
