// Run against an isolated Chromium profile with --remote-debugging-port=9238.
// Usage: node tests/fullscreen.mjs <Hyprland window address> [debugging port]
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

const address = process.argv[2];
assert.match(address || '', /^0x[0-9a-f]+$/);
const port = Number(process.argv[3] || 9238);
assert(Number.isInteger(port) && port > 0 && port < 65536);
const clients = () => JSON.parse(execFileSync('/usr/bin/hyprctl', ['clients', '-j']));
const window = () => clients().find(w => w.address === address);
assert.match(window().class, /^chrome-(www\.)?youtube\.com__/);
const originalSize = window().size;
const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const tab = tabs.find(t => t.type === 'page' && t.url.includes('youtube.com/watch'));
assert(tab, 'Open a YouTube video in the isolated test browser first');
const socket = new WebSocket(tab.webSocketDebuggerUrl);
await new Promise(resolve => socket.addEventListener('open', resolve, { once: true }));
let id = 0;
const pending = new Map();
socket.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  message.error ? request.reject(new Error(message.error.message)) : request.resolve(message.result);
});
function send(method, params) {
  return new Promise((resolve, reject) => {
    pending.set(++id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', { expression, returnByValue: true, userGesture: true, awaitPromise: true });
  assert(!result.exceptionDetails, JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
async function pressF() {
  await send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'f', code: 'KeyF', windowsVirtualKeyCode: 70, text: 'f' });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'f', code: 'KeyF', windowsVirtualKeyCode: 70 });
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
function resize(size) {
  execFileSync('/usr/bin/hyprctl', ['dispatch', `hl.dsp.window.resize({window="address:${address}",x=${size[0]},y=${size[1]},relative=false})`]);
}
async function geometry() {
  return evaluate(`(()=>{
    const fullscreen = document.fullscreenElement;
    const player = document.querySelector('#movie_player')?.getBoundingClientRect();
    const video = document.querySelector('video')?.getBoundingClientRect();
    return { fullscreen: !!fullscreen, viewport: [innerWidth, innerHeight],
      player: player && [player.width, player.height], video: video && [video.width, video.height] };
  })()`);
}
try {
  await evaluate("document.querySelector('video').muted=true; document.querySelector('video').pause(); document.querySelector('#movie_player').focus()");
  await pressF();
  await pause(1000);
  const before = await geometry();
  assert(before.fullscreen, 'F must enter browser player fullscreen');
  for (const size of [[640, 440], [800, 450]]) {
    resize(size);
    await pause(1000);
    const after = await geometry();
    assert(after.fullscreen);
    assert.deepEqual(window().size, size);
    assert(window().floating && window().pinned);
    assert.equal(window().fullscreen, 0, 'Player fullscreen must not fullscreen the desktop window');
    assert(after.player.every((value, index) => Math.abs(value - after.viewport[index]) <= 1), 'Player must fill the current viewport');
    assert(after.video[0] <= after.viewport[0] + 1 && after.video[1] <= after.viewport[1] + 1);
    assert(after.video[0] < before.video[0], 'Video must shrink with the window');
    console.log(JSON.stringify({ window: size, ...after }));
  }
  await pressF();
  await pause(500);
  assert(!(await geometry()).fullscreen, 'Second F must leave player fullscreen');
  console.log('F, two resizes and F again passed');
} finally {
  await evaluate('document.fullscreenElement ? document.exitFullscreen() : undefined');
  resize(originalSize);
  socket.close();
}
