-- Optional ASUS ROG G15 Strix (2021) bindings.
-- Requires compatible ASUS hardware and asusctl.

hl.bind(
    "code:156",
    hl.dsp.exec_cmd("rog-control-center")
)

hl.bind(
    "code:211",
    hl.dsp.exec_cmd(
        "sh -c 'asusctl profile -n; pkill -SIGRTMIN+8 waybar'"
    )
)

hl.bind(
    "code:210",
    hl.dsp.exec_cmd("asusctl led-mode -n")
)
