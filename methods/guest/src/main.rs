#![no_main]
#![no_std]
use risc0_zkvm::guest::env;
use zkbounty_claims::{evaluate, Witness};
risc0_zkvm::guest::entry!(main);
fn main() {
    let witness: Witness = env::read();
    let claim = evaluate(&witness).expect("invalid counterexample");
    env::commit(&claim);
}
