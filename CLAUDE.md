# kwekuaboagye.me

Personal portfolio site. A static Bootstrap template (BootstrapMade) wrapped in
a thin Jekyll layer, deployed by GitHub Pages from `main` to the custom domain
in `CNAME`.

## Layout

- `index.html` — the whole single-page site: hero, About, Experience, Projects,
  Contact. Its only Jekyll content is the `permalink: /` front matter; there are
  no Liquid tags anywhere in it.
- `projects-details/*.html` — one standalone page per project. Plain HTML, no
  front matter.
- `assets/css/style.css` — all custom styling.
- `assets/js/main.js` — nav, scroll animations, project filtering.
- `assets/vendor/**` — third-party libraries. Do not edit these; they are
  vendored copies.
- `*.bak` files are old snapshots kept alongside the real files. Never edit a
  `.bak`, and never let one shadow the change you were asked to make.

## Look at the UI before and after visual changes

This site is a visual artifact, so do not change styling or markup blind.
Render it and actually look at it — both before, to see what you are changing,
and after, to confirm the change landed and broke nothing:

    ./scripts/preview.sh                                            # home page
    ./scripts/preview.sh /projects-details/flix-projects-details.html

That serves the site locally and writes `desktop.png` (1440x900) and
`mobile.png` (390x844) to `/tmp/portfolio-shots/`. Read both images.

Always check mobile. The template is responsive, the nav collapses to a
hamburger under 992px, and the hero image reflows — a change that looks right
at 1440px regularly breaks at 390px.

For a single custom shot:

    node scripts/shot.mjs http://127.0.0.1:4321/ /tmp/out.png 768 1024

Notes:

- `preview.sh` prefers `bundle exec jekyll serve` for exact fidelity. If Jekyll
  is not installed it falls back to `python3 -m http.server`, which renders
  everything correctly except that `index.html`'s front matter appears as stray
  `--- permalink: / ---` text at the top of the page. That artifact is from the
  fallback server, not a bug in the page — do not "fix" it.
- Screenshots go to `/tmp`, never into the repo.
- In Claude Code web sessions, Chromium and Playwright are preinstalled and the
  live site at https://kwekuaboagye.me is unreachable (blocked by the sandbox
  network policy). Always render locally rather than fetching production.

## Deploying

Pushing to `main` publishes. There is no build step to run and no CI, so a
mistake goes straight to the live site — hence the screenshot check above.
