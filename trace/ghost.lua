-- the leak repro: bare decl, redecl, nil release — 60 must now answer 50
local ghost
local ghost = {}
ghost = nil
print(sys_alloc_count())
