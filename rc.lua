-- vim: ts=4:sw=4:et:fdm=marker:foldenable:foldlevel=0:fdc=5:nonu:nornu


-- {{{ Required libraries
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local vicious = require("vicious")
-- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart applications
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

--run_once("urxvtd")
--run_once("unclutter")
run_once("unagi")
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.getdir("config") .. "/themes/material/theme.lua")
--beautiful.init(awful.util.getdir("config") .. "/themes/holo/theme.lua")

-- This is used later as the default terminal and editor to run.
--terminal = "xterm -ls -xrm 'XTerm*selectToClipboard: true'"
terminal = "xterm -ls -xrm 'XTerm*selectToClipboard: true'"
--terminal = "gnome-terminal"
editor = os.getenv("EDITOR") or "gvim" or "vi"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

--{{{ Volume
 -- }}}
 
--{{{ CPU
-- Initialize widget
local widget_margin = 3
local cpuwidget_text = wibox.widget.textbox()
local cpuwidget = wibox.widget.background()
cpuwidget:set_widget(cpuwidget_text)
cpuwidget:set_bg(beautiful.widget_bg)
cpuwidget:set_fg(beautiful.widget_fg)
-- Register widget
vicious.register(cpuwidget_text, vicious.widgets.cpu, "cpu: $1%")-- Initialize widget
-- }}}

-- {{{ Memory
-- -- Initialize widget
memwidget_text = wibox.widget.textbox()
memwidget_bg = wibox.widget.background()
memwidget_bg:set_widget(memwidget_text)
memwidget_bg:set_bg(beautiful.widget_bg)
memwidget_bg:set_fg(beautiful.widget_fg)
local memwidget = wibox.layout.margin()
memwidget:set_widget(memwidget_bg)
memwidget:set_right(widget_margin)
--memwidget:set_left(5)
-- Register widget
vicious.register(memwidget_text, vicious.widgets.mem, "mem: $1% ($2MB) ", 13)
-- }}}

-- {{{ Net
-- -- Initialize widget

netup_icon = wibox.widget.imagebox()
netup_icon:set_image(beautiful.netup_icon)
netup_bg = wibox.widget.background()
netup_bg:set_widget(netup_icon)
netup_bg:set_bg(beautiful.widget_bg)
local netup_arrow = wibox.layout.margin()
netup_arrow:set_widget(netup_bg)
netup_arrow:set_left(widget_margin)

netwidget_text = wibox.widget.textbox()
netwidget_bg = wibox.widget.background()
netwidget_bg:set_widget(netwidget_text)
netwidget_bg:set_bg(beautiful.widget_bg)
netwidget_bg:set_fg(beautiful.widget_fg)
local netwidget = wibox.layout.margin()
netwidget:set_widget(netwidget_bg)
vicious.register(netwidget_text, vicious.widgets.net, "${enp3s0 up_mb}-${enp3s0 down_mb}", 1)

netdown_icon = wibox.widget.imagebox()
netdown_icon:set_image(beautiful.netdown_icon)
netdown_bg = wibox.widget.background()
netdown_bg:set_widget(netdown_icon)
netdown_bg:set_bg(beautiful.widget_bg)
local netdown_arrow = wibox.layout.margin()
netdown_arrow:set_widget(netdown_bg)
netdown_arrow:set_right(widget_margin)
--netdown_arrow:set_color("#ffffff")

-- }}}

--{{{ Task warrior
task_icon = wibox.widget.imagebox()
task_icon:set_image("/home/jsc/.config/awesome/icons/taskw.png")
task_icon:buttons(awful.util.table.join( awful.button({ }, 1, function() awful.util.spawn("gvim -c TW") end)))
--}}}

--{{{ Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(task_icon)
    right_layout:add(netup_arrow)
    right_layout:add(netwidget)
    right_layout:add(netdown_arrow)
    right_layout:add(memwidget)
    right_layout:add(cpuwidget)
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
  -- {{{ Tag browsing
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,  altkey         }, "h", 
        function()
            local s = mouse.screen
            if client.focus then
                s = client.focus.screen
            end

            -- if we are on screen 1 or 3, we shift tags on both screens
            awful.tag.viewprev(s)
            if screen.count() > 1 and s == 1 then
                awful.tag.viewprev(3)
            end
            if screen.count() > 1 and s == 3 then
                awful.tag.viewprev(1)
            end
        end
    ),
    awful.key({ modkey,  altkey         }, "l",
        function()
            local s = mouse.screen
            if client.focus then
                s = client.focus.screen
            end

            -- if we are on screen 1 or 3, we shift tags on both screens
            awful.tag.viewnext(s)
            if screen.count() > 1 and s == 1 then
                awful.tag.viewnext(3)
            end
            if screen.count() > 1 and s == 3 then
                awful.tag.viewnext(1)
            end
        end
    ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
  -- }}}

    -- {{{ Show Menu
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),
    --}}}

    -- {{{ Config files
    awful.key({ modkey, "Control"   }, "a", function () awful.util.spawn("gvim /home/jsc/.config/awesome/rc.lua")    end),
    -- }}}

    -- {{{ Test     (mod + t)
    awful.key({ modkey }, "t",
        function()
            local pos = awful.client.idx(client.focus)
            if pos then
                naughty.notify({ 
                                 border_width = 0,
                                 bg = beautiful.bg_focus,
                                 fg = beautiful.fg_focus,
                                 title = "Result of test",
                                 text = "col: "..pos.col.." idx: "..pos.idx.." num: "..pos.num })
           end
         end),
    -- }}}

    -- {{{ Client focus
    -- {{{ Focus left       (mod + h)
    awful.key({ modkey }, "h",
        function()
            if client.focus then
                if awful.client.getmaster() == awful.client.next(0) and
                    awful.client.focus.history.get(client.focus.screen, 1) and
                    awful.layout.get(client.focus.screen) == awful.layout.suit.tile.left then
                        awful.client.focus.history.previous()
                else
                    awful.client.focus.global_bydirection("left")
                end
            end
            if client.focus then client.focus:raise() end
        end),
    -- }}}
    -- {{{ Focus right      (mod + l)
    awful.key({ modkey }, "l",
        function()
            if client.focus then
                if awful.client.getmaster() == awful.client.next(0) and
                    awful.client.focus.history.get(client.focus.screen, 1) and
                    awful.layout.get(client.focus.screen) == awful.layout.suit.tile then
                        awful.client.focus.history.previous()
                else
                    awful.client.focus.global_bydirection("right")
                end
            end
            if client.focus then client.focus:raise() end
        end),
    -- }}}
    -- {{{ Focus up         (mod + k)
    awful.key({ modkey }, "k",
        function()
            if client.focus then
                if awful.client.getmaster() == awful.client.next(0) and
                    awful.client.focus.history.get(client.focus.screen, 1) then
                    awful.client.focus.history.previous()
                else
                    awful.client.focus.bydirection("up")
                end
            end
            if client.focus then client.focus:raise() end
        end),
    -- }}}
    -- {{{ Focus down       (mod + j)
    awful.key({ modkey }, "j",
        function()
            if client.focus then
                if awful.client.getmaster() == awful.client.next(0) and
                    awful.client.focus.history.get(client.focus.screen, 1) then
                    awful.client.focus.history.previous()
                else
                    awful.client.focus.bydirection("down")
                end
            end
            if client.focus then client.focus:raise() end
        end),
    -- }}}
    -- {{{ Focus by history (mod + tab)
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then client.focus:raise() end
        end),
    -- }}}
    -- }}}

    -- {{{ Client manipulation
    -- {{{ Swap left       (mod + H)
    awful.key({ modkey, "Shift"   }, "h",
        function ()
            if awful.layout.get(client.focus.screen) == awful.layout.suit.tile.left then
                -- We aim to swap left but this command always puts the slave window 
                -- in the top of the slave column. So to keep the order of our slave
                -- windows intact we we use history buffer and focus the last slave
                -- window and swap this right.
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("right")
                -- Uncomment to let focus follow the client.
                --awful.client.focus.history.previous()
            elseif awful.layout.get(client.focus.screen) == awful.layout.suit.tile then
                -- put the master window in the history buffer first so when we
                -- swap right, we'll swap the previous master window
                awful.client.focus.bydirection("left")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("left")
            else
                awful.client.swap.bydirection("left")
            end
        end),
    -- }}}
    -- {{{ Swap right      (mod + L)
    awful.key({ modkey, "Shift"   }, "l",
        function ()
            if awful.layout.get(client.focus.screen) == awful.layout.suit.tile.left then
                -- put the master window in the history buffer first so when we
                -- swap left, we'll swap the previous master window
                awful.client.focus.bydirection("right")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("right")
            elseif awful.layout.get(client.focus.screen) == awful.layout.suit.tile then
                -- We aim to swap right but this command always puts the slave window 
                -- in the top of the slave column. So to keep the order of our slave
                -- windows intact we we use history buffer and focus the last slave
                -- window and swap this left.
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("left")
                -- Uncomment to let focus follow the client.
                --awful.client.focus.history.previous()
            else
                awful.client.swap.bydirection("right")
            end
        end),
    -- }}}
    -- {{{ Swap up         (mod + K)
    -- The concept for bottom/top layouts are the same as for left/right, no
    -- further comments
    awful.key({ modkey, "Shift"   }, "k",
        function () 
            if awful.layout.get(client.focus.screen) == awful.layout.suit.tile.bottom then
                awful.client.focus.bydirection("up")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("up")
            elseif awful.layout.get(client.focus.screen) == awful.layout.suit.tile.top then
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("down")
                -- Enable let focus follow the client.
                --awful.client.focus.history.previous()
            else
                awful.client.swap.bydirection("up")
            end
        end),
    -- }}}
    -- {{{ Swap down       (mod + J)
    awful.key({ modkey, "Shift"   }, "j",
        function () 
            if awful.layout.get(client.focus.screen) == awful.layout.suit.tile.bottom then
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("up")
                -- Enable to let focus follow the client.
                --awful.client.focus.history.previous()
            elseif awful.layout.get(client.focus.screen) == awful.layout.suit.tile.top then
                -- put the master window in the history buffer first
                awful.client.focus.bydirection("down")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("down")
            else
                awful.client.swap.bydirection("down")
            end
        end),
    -- }}}
    -- {{{ Shift left       (mod + ctrl + h)
    awful.key({ modkey, "Control"   }, "h",
        function ()
            if awful.layout.get(client.focus.screen) ~= awful.layout.suit.tile then
                awful.layout.set(awful.layout.suit.tile)
            end
            if awful.client.getmaster() ~= awful.client.next(0) then
                awful.client.focus.bydirection("left")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("left")
            end
        end),
    -- }}}
    -- {{{ Shift right      (mod + ctrl + l)
    awful.key({ modkey, "Control"   }, "l",
        function ()
            if awful.layout.get(client.focus.screen) ~= awful.layout.suit.tile.left then
                awful.layout.set(awful.layout.suit.tile.left)
            end
            if awful.client.getmaster() ~= awful.client.next(0) then
                awful.client.focus.bydirection("right")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("right")
            end
        end),
    -- }}}
    -- {{{ Shift up         (mod + ctrl + k)
    awful.key({ modkey, "Control"   }, "k",
        function ()
            if awful.layout.get(client.focus.screen) ~= awful.layout.suit.tile.bottom then
                awful.layout.set(awful.layout.suit.tile.bottom)
            end
            if awful.client.getmaster() ~= awful.client.next(0) then
                awful.client.focus.bydirection("up")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("up")
            end
        end),
    -- }}}
    -- {{{ Shift down       (mod + ctrl + j)
    awful.key({ modkey, "Control"   }, "j",
        function ()
            if awful.layout.get(client.focus.screen) ~= awful.layout.suit.tile.top then
                awful.layout.set(awful.layout.suit.tile.top)
            end
            if awful.client.getmaster() ~= awful.client.next(0) then
                awful.client.focus.bydirection("down")
                awful.client.focus.history.previous()
                awful.client.swap.bydirection("down")
            end
        end),
    -- }}}
    -- {{{ Move to first screen    (mod + Shift + F1)
    awful.key({ modkey, "Shift"   }, "F1",     function(c) awful.client.movetoscreen(c,3) end),
    -- }}}
    -- {{{ Move to second screen    (mod + Shift + F2)
    awful.key({ modkey, "Shift"   }, "F2",     function(c) awful.client.movetoscreen(c,1) end),
    -- }}}
    -- {{{ Move to third screen    (mod + Shift + F3)
    awful.key({ modkey, "Shift"   }, "F3",     function(c) awful.client.movetoscreen(c,2) end),
    -- }}}
    -- {{{ Move to left screen    (mod + ctrl + H)
    -- TODO
    -- }}}
    -- {{{ Move to right screen    (mod + ctrl + L)
    -- TODO
    -- }}}
    -- }}}

    -- {{{ Screen manipulation
    -- {{{ Focus first screen    (mod + F1)
    awful.key({ modkey,           }, "F1",     function(c) awful.screen.focus(3) end),
    -- }}}
    -- {{{ Focus second screen    (mod + F2)
    awful.key({ modkey,           }, "F2",     function(c) awful.screen.focus(1) end),
    -- }}}
    -- {{{ Focus third screen    (mod + F3)
    awful.key({ modkey,           }, "F3",     function(c) awful.screen.focus(2) end),
    -- }}}
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    -- }}}

    -- {{{ Layout manipulation
    awful.key({ modkey, "Shift"   }, "Right",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey, "Shift"   }, "Left",     function () awful.tag.incmwfact(-0.05)    end),
    --awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    --awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    --awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    --awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    --}}}

    --{{{ Program control
    -- {{{ Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),


    awful.key({ modkey, "Control" }, "n", awful.client.restore),
    --}}}

    --{{{ Copy to clipboard
    awful.key({ "Ctrl", "Shift" }, "c", function () os.execute("xsel -p -o | xsel -i -b") end),
    --}}}

    --{{{ User programs
    awful.key({ modkey, }, "c", function () awful.util.spawn("chromium") end),
    awful.key({ modkey, }, "f", function () awful.util.spawn("firefox") end),
    awful.key({ modkey, }, "v", function () awful.util.spawn("xterm -e vifm") end),
    awful.key({ modkey, }, "g", function () awful.util.spawn("gvim") end),
    --}}}

    -- {{{ Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- }}}
    -- }}}

    -- {{{ Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
    --}}}

)

clientkeys = awful.util.table.join(
  --{{{ Client control
        awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
        awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
        --awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
        awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
        awful.key({ modkey,           }, "n",
            function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end),
        awful.key({ modkey,           }, "m",
            function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
            end)
    --}}}
)

-- {{{ Tag manipulation
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        --{{{ View exclusive tag    (mod + alt + #)
        awful.key({ modkey, altkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        --}}}
        --{{{ Toggle view tag       (mod + ctrl + #)
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        --}}}
        --{{{ Move client to tag    (mod + shift + #)
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        --}}}
        --{{{ Toggle tag on client  (mod + #)
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
         --}}}
end

globalkeys = awful.util.table.join(globalkeys,
        --{{{ Toggle all tags on client  (mod + a)
        awful.key({ modkey }, "a",
                  function ()
                    if client.focus then
                        for i = 1, 9 do
                            local tag = awful.tag.gettags(client.focus.screen)[i]
                            if tag then
                                if tag ~= awful.tag.selected(client.focus.screen) then
                                    awful.client.toggletag(tag)
                                end
                            end
                        end
                    end
                  end))
         --}}}

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- }}}
-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = 3,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     size_hints_honor = false,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus",
function(c)
    c.border_color = beautiful.border_focus
    c.opacity = 1
end)
client.connect_signal("unfocus",
function(c)
    c.border_color = beautiful.border_normal
    c.opacity = 0.85
end)
-- }}}
