local N = 10000000
local ROUNDS = 100

local MOD = 1000000007

-- Loop-invariant constants.
local A = 48271
local B = 69621
local C = 31337

local x = {}
local y = {}
local z = {}

local i = 0

-- Initialization
while i < N do
    x[i] = (i * 17 + 23) % MOD
    y[i] = (i * 31 + 71) % MOD
    z[i] = (i * 43 + 113) % MOD

    i = i + 1
end


local round = 0

while round < ROUNDS do

    i = 0

    while i < N do

        -- Intentionally keep invariant-looking values inside
        -- the hot loop. This is useful for testing LICM / hoisting.
        local aa = A
        local bb = B
        local cc = C
        local modulus = MOD

        local vx = x[i]
        local vy = y[i]
        local vz = z[i]

        local next_x = (vx * aa + vy * bb + vz * cc) % modulus
        local next_y = (vy * aa + vz * bb + vx * cc) % modulus
        local next_z = (vz * aa + vx * bb + vy * cc) % modulus

        x[i] = next_x
        y[i] = next_y
        z[i] = next_z

        i = i + 1
    end

    round = round + 1
end


-- Witness.

local witness = 0

i = 0

while i < N do
    witness = (witness + x[i]) % MOD
    witness = (witness + y[i]) % MOD
    witness = (witness + z[i]) % MOD

    i = i + 1
end

print("witness", witness)
