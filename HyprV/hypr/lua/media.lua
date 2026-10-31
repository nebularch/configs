local scripts = os.getenv("HOME") .. "/.config/HyprV/waybar/scripts/"

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "volume --inc"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "volume --dec"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "volume --toggle-mic"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "volume --toggle"))

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scripts .. "kb-brightness --dec"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(scripts .. "kb-brightness --inc"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness --dec"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "brightness --inc"))
