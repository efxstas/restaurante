// Renderiza comp.html frame a frame con Playwright y codifica con ffmpeg.
// Uso:
//   node build/render.js stills 0,40,100   → out/stills/fNNNN.png (con zonas seguras)
//   node build/render.js video             → out/reel_prop_firms_1000.mp4
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const fs = require('fs'), path = require('path'), http = require('http');

const ROOT = path.resolve(__dirname, '..');
const timing = JSON.parse(fs.readFileSync(path.join(__dirname, 'timing.json'), 'utf8'));
const [mode = 'video', list = ''] = process.argv.slice(2);

const MIME = { '.html':'text/html', '.js':'text/javascript', '.png':'image/png', '.woff2':'font/woff2', '.json':'application/json' };
const server = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  if (!f.startsWith(ROOT) || !fs.existsSync(f)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});

(async () => {
  await new Promise(r => server.listen(0, r));
  const port = server.address().port;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
  await page.goto(`http://127.0.0.1:${port}/build/comp.html`);
  await page.evaluate(t => window.load(t), timing);
  const total = Math.round(timing.duration * timing.fps);
  const canvas = await page.$('canvas');

  if (mode === 'stills') {
    const dir = path.join(ROOT, 'out', 'stills'); fs.mkdirSync(dir, { recursive: true });
    const frames = list ? list.split(',').map(Number) : timing.shots.map(s => Math.round((s.start + (s.end - s.start) * .8) * timing.fps));
    await page.evaluate(() => { window.SAFE_OVERLAY = true; });
    for (const f of frames) {
      const id = await page.evaluate(f => window.renderFrame(f), f);
      await canvas.screenshot({ path: path.join(dir, `f${String(f).padStart(4, '0')}_${id}.png`) });
    }
    console.log(`stills: ${frames.length}`);
  } else {
    const out = path.join(ROOT, 'out', 'reel_prop_firms_1000.mp4');
    const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error',
      '-f', 'image2pipe', '-framerate', String(timing.fps), '-c:v', 'png', '-i', '-',
      '-i', path.join(ROOT, 'out', 'vo.wav'),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-profile:v', 'high',
      '-r', String(timing.fps), '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-shortest', '-movflags', '+faststart', out],
      { stdio: ['pipe', 'inherit', 'inherit'] });
    const t0 = Date.now();
    for (let f = 0; f < total; f++) {
      await page.evaluate(f => window.renderFrame(f), f);
      const buf = await canvas.screenshot({ type: 'png' });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (f % 150 === 0) console.log(`frame ${f}/${total} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
    console.log(`video: ${out}`);
  }
  await browser.close(); server.close();
})();
