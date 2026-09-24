// g++ -O3 -march=native -DNDEBUG -g1 -masm=intel -fverbose-asm -fno-exceptions -fno-rtti -save-temps=obj cpp/race.cpp -o target/race_cpp

#include <cstdint>
#include <iostream>
#include <vector>

static volatile std::int64_t witness_sink = 0;

// Emulates Phia's Rust codegen for Lua modulo exactly
inline std::int64_t lua_mod(std::int64_t left, std::int64_t right) {
    std::int64_t rem = left % right;
    // Equivalent to: rem + i64::from(rem != 0 && (rem < 0) != (right < 0)) * right
    return rem + static_cast<std::int64_t>(rem != 0 && (rem < 0) != (right < 0)) * right;
}

int main() {
    constexpr std::int64_t N = 10000000;
    constexpr std::int64_t ROUNDS = 100;
    constexpr std::int64_t MOD = 1000000007LL;

    constexpr std::int64_t A = 48271;
    constexpr std::int64_t B = 69621;
    constexpr std::int64_t C = 31337;

    std::vector<std::int64_t> x(N);
    std::vector<std::int64_t> y(N);
    std::vector<std::int64_t> z(N);

    // Initialization
    for (std::int64_t i = 0; i < N; ++i) {
        x[i] = lua_mod(i * 17 + 23, MOD);
        y[i] = lua_mod(i * 31 + 71, MOD);
        z[i] = lua_mod(i * 43 + 113, MOD);
    }

    for (std::int64_t round = 0; round < ROUNDS; ++round) {
        for (std::int64_t i = 0; i < N; ++i) {
            const std::int64_t aa = A;
            const std::int64_t bb = B;
            const std::int64_t cc = C;
            const std::int64_t modulus = MOD;

            const std::int64_t vx = x[i];
            const std::int64_t vy = y[i];
            const std::int64_t vz = z[i];

            const std::int64_t next_x = lua_mod(vx * aa + vy * bb + vz * cc, modulus);
            const std::int64_t next_y = lua_mod(vy * aa + vz * bb + vx * cc, modulus);
            const std::int64_t next_z = lua_mod(vz * aa + vx * bb + vy * cc, modulus);

            x[i] = next_x;
            y[i] = next_y;
            z[i] = next_z;
        }
    }

    // Witness.
    std::int64_t witness = 0;
    for (std::int64_t i = 0; i < N; ++i) {
        witness = lua_mod(witness + x[i], MOD);
        witness = lua_mod(witness + y[i], MOD);
        witness = lua_mod(witness + z[i], MOD);
    }

    witness_sink = witness;
    std::cout << "witness " << witness_sink << '\n';

    return 0;
}
