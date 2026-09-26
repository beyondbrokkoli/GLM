-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
-- A bare `local t` is nil-valued (NULL_ROOT alias at the shape layer),
-- so table stores through it hit the possibly-nil lifetime guard — the
-- same rejection as use-after-drop, not an "Undeclared variable".
local t
t[0] = 1
