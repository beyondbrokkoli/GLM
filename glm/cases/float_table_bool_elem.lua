-- EXPECT: true	false	false	8
-- EXPECT: false	true
-- Pillar 7: bool tables — byte-packed cells (the pillars charter;
-- bitpacking would force read-modify-write stores). '{true, false}'
-- is the typed constructor; the growth zero reads 'false'.
local t = {true, false}
print(t[0], t[1], t[2], #t)
local i = 0
while i < 5 do
    t[i] = not t[i]
    i = i + 1
end
print(t[0], t[3])
