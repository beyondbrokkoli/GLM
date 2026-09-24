-- EXPECT: survived double nil
-- A second 'x = nil' re-drops an already-dropped reference: the
-- lifetime pass sees the name bound to null only, emits no free, and
-- the old double-free segfault is a plain no-op. (Probe 1 of the UB
-- series, now defined.)
local t = {}
t[0] = 41
t = nil
t = nil
print("survived double nil")
