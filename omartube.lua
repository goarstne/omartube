-- YouTube app windows only; regular browser tabs keep their normal rules.
local youtube = "^.+-(www\\.)?youtube\\.com__.*$"
o.window(youtube, {
  tag = "-default-opacity",
  float = true,
  pin = true,
  border_size = 0,
  size = { 960, 600 },
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
  suppress_event = "maximize",
  sync_fullscreen = false,
})

function omartube_set_transparency(focused, unfocused)
  assert(type(focused) == "number" and focused >= 0 and focused <= 90, "Invalid focused transparency")
  assert(type(unfocused) == "number" and unfocused >= 0 and unfocused <= 90, "Invalid unfocused transparency")
  hl.window_rule({
    name = "omartube-opacity",
    match = { class = youtube },
    opacity = string.format("%.2f override %.2f override", 1 - focused / 100, 1 - unfocused / 100),
  })
end

omartube_set_transparency(10, 15)

o.window({ class = "org.quickshell", title = "^OmarTube controls$" }, { float = true, center = true })

-- Keep the browser fullscreen flag on resize, without fullscreening the desktop window.
hl.on("window.fullscreen", function(window)
  if not window or not window.class or window.fullscreen == 0 then return end
  if not (window.class:match("%-youtube%.com__") or window.class:match("%-www%.youtube%.com__")) then return end
  hl.dispatch(hl.dsp.window.fullscreen_state({
    window = "address:" .. window.address,
    action = "set", internal = 0, client = window.fullscreen_client,
  }))
end)
