
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
    for res in lexer::Token::lexer(&source) {
        tokens.push(res.expect("Lexer error"));
    }

    let ast = parser::Parser::new(tokens).parse_program();

    // 1. Build the shared context ONCE
    let ctx = analysis::build_context(&ast);

    // 2. Pass the context instead of the raw AST
    let mut shape = shape::analyze(&ctx);

    let mut checker = type_checker::TypeChecker::new(&mut shape);
    checker.check_program(&ast);

    let ir_program = lowerer::IrLowerer::new(&shape).lower_program(&ast);

    let llvm_ir = backend::generate_llvm_ir(&ir_program);
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
