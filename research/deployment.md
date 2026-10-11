# Static project site

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
404 handling and static response headers. No custom domain is configured.

Cloudflare Workers Builds should connect `pierce403/zkbounty`, production branch
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
- Native Git publication and public checks are pending.

The restricted shell cannot bind localhost or spawn all build subprocesses;
the build dry run and local preview succeeded outside that process sandbox.
The existing Wrangler OAuth token returned HTTP 403, so the authenticated
Cloudflare dashboard is used for the Git integration. No token values were printed.

## Source documentation

- [Workers Static Assets setup](https://developers.cloudflare.com/workers/static-assets/get-started/)
- [Workers Builds](https://developers.cloudflare.com/workers/ci-cd/builds/)
