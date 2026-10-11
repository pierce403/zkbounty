//! A deliberately small missing-binding model, NOT the Orchard circuit.
#![no_std]
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const TARGET: &str = "zkbounty/missing-binding-model/v1";
pub const MODULUS: u32 = 97;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Witness {
    pub bounty: [u8; 32],
    pub claimant: [u8; 32],
    pub base: u32,
    pub loop_base: u32,
    pub scalar: u32,
    pub output: u32,
    pub salt: [u8; 32],
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Claim {
    pub schema: u32,
    pub target_digest: [u8; 32],
    pub bounty: [u8; 32],
    pub claimant: [u8; 32],
    pub evidence_commitment: [u8; 32],
}

/// The verifier is fixed in the image: host input cannot choose its target predicate.
pub fn evaluate(w: &Witness) -> Result<Claim, &'static str> {
    if [w.base, w.loop_base, w.scalar, w.output]
        .iter()
        .any(|x| *x >= MODULUS)
    {
        return Err("noncanonical field element");
    }
    if w.scalar == 0 || w.base == 0 || w.loop_base == 0 {
        return Err("degenerate example");
    }
    let vulnerable_accepts = (w.scalar * w.loop_base) % MODULUS == w.output;
    let intended_accepts = (w.scalar * w.base) % MODULUS == w.output;
    if !vulnerable_accepts || intended_accepts || w.base == w.loop_base {
        return Err("not a counterexample");
    }
    let target_digest: [u8; 32] = Sha256::digest(TARGET.as_bytes()).into();
    let mut hash = Sha256::new();
    hash.update(b"zkbounty/evidence/v1\0");
    hash.update(target_digest);
    hash.update(w.bounty);
    hash.update(w.claimant);
    for x in [w.base, w.loop_base, w.scalar, w.output] {
        hash.update(x.to_le_bytes());
    }
    hash.update(w.salt);
    Ok(Claim {
        schema: 1,
        target_digest,
        bounty: w.bounty,
        claimant: w.claimant,
        evidence_commitment: hash.finalize().into(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    fn example() -> Witness {
        Witness {
            bounty: [1; 32],
            claimant: [2; 32],
            base: 5,
            loop_base: 9,
            scalar: 7,
            output: 63,
            salt: [3; 32],
        }
    }
    #[test]
    fn accepts_counterexample_rejects_honest_and_invalid() {
        assert!(evaluate(&example()).is_ok());
        let mut w = example();
        w.loop_base = w.base;
        w.output = 35;
        assert!(evaluate(&w).is_err());
        w = example();
        w.output = 62;
        assert!(evaluate(&w).is_err());
        w = example();
        w.base += MODULUS;
        assert!(evaluate(&w).is_err());
        w = example();
        w.scalar = 0;
        w.output = 0;
        assert!(evaluate(&w).is_err());
    }
    #[test]
    fn commitment_binds_context_and_salt() {
        let w = example();
        let c = evaluate(&w).unwrap();
        let mut other = w.clone();
        other.bounty[0] ^= 1;
        assert_ne!(
            c.evidence_commitment,
            evaluate(&other).unwrap().evidence_commitment
        );
        other = w.clone();
        other.claimant[0] ^= 1;
        assert_ne!(
            c.evidence_commitment,
            evaluate(&other).unwrap().evidence_commitment
        );
        other = w;
        other.salt[0] ^= 1;
        assert_ne!(
            c.evidence_commitment,
            evaluate(&other).unwrap().evidence_commitment
        );
    }
}
