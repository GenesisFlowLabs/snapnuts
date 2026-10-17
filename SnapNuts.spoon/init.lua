--- === SnapNuts ===
---
--- The number = the division. Cmd+4 for fourths, Cmd+9 for ninths.
--- Window management that teaches itself.
---
--- Install: put SnapNuts.spoon in ~/.hammerspoon/Spoons/ and add
---   hs.loadSpoon("SnapNuts")
---   spoon.SnapNuts:start()
--- to ~/.hammerspoon/init.lua. See README.md for the shortcut table.
---
--- Home: https://github.com/GenesisFlowLabs/snapnuts

local obj = {}
obj.__index = obj

obj.name = "SnapNuts"
obj.version = "2.1.0"
obj.author = "Shafen Khan / Genesis Flow Labs"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://github.com/GenesisFlowLabs/snapnuts"

local here = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
local core = dofile(here .. "core.lua")
obj.core = core

-- ------------------------------------------------------------
-- Settings. Change these before :start().
-- ------------------------------------------------------------

--- Pixels between a snapped window and the screen edge / its neighbor.
obj.gap = 0
--- Pixels between windows when tiling.
obj.tileGap = 4
--- Turn divisions 90 degrees on portrait screens (thirds become bands).
obj.portraitAware = true
--- Slack, in pixels, when reading which cell a window is already in.
obj.matchTolerance = 16
--- Seconds the on-screen label stays up.
obj.alertDuration = 0.5
--- How many snaps can be undone.
obj.undoLevels = 10
--- Where saved workspaces live. nil = ~/.hammerspoon/snapnuts-workspaces.json
obj.workspaceFile = nil
--- Pixels of a stashed window left peeking in from the edge.
obj.stashPeek = 15
--- Move the mouse pointer along when a window lands on another screen.
obj.mouseFollows = false

obj.logger = hs.logger.new("SnapNuts", "info")

-- ------------------------------------------------------------
-- The divisions. The key is the number you press.
-- ------------------------------------------------------------

obj.divisions = {
  ["1"]  = {name = "Maximize",   positions = {{x = 0, y = 0, w = 1, h = 1}}},
  ["2"]  = {name = "Halves",     positions = core.concat(core.grid(2, 1), core.grid(1, 2))},
  ["3"]  = {name = "Thirds",     positions = core.grid(3, 1)},
  ["4"]  = {name = "Fourths",    positions = core.concat(core.grid(4, 1), core.grid(2, 2))},
  ["5"]  = {name = "Center",     positions = {{x = 0.1, y = 0.1, w = 0.8, h = 0.8}}},
  ["6"]  = {name = "Sixths",     positions = core.grid(3, 2)},
  ["7"]  = {name = "Almost Max", positions = {{x = 0.05, y = 0.05, w = 0.9, h = 0.9}}},
  ["8"]  = {name = "Eighths",    positions = core.grid(4, 2)},
  ["9"]  = {name = "Ninths",     positions = core.grid(3, 3)},
  ["16"] = {name = "Sixteenths", positions = core.grid(4, 4)},
}

local divisionForAction = {
  maximize = "1", halves = "2", thirds = "3", fourths = "4", center = "5",
  sixths = "6", almostMax = "7", eighths = "8", ninths = "9", sixteenths = "16",
}

-- ------------------------------------------------------------
-- Default shortcuts. Every action has a numpad chord and a laptop chord.
-- None of them collide with a macOS or common app shortcut.
-- Override any of them with :bindHotkeys{action = {mods, key}}.
-- ------------------------------------------------------------

local defaultHotkeys = {
  tileApp    = {{{"cmd"}, "pad0"}, {{"cmd"}, "pad*"}, {{"cmd", "ctrl"}, "0"}},
  tileAll    = {{{"cmd", "alt"}, "pad0"}, {{"cmd", "ctrl", "alt"}, "0"}},
  maximize   = {{{"cmd"}, "pad1"}, {{"cmd", "ctrl"}, "1"}},
  halves     = {{{"cmd"}, "pad2"}, {{"cmd", "ctrl"}, "2"}},
  thirds     = {{{"cmd"}, "pad3"}, {{"cmd", "ctrl"}, "3"}},
  fourths    = {{{"cmd"}, "pad4"}, {{"cmd", "ctrl"}, "4"}},
  center     = {{{"cmd"}, "pad5"}, {{"cmd", "ctrl"}, "5"}},
  sixths     = {{{"cmd"}, "pad6"}, {{"cmd", "ctrl"}, "6"}},
  almostMax  = {{{"cmd"}, "pad7"}, {{"cmd", "ctrl"}, "7"}},
  eighths    = {{{"cmd"}, "pad8"}, {{"cmd", "ctrl"}, "8"}},
  ninths     = {{{"cmd"}, "pad9"}, {{"cmd", "ctrl"}, "9"}},
  sixteenths = {{{"cmd", "alt"}, "pad4"}, {{"cmd", "ctrl", "alt"}, "4"}},

  undo             = {{{"cmd"}, "pad-"}, {{"cmd", "ctrl"}, "z"}},
  saveWorkspace    = {{{"cmd"}, "pad+"}, {{"cmd", "ctrl"}, "s"}},
  restoreWorkspace = {{{"cmd"}, "pad/"}, {{"cmd", "ctrl"}, "w"}},
  stashLeft        = {{{"cmd", "ctrl", "shift"}, "left"}},
  stashRight       = {{{"cmd", "ctrl", "shift"}, "right"}},
  unstash          = {{{"cmd", "ctrl", "shift"}, "u"}},
  sendNext         = {{{"cmd"}, "pad."}, {{"cmd", "ctrl", "alt"}, "right"}},
  sendPrev         = {{{"cmd", "alt"}, "pad."}, {{"cmd", "ctrl", "alt"}, "left"}},
}
-- Direct restore of slot N is numpad-only by default: every laptop digit chord
-- is either a macOS screenshot key (Cmd+Shift / Cmd+Ctrl+Shift + 3,4) or taken
-- on enough machines to be unsafe. Laptops use the chooser (restoreWorkspace),
-- or bind restore1..restore9 to whatever is free.
for i = 1, 9 do
  defaultHotkeys["restore" .. i] = {{{"cmd", "shift"}, "pad" .. i}}
end

local function copyHotkeys(src)
  local out = {}
  for action, chords in pairs(src) do
    out[action] = {}
    for i, chord in ipairs(chords) do
      out[action][i] = {chord[1], chord[2]}
    end
  end
  return out
end

-- ------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------

function obj:init()
  self._undo = {}
  self._last = {}
  self._stashed = {}
  self._workspaces = {}
  self._bound = {}
  self.hotkeys = copyHotkeys(defaultHotkeys)
  return self
end

--- Override shortcuts. mapping = {action = {mods, key}} or
--- {action = {{mods, key}, {mods, key}}} for several chords per action.
function obj:bindHotkeys(mapping)
  for action, chords in pairs(mapping) do
    if type(chords[1]) == "table" and type(chords[1][1]) == "table" then
      self.hotkeys[action] = chords
    else
      self.hotkeys[action] = {chords}
    end
  end
  return self
end

function obj:start()
  self:loadWorkspaces()
  local failed = self:_bindAll()
  if failed > 0 then
    hs.alert.show(string.format(
      "SnapNuts %s: %d shortcut%s already taken by macOS or another app (see console)",
      self.version, failed, failed == 1 and "" or "s"), 3)
  else
    hs.alert.show("SnapNuts " .. self.version, 1)
  end
  return self
end

function obj:stop()
  for _, hk in ipairs(self._bound) do hk:delete() end
  self._bound = {}
  return self
end

function obj:_actions()
  local a = {}
  for action, key in pairs(divisionForAction) do
    a[action] = function() self:snap(key) end
  end
  a.tileApp = function() self:tileApp() end
  a.tileAll = function() self:tileAll() end
  a.undo = function() self:undo() end
  a.saveWorkspace = function() self:chooseWorkspaceToSave() end
  a.restoreWorkspace = function() self:chooseWorkspaceToRestore() end
  for i = 1, 9 do
    a["restore" .. i] = function() self:restoreWorkspace(i) end
  end
  a.stashLeft = function() self:stash("left") end
  a.stashRight = function() self:stash("right") end
  a.unstash = function() self:unstashAll() end
  a.sendNext = function() self:moveToScreen(1) end
  a.sendPrev = function() self:moveToScreen(-1) end
  return a
end

--- Binds every chord in self.hotkeys. Returns how many could not be bound.
function obj:_bindAll()
  self:stop()
  local actions = self:_actions()
  local failed = 0
  for action, chords in pairs(self.hotkeys) do
    local fn = actions[action]
    if not fn then
      self.logger.w("unknown action in hotkeys: " .. tostring(action))
    else
      for _, chord in ipairs(chords) do
        local ok, hk = pcall(hs.hotkey.bind, chord[1], chord[2], fn)
        if ok and hk then
          table.insert(self._bound, hk)
        else
          failed = failed + 1
          self.logger.w(string.format("could not bind %s to %s+%s: %s",
            action, table.concat(chord[1], "+"), chord[2], tostring(hk)))
        end
      end
    end
  end
  return failed
end

-- ------------------------------------------------------------
-- Screens and frames
-- ------------------------------------------------------------

function obj:alert(msg)
  hs.alert.show(msg, self.alertDuration)
end

--- All screens, left to right, then top to bottom.
function obj:sortedScreens()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b)
    local fa, fb = a:frame(), b:frame()
    if fa.x ~= fb.x then return fa.x < fb.x end
    return fa.y < fb.y
  end)
  return screens
end

function obj:screenIndexOf(screens, screen)
  for i, s in ipairs(screens) do
    if s:id() == screen:id() then return i end
  end
  return 1
end

--- The division's cells as they apply to this screen frame.
function obj:positionsFor(division, sf)
  if self.portraitAware then
    return core.orient(division.positions, sf)
  end
  return division.positions
end

local function off(a, b)
  return math.abs(a - b) > 2
end

--- Put a window at an absolute frame. Two macOS quirks are handled:
--- an app may refuse a frame on a screen the window is not on yet (move it
--- there first), and a secondary display refuses to shrink a full-height
--- window by less than the menu bar height (go via a clearly smaller frame).
function obj:setFrameOn(win, screen, frame)
  win:setFrame(frame, 0)
  local got = win:frame()
  if off(got.x, frame.x) or off(got.y, frame.y) then
    win:moveToScreen(screen, false, false, 0)
    win:setFrame(frame, 0)
    got = win:frame()
  end
  if off(got.w, frame.w) or off(got.h, frame.h) then
    win:setFrame({
      x = frame.x, y = frame.y,
      w = math.max(100, frame.w - 64), h = math.max(100, frame.h - 64),
    }, 0)
    win:setFrame(frame, 0)
  end
end

--- The screen holding most of a frame; the main screen if none does.
function obj:screenForFrame(frame)
  local best, bestArea = nil, 0
  for _, s in ipairs(hs.screen.allScreens()) do
    local i = hs.geometry.intersectionRect(frame, s:fullFrame())
    local area = math.max(0, i.w) * math.max(0, i.h)
    if best == nil or area > bestArea then best, bestArea = s, area end
  end
  return best or hs.screen.mainScreen()
end

--- A window that cannot be snapped: native full screen, or none at all.
function obj:_unsnappable(win)
  if not win then
    self:alert("No focused window")
    return true
  end
  if win:isFullScreen() then
    self:alert("Window is full screen (Ctrl+Cmd+F to leave)")
    return true
  end
  return false
end

function obj:_followMouse(win, movedScreens)
  if self.mouseFollows and movedScreens then
    local f = win:frame()
    hs.mouse.absolutePosition({x = f.x + f.w / 2, y = f.y + f.h / 2})
  end
end

-- ------------------------------------------------------------
-- Snapping
-- ------------------------------------------------------------

--- Snap the focused window with division `key` ("1".."9", "16").
function obj:snap(key)
  return self:snapWindow(hs.window.focusedWindow(), key)
end

--- Snap a given window. Reads which cell the window is in now and moves it
--- to the next one; after the last cell it goes to cell 1 on the next screen.
function obj:snapWindow(win, key)
  local division = self.divisions[key]
  if not division then
    self.logger.w("no division " .. tostring(key))
    return false
  end
  if self:_unsnappable(win) then return false end

  local screens = self:sortedScreens()
  local sIdx = self:screenIndexOf(screens, win:screen() or hs.screen.mainScreen())
  local sf = screens[sIdx]:frame()
  local positions = self:positionsFor(division, sf)
  local wf = win:frame()
  local id = win:id()

  local current = core.matchPosition(positions, sf, self.gap, wf, self.matchTolerance)
  if not current and id then
    -- A window the app would not shrink to the cell: trust where we last
    -- put it, as long as its corner is still there.
    local mem = self._last[id]
    if mem and mem.key == key and mem.screen == screens[sIdx]:id() and positions[mem.index] then
      local f = core.frameFor(positions[mem.index], sf, self.gap)
      if math.abs(f.x - wf.x) <= self.matchTolerance and math.abs(f.y - wf.y) <= self.matchTolerance then
        current = mem.index
      end
    end
  end

  local index, tIdx = core.nextStep(#positions, current, sIdx, #screens)
  local target = screens[tIdx]
  local tsf = target:frame()
  local tpositions = self:positionsFor(division, tsf)
  local pos = tpositions[index]
  local frame = core.frameFor(pos, tsf, self.gap)

  self:recordUndo({{win = win, frame = wf}})
  self:setFrameOn(win, target, frame)
  if id then
    self._last[id] = {key = key, index = index, screen = target:id()}
  end
  self:_followMouse(win, tIdx ~= sIdx)

  local label = division.name .. ": " .. core.describe(pos)
  if #tpositions > 1 then
    label = label .. string.format(" (%d/%d)", index, #tpositions)
  end
  if #screens > 1 then
    label = label .. string.format(" [%d/%d]", tIdx, #screens)
  end
  self:alert(label)
  return true
end

--- Send a window to the next (dir = 1) or previous (dir = -1) screen.
--- A window SnapNuts placed keeps its cell, oriented for the new screen;
--- any other window keeps its frame relative to the screen.
function obj:moveToScreen(dir, win)
  win = win or hs.window.focusedWindow()
  if self:_unsnappable(win) then return false end
  local screens = self:sortedScreens()
  if #screens < 2 then
    self:alert("Only one screen")
    return false
  end
  local sIdx = self:screenIndexOf(screens, win:screen() or hs.screen.mainScreen())
  local tIdx = core.nextScreen(sIdx, #screens, dir)
  local sf, tsf = screens[sIdx]:frame(), screens[tIdx]:frame()
  local wf, id = win:frame(), win:id()

  local frame, label, keep
  local mem = id and self._last[id]
  if mem and mem.screen == screens[sIdx]:id() and self.divisions[mem.key] then
    local division = self.divisions[mem.key]
    local here = self:positionsFor(division, sf)
    if core.matchPosition(here, sf, self.gap, wf, self.matchTolerance) == mem.index then
      local pos = self:positionsFor(division, tsf)[mem.index]
      if pos then
        frame = core.frameFor(pos, tsf, self.gap)
        label = division.name .. ": " .. core.describe(pos)
        keep = {key = mem.key, index = mem.index, screen = screens[tIdx]:id()}
      end
    end
  end
  if not frame then
    frame = core.absoluteFrame(core.relativeFrame(wf, sf), tsf)
    label = "Moved"
  end

  self:recordUndo({{win = win, frame = wf}})
  self:setFrameOn(win, screens[tIdx], frame)
  if id then self._last[id] = keep end
  self:_followMouse(win, true)
  self:alert(string.format("%s [%d/%d]", label, tIdx, #screens))
  return true
end

-- ------------------------------------------------------------
-- Undo
-- ------------------------------------------------------------

--- entries = list of {win = hs.window, frame = rect}. One entry per undo step,
--- so a tile of six windows undoes as one step.
function obj:recordUndo(entries)
  table.insert(self._undo, entries)
  while #self._undo > self.undoLevels do
    table.remove(self._undo, 1)
  end
end

function obj:undo()
  local entries = table.remove(self._undo)
  if not entries then
    self:alert("Nothing to undo")
    return false
  end
  local n = 0
  for _, e in ipairs(entries) do
    local ok, visible = pcall(function() return e.win and e.win:isVisible() end)
    if ok and visible then
      self:setFrameOn(e.win, self:screenForFrame(e.frame), e.frame)
      local id = e.win:id()
      if id then self._last[id] = nil end
      n = n + 1
    end
  end
  if n == 0 then
    self:alert("Window no longer exists")
  elseif n == 1 then
    self:alert("Undone")
  else
    self:alert("Undone (" .. n .. " windows)")
  end
  return n > 0
end

-- ------------------------------------------------------------
-- Tile All
-- ------------------------------------------------------------

local function standardWindows(list)
  local out = {}
  for _, w in ipairs(list) do
    if w:isStandard() and w:isVisible() and not w:isMinimized() and not w:isFullScreen() then
      out[#out + 1] = w
    end
  end
  return out
end

function obj:_tile(wins, screen, what)
  if #wins == 0 then
    self:alert("No windows to tile")
    return false
  end
  local sf = screen:frame()
  local frames = core.tileFrames(#wins, sf, self.tileGap)
  local undo = {}
  for i, w in ipairs(wins) do undo[i] = {win = w, frame = w:frame()} end
  self:recordUndo(undo)
  for i, w in ipairs(wins) do
    self:setFrameOn(w, screen, frames[i])
    local id = w:id()
    if id then self._last[id] = nil end
  end
  local cols, rows = core.tileGrid(#wins, sf)
  self:alert(string.format("Tiled %d %s (%dx%d)", #wins, what, cols, rows))
  return true
end

local function focusedScreen()
  local win = hs.window.focusedWindow()
  return (win and win:screen()) or hs.screen.mainScreen()
end

--- Tile every window of one app (default: the frontmost app) on the focused screen.
function obj:tileApp(app)
  app = app or hs.application.frontmostApplication()
  if not app then
    self:alert("No active app")
    return false
  end
  local wins = standardWindows(app:allWindows())
  return self:_tile(wins, focusedScreen(), (app:name() or "app") .. " windows")
end

--- Tile every visible window of every app on the focused screen.
function obj:tileAll()
  local screen = focusedScreen()
  local wins = {}
  for _, w in ipairs(standardWindows(hs.window.visibleWindows())) do
    if w:screen():id() == screen:id() then wins[#wins + 1] = w end
  end
  return self:_tile(wins, screen, "windows")
end

-- ------------------------------------------------------------
-- Workspaces: saved to disk, restored onto whatever screens are attached
-- ------------------------------------------------------------

function obj:workspacePath()
  return self.workspaceFile or (hs.configdir .. "/snapnuts-workspaces.json")
end

function obj:loadWorkspaces()
  local ok, data = pcall(hs.json.read, self:workspacePath())
  self._workspaces = (ok and type(data) == "table") and data or {}
end

function obj:saveWorkspaces()
  local ok, err = pcall(hs.json.write, self._workspaces, self:workspacePath(), true, true)
  if not ok then self.logger.e("could not write workspaces: " .. tostring(err)) end
end

function obj:saveWorkspace(slot)
  slot = tostring(slot)
  local screens = self:sortedScreens()
  local list = {}
  for _, win in ipairs(standardWindows(hs.window.visibleWindows())) do
    local app = win:application()
    if app then
      local scr = win:screen()
      list[#list + 1] = {
        app = app:name(),
        bundle = app:bundleID(),
        title = win:title(),
        screen = scr:name(),
        screenIndex = self:screenIndexOf(screens, scr),
        rel = core.relativeFrame(win:frame(), scr:frame()),
      }
    end
  end
  self._workspaces[slot] = {saved = os.date("%Y-%m-%d %H:%M"), windows = list}
  self:saveWorkspaces()
  self:alert("Workspace " .. slot .. " saved (" .. #list .. " windows)")
  return #list
end

function obj:restoreWorkspace(slot)
  slot = tostring(slot)
  local ws = self._workspaces[slot]
  if not ws or not ws.windows then
    self:alert("No workspace in slot " .. slot)
    return 0
  end
  local screens = self:sortedScreens()
  local byName = {}
  for _, s in ipairs(screens) do byName[s:name()] = byName[s:name()] or s end

  local claimed, undo, restored = {}, {}, 0
  for _, saved in ipairs(ws.windows) do
    local app = (saved.bundle and hs.application.get(saved.bundle)) or (saved.app and hs.application.get(saved.app))
    if app then
      local candidates = {}
      for _, w in ipairs(standardWindows(app:allWindows())) do
        if not claimed[w:id()] then candidates[#candidates + 1] = w end
      end
      local pick
      for _, w in ipairs(candidates) do
        if w:title() == saved.title then pick = w; break end
      end
      pick = pick or candidates[1]
      if pick then
        claimed[pick:id()] = true
        local scr = byName[saved.screen] or screens[saved.screenIndex or 1] or hs.screen.primaryScreen()
        local frame = core.absoluteFrame(saved.rel, scr:frame())
        undo[#undo + 1] = {win = pick, frame = pick:frame()}
        self:setFrameOn(pick, scr, frame)
        local id = pick:id()
        if id then self._last[id] = nil end
        restored = restored + 1
      end
    end
  end
  if #undo > 0 then self:recordUndo(undo) end
  self:alert(string.format("Workspace %s restored (%d/%d windows)", slot, restored, #ws.windows))
  return restored
end

local function slotLabel(self, i)
  local ws = self._workspaces[tostring(i)]
  if ws and ws.windows then
    return string.format("%d windows, saved %s", #ws.windows, ws.saved or "?")
  end
  return "empty"
end

function obj:chooseWorkspaceToSave()
  local choices = {}
  for i = 1, 9 do
    choices[#choices + 1] = {text = "Slot " .. i, subText = slotLabel(self, i), slot = i}
  end
  local chooser = hs.chooser.new(function(choice)
    if choice then self:saveWorkspace(choice.slot) end
  end)
  chooser:choices(choices)
  chooser:placeholderText("Save workspace to slot")
  chooser:show()
end

function obj:chooseWorkspaceToRestore()
  local choices = {}
  for i = 1, 9 do
    local ws = self._workspaces[tostring(i)]
    if ws and ws.windows then
      choices[#choices + 1] = {text = "Slot " .. i, subText = slotLabel(self, i), slot = i}
    end
  end
  if #choices == 0 then
    self:alert("No saved workspaces")
    return
  end
  local chooser = hs.chooser.new(function(choice)
    if choice then self:restoreWorkspace(choice.slot) end
  end)
  chooser:choices(choices)
  chooser:placeholderText("Restore workspace")
  chooser:show()
end

-- ------------------------------------------------------------
-- Stashing: park a window at the screen edge, bring them all back later
-- ------------------------------------------------------------

--- Stash the focused window off the left or right edge of the whole desktop.
function obj:stash(side)
  return self:stashSide(side, hs.window.focusedWindow())
end

function obj:stashSide(side, win)
  if self:_unsnappable(win) then return false end
  local frames = {}
  for i, s in ipairs(hs.screen.allScreens()) do frames[i] = s:fullFrame() end
  local f = win:frame()
  local target = core.stashFrame(side, f, frames, self.stashPeek)
  self:recordUndo({{win = win, frame = f}})
  table.insert(self._stashed, {win = win, frame = f})
  self:setFrameOn(win, self:screenForFrame(target), target)
  self:alert("Stashed " .. side)
  return true
end

function obj:unstashAll()
  if #self._stashed == 0 then
    self:alert("No stashed windows")
    return 0
  end
  local n = 0
  for _, s in ipairs(self._stashed) do
    local ok, visible = pcall(function() return s.win and s.win:isVisible() end)
    if ok and visible then
      self:setFrameOn(s.win, self:screenForFrame(s.frame), s.frame)
      n = n + 1
    end
  end
  self._stashed = {}
  self:alert("Unstashed " .. n .. " windows")
  return n
end

return obj
