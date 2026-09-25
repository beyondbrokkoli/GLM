// GLM_TRACE — a 256-slot signal array persisted one byte per slot in
// ./.glm_trace.bin (no bit-packing: slot index == byte offset, so
// `xxd -a .glm_trace.bin` reads it straight from the shell). Slot 0
// means "compiled ok", slot 1 "build failed (EXPECT_BUILD_FAIL)", and
// slots 10..90 are the pipeline handles from the trace spec. The
// compiler process pokes the file with write_at; the runtime maps it
// MAP_SHARED (src/rt.rs), so both sides — and every run, including
// crashing ones — accumulate into the same bytes on disk.
//
// The plate is managed twice for occurrence counting. The low half
// (0..128) stays the sticky signal array it always was: a bare `1`
// OR'd in per slot, never reset, so it reads as "fired at least once
// across all runs". The high half (128..256) is the per-run counter
// mirror: byte 128+N counts how many times slot N fired THIS run,
// zeroed by compiler_trace_reset_counts at compiler startup (the file
// is never truncated, so the clear must be explicit) and incremented
// saturating by compiler_trace_count — 255 means "many". The runtime
// only ever touches the low half, so the counters are compiler-owned
// and the read-modify-write stays lock-free on the same page-cache
// coherence the boolean pokes use.

pub const TRACE_COMPILED: u8 = 0;
pub const TRACE_BUILD_FAIL: u8 = 1;

pub const TRACE_BIND_SCALAR: u8 = 10;
pub const TRACE_BIND_HEAP: u8 = 11;
pub const TRACE_SHAPE_DROP: u8 = 20;
// Shape-analyzer debug signals (shadow of the elem_type_of_tbl /
// decide decision points — the future state machine reads these).
pub const TRACE_SHAPE_CONFLICT_GUARD: u8 = 21;
pub const TRACE_RECORD_PRESERVED: u8 = 22;
pub const TRACE_CHILD_FAST_PATH: u8 = 23;
pub const TRACE_FALLBACK_RESOLVE: u8 = 24;
pub const TRACE_DECIDE_VISIT: u8 = 25;
pub const TRACE_JOIN_RETYPED: u8 = 26;
pub const TRACE_OFFLOAD_EMIT: u8 = 30;
pub const TRACE_RT_ALLOC: u8 = 50;
pub const TRACE_RT_FREE: u8 = 60;
pub const TRACE_RT_SPARSE_UPGRADE: u8 = 70;
pub const TRACE_FAIL_ALIAS_UNION: u8 = 80;
pub const TRACE_FAIL_TYPE_CONFUSION: u8 = 81;
pub const TRACE_FAIL_LEAK_DETECTED: u8 = 90;

/// First counter byte of the mirror: signal N counts at 128+N.
pub const TRACE_COUNT_BASE: u8 = 128;

const TRACE_FILE: &str = ".glm_trace.bin";
const TRACE_SLOTS: usize = 256;

/// Compiler-side poke: OR a 1 into `slot` via a plain file write. The
/// kernel page cache keeps this coherent with the runtime's MAP_SHARED
/// mapping of the same file, so the two processes need no protocol
/// between them. Best-effort: a write-protected CWD silently drops the
/// signal instead of failing the compile.
pub fn compiler_trace_set(slot: u8) {
    use std::fs::OpenOptions;
    use std::os::unix::fs::FileExt;
    if let Ok(file) = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(false) // accumulate across runs — never reset the array
        .open(TRACE_FILE)
    {
        let _ = file.set_len(TRACE_SLOTS as u64);
        let _ = file.write_at(&[1], slot as u64);
    }
}

/// Pass A of the counting protocol: zero the high-half counter mirror
/// (bytes 128..256) at compiler startup. The plate itself is never
/// truncated, so per-run counts must be cleared explicitly; the sticky
/// low-half booleans — slot 0/1 build status included — are untouched.
pub fn compiler_trace_reset_counts() {
    use std::fs::OpenOptions;
    use std::os::unix::fs::FileExt;
    if let Ok(file) = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(false)
        .open(TRACE_FILE)
    {
        let _ = file.set_len(TRACE_SLOTS as u64);
        let _ = file.write_at(&[0u8; TRACE_SLOTS / 2], TRACE_COUNT_BASE as u64);
    }
}

/// Pass B of the counting protocol: increment the counter mirror for
/// `slot` (byte 128+N) with a saturating add — 255 reads as "many".
/// Same best-effort contract as compiler_trace_set; the read-modify-
/// write is safe because the compiler is the only writer of the high
/// half and pwrite keeps the runtime's mapping coherent.
pub fn compiler_trace_count(slot: u8) {
    use std::fs::OpenOptions;
    use std::os::unix::fs::FileExt;
    if let Ok(file) = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(TRACE_FILE)
    {
        let _ = file.set_len(TRACE_SLOTS as u64);
        let at = TRACE_COUNT_BASE as u64 + slot as u64;
        let mut byte = [0u8; 1];
        let _ = file.read_at(&mut byte, at);
        byte[0] = byte[0].saturating_add(1);
        let _ = file.write_at(&byte, at);
    }
}
