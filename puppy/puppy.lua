-- Puppy, manages "workspaces" of floating clients
-- Based on the quake example at:
-- http://awesome.naquadah.org/wiki/Drop-down_terminal

-- But modified to manage several applications positioned anywhere on the screen.

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

-- {{{ table functions from http://lua-users.org/wiki/SaveTableToFile
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
-- }}}

-- Display
function PuppyScreen:display()
  -- First, we locate the app

  for k,v in capi.pairs(self.clients) do
    local client = nil
    local i = 0
    for c in awful.client.iterate(function (c)
      -- c.instance may be changed!
      return c.instance == k
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

    if not client then
      -- The client is not here, do nothing.
      return
    end

    -- Resize
    awful.client.floating.set(client, true)
    client.border_width = 0
    client.size_hints_honor = false
    client:geometry({ x = v["x"], y = v["y"], width = v["width"], height = v["height"] })

    -- Sticky and on top
    client.ontop = true
    client.above = true
    client.skip_taskbar = true
    client.sticky = false

    -- Toggle display
    if self.visible then
      client.hidden = false
      client:raise()
      capi.client.focus = client
    else
      client.hidden = true
    end
  end
end

-- Create a configuration
function PuppyScreen:new(config)

  confdir = awful.util.getdir("config")
  config.clients = capi.table.load(confdir .. "/puppy-conf-" .. config.name)
  if not config.clients then
    naughty.notify({ 
      border_width = 0,
      bg = beautiful.bg_focus,
      fg = beautiful.fg_focus,
      title = "Puppy name " .. config.name .. " not found"})
      return
  end

  -- initiate client properties
  config.ontop = config.ontop or true
  config.above = config.above or true
  config.skip_taskbar = config.skip_taskbar or true
  config.sticky = config.sticky or true
  config.screen   = config.screen or capi.mouse.screen

  --capi.table.save(config, confdir .. "/pup")

  local puppyConfig = setmetatable(config, { __index = PuppyScreen })
    capi.client.connect_signal("manage",
    function(c)
      for k,v in capi.pairs(puppyConfig.clients) do
          if c.instance == k and c.screen == puppyConfig.screen then
            puppyConfig:display()
          end
      end
    end)
    capi.client.connect_signal("unmanage",
    function(c)
      for k,v in capi.pairs(puppyConfig.clients) do
        if c.instance == k and c.screen == puppyConfig.screen then
          puppyConfig.visible = false
        end
      end
    end)

  -- "Reattach" currently running PuppyScreen. This is in case awesome is restarted.
  local reattach = capi.timer { timeout = 0 }
  reattach:connect_signal("timeout",
  function()
    reattach:stop()
    puppyConfig:display()
  end)
  reattach:start()
  return puppyConfig
end

-- Toggle the console
function PuppyScreen:toggle()
  self.visible = not self.visible
  self:display()
end

local function process_get_cmd(pid)
  local fp = capi.io.popen("xargs -0 < /proc/" .. pid .. "/cmdline")
  return fp:read()
end

function PuppyScreen:save(name, screen)
  screen = screen or capi.mouse.screen
  local puppyClients = {}
  for c in awful.client.iterate(function (c)
    -- save visible floating clients
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
  end
  confdir = awful.util.getdir("config")
  capi.table.save(puppyClients, confdir .. "/puppy-conf-" .. name)
end

function PuppyScreen:launch(name)
  self.visible  = false -- Initially, not visible
  confdir = awful.util.getdir("config")
  local puppyClients = capi.table.load(confdir .. "/puppy-conf-" .. name)
  for k, v in capi.pairs(puppyClients) do
    awful.util.spawn(v["cmdline"])
  end
  naughty.notify({ 
    border_width = 0,
    bg = beautiful.bg_focus,
    fg = beautiful.fg_focus,
    title = "Puppy config " .. name .. " launched" })
end

setmetatable(_M, { __call = function(_, ...) return PuppyScreen:new(...) end })

-- vim: ts=2:sw=2:et:fdm=marker:foldenable:foldlevel=0:fdc=2
