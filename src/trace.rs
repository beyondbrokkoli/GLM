// GLM_TRACE — a 256-slot signal array persisted one byte per slot in
// ./.glm_trace.bin (no bit-packing: slot index == byte offset, so
// `xxd -a .glm_trace.bin` reads it straight from the shell). Slot 0
// means "compiled ok", slot 1 "build failed (EXPECT_BUILD_FAIL)", and
// slots 10..90 are the pipeline handles from the trace spec. The
// compiler maps the file once at startup (compiler_trace_init) and
// pokes it with bare memory stores, so every run — including crashing
// ones — accumulates into the same bytes on disk at zero syscall cost.
// The runtime (src/rt.rs) records to its own dedicated sidecar,
// ./.glm_rt_trace.bin, so the two writers never share bytes.
//
// The plate is managed twice for occurrence counting. The low half
// (0..128) stays the sticky signal array it always was: a bare `1`
// OR'd in per slot, never reset, so it reads as "fired at least once
// across all runs". The high half (128..256) is the per-run counter
// mirror: byte 128+N counts how many times slot N fired THIS run,
// zeroed by compiler_trace_reset_counts at compiler startup (the file
// is never truncated, so the clear must be explicit) and incremented
// saturating by compiler_trace_count — 255 means "many". The runtime
// never writes this file, so the counters are compiler-owned and the
// read-modify-write is a plain memory op in the single-threaded
// compiler.

use std::ffi::c_void;
use std::ptr;
use std::sync::atomic::{AtomicPtr, AtomicU32, Ordering};

// Signal slots live in trace_signals.txt (repo root) — the single source
// of truth. build.rs parses it into the consts included below; duplicate
// slots or names fail the build. Edit the SSOT, never the generated items.

/// One row of the signal SSOT (trace_signals.txt) mirrored into the
/// binary, so runtime code can name slots without re-parsing anything.
#[allow(dead_code)]
pub struct TraceSignal {
    pub slot: u8,
    pub name: &'static str,
    pub owner: &'static str,
    pub meaning: &'static str,
}

include!(concat!(env!("OUT_DIR"), "/trace_signals.rs"));

/// First counter byte of the mirror: signal N counts at 128+N.
pub const TRACE_COUNT_BASE: u8 = 128;

const TRACE_FILE: &str = ".glm_trace.bin";
const TRACE_SLOTS: usize = 256;

// --- third buffer: per-run scope context ------------------------------------
//
// Who fired is the plate's first two halves; WHERE it fired is this one.
// The scope histogram is the counter mirror extended by one scope axis:
// cell (signal N, scope S) saturates independently at 255, so parallel
// events keep their own "many" caps and a signal's run total is the sum
// of its cells. Depth is not a fourth buffer — it lives once per scope in
// the directory, and the decoder projects signal × depth from it. Scope
// context is compiler-side: the runtime has no scope concept, so bytes
// >= 128 stay compiler-owned and the runtime must never write them.

/// Scope count: one byte per id, like everything else on the plate.
/// Walks with more scopes fold into 255 — a deliberate small-script limit.
pub const TRACE_SCOPE_SLOTS: usize = 256;
/// Cell (signal N, scope S) sits at HISTO_OFF + N * TRACE_SCOPE_SLOTS + S.
pub const TRACE_SCOPE_HISTO_OFF: u64 = TRACE_SLOTS as u64;
/// Directory: two bytes per scope (depth, parent) at DIR_OFF + S * 2.
pub const TRACE_SCOPE_DIR_OFF: u64 = TRACE_SCOPE_HISTO_OFF + (128 * TRACE_SCOPE_SLOTS) as u64;
/// Parent sentinel in the directory; the root scope is (0, PARENT_NONE),
/// an all-zero entry means the scope was never seen this run.
pub const TRACE_SCOPE_PARENT_NONE: u8 = 0xFF;
const TRACE_SCOPE_FILE_LEN: u64 = TRACE_SCOPE_DIR_OFF + (TRACE_SCOPE_SLOTS as u64) * 2;

// --- fourth buffer: per-run chronology --------------------------------------
//
// WHEN it fired, in deterministic event order. The section header holds
// the per-run event count and the ring capacity (so decoders follow
// geometry changes without a rebuild); the ring holds one (slot, scope)
// pair per event in fire order, wrapping on capacity. Compiler-owned end
// to end — the runtime has no chronology concept and pokes only its own
// sidecar file.

/// First byte of the chronology section: right after the scope sections.
pub const TRACE_CHRONO_OFF: u64 = TRACE_SCOPE_FILE_LEN;
/// Ring capacity in events; one event is 2 bytes (slot, scope).
pub const TRACE_RING_CAPACITY: u32 = 8192;
/// Chronology header: global_seq (u32) at CHRONO_OFF, ring_capacity (u32)
/// at CHRONO_OFF + 4. Both little-endian on disk.
pub const TRACE_CHRONO_HDR_LEN: u64 = 8;
/// Full plate length once the chronology section exists — the only
/// length the trace helpers ever grow the file to.
pub const TRACE_PLATE_LEN: u64 =
    TRACE_CHRONO_OFF + TRACE_CHRONO_HDR_LEN + (TRACE_RING_CAPACITY as u64) * 2;

/// Current scope register, packed scope | depth<<8 | parent<<16; scope
/// byte 0xFF means "no scope context". Process-wide because the signal!
/// macro carries only the slot — the analyzer keeps it current around the
/// walk it records (one compiler per plate, contract §4).
static CURRENT_SCOPE: AtomicU32 = AtomicU32::new(0xFF);

// The mmap'd plate, established once by compiler_trace_init. Null means
// tracing is degraded (unwritable CWD, mmap refused) and every poke
// silently drops — the same best-effort contract as the write_at path.
static TRACE_MAP: AtomicPtr<u8> = AtomicPtr::new(ptr::null_mut());

const PROT_READ: i32 = 0x1;
const PROT_WRITE: i32 = 0x2;
const MAP_SHARED: i32 = 0x01;

unsafe extern "C" {
    fn mmap(addr: *mut c_void, len: usize, prot: i32, flags: i32, fd: i32, off: i64) -> *mut c_void;
}

fn is_map_failed(p: *mut c_void) -> bool {
    p.addr() == usize::MAX
}

/// Establish the mmap'd plate: grow the file to its full length (never
/// shrink), map it MAP_SHARED, zero the per-run event count, and stamp
/// the ring capacity. Called once at compiler startup, before any reset
/// or poke. All later trace calls are pure memory writes through this
/// map. Best-effort: any failure leaves the map null and tracing
/// degrades silently, never fatally.
pub fn compiler_trace_init() {
    use std::fs::OpenOptions;
    use std::os::unix::io::AsRawFd;
    if let Ok(file) = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false) // accumulate across runs — never reset the array
        .open(TRACE_FILE)
    {
        let _ = file.set_len(TRACE_PLATE_LEN);
        let ptr = unsafe {
            mmap(
                ptr::null_mut(),
                TRACE_PLATE_LEN as usize,
                PROT_READ | PROT_WRITE,
                MAP_SHARED,
                file.as_raw_fd(),
                0,
            )
        };
        if !is_map_failed(ptr) {
            let map = ptr.cast::<u8>();
            TRACE_MAP.store(map, Ordering::SeqCst);
            unsafe {
                // Per-run event count starts at 0; the ring keeps its
                // stale bytes — identical runs rewrite identical events.
                let hdr = map.add(TRACE_CHRONO_OFF as usize) as *mut u32;
                hdr.write(0);
                hdr.add(1).write(TRACE_RING_CAPACITY);
            }
        }
    }
}

/// Compiler-side poke: OR a 1 into `slot` — a bare store through the
/// mmap'd plate, so it survives crashes with no flush step and costs no
/// syscall. Best-effort: a degraded (null) map silently drops the
/// signal instead of failing the compile.
pub fn compiler_trace_set(slot: u8) {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if map.is_null() {
        return;
    }
    unsafe { *map.add(slot as usize) = 1 };
}

/// Pass A of the counting protocol: zero the high-half counter mirror
/// (bytes 128..256) at compiler startup. The plate itself is never
/// truncated, so per-run counts must be cleared explicitly; the sticky
/// low-half booleans — slot 0/1 build status included — are untouched.
/// global_seq is not touched here either: init owns the chronology header.
pub fn compiler_trace_reset_counts() {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if map.is_null() {
        return;
    }
    unsafe { std::ptr::write_bytes(map.add(TRACE_COUNT_BASE as usize), 0, TRACE_SLOTS / 2) };
}

/// Pass B of the counting protocol: increment the counter mirror for
/// `slot` (byte 128+N) with a saturating add — 255 reads as "many".
/// Same best-effort contract as compiler_trace_set; the read-modify-
/// write is safe because the compiler is the only writer of the high
/// half.
pub fn compiler_trace_count(slot: u8) {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if map.is_null() {
        return;
    }
    unsafe {
        let count_ptr = map.add(TRACE_COUNT_BASE as usize + slot as usize);
        *count_ptr = (*count_ptr).saturating_add(1);
    }
}

/// One trace spot, all four buffers: sticky bit, saturating per-run
/// counter, scope cell, and one chronology ring event in deterministic
/// fire order. Silent by design — the plate is the output. Zero
/// syscalls: every access is a memory write through the mmap'd plate.
pub fn compiler_trace_signal(slot: u8) {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if map.is_null() {
        return;
    }
    unsafe {
        // 1. Sticky bit. 2. Saturating per-run counter.
        *map.add(slot as usize) = 1;
        let count_ptr = map.add(TRACE_COUNT_BASE as usize + slot as usize);
        *count_ptr = (*count_ptr).saturating_add(1); // 255 means "many", never wraps

        // 3. Scope cell + directory upsert.
        bump_scope_cell(map, slot);

        // 4. Chronology ring: (slot, scope) at the seq'th slot, wrapping
        // on capacity; seq keeps counting so the decoder knows how many
        // events were dropped. Capacity is read from the header so Rust
        // and Python can never disagree on the geometry.
        let seq_ptr = map.add(TRACE_CHRONO_OFF as usize) as *mut AtomicU32;
        let seq = (*seq_ptr).fetch_add(1, Ordering::Relaxed);
        let capacity = *(map.add(TRACE_CHRONO_OFF as usize + 4) as *const u32);
        if capacity > 0 {
            let event_ptr = map.add(
                TRACE_CHRONO_OFF as usize
                    + TRACE_CHRONO_HDR_LEN as usize
                    + (seq % capacity) as usize * 2,
            );
            *event_ptr = slot;
            let cur = CURRENT_SCOPE.load(Ordering::Relaxed);
            *event_ptr.add(1) = (cur & 0xFF) as u8; // scope id, or 0xFF = none
        }
    }
}

/// Pass A, scope sections: zero the per-run scope histogram and directory
/// next to the counter mirror. Same never-truncate contract — this clears
/// only the per-run view; the sticky low half stays untouched. The
/// chronology section below is not touched here: its ring keeps stale
/// bytes (identical runs rewrite them identically) and init resets
/// global_seq.
pub fn compiler_trace_scope_reset() {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if map.is_null() {
        return;
    }
    unsafe {
        // Histogram + directory: bytes 256..33536, the classic sections.
        let len = (TRACE_CHRONO_OFF - TRACE_SCOPE_HISTO_OFF) as usize;
        std::ptr::write_bytes(map.add(TRACE_SCOPE_HISTO_OFF as usize), 0, len);
    }
    compiler_trace_current_scope(0xFF, 0, 0); // 0xFF = no scope context
}

/// Set the scope context pokes pair with: scope id, its depth in the
/// scope tree, and its parent's id (PARENT_NONE for the root). Scope
/// 0xFF means "no context" — build-status pokes carry none.
pub fn compiler_trace_current_scope(scope: u8, depth: u8, parent: u8) {
    CURRENT_SCOPE.store(
        u32::from(scope) | u32::from(depth) << 8 | u32::from(parent) << 16,
        Ordering::Relaxed,
    );
}

/// Bump cell (slot, current scope) and upsert the scope's directory
/// entry — the directory write is skipped when it already holds the
/// entry, so the common path stays two one-byte accesses like the
/// counters. No-op without scope context.
fn bump_scope_cell(map: *mut u8, slot: u8) {
    let cur = CURRENT_SCOPE.load(Ordering::Relaxed);
    let scope = (cur & 0xFF) as u8;
    if scope == 0xFF {
        return;
    }
    let depth = (cur >> 8) as u8;
    let parent = (cur >> 16) as u8;
    unsafe {
        let cell_ptr = map.add(
            TRACE_SCOPE_HISTO_OFF as usize + slot as usize * TRACE_SCOPE_SLOTS + scope as usize,
        );
        *cell_ptr = (*cell_ptr).saturating_add(1); // 255 means "many", never wraps
        let dir_ptr = map.add(TRACE_SCOPE_DIR_OFF as usize + scope as usize * 2);
        if *dir_ptr != depth || *dir_ptr.add(1) != parent {
            *dir_ptr = depth;
            *dir_ptr.add(1) = parent;
        }
    }
}

/// Fire a trace signal. `signal!(SLOT)` is unconditional;
/// `signal!(gate, SLOT)` fires only when `gate` is true — every analyzer
/// call site passes `self.recording` so the fixed-point loop stays out
/// of the per-run counters.
#[macro_export]
macro_rules! signal {
    ($slot:expr) => {
        $crate::trace::compiler_trace_signal($slot)
    };
    ($gate:expr,$slot:expr) => {
        if $gate {
            $crate::trace::compiler_trace_signal($slot)
        }
    };
}
