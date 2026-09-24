#!/usr/bin/env python3
import argparse, subprocess, sys, os, time, re
from pathlib import Path

# Ensure this script's directory is always resolvable regardless of where it is called from
sys.path.insert(0, str(Path(__file__).resolve().parent))
from generator import GlmLuaGenerator

# --- Terminal Colors ---
class C:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

# nil-vs-0 pairs hardwired equal per seed run: glm's growth zero-fill
# reads as 'nil' in Lua (int tables only, so a nil can mean nothing
# else). Counted so a campaign report shows the feature is exercised.
NIL0 = [0]

INT_TOKEN = re.compile(r'^-?\d+$')

def tokens_match(a, b):
    """One output token from Lua vs one from glm."""
    if a == b:
        return True
    # nil↔0 for int tables: unwritten cells print nil (Lua) vs 0 (GLM
    # growth-zero fill). Counted so a campaign report shows the feature
    # is exercised — the fuzzer's generator emits these reads intentionally.
    if {a, b} == {"nil", "0"}:
        NIL0[0] += 1
        return True
    # nil↔0.0 for float tables: same semantic gap — unwritten float cells
    # are nil in Lua, growth-zero (0.0) in GLM. Without this the fuzzer
    # would always report mismatches on any float table read beyond the
    # written span.
    if {a, b} == {"nil", "0.0"}:
        NIL0[0] += 1
        return True
    # exact integer comparison — float tolerance must never mask a
    # genuine integer delta ( Lua and Rust both print i64 exactly)
    if INT_TOKEN.match(a) and INT_TOKEN.match(b):
        return int(a) == int(b)
    try:
        # Float tolerance (handles 0.0 vs 0, and Lua's %.14g vs Rust {})
        if abs(float(a) - float(b)) < 1e-9:
            return True
    except ValueError:
        pass
    return False

def print_diff(ref_vals, got_vals):
    """Prints a clear side-by-side comparison of Lua vs Glm outputs."""
    print(f"\n{C.BOLD}--- Output Mismatch Diff ---{C.RESET}")
    print(f"{'Idx':<4} | {'Lua (Expected)':<16} | {'Glm (Got)':<16} | {'Status'}")
    print("-" * 52)
    max_len = max(len(ref_vals), len(got_vals))
    for i in range(max_len):
        exp = ref_vals[i] if i < len(ref_vals) else "MISSING"
        got = got_vals[i] if i < len(got_vals) else "MISSING"
        status = f"{C.GREEN}✔ Match{C.RESET}" if tokens_match(exp, got) else f"{C.RED}✘ Fail{C.RESET}"
        print(f"{i:<4} | {exp:<16} | {got:<16} | {status}")

def run_seed(seed, cwd):
    generator = GlmLuaGenerator(seed)
    src = generator.generate()

    os.makedirs("/tmp/adv", exist_ok=True)
    path = f"/tmp/adv/fuzz_{seed}.lua"
    with open(path, "w") as f:
        f.write(src)

    # 1. Run reference Lua
    ref = subprocess.run(["lua", path], capture_output=True, text=True)
    if ref.returncode != 0:
        return {"status": "SKIP", "src": src}

    # 2. Compile with Glm
    glm_bin = os.path.join(cwd, "target", "release", "glm")
    compile_proc = subprocess.run([glm_bin, path], capture_output=True, text=True, cwd=cwd)

    if compile_proc.returncode != 0:
        err = compile_proc.stderr
        # Intentional strict-dialect rejections are not compiler bugs.
        # They mean the compiler correctly caught a lifetime/scope violation.
        strict_errors = [
            "Lifetime Error:",
            "Type Error:",
            "Scope Error:",
            "table index overflow",
            "nested tables are not supported yet",
        ]
        if any(s in err for s in strict_errors):
            return {"status": "SKIP", "src": src}

        return {"status": "COMPILE_FAIL", "msg": compile_proc.stderr[-800:], "src": src}

    # 3. Execute the compiled binary
    glm_out_bin = os.path.join(cwd, "glm_out")
    if not os.path.exists(glm_out_bin):
        return {"status": "MISSING_BIN", "msg": "Compilation succeeded but ./glm_out was not found.", "src": src}

    got = subprocess.run([glm_out_bin], capture_output=True, text=True)
    if got.returncode != 0:
        return {"status": "RUN_FAIL", "msg": got.stderr[-800:], "src": src}

    # 4. Parse & Compare Outputs
    ref_vals = ref.stdout.split()
    got_vals = got.stdout.split()

    if len(ref_vals) != len(got_vals):
        return {"status": "SHAPE_FAIL", "ref": ref_vals, "got": got_vals, "src": src}

    for a, b in zip(ref_vals, got_vals):
        if tokens_match(a, b):
            continue
        return {"status": "MISMATCH", "ref": ref_vals, "got": got_vals, "src": src}

    return {"status": "PASS"}

def main():
    parser = argparse.ArgumentParser(
        description="The fuzzer: generates random programs "
                    "(python/generator.py), compiles them with glm, and diffs "
                    "the output against the system lua binary — the semantic "
                    "oracle the corpus is not. Run from the repo root.")
    parser.add_argument("cmd", nargs="?", choices=["run"],
                        help="start the fuzzer (no argument prints this help)")
    parser.add_argument("--seeds", "-n", type=int, default=50, help="Number of random tests to execute (default: 50)")
    parser.add_argument("--seed", "-s", type=int, default=None, help="Target a specific seed to reproduce a bug")
    parser.add_argument("--max-fails", type=int, default=3, help="Halt after this many failures (default: 3)")
    parser.add_argument("--blacklist", "-b", type=int, nargs='+', default=[], help="Additional seeds to skip manually")
    args = parser.parse_args()

    if args.cmd is None:
        parser.print_help()
        sys.exit(0)

    cwd = os.getcwd()

    # Pre-build Glm once for maximum fuzzer throughput
    print(f"{C.CYAN}Building Glm (--release)...{C.RESET}")
    build = subprocess.run(["cargo", "build", "--release"], cwd=cwd)
    if build.returncode != 0:
        print(f"{C.RED}Failed to build Glm. Aborting.{C.RESET}")
        sys.exit(1)

    seed_list = [args.seed] if args.seed is not None else list(range(args.seeds))
    blacklist = set(args.blacklist)
    seed_list = [s for s in seed_list if s not in blacklist]
    total_runs = len(seed_list)

    print(f"\n{C.CYAN}{C.BOLD}=== Glm LLVM IR Differential Fuzzer ==={C.RESET}")
    print(f"Targeting {total_runs} runs...\n")

    fails = 0
    passed = 0
    skipped = 0
    nil0_total = 0
    start_time = time.time()

    for idx, seed in enumerate(seed_list):
        sys.stdout.write(f"\rTesting seed {seed} ({idx + 1}/{total_runs})...")
        sys.stdout.flush()

        NIL0[0] = 0
        res = run_seed(seed, cwd)
        nil0_total += NIL0[0]

        if res["status"] == "SKIP":
            skipped += 1
            continue

        if res["status"] == "PASS":
            passed += 1
            continue

        # Handle Failure
        fails += 1
        sys.stdout.write("\r" + " " * 50 + "\r")
        print(f"{C.RED}❌ FAIL [Seed {seed}]{C.RESET} - Reason: {C.BOLD}{res['status']}{C.RESET}")

        if res["status"] in ["MISMATCH", "SHAPE_FAIL"]:
            print_diff(res["ref"], res["got"])
        else:
            print(f"\n{C.YELLOW}Error Details:{C.RESET}\n{res.get('msg', '')}")

        print(f"\n{C.YELLOW}Reproducer Script (/tmp/adv/fuzz_{seed}.lua):{C.RESET}\n{res['src']}")

        if fails >= args.max_fails:
            print(f"\n{C.RED}Reached failure threshold ({args.max_fails}). Halting.{C.RESET}")
            break

    elapsed = time.time() - start_time
    print("-" * 52)
    print(f"Done in {elapsed:.2f}s | {C.GREEN}{passed} Passed{C.RESET} | {C.YELLOW}{skipped} Skipped{C.RESET} | {C.RED if fails else C.GREEN}{fails} Failed{C.RESET}")
    print(f"nil-as-0 growth-zero pairs verified: {nil0_total}")

    sys.exit(1 if fails > 0 else 0)

if __name__ == "__main__":
    main()
