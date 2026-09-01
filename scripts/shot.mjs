#!/usr/bin/env node
// Screenshot a page so Claude (or you) can look at it.
//
//   node scripts/shot.mjs <url> <out.png> [width] [height]
//
// Example:
//   node scripts/shot.mjs http://127.0.0.1:4321/ /tmp/desktop.png 1440 900
//
// Needs Playwright. Claude Code web sessions have it preinstalled globally;
// locally, `npm install -g playwright && npx playwright install chromium`.

import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';

async function loadPlaywright() {
  try {
    const mod = await import('playwright');
    return mod.default ?? mod;
  } catch {
    // Fall back to a global install, which bare ESM specifiers do not resolve.
    const root = execSync('npm root -g', { encoding: 'utf8' }).trim();
    return createRequire(import.meta.url)(`${root}/playwright`);
  }
}

const [url, out, width = '1440', height = '900'] = process.argv.slice(2);

if (!url || !out) {
  console.error('usage: node scripts/shot.mjs <url> <out.png> [width] [height]');
  process.exit(1);
}

const w = Number(width);
const h = Number(height);
if (!Number.isFinite(w) || !Number.isFinite(h) || w <= 0 || h <= 0) {
  console.error(`invalid viewport "${width}x${height}": width and height must be positive numbers`);
  process.exit(1);
}

const { chromium } = await loadPlaywright();
const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  // The template animates sections in on scroll; settle before capturing.
  await page.waitForTimeout(500);
  await page.screenshot({ path: out, fullPage: true });
} finally {
  // Otherwise a failed navigation leaves an orphaned Chromium behind.
  await browser.close();
}

console.log(`wrote ${out} (${w}x${h})`);
