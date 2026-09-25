# Run the benchmark to confirm performance
touch src/main.rs && cargo build --release && ./target/release/glm glm/main.lua
./measure.sh ./glm_out
