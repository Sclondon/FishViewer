// Checks the web build in Chrome at a phone size (360x780, touch): serves build/ on a fresh port, loads the page,
// taps two kinds in the list, then loads ?add=<kinds> for a few more shapes; saves stills and prints the time to
// the first picture and every console error.
//   node tests/web_check.js <out dir>
const { chromium } = require('C:/Projects/scareathon/trailer/node_modules/playwright-core');
const http = require('http');
const fs = require('fs');
const path = require('path');

const out = process.argv[2] || 'tests/shots_web';
fs.mkdirSync(out, { recursive: true });
const root = path.join(__dirname, '..', 'build');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const server = http.createServer((req, res) => {
	const file = path.join(root, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
	if (!file.startsWith(root) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
	res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
	fs.createReadStream(file).pipe(res);
});

(async () => {
	await new Promise((r) => server.listen(0, r));
	const port = server.address().port;
	const profile = fs.mkdtempSync(path.join(require('os').tmpdir(), 'fishview-'));
	const ctx = await chromium.launchPersistentContext(profile, {
		executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
		headless: true,
		viewport: { width: 360, height: 780 },
		hasTouch: true,
		isMobile: true,
		deviceScaleFactor: 2,
		args: ['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist', '--mute-audio'],
	});
	const errors = [];
	try {
		const page = await ctx.newPage();
		page.on('console', (m) => { if (m.type() === 'error' || /ERROR/.test(m.text())) errors.push(m.text()); });
		page.on('pageerror', (e) => errors.push(String(e)));
		const t0 = Date.now();
		await page.goto(`http://localhost:${port}/index.html`);
		// Ready when Godot's status overlay is gone.
		await page.waitForFunction(() => { const s = document.getElementById('status'); return !s || s.style.display === 'none' || s.style.visibility === 'hidden'; }, null, { timeout: 120000 });
		console.log(`first picture after ${((Date.now() - t0) / 1000).toFixed(1)} s`);
		await page.waitForTimeout(1500);
		await page.screenshot({ path: path.join(out, 'w0_start.png') });
		await page.touchscreen.tap(63, 502);   // Sardine
		await page.waitForTimeout(800);
		await page.touchscreen.tap(293, 502);  // Salmon
		await page.waitForTimeout(4000);
		await page.screenshot({ path: path.join(out, 'w1_tapped.png') });
		const t1 = Date.now();
		await page.goto(`http://localhost:${port}/index.html?add=white_shark,manta,octopus,humpback,clownfish`);
		await page.waitForFunction(() => { const s = document.getElementById('status'); return !s || s.style.display === 'none' || s.style.visibility === 'hidden'; }, null, { timeout: 120000 });
		console.log(`second visit after ${((Date.now() - t1) / 1000).toFixed(1)} s`);
		await page.waitForTimeout(6000);
		await page.screenshot({ path: path.join(out, 'w2_shapes.png') });
		await page.touchscreen.tap(326, 42);   // clear
		await page.waitForTimeout(1000);
		await page.screenshot({ path: path.join(out, 'w3_cleared.png') });
	} finally {
		await ctx.close();
		server.close();
	}
	console.log(errors.length ? `ERRORS (${errors.length}):\n` + [...new Set(errors)].slice(0, 20).join('\n') : 'no console errors');
})();
