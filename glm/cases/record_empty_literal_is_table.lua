-- EXPECT: 10
-- {} parses as an empty ARRAY table, never a record: the record
-- grammar needs Identifier ':' lookahead, which empty braces lack
-- (src/parser.rs:359-367).
local t = {}
t[0] = 10
print(t[0])
