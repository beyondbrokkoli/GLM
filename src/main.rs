// src/main.rs
use logos::Logos;

mod analysis;
mod ast;
mod backend;
mod ir;
mod lexer;
mod lowerer;
mod parser;
mod shape;
mod type_checker;

fn main() {
    // GLM_TRACE setup: map the full plate — classic sections plus the
    // chronology section (header + 8192-event ring, 49,928 bytes total) —
    // and stamp the header: global_seq 0, ring capacity. Best-effort: any
    // failure leaves the map null and tracing degrades silently, never
    // fatally.
    glm_rt::trace::compiler_trace_init();

    // GLM_TRACE pass A: the plate is never truncated, so zero the
    // high-half counter region (bytes 128..256) once per run — per-run
    // occurrence counts start from 0 while the sticky low-half
    // booleans (slot 0/1 build status included) are left untouched.
    glm_rt::trace::compiler_trace_reset_counts();
    // GLM_TRACE pass A, scope sections: zero the per-run scope histogram
    // and directory (bytes 256..) the same way — WHERE each signal fired
    // this run, for the scope-drift shadow.
    glm_rt::trace::compiler_trace_scope_reset();

    // GLM_TRACE bracket: any compile panic records slot 1
    // (EXPECT_BUILD_FAIL) before the abort — write_at is already on
    // disk, so no unwind/catch is needed even with panic=abort. The
    // default hook is chained so stderr keeps its exact corpus-pinned
    // format. Slot 0 marks the full compile+link success.
    let default_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
        eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
        default_hook(info);
    }));

    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        panic!("Usage: glm <file.lua>");
    }
    let source_path = &args[1];
    let source = std::fs::read_to_string(source_path).expect("Failed to read source");

    let mut tokens = Vec::new();
    let mut front_diagnostics = Vec::new();
    for res in lexer::Token::lexer(&source) {
        match res {
            Ok(token) => tokens.push(token),
            Err(_) => {
                front_diagnostics.push("Syntax Error: Lexer error".to_string());
                break; // Bail lexing on first unrecognized token
            }
        }
    }

    let mut parser = parser::Parser::new(tokens);
    let ast = parser.parse_program();
    front_diagnostics.extend(parser.diagnostics);

    // Gate 0: Front-End (Lexer & Parser)
    // Passes strictly dependent: abort gracefully if the syntax is broken
    // before we build the context or run the analyzer.
    if !front_diagnostics.is_empty() {
        for d in &front_diagnostics {
            eprintln!("{d}");
        }
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
        eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
        std::process::exit(1);
    }

    // 1. Build the shared context ONCE
    let ctx = analysis::build_context(&ast);

    // 2. Pass the context instead of the raw AST
    let mut shape = shape::analyze(&ctx);

    // Ghost run: the shape walk always completes — poisoned blocks bail
    // to their own boundary (GHOST_BAIL on the plate marks exactly where)
    // and their errors land in this ledger. Report it and fail the build
    // without aborting, so the full plate survives for plate.py diffing.
    // The slot-1 poke + stderr marker mirror the panic hook's contract.
    if !shape.diagnostics.is_empty() {
        for d in &shape.diagnostics {
            eprintln!("{d}");
        }
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
        eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
        std::process::exit(1);
    }

    let mut checker = type_checker::TypeChecker::new(&mut shape);
    checker.check_program(&ast);

    // Second gate, same contract as the shape gate above: the Type
    // Checker's ghost run ledgered its poisoned blocks instead of
    // panicking. Report and fail before the lowerer — it consumes the
    // checked types (LayoutVerdict, resolved StaticTypes) and cannot run
    // on blocks the checker never finished. Passes are strictly
    // dependent: each gate only runs when the previous ledger is empty.
    if !shape.diagnostics.is_empty() {
        for d in &shape.diagnostics {
            eprintln!("{d}");
        }
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
        eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
        std::process::exit(1);
    }

    let mut ir_lowerer = lowerer::IrLowerer::new(&shape);
    let ir_program = ir_lowerer.lower_program(&ast);

    // Gate 3: Lowerer
    // Passes are strictly dependent: abort gracefully if the lowerer
    // hit an undefined variable or structural issue before generating LLVM IR.
    if !ir_lowerer.diagnostics.is_empty() {
        for d in &ir_lowerer.diagnostics {
            eprintln!("{d}");
        }
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
        eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
        std::process::exit(1);
    }

    // Gate 4: Backend
    // Passes are strictly dependent: abort gracefully if the emitter's
    // ledger caught a semantic rejection (print of a table or record) or
    // an internal invariant breach, instead of panicking. Same contract
    // as every gate above; the panic hook remains as the backstop.
    let llvm_ir = match backend::generate_llvm_ir(&ir_program) {
        Ok(ir) => ir,
        Err(diagnostics) => {
            for d in &diagnostics {
                eprintln!("{d}");
            }
            glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_BUILD_FAIL);
            eprintln!("GLM_TRACE: slot 1 — build failed (EXPECT_BUILD_FAIL)");
            std::process::exit(1);
        }
    };
    std::fs::write("out.ll", llvm_ir).expect("Failed to write out.ll");

    let profile = if cfg!(debug_assertions) {
        "debug"
    } else {
        "release"
    };
    let runtime = format!(
        "{}/target/{}/libglm_rt.a",
        env!("CARGO_MANIFEST_DIR"),
        profile
    );

    let status = std::process::Command::new("clang")
        .arg("-O3")
        .arg("out.ll")
        .arg(&runtime)
        .arg("-lpthread")
        .arg("-ldl")
        .arg("-lm")
        .arg("-o")
        .arg("glm_out")
        .status()
        .expect("Failed to execute clang");

    if status.success() {
        println!("Success! Executable written to ./glm_out");
        glm_rt::trace::compiler_trace_set(glm_rt::trace::TRACE_COMPILED);
        eprintln!("GLM_TRACE: slot 0 — compiled ok");
    } else {
        panic!("Clang failed to assemble and link the executable.");
    }
}
