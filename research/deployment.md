# Static project site

Production domain: <https://zkbounty.org/> (with `www.zkbounty.org` also routed).
Worker URL: <https://zkbounty.bcrt43.workers.dev/>.

The website describes the current research lab. It uses handwritten HTML/CSS,
with no client JavaScript, witness intake, wallet, or hosted proving service.
The local Rust/RISC Zero workflow is unchanged.

## Build and publish

Node.js 22+ and the pinned npm lockfile are required. Wrangler is pinned to 4.149.0.

```sh
npm ci
npm run build
npm run check:deploy
```

`scripts/build-site.mjs` copies only `site/` into `dist/` and writes
`deployment.json` with the Git revision. Local artifacts, witnesses, and credentials
are never copied. Cloudflare Workers Static Assets serves `dist/`, with custom
404 handling and static response headers. Tracked ordinary Worker routes cover
`zkbounty.org/*` and `www.zkbounty.org/*`. The zone keeps its original website
records proxied; static assets and the custom 404 page answer these requests.
Cloudflare manages HTTPS. Domain activation and public verification are recorded
in the local cloudflare-migrations coordination project.

Cloudflare Workers Builds connects `pierce403/zkbounty`, production branch
`main`, root `/`, build command `npm run build`, and deploy command
`npx wrangler deploy`. Credentials stay in Cloudflare. Changes go directly to main;
do not add a GitHub Actions deployment or overlap a native build with a local deploy.

For a local preview, use `npm run dev`. `npm run deploy` exists for a deliberate
manual recovery deployment after confirming no native build is running.

## Verification record: October 11, 2026

- Installed pinned Wrangler; npm reported no dependency vulnerabilities.
- `npm run build`: passed.
- `npm run check:deploy`: passed, six public assets packaged.
- Local browser rendered the project overview, public arithmetic example,
  research links, and open milestones.
- Cloudflare dashboard is authenticated to the existing account. No existing
  project named `zkbounty` was found.
- Initial native Git build
  [`bfb2635c-75de-4e72-9842-927ef78f8296`](https://dash.cloudflare.com/b6d1478423f0bb0c0477df387305e46b/workers/services/view/zkbounty/production/builds/bfb2635c-75de-4e72-9842-927ef78f8296)
  completed in 21 seconds, deploying source commit
  `3fb1d3411df8294647a2a56a0cf0c5f0370492ad` as Worker version
  `60336ded-138b-43ca-b8ab-7ebddabb6998`.
- Dashboard settings confirm production branch `main`, builds enabled, root `/`,
  and the commands above. Reused the existing general Workers Builds token;
  no new token or GitHub secret was created. Default preview builds remain enabled.
- Public HTTPS checks returned 200 for HTML, CSS, favicon, and deployment metadata;
  served HTML/CSS/favicon bytes exactly matched source. The metadata identified
  the deployed source commit, with `Cache-Control: no-store`.
- Unknown URLs, `/fixtures/model.json`, and `/artifacts/receipt.json` returned the
  custom 404 page. CSP and `nosniff` headers were present on every checked response.
- Desktop and mobile live browser rendering passed. Mobile layout had equal
  document and scroll widths (375 CSS pixels); the prototype anchor navigated
  correctly. The Codex browser showed no warning or error logs.
- Public HTTP response evidence is saved in [site-checks.json](site-checks.json).
  A live desktop screenshot is retained locally in ignored `artifacts/live-site.jpg`.

The restricted shell cannot bind localhost or spawn all build subprocesses;
the build dry run and local preview succeeded outside that process sandbox.
The existing Wrangler OAuth token returned HTTP 403, so the authenticated
Cloudflare dashboard is used for the Git integration. No token values were printed.

Python urllib initially received HTTP 403; curl and the browser independently
served the expected HTTPS content. Verification uses the successful curl path.
Automatic approval review blocked disabling preview builds as an unauthorized
persistent setting change, so defaults were retained. It also blocked a local
Git reset; a recovery stash and fast-forward merge synchronized the checkout
without dropping working files or rewriting history.

## Historical pilot status publication

The static page reports only the reproduced circuit proofs, confirmed
ordinary historical-node baseline, and locally tested escrow. It labels the
same-note transaction replay, full RISC Zero exploit receipt, and Sepolia
payout incomplete. The page links the original advisory and repository
evidence. Continue using native Git deployment from `main`; compare the public
`/deployment.json` revision with the published commit and check both the
Worker URL and production domain after the build reaches the live site.

## Source documentation

- [Workers Static Assets setup](https://developers.cloudflare.com/workers/static-assets/get-started/)
- [Workers Builds](https://developers.cloudflare.com/workers/ci-cd/builds/)
