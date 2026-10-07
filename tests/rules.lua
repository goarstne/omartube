local rules = {}
local fullscreen, dispatched
hl = {
  window_rule = function(rule) rules[rule.name] = rule end,
  on = function(event, handler) assert(event == "window.fullscreen"); fullscreen = handler end,
  dsp = { window = { fullscreen_state = function(state) return state end } },
  dispatch = function(state) dispatched = state end,
}
o = { window = function(match, rule) if type(match) == "string" then rules.window = rule; rules.match = match end end }
dofile("omartube.lua")
assert(rules.window.float and rules.window.pin)
assert(rules.window.border_size == 0)
assert(rules.window.tag == "-default-opacity")
assert(rules.window.suppress_event == "maximize" and rules.window.sync_fullscreen == false)
assert(rules["omartube-opacity"].opacity == "0.90 override 0.85 override")
omartube_set_transparency(0, 90)
assert(rules["omartube-opacity"].opacity == "1.00 override 0.10 override")
assert(not pcall(omartube_set_transparency, "10", 15))
assert(not pcall(omartube_set_transparency, 10, -1))
assert(not pcall(omartube_set_transparency, 91, 15))
assert(not pcall(omartube_set_transparency, 0 / 0, 15))
fullscreen({ class = "brave-youtube.com__-Default", address = "0x123", fullscreen = 2, fullscreen_client = 2 })
assert(dispatched.internal == 0 and dispatched.client == 2 and dispatched.window == "address:0x123")
dispatched = nil
fullscreen({ class = "brave-browser", fullscreen = 2 })
fullscreen({ class = "brave-youtube.com__-Default", fullscreen = 0 })
fullscreen(nil)
assert(dispatched == nil)
print("Window rules and transparency bounds passed")
