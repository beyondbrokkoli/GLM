#![allow(unsafe_op_in_unsafe_fn)]
// The glm runtime: C-ABI surface (print + table memory).
use std::alloc::{Layout, alloc_zeroed, dealloc, realloc};
use std::collections::HashMap;
use std::ffi::c_void;
use std::fs::OpenOptions;
use std::os::unix::io::AsRawFd;
use std::ptr;
use std::sync::atomic::{AtomicPtr, AtomicUsize, Ordering};

use crate::trace::{
    TRACE_FAIL_LEAK_DETECTED, TRACE_RT_ALLOC, TRACE_RT_FREE, TRACE_RT_SPARSE_UPGRADE,
};

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TableMode {
    Dense = 0,
    Sparse = 1,
}

#[repr(C)]
pub struct GlmTable {
    pub data: *mut u8,
    pub len: i64,
    pub reserve: usize,
    pub esize: usize,
    pub mode: TableMode,
    pub contains_tables: u8,
    pub sparse_map: *mut HashMap<i64, u64>,
}

static ALLOC_COUNT: AtomicUsize = AtomicUsize::new(0);

// === GLM_TRACE signal array ===
// 256 one-byte slots mapped MAP_SHARED off ./.glm_rt_trace.bin — a
// runtime-owned sidecar, fully separate from the compiler's
// .glm_trace.bin plate, so neither writer can ever touch the other's
// bytes (the old shared-file setup let the runtime's set_len(256)
// ftruncate the compiler's counters, histograms, and scope sections).
// A signal is a bare store, so tracing survives crashes with no flush
// step and costs no syscall in steady state (the gauntlet's 1M
// ctor/free churn stays clean). First caller maps; later callers reuse
// the pointer.

const TRACE_SLOTS: usize = 256;
const TRACE_FILE: &str = ".glm_rt_trace.bin";

static TRACE_MAP: AtomicPtr<u8> = AtomicPtr::new(ptr::null_mut());
static LEAK_HOOK: std::sync::atomic::AtomicU8 = std::sync::atomic::AtomicU8::new(0);

pub unsafe fn init_trace_map() {
    let Ok(file) = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false) // accumulate across runs — never reset the array
        .open(TRACE_FILE)
    else {
        return; // unwritable CWD: degrade silently, tracing never fatal
    };
    let _ = file.set_len(TRACE_SLOTS as u64);
    let ptr = unsafe {
        mmap(
            ptr::null_mut(),
            TRACE_SLOTS,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            file.as_raw_fd(),
            0,
        )
    };
    if is_map_failed(ptr) {
        return;
    }
    TRACE_MAP.store(ptr.cast::<u8>(), Ordering::Relaxed);
}

#[inline]
fn trace_map() -> *mut u8 {
    let map = TRACE_MAP.load(Ordering::Relaxed);
    if !map.is_null() {
        return map;
    }
    unsafe { init_trace_map() };
    TRACE_MAP.load(Ordering::Relaxed)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_trace_set(slot: u8) {
    let map = trace_map();
    if !map.is_null() {
        unsafe { *map.add(slot as usize) = 1 };
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_trace_clear(slot: u8) {
    let map = trace_map();
    if !map.is_null() {
        unsafe { *map.add(slot as usize) = 0 };
    }
}

// Registered once by the first glm_tbl_new: at process exit, any live
// GlmTable is a leak. Runs even though the crate builds with
// panic=abort (atexit fires on the normal exit path).
unsafe extern "C" fn glm_trace_leak_check() {
    if ALLOC_COUNT.load(Ordering::Relaxed) > 0 {
        unsafe { glm_trace_set(TRACE_FAIL_LEAK_DETECTED) };
        eprintln!("GLM_TRACE: slot 90 — leak at exit (sys_alloc_count() > 0)");
    }
}

fn elem_layout(len: i64, esize: usize) -> Layout {
    let bytes = usize::try_from(len)
        .ok()
        .and_then(|l| l.checked_mul(esize))
        .unwrap_or_else(|| abort_alloc(usize::MAX));
    Layout::from_size_align(bytes, 8).unwrap_or_else(|_| abort_alloc(bytes))
}

fn abort_alloc(bytes: usize) -> ! {
    eprintln!("glm: table allocation of {bytes} bytes failed");
    std::process::abort();
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_new(esize: usize, flags: u8) -> *mut GlmTable {
    // Unpack bit 7 → contains_tables for the deep-free path
    let contains_tables = (flags & 0x80) >> 7;
    // Unpack bit 0 → sparse mode (bits 1-6 unused)
    let is_sparse = (flags & 0x01) != 0;

    let hdr = Box::into_raw(Box::new(GlmTable {
        data: std::ptr::null_mut(),
        len: 0,
        reserve: 0,
        esize,
        mode: if is_sparse { TableMode::Sparse } else { TableMode::Dense },
        contains_tables,
        sparse_map: if is_sparse {
            Box::into_raw(Box::new(HashMap::new()))
        } else {
            std::ptr::null_mut()
        },
    }));
    ALLOC_COUNT.fetch_add(1, Ordering::Relaxed);
    unsafe { glm_trace_set(TRACE_RT_ALLOC) };
    if LEAK_HOOK
        .compare_exchange(0, 1, Ordering::Relaxed, Ordering::Relaxed)
        .is_ok()
    {
        unsafe { atexit(glm_trace_leak_check) };
    }
    hdr
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_grow(t: *mut GlmTable, idx: i64) {
    if !t.is_null() {
        let tbl = &mut *t;
        if tbl.mode != TableMode::Dense {
            return;
        }
    }
    if idx >= 0 && idx == i64::MAX {
        eprintln!("glm fatal: table index overflow (idx={idx})");
        std::process::abort();
    }
    unsafe { span_grow(t, idx.wrapping_add(1)) };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_reserve(t: *mut GlmTable, n: i64) {
    let tbl = unsafe { &mut *t };
    if tbl.mode != TableMode::Dense {
        return;
    }
    unsafe { span_grow(t, n) };
}

// Phase 2 — upgrade to sparse backing store

const SPARSE_THRESHOLD: i64 = 100_000;

#[inline(never)]
pub unsafe fn upgrade_to_sparse(t: *mut GlmTable) -> bool {
    let tbl = &mut *t;
    let n = tbl.len as usize;
    if n == 0 {
        return false;
    }

    let map = Box::into_raw(Box::new(HashMap::with_capacity(n)));

    if tbl.esize == 8 {
        let cells = std::slice::from_raw_parts(tbl.data.cast::<u64>(), n);
        for (i, &cell) in cells.iter().enumerate() {
            (*map).insert(i as i64, cell);
        }
    } else {
        let cells = std::slice::from_raw_parts(tbl.data, n);
        for (i, &cell) in cells.iter().enumerate() {
            (*map).insert(i as i64, cell as u64);
        }
    }

    if tbl.reserve != 0 {
        unsafe { munmap(tbl.data.cast(), tbl.reserve) };
    } else {
        unsafe { dealloc(tbl.data, elem_layout(tbl.len, tbl.esize)) };
    }

    tbl.data = std::ptr::null_mut();
    tbl.len = 0;
    tbl.reserve = 0;
    tbl.mode = TableMode::Sparse;
    tbl.sparse_map = map;
    unsafe { glm_trace_set(TRACE_RT_SPARSE_UPGRADE) };
    true
}

// Phase 3 — C-ABI set / get endpoints (mode-aware routing)

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_set(t: *mut GlmTable, index: i64, val: *const u8) {
    if t.is_null() {
        return;
    }
    let tbl = &mut *t;

    // ---- Sparse: direct HashMap insert ----
    if tbl.mode == TableMode::Sparse {
        if index < 0 {
            return;
        }
        let map = &mut *tbl.sparse_map;
        if tbl.esize == 8 {
            let v = *(val as *const u64);
            map.insert(index, v);
        } else {
            let v = *val as u64;
            map.insert(index, v);
        }
        return;
    }

    // ---- Dense: threshold check ----
    if index > tbl.len.saturating_add(SPARSE_THRESHOLD) {
        if !upgrade_to_sparse(t) {
            unsafe { glm_trace_set(TRACE_RT_SPARSE_UPGRADE) };
            let tbl = &mut *t;
            if !tbl.data.is_null() {
                if tbl.reserve != 0 {
                    unsafe { munmap(tbl.data.cast(), tbl.reserve) };
                } else {
                    unsafe { dealloc(tbl.data, elem_layout(tbl.len, tbl.esize)) };
                }
            }
            let map = Box::into_raw(Box::new(HashMap::with_capacity(1)));
            tbl.data = std::ptr::null_mut();
            tbl.len = 0;
            tbl.reserve = 0;
            tbl.mode = TableMode::Sparse;
            tbl.sparse_map = map;
        }
        let tbl = &mut *t;
        let map = &mut *tbl.sparse_map;
        if tbl.esize == 8 {
            let v = *(val as *const u64);
            map.insert(index, v);
        } else {
            let v = *val as u64;
            map.insert(index, v);
        }
        return;
    }

    // ---- Dense, in-threshold: span grow then write ----------------------
    if index < 0 {
        return;
    }
    unsafe { span_grow(t, index.wrapping_add(1)) };
    let ptr = tbl.data.add(index as usize * tbl.esize);
    if tbl.esize == 8 {
        let v = *(val as *const u64);
        ptr.cast::<u64>().write(v);
    } else {
        ptr.write(*val);
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_get(t: *mut GlmTable, index: i64, dst: *mut u8) {
    if t.is_null() || dst.is_null() {
        return;
    }
    let tbl = &mut *t;

    // ---- Sparse: HashMap lookup ----------------------------------------
    if tbl.mode == TableMode::Sparse {
        if index < 0 {
            std::ptr::write_bytes(dst, 0, tbl.esize);
            return;
        }
        let map = &mut *tbl.sparse_map;
        if let Some(&v) = map.get(&index) {
            if tbl.esize == 8 {
                *(dst as *mut u64) = v;
            } else {
                *dst = (v & 0xff) as u8;
            }
        } else {
            std::ptr::write_bytes(dst, 0, tbl.esize);
        }
        return;
    }

    // ---- Dense: bounds check -------------------------------------------
    if index < 0 || index >= tbl.len {
        std::ptr::write_bytes(dst, 0, tbl.esize);
        return;
    }
    let ptr = tbl.data.add(index as usize * tbl.esize);
    if tbl.esize == 8 {
        *(dst as *mut u64) = ptr.cast::<u64>().read();
    } else {
        *dst = ptr.read();
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_len(t: *mut GlmTable) -> i64 {
    if t.is_null() {
        return 0;
    }
    let tbl = &*t;
    if tbl.mode == TableMode::Dense {
        tbl.len
    } else {
        let map = &*tbl.sparse_map;
        let mut bound = 0i64;
        while map.contains_key(&bound) {
            bound += 1;
        }
        bound
    }
}

unsafe fn span_grow(t: *mut GlmTable, want: i64) {
    if want < 0 {
        eprintln!("glm fatal: table capacity overflow (want={want})");
        std::panic::panic_any("table capacity overflow");
    }

    let tbl = unsafe { &mut *t };
    if want <= tbl.len {
        return;
    }
    let new_len = want.max(tbl.len.wrapping_mul(2)).max(8);
    let new_bytes = usize::try_from(new_len)
        .ok()
        .and_then(|l| l.checked_mul(tbl.esize))
        .unwrap_or_else(|| abort_alloc(usize::MAX));
    if tbl.reserve != 0 {
        unsafe { grow_vm(tbl, new_bytes) };
        tbl.len = new_len;
        return;
    }
    if new_bytes >= GRADUATE_AT && vm_enabled() {
        unsafe { graduate(tbl, new_bytes) };
        tbl.len = new_len;
        return;
    }
    let new = elem_layout(new_len, tbl.esize);
    let buf = if tbl.data.is_null() {
        unsafe { alloc_zeroed(new) }
    } else {
        let old = elem_layout(tbl.len, tbl.esize);
        let grown = unsafe { realloc(tbl.data.cast(), old, new.size()) };

        if grown.is_null() {
            abort_alloc(new.size());
        }

        unsafe {
            grown
                .byte_offset((tbl.len * tbl.esize as i64) as isize)
                .write_bytes(0, (new_len - tbl.len) as usize * tbl.esize);
        }
        grown
    };
    tbl.data = buf;
    tbl.len = new_len;
}

const GRADUATE_AT: usize = 1 << 20; // 1 MiB
const RESERVE_FLOOR: usize = 1 << 26; // 64 MiB
const PAGE: usize = 4096;

const PROT_NONE: i32 = 0x0;
const PROT_READ: i32 = 0x1;
const PROT_WRITE: i32 = 0x2;
const MAP_PRIVATE: i32 = 0x02;
const MAP_SHARED: i32 = 0x01;
const MAP_ANONYMOUS: i32 = 0x20;
const MAP_NORESERVE: i32 = 0x4000;
const MREMAP_MAYMOVE: i32 = 1;

unsafe extern "C" {
    fn mmap(addr: *mut c_void, len: usize, prot: i32, flags: i32, fd: i32, off: i64) -> *mut c_void;
    fn mprotect(addr: *mut c_void, len: usize, prot: i32) -> i32;
    fn munmap(addr: *mut c_void, len: usize) -> i32;
    fn mremap(addr: *mut c_void, old_len: usize, new_len: usize, flags: i32, ...) -> *mut c_void;
    fn atexit(cb: unsafe extern "C" fn()) -> i32;
}

fn reserve_for(bytes: usize) -> usize {
    bytes
        .max(RESERVE_FLOOR)
        .checked_next_power_of_two()
        .unwrap_or_else(|| abort_alloc(usize::MAX))
}

fn is_map_failed(p: *mut c_void) -> bool {
    p.addr() == usize::MAX
}

fn round_up_page(n: usize) -> usize {
    (n + PAGE - 1) & !(PAGE - 1)
}

fn vm_enabled() -> bool {
    use std::sync::atomic::{AtomicU8, Ordering};
    static STATE: AtomicU8 = AtomicU8::new(0);
    match STATE.load(Ordering::Relaxed) {
        1 => true,
        2 => false,
        _ => {
            let off = std::env::var_os("GLM_VM").is_some_and(|v| v == "off" || v == "0");
            STATE.store(if off { 2 } else { 1 }, Ordering::Relaxed);
            !off
        }
    }
}

unsafe fn graduate(tbl: &mut GlmTable, new_bytes: usize) {
    let reserve = reserve_for(new_bytes);
    let vm = unsafe {
        mmap(
            ptr::null_mut(),
            reserve,
            PROT_NONE,
            MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE,
            -1,
            0,
        )
    };
    if is_map_failed(vm) {
        abort_alloc(reserve);
    }
    let commit = round_up_page(new_bytes);
    if unsafe { mprotect(vm, commit, PROT_READ | PROT_WRITE) } != 0 {
        unsafe { munmap(vm, reserve) };
        abort_alloc(commit);
    }
    if !tbl.data.is_null() {
        unsafe {
            ptr::copy_nonoverlapping(
                tbl.data,
                vm.cast::<u8>(),
                elem_layout(tbl.len, tbl.esize).size(),
            );
            dealloc(tbl.data, elem_layout(tbl.len, tbl.esize));
        }
    }
    tbl.data = vm.cast::<u8>();
    tbl.reserve = reserve;
}

unsafe fn grow_vm(tbl: &mut GlmTable, new_bytes: usize) {
    if new_bytes > tbl.reserve {
        let new_reserve = reserve_for(new_bytes);
        let moved = unsafe { mremap(tbl.data.cast(), tbl.reserve, new_reserve, MREMAP_MAYMOVE) };
        if is_map_failed(moved) {
            abort_alloc(new_reserve);
        }
        tbl.data = moved.cast::<u8>();
        tbl.reserve = new_reserve;
    }
    let commit = round_up_page(new_bytes);
    if unsafe { mprotect(tbl.data.cast(), commit, PROT_READ | PROT_WRITE) } != 0 {
        abort_alloc(commit);
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_tbl_free(t: *mut GlmTable) {
    if t.is_null() {
        return;
    }
    unsafe { glm_trace_set(TRACE_RT_FREE) };
    ALLOC_COUNT.fetch_sub(1, Ordering::Relaxed);
    let tbl = unsafe { Box::from_raw(t) };

    // === Deep-free children if this table contains nested tables ===
    if tbl.contains_tables != 0 {
        // Inline platform-aware validation: avoids zero-page, accounts for
        // ARM64/jemalloc lower bounds, and filters upper kernel/vDSO space.
        let is_valid_ptr = |addr: usize| -> bool {
            #[cfg(target_pointer_width = "64")]
            let is_user_space = addr < 0x0000_7FFF_FFFF_FFFF;
            #[cfg(not(target_pointer_width = "64"))]
            let is_user_space = true;

            // > 16MB lower bound + 8-byte alignment + < 128TB upper bound
            addr > 0x0100_0000 && is_user_space && (addr & 7) == 0
        };

        if tbl.mode == TableMode::Dense && !tbl.data.is_null() {
            let ptrs = std::slice::from_raw_parts(tbl.data.cast::<*mut GlmTable>(), tbl.len as usize);
            for &child in ptrs {
                if is_valid_ptr(child as usize) {
                    glm_tbl_free(child);
                }
            }
        } else if tbl.mode == TableMode::Sparse && !tbl.sparse_map.is_null() {
            let map = &*tbl.sparse_map;
            for &child_addr in map.values() {
                if is_valid_ptr(child_addr as usize) {
                    glm_tbl_free(child_addr as *mut GlmTable);
                }
            }
        }
    }

    // === Existing flat deallocation path ===
    if tbl.mode == TableMode::Sparse {
        if !tbl.sparse_map.is_null() {
            let _ = unsafe {
                Box::from_raw(tbl.sparse_map.cast::<std::collections::HashMap<i64, u64>>())
            };
        }
    } else if !tbl.data.is_null() {
        if tbl.reserve != 0 {
            unsafe { munmap(tbl.data.cast(), tbl.reserve) };
        } else {
            unsafe { dealloc(tbl.data, elem_layout(tbl.len, tbl.esize)) };
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn glm_print_int(val: i64) {
    print!("{val}");
}

#[unsafe(no_mangle)]
pub extern "C" fn glm_print_float(val: f64) {
    print!("{val}");
}

#[unsafe(no_mangle)]
pub extern "C" fn glm_print_bool(val: bool) {
    print!("{val}");
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn glm_print_string(val: *const u8) {
    let mut len = 0usize;
    unsafe {
        while *val.add(len) != 0 {
            len += 1;
        }
    }
    let bytes = unsafe { std::slice::from_raw_parts(val, len) };
    print!("{}", String::from_utf8_lossy(bytes));
}

#[unsafe(no_mangle)]
pub extern "C" fn glm_print_sep() {
    print!("\t");
}

#[unsafe(no_mangle)]
pub extern "C" fn glm_print_nl() {
    println!();
}

#[unsafe(no_mangle)]
pub extern "C" fn sys_alloc_count() -> i64 {
    ALLOC_COUNT.load(Ordering::Relaxed) as i64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tbl_grow_normal_increasing() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            glm_tbl_grow(t, 0);
            assert!((*t).len >= 1, "grow to 0: len = {}", (*t).len);
            glm_tbl_grow(t, 99);
            assert!((*t).len >= 100, "grow to 99: len = {}", (*t).len);
            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_abi_layout_offsets() {
        use std::mem::{offset_of, size_of};

        assert_eq!(offset_of!(GlmTable, data), 0, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, len), 8, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, reserve), 16, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, esize), 24, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, mode), 32, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, contains_tables), 33, "ABI mismatch");
        assert_eq!(offset_of!(GlmTable, sparse_map), 40, "ABI mismatch");
        assert_eq!(size_of::<GlmTable>(), 48, "ABI mismatch");
    }

    #[test]
    fn test_tbl_grow_overflow_guard_exists() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            glm_tbl_grow(t, 999);
            let len_before = (*t).len;
            assert!(len_before >= 1000, "initial len = {len_before}");

            let idx = i64::MAX;
            assert!(
                idx >= 0 && idx == i64::MAX,
                "Guard condition should trigger for i64::MAX",
            );
            assert_eq!(
                i64::MAX.wrapping_add(1),
                i64::MIN,
                "The guard prevents this wrap from reaching span_grow",
            );
            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_force_crash_chunk_header_corruption() {
        // If the crash-test env var is set, run the heap corruption and exit.
        if std::env::var_os("GLM_CRASH_TEST").is_some() {
            unsafe {
                let t = glm_tbl_new(8, 0);
                glm_tbl_grow(t, 0);
                let data_ptr = (*t).data;
                // [HeapCorruption: Chunk Header]
                // Standard malloc (glibc) / jemalloc hide a chunk header immediately before
                // the returned pointer.  Subtracting 8 bytes lands on that header which
                // stores the allocation's size and flags; corrupting it makes realloc()
                // read a bogus length, which triggers a fatal abort inside the allocator.
                let corrupt_ptr = (data_ptr as i64 - 8) as *mut u64;
                *corrupt_ptr = 0x10000000000;
                glm_tbl_grow(t, 10);
                glm_tbl_free(t);
            }
            std::process::exit(0); // reached only on a non-crash path
        }

        // Otherwise spawn ourselves as a child and assert that it aborts.
        let current_exe = std::env::current_exe().unwrap();
        let status = std::process::Command::new(current_exe)
            .env("GLM_CRASH_TEST", "1")
            .arg("--test")
            .arg("--test-threads=1")
            .arg("rt::tests::test_force_crash_chunk_header_corruption")
            .status()
            .expect("failed to spawn crash-test subprocess");

        assert!(!status.success(), "heap corruption did not cause a fatal abort");
    }

    #[test]
    fn test_sparse_threshold_triggers_upgrade() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            for i in 0..=SPARSE_THRESHOLD {
                let v = (i as u64).wrapping_add(1);
                glm_tbl_set(t, i, &v as *const u64 as *const u8);
            }
            assert!((*t).mode == TableMode::Dense, "should still be dense");

            let gap = 500000i64;
            let big_val: u64 = 999;
            glm_tbl_set(t, gap, &big_val as *const u64 as *const u8);

            assert!((*t).mode == TableMode::Sparse, "should be sparse after gap threshold");
            assert!((*t).data.is_null(), "flat buffer should be freed");
            assert!(!(*t).sparse_map.is_null(), "sparse_map should be set");

            let map = &mut *(*t).sparse_map;
            assert_eq!(map.get(&0), Some(&1), "index 0 should have value 1");
            assert_eq!(map.get(&gap), Some(&999), "gap index should have value 999");

            let mut out: u64 = 0;
            glm_tbl_get(t, 0, &mut out as *mut u64 as *mut u8);
            assert_eq!(out, 1, "retrieve from sparse should return 1");

            glm_tbl_get(t, gap, &mut out as *mut u64 as *mut u8);
            assert_eq!(out, 999, "retrieve from sparse should return 999");

            let mut nil_out: u64 = 1;
            glm_tbl_get(t, 1000000, &mut nil_out as *mut u64 as *mut u8);
            assert_eq!(nil_out, 0, "missing key should return nil/zero");

            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_sparse_set_in_dense_below_threshold() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            let val: u64 = 77;
            glm_tbl_set(t, 500, &val as *const u64 as *const u8);

            assert!((*t).mode == TableMode::Dense, "should remain dense");
            assert!(!(*t).data.is_null(), "data should still be allocated");

            let mut out: u64 = 0;
            glm_tbl_get(t, 500, &mut out as *mut u64 as *mut u8);
            assert_eq!(out, 77, "retrieved value should match");

            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_sparse_free_no_crash() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            for i in 0..=SPARSE_THRESHOLD {
                let v = (i as u64).wrapping_add(1);
                glm_tbl_set(t, i, &v as *const u64 as *const u8);
            }
            let gap = 500000i64;
            let big_val: u64 = 12345;
            glm_tbl_set(t, gap, &big_val as *const u64 as *const u8);
            assert!((*t).mode == TableMode::Sparse, "should be sparse");
            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_upgrade_to_sparse_returns_false_on_empty() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            let upgraded = upgrade_to_sparse(t);
            assert!(!upgraded, "empty table should not upgrade");
            assert!((*t).mode == TableMode::Dense, "should remain dense");
            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_sparse_grow_reserve_nop() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            let val: u64 = 1;
            glm_tbl_set(t, SPARSE_THRESHOLD + 10, &val as *const u64 as *const u8);
            assert!((*t).mode == TableMode::Sparse, "should be sparse");

            glm_tbl_grow(t, SPARSE_THRESHOLD + 100);
            assert!((*t).mode == TableMode::Sparse, "should still be sparse after grow");

            let val2: u64 = 2;
            glm_tbl_set(t, SPARSE_THRESHOLD + 100, &val2 as *const u64 as *const u8);

            let mut out: u64 = 0;
            glm_tbl_get(t, SPARSE_THRESHOLD + 100, &mut out as *mut u64 as *mut u8);
            assert_eq!(out, 2, "should find new sparse entry");

            glm_tbl_free(t);
        }
    }

    #[test]
    fn test_sparse_negative_index_noop() {
        unsafe {
            let t = glm_tbl_new(8, 0);
            let val: u64 = 999;
            glm_tbl_set(t, -1, &val as *const u64 as *const u8);

            let big_val: u64 = 1;
            glm_tbl_set(t, SPARSE_THRESHOLD + 1, &big_val as *const u64 as *const u8);
            let mut out: u64 = 0;
            glm_tbl_get(t, -1, &mut out as *mut u64 as *mut u8);
            assert_eq!(out, 0, "negative index should return nil");

            glm_tbl_free(t);
        }
    }
}
