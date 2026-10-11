use anyhow::{bail, ensure, Context, Result};
use risc0_zkvm::{default_prover, ExecutorEnv, InnerReceipt, Receipt};
use zkbounty_claims::{evaluate, Claim, Witness};
use zkbounty_methods::{COUNTEREXAMPLE_ELF, COUNTEREXAMPLE_ID};

fn id(s: &str) -> Result<[u8; 32]> {
    hex::decode(s)?
        .try_into()
        .map_err(|_| anyhow::anyhow!("ID must be 32 bytes"))
}
fn verify(receipt: &Receipt, bounty: [u8; 32], claimant: [u8; 32]) -> Result<Claim> {
    ensure!(
        !matches!(receipt.inner, InnerReceipt::Fake(_)),
        "development receipt rejected"
    );
    receipt.verify(COUNTEREXAMPLE_ID)?;
    let claim: Claim = receipt.journal.decode()?;
    ensure!(
        claim.schema == 1 && claim.bounty == bounty && claim.claimant == claimant,
        "receipt does not match expected bounty/claimant/schema"
    );
    // Target ID is pinned by the guest; accepting an arbitrary host-provided image is forbidden.
    Ok(claim)
}
fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(String::as_str) {
        Some("prove") if args.len() == 4 => {
            ensure!(std::env::var("RISC0_DEV_MODE").unwrap_or_default().is_empty()
                || std::env::var("RISC0_DEV_MODE").unwrap_or_default() == "0",
                "unset RISC0_DEV_MODE for real proofs");
            let witness: Witness = serde_json::from_slice(&std::fs::read(&args[2])?)?;
            let expected = evaluate(&witness).map_err(anyhow::Error::msg)?;
            let env = ExecutorEnv::builder().write(&witness)?.build()?;
            let result = default_prover().prove(env, COUNTEREXAMPLE_ELF)?;
            let claim = verify(&result.receipt, witness.bounty, witness.claimant)?;
            ensure!(claim == expected, "unexpected guest result");
            std::fs::write(&args[3], serde_json::to_vec(&result.receipt)?)
                .context("write receipt")?;
            println!("{}", serde_json::to_string_pretty(&claim)?);
        }
        Some("verify") if args.len() == 5 => {
            let receipt: Receipt = serde_json::from_slice(&std::fs::read(&args[2])?)?;
            let claim = verify(&receipt, id(&args[3])?, id(&args[4])?)?;
            println!("{}", serde_json::to_string_pretty(&claim)?);
        }
        _ => bail!("usage: zkbounty-host prove WITNESS.json RECEIPT.json | verify RECEIPT.json BOUNTY_HEX CLAIMANT_HEX"),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use risc0_zkvm::{FakeReceipt, ReceiptClaim};

    #[test]
    fn explicitly_rejects_fake_receipts() {
        let receipt = Receipt::new(
            InnerReceipt::Fake(FakeReceipt::new(ReceiptClaim::ok(
                COUNTEREXAMPLE_ID,
                Vec::<u8>::new(),
            ))),
            vec![],
        );
        let error = verify(&receipt, [1; 32], [2; 32]).unwrap_err();
        assert!(error.to_string().contains("development receipt rejected"));
    }
}
