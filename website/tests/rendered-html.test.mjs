import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const templateRoot = new URL("../", import.meta.url);

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("server-renders the Room landing page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>Room — See what’s full\. Make room\.<\/title>/i);
  assert.match(html, /Know what’s full/);
  assert.match(html, /Memory Pressure/);
  assert.match(html, /Nothing happens/);
  assert.match(html, /brew install --cask takeshita-0x0201\/tap\/room/);
  assert.match(html, /https:\/\/github\.com\/takeshita-0x0201\/room\/releases/);
});

test("ships final metadata, assets, and no starter preview", async () => {
  const [css, page, layout, packageJson] = await Promise.all([
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
  ]);

  assert.match(packageJson, /"name": "room-landing-page"/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);
  assert.match(css, /prefers-reduced-motion:\s*reduce/);
  assert.match(css, /@media\(max-width:600px\)/);
  assert.match(layout, /openGraph/);
  assert.match(layout, /\/og\.png/);
  assert.match(page, /aria-label="Main navigation"/);
  assert.doesNotMatch(page, /SkeletonPreview|codex-preview/);
  await access(new URL("public/og.png", templateRoot));
  await access(new URL("public/room-app-icon.png", templateRoot));
  await assert.rejects(access(new URL("app/_sites-preview", templateRoot)));
});
