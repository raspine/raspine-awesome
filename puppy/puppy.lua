-- Puppy, a popup application
-- Based on the quake example at:
-- http://awesome.naquadah.org/wiki/Drop-down_terminal

-- But modified to run any application supporting -name (instance)
-- as a popup client positioned anywhere on the screen.

-- Use:

--{{{ Required libraries
local naughty = require("naughty")
local beautiful = require("beautiful")
local awful  = require("awful")
require("tablefile")
--}}}

--{{{ Variables
local string = string
local setmetatable = setmetatable
local capi   =
{
  mouse = mouse,
  screen = screen,
  client = client,
  timer = timer
}
local PuppyScreen = {}
--}}}

-- Namespace
module("puppy")


-- Display
function PuppyScreen:display()
  -- First, we locate the app
  local client = nil
  local i = 0
  for c in awful.client.iterate(function (c)
    -- c.name may be changed!
    return c.instance == self.name
  end, nil, self.screen) do
  i = i + 1
  if i == 1 then
    client = c
  else
    -- Additional matching clients, let's remove the sticky bit
    -- which may persist between awesome restarts. We don't close
    -- them as they may be valuable. They will just turn into a
    -- classic terminal.
    c.sticky = false
    c.ontop = false
    c.above = false
  end
  end

  if not client and not self.visible then
    -- The app is not here yet but we don't want it yet. Just do nothing.
    return
  end

  if not client then
    -- The client does not exist, we spawn it

    --naughty.notify({ 
    --border_width = 0,
    --bg = beautiful.bg_focus,
    --fg = beautiful.fg_focus,
    --title = "Result of test",
    ----text = "col: "..pos.col.." idx: "..pos.idx.." num: "..pos.num })
    --text = "x: "..geo.x.." y: "..geo.y.." width: "..geo.width.." height: "..geo.height})--.." num: "..pos.num })
    awful.util.spawn(self.app .. " " .. string.format(self.argname, self.name) .. " " ..self.command,
    false, self.screen)
    return
  end

  -- Comptute size
  local geom = capi.screen[self.screen].workarea
  local width, height = self.width, self.height
  if width  <= 1 then width = geom.width * width end
  if height <= 1 then height = geom.height * height end
  local x, y
  if     self.horiz == "left"  then x = geom.x
  elseif self.horiz == "right" then x = geom.width + geom.x - width
  else   x = geom.x + (geom.width - width)/2 end
  if     self.vert == "top"    then y = geom.y
  elseif self.vert == "bottom" then y = geom.height + geom.y - height
  else   y = geom.y + (geom.height - height)/2 end

  -- Resize
  awful.client.floating.set(client, true)
  client.border_width = 0
  client.size_hints_honor = false
  --client:geometry({ x = x, y = y, width = width, height = height })
  client:geometry({ x = 1200, y = 30, width = 480, height = 480 })

  -- Sticky and on top
  client.ontop = true
  client.above = true
  client.skip_taskbar = true
  client.sticky = false

  -- This is not a normal window, don't apply any specific keyboard stuff
  --client:buttons({})
  --client:keys({})

  -- Toggle display
  if self.visible then
    client.hidden = false
    client:raise()
    capi.client.focus = client
  else
    client.hidden = true
  end
end

-- Create a console
function PuppyScreen:new(config)
  -- The "console" object is just its configuration.

  -- The application to be invoked is:
  --   config.app .. " " .. string.format(config.argname, config.name)
  config.app = config.app or "xterm" -- application to spawn
  config.command = config.command or "" -- command to run
  config.name     = config.name     or "PuppyScreenNeedsUniqueName" -- window name
  config.argname  = config.argname  or "-name %s"     -- how to specify window name

  -- If width or height <= 1 this is a proportion of the workspace
  config.height   = config.height   or 0.25           -- height
  config.width    = config.width    or 1          -- width
  config.vert     = config.vert     or "top"          -- top, bottom or center
  config.horiz    = config.horiz    or "center"       -- left, right or center

  config.screen   = config.screen or capi.mouse.screen
  config.visible  = config.visible or false -- Initially, not visible

  local console = setmetatable(config, { __index = PuppyScreen })
  capi.client.connect_signal("manage",
  function(c)
    if c.instance == console.name and c.screen == console.screen then
      console:display()
    end
  end)
  capi.client.connect_signal("unmanage",
  function(c)
    if c.instance == console.name and c.screen == console.screen then
      console.visible = false
    end
  end)

  -- "Reattach" currently running PuppyScreen. This is in case awesome is restarted.
  local reattach = capi.timer { timeout = 0 }
  reattach:connect_signal("timeout",
  function()
    reattach:stop()
    console:display()
  end)
  reattach:start()
  return console
end

-- Toggle the console
function PuppyScreen:toggle()
  self.visible = not self.visible
  self:display()
end

function PuppyScreen:save()

  local puppyScreen = {}
  local puppyClient = {}
  for c in awful.client.iterate(function (c)
    -- only save floating clients
    return awful.client.floating.get(c)
  end,
  nil, self.screen) do
    puppyClient[c.instance] = { geometry=c:geometry() }
  end

end

setmetatable(_M, { __call = function(_, ...) return PuppyScreen:new(...) end })

-- vim: ts=2:sw=2:et:fdm=marker:foldenable:foldlevel=0:fdc=2
