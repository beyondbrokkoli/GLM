-- EXPECT: hello	world	8
-- EXPECT: world
-- Pillar 8: string tables — cells are C-string pointers, one word
-- like int/float cells. Unwritten cells are null pointers: '#t' and
-- stores are fine, but printing or comparing one is not (that is why
-- the fuzzer never prints unwritten string cells).
local s = {}
s[0] = "hello"
s[1] = "world"
print(s[0], s[1], #s)
local u = s
print(u[1])
