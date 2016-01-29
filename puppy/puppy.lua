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
--local table = require("puppy.tablefile")
--}}}

--{{{ Variables
local string = string
local setmetatable = setmetatable
local capi   =
{
  mouse = mouse,
  screen = screen,
  client = client,
  timer = timer,
  io = io,
  loadfile = loadfile,
  table = table,
  ipairs = ipairs,
  pairs = pairs,
  type = type,
  tostring = tostring
}
local PuppyScreen = {}
--}}}

-- Namespace
module("puppy")

do
   -- declare local variables
   --// exportstring( string )
   --// returns a "Lua" portable version of the string
   local function exportstring( s )
      return string.format("%q", s)
   end

   --// The Save Function
   function capi.table.save(  tbl,filename )
      local charS,charE = "   ","\n"
      local file,err = capi.io.open( filename, "wb" )
      if err then return err end

      -- initiate variables for save procedure
      local tables,lookup = { tbl },{ [tbl] = 1 }
      file:write( "return {"..charE )

      for idx,t in capi.ipairs( tables ) do
         file:write( "-- Table: {"..idx.."}"..charE )
         file:write( "{"..charE )
         local thandled = {}

         for i,v in capi.ipairs( t ) do
            thandled[i] = true
            local stype = capi.type( v )
            -- only handle value
            if stype == "table" then
               if not lookup[v] then
                  capi.table.insert( tables, v )
                  lookup[v] = #tables
               end
               file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
               file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
               file:write(  charS..capi.tostring( v )..","..charE )
            end
         end

         for i,v in capi.pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then
            
               local str = ""
               local stype = capi.type( i )
               -- handle index
               if stype == "table" then
                  if not lookup[i] then
                     capi.table.insert( tables,i )
                     lookup[i] = #tables
                  end
                  str = charS.."[{"..lookup[i].."}]="
               elseif stype == "string" then
                  str = charS.."["..exportstring( i ).."]="
               elseif stype == "number" then
                  str = charS.."["..capi.tostring( i ).."]="
               end
            
               if str ~= "" then
                  stype = capi.type( v )
                  -- handle value
                  if stype == "table" then
                     if not lookup[v] then
                        capi.table.insert( tables,v )
                        lookup[v] = #tables
                     end
                     file:write( str.."{"..lookup[v].."},"..charE )
                  elseif stype == "string" then
                     file:write( str..exportstring( v )..","..charE )
                  elseif stype == "number" then
                     file:write( str..capi.tostring( v )..","..charE )
                  end
               end
            end
         end
         file:write( "},"..charE )
      end
      file:write( "}" )
      file:close()
   end
   
   --// The Load Function
   function capi.table.load( sfile )
      local ftables,err = capi.loadfile( sfile )
      if err then return _,err end
      local tables = ftables()
      for idx = 1,#tables do
         local tolinki = {}
         for i,v in capi.pairs( tables[idx] ) do
            if capi.type( v ) == "table" then
               tables[idx][i] = tables[v[1]]
            end
            if capi.type( i ) == "table" and tables[i[1]] then
               capi.table.insert( tolinki,{ i,tables[i[1]] } )
            end
         end
         -- link indices
         for _,v in capi.ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
         end
      end
      return tables[1]
   end
-- close do
end

-- Display
function PuppyScreen:display()
  -- First, we locate the app
    naughty.notify({ 
      border_width = 0,
      bg = beautiful.bg_focus,
      fg = beautiful.fg_focus,
      title = "Puppy display"})
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

    naughty.notify({ 
      border_width = 0,
      bg = beautiful.bg_focus,
      fg = beautiful.fg_focus,
      title = "Result of test"})
      --text = "col: "..pos.col.." idx: "..pos.idx.." num: "..pos.num })
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
    --naughty.notify({ 
      --border_width = 0,
      --bg = beautiful.bg_focus,
      --fg = beautiful.fg_focus,
      --title = "Result of test"})
      --text = "col: "..pos.col.." idx: "..pos.idx.." num: "..pos.num })
      --text = "x: "..geo.x.." y: "..geo.y.." width: "..geo.width.." height: "..geo.height})--.." num: "..pos.num })
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
  --local reattach = capi.timer { timeout = 0 }
  --reattach:connect_signal("timeout",
  --function()
    --reattach:stop()
    --console:display()
    --naughty.notify({ 
      --border_width = 0,
      --bg = beautiful.bg_focus,
      --fg = beautiful.fg_focus,
      --title = "Reattache = true"})
  --end)
  --reattach:start()
  return console
end

-- Toggle the console
--function PuppyScreen:toggle()
  --self.visible = not self.visible
  --self:display()
--end

function PuppyScreen:toggle(name)
  for c in awful.client.iterate(function (c)
    -- only save floating clients
    -- TODO: ..and clients handled by puppy
    return awful.client.floating.get(c)
  end,
  nil, self.screen) do
    --c.visible = not c.visible
    if c.hidden then
      c.hidden = false
      c:raise()
    else
       c.hidden = true
  end
 end
end

function process_get_cmd(pid)
  local fp = capi.io.popen("xargs -0 < /proc/" .. pid .. "/cmdline")
  return fp:read()
end

function PuppyScreen:save(name, screen)
  screen = screen or capi.mouse.screen
  local puppyClients = {}
  --local i = 0
  for c in awful.client.iterate(function (c)
    -- only save visible floating clients
    return awful.client.floating.get(c) and not c.hidden
  end,
  nil, screen) do
    local pid = c.pid
    local pos = string.find(pid, ".", 1, true)
    if pos then
      pid = string.sub(pid, 0, pos - 1)
    end
    puppyClients[c.instance] = {
                  cmdline=process_get_cmd(pid),
                  height=c:geometry().height,
                  width=c:geometry().width,
                  x=c:geometry().x,
                  y=c:geometry().y
                }
    --i = i + 1
  end
  confdir = awful.util.getdir("config")
  capi.table.save(puppyClients, confdir .. "/puppy-conf-" .. name)
end

function PuppyScreen:launch(name, screen)
  confdir = awful.util.getdir("config")
  local puppyClients = capi.table.load(confdir .. "/puppy-conf-" .. name)
  for k, v in capi.pairs(puppyClients) do
    awful.util.spawn(v["cmdline"])
  end
end

setmetatable(_M, { __call = function(_, ...) return PuppyScreen:new(...) end })

-- vim: ts=2:sw=2:et:fdm=marker:foldenable:foldlevel=0:fdc=2
