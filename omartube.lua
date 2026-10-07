-- YouTube app windows only; regular browser tabs keep their normal rules.
o.window("^.+-youtube\\.com__.*$", {
  float = true,
  pin = true,
  size = { 960, 600 },
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
  opacity = "0.90 override 0.85 override",
})
