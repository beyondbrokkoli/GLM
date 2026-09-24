-- EXPECT: loop drop ok
-- A drop inside a loop is a conditional free: trip 1 holds the sole
-- live reference and frees for real; trips 2+ reach the free site with
-- the reference already dropped. The one branch conditionality needs
-- lives inside the cold glm_tbl_free (null operand = no-op) — the
-- loop body itself carries no check.
local t = {}
t[0] = 41
local i = 0
while i < 3 do
    t = nil
    i = i + 1
end
print("loop drop ok")
