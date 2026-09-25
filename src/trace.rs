// GLM_TRACE — a 256-slot signal array persisted one byte per slot in
// ./.glm_trace.bin (no bit-packing: slot index == byte offset, so
// `xxd -a .glm_trace.bin` reads it straight from the shell). Slot 0
// means "compiled ok", slot 1 "build failed (EXPECT_BUILD_FAIL)", and
// slots 10..90 are the pipeline handles from the trace spec. The
// compiler process pokes the file with write_at; the runtime maps it
// MAP_SHARED (src/rt.rs), so both sides — and every run, including
// crashing ones — accumulate into the same bytes on disk.

pub const TRACE_COMPILED: u8 = 0;
pub const TRACE_BUILD_FAIL: u8 = 1;

pub const TRACE_BIND_SCALAR: u8 = 10;
pub const TRACE_BIND_HEAP: u8 = 11;
pub const TRACE_SHAPE_DROP: u8 = 20;
pub const TRACE_OFFLOAD_EMIT: u8 = 30;
pub const TRACE_RT_ALLOC: u8 = 50;
pub const TRACE_RT_FREE: u8 = 60;
pub const TRACE_RT_SPARSE_UPGRADE: u8 = 70;
pub const TRACE_FAIL_ALIAS_UNION: u8 = 80;
pub const TRACE_FAIL_TYPE_CONFUSION: u8 = 81;
pub const TRACE_FAIL_LEAK_DETECTED: u8 = 90;

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
