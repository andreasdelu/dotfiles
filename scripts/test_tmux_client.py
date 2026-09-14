"""Exercise attached/detached Ghostty cleanup on the caller's private tmux socket."""
import os
import pty
import select
import subprocess
import sys
import time

socket = sys.argv[1]
reset = b"\x1b]104;160;161;162;163;164;165\x1b\\"


def tmux(*args):
    return subprocess.check_output(["tmux", "-S", socket, *args])


def drain(fd, duration=0.4):
    output = b""
    deadline = time.monotonic() + duration
    while time.monotonic() < deadline:
        if select.select([fd], [], [], 0.05)[0]:
            try:
                output += os.read(fd, 65536)
            except OSError:
                break
    return output


master, slave = pty.openpty()
client = None
try:
    client = subprocess.Popen(
        ["tmux", "-S", socket, "attach-session", "-t", "test"],
        stdin=slave, stdout=slave, stderr=slave,
        env={**os.environ, "TERM": "xterm-ghostty"},
    )
    for _ in range(40):
        clients = tmux("list-clients", "-F", "#{client_tty}").decode().strip()
        if clients:
            break
        drain(master, 0.05)
    else:
        raise AssertionError("private Ghostty client failed to attach")
    tty = clients.splitlines()[0]
    drain(master)

    # Simulate the previous unconditional hooks, which had no feature option.
    tmux("set-option", "-gu", "@dotfiles-pane-dimming")
    tmux("set-environment", "-g", "DOTFILES_GHOSTTY_PANE_DIMMING", "0")
    tmux("source-file", os.path.expanduser("~/.tmux.conf"))
    assert reset in drain(master), "legacy -> off did not reset Ghostty palette"

    tmux("set-environment", "-g", "DOTFILES_GHOSTTY_PANE_DIMMING", "1")
    tmux("source-file", os.path.expanduser("~/.tmux.conf"))
    drain(master)
    tmux("detach-client", "-t", tty)
    assert reset in drain(master, 1), "detach did not reset Ghostty palette"
    print("PASS: real PTY Ghostty client, legacy-to-off and detached palette reset")
finally:
    if client is not None:
        client.terminate()
        client.wait(timeout=5)
    os.close(master)
    os.close(slave)
