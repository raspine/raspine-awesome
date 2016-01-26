local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")

terminal_cwd = "xterm -ls -xrm 'XTerm*selectToClipboard: true' -cd"

-- Get the cwd of the process pid
function process_get_cwd(pid)
	local fp = io.popen("readlink /proc/" .. pid .. "/cwd")
	return fp:read()
end


-- Get subprocess pid
-- (This is useful for getting the bash underlying urxvt)
function process_get_subproc_pid(pid)
	local fp = io.popen("ps -ef | awk '$r=="..pid.." { print $2 }'")
	return fp:read()
end


-- Open a terminal with at the same CWD as the current
-- terminal client
-- Optional arg: current client
-- (Install this function into client keybindings)
function open_terminal_same_cwd(client)
	if not client then
		client = awful.client.next(0)
	end

	if not client then
		awful.util.spawn_with_shell(TERMINAL)
		return
	end

	local pid = client.pid
	pid = string.sub(pid, 0, string.find(pid, ".", 1, true) - 1)
	local subpid = process_get_subproc_pid(pid)

	if subpid then
		pid = subpid
	end

	local cwd = process_get_cwd(pid)
    --naughty.notify({ 
		     --border_width = 0,
		     --bg = beautiful.bg_focus,
		     --fg = beautiful.fg_focus,
		     --title = "Result of test",
		     --text = "pid: ".. pid .. " cwd: " .. cwd})
	awful.util.spawn_with_shell("urxvt -cd " .. cwd)
end

