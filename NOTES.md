# Working notes

## October 11, 2026: Cloudflare project overview

Dean requested a static HTML site describing zkbounty. The public site summarizes
the existing prototype and research without adding a proving service. Static
HTML/CSS and native Cloudflare Git deployment keep this addition small.

Implementation and verification: [deployment record](research/deployment.md).
Research validation remains in [research/validation.md](research/validation.md).

The first native Cloudflare build succeeded. Public HTML/CSS/favicon hashes matched
source, deployment identity matched main, and custom 404/header checks passed.
Proving remains in the local CLI. A recovery stash preserves the site contribution
before the local checkout was fast-forwarded to its connector-published commit.

## October 12, 2026: Registered domain routing

The owner reactivated zkbounty.org and requested DNS setup. Preserved the renewed
registrar's eight DNS values in Cloudflare, proxied apex/www, and saved the zone's
assigned cash/hope nameservers at Namecheap. Tracked apex/www routes ensure native
Git deployments retain domain serving. Activation, certificate and public checks
are recorded separately in the cloudflare-migrations project; route configuration
alone does not prove public availability.
