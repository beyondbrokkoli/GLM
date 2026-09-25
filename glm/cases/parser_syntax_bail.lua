-- EXPECT_BUILD_FAIL: Syntax Error: Expected expression
-- Gate 0 (parser) proof of concept: the statement below opens an
-- expression it never completes. parse_program catches the ParseError,
-- ledgeres it, fires GHOST_BAIL_PARSER (slot 69, scope 0 — the program
-- root) and bails the rest of the file; Gate 0 then fails the build
-- before the shape analyzer runs. Nothing here may panic.
local x =
