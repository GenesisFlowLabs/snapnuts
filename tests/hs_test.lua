-- SnapNuts integration test. Runs INSIDE Hammerspoon, with the Spoon installed:
--   hs -c 'dofile(os.getenv("HOME") .. "/projects/tools/snapnuts/tests/hs_test.lua")'
-- It pushes the Hammerspoon console window around for a few seconds, then puts
-- it back and closes it. Nothing else on screen is touched.

local passed, failed = 0, 0
local lines = {}
local function say(s) lines[#lines + 1] = s end
local function check(name, cond, detail)
  if cond then
    passed = passed + 1
  else
    failed = failed + 1
    say("FAIL: " .. name .. (detail and (" :: " .. tostring(detail)) or ""))
  end
end
local function near(a, b, tol) return math.abs(a - b) <= tol end
local function frameNear(f, g, tol)
  return near(f.x, g.x, tol) and near(f.y, g.y, tol) and near(f.w, g.w, tol) and near(f.h, g.h, tol)
end
local function fmt(f) return string.format("(%d,%d %dx%d)", f.x, f.y, f.w, f.h) end
local function finish()
  say(string.format("%d passed, %d failed", passed, failed))
  print(table.concat(lines, "\n"))
end

local S = spoon and spoon.SnapNuts
if not S then
  failed = failed + 1
  say("FAIL: spoon.SnapNuts is not loaded")
  finish()
  return
end
local core = S.core
local TOL = 4
local FULL = {x = 0, y = 0, w = 1, h = 1}

hs.openConsole()
local win = hs.console.hswindow()
if not win then
  failed = failed + 1
  say("FAIL: no console window to test with")
  finish()
  return
end
local original = win:frame()

local screens = S:sortedScreens()
local nScreens = #screens
say("screens: " .. nScreens)

-- 1. Halves: successive presses land on each cell in order, on the window's own screen
local sf = win:screen():frame()
local startScreen = S:screenIndexOf(screens, win:screen())
local halves = S:positionsFor(S.divisions["2"], sf)
S._last = {}
win:setFrame({x = sf.x + 123, y = sf.y + 77, w = 640, h = 480}, 0)
for i = 1, #halves do
  S:snapWindow(win, "2")
  local want = core.frameFor(halves[i], sf, S.gap)
  check("halves press " .. i, frameNear(win:frame(), want, TOL), fmt(win:frame()) .. " vs " .. fmt(want))
end

-- 2. After the last cell the window hops to the next screen, cell 1
S:snapWindow(win, "2")
local nowScreen = S:screenIndexOf(screens, win:screen())
check("hops to the next screen after the last cell",
  nowScreen == (startScreen % nScreens) + 1, "from " .. startScreen .. " to " .. nowScreen)
local nsf = win:screen():frame()
local nh = S:positionsFor(S.divisions["2"], nsf)
check("lands on cell 1 of the new screen",
  frameNear(win:frame(), core.frameFor(nh[1], nsf, S.gap), TOL), fmt(win:frame()))

-- 3. Undo puts it back on the previous screen's last cell
S:undo()
check("undo restores the previous frame across screens",
  frameNear(win:frame(), core.frameFor(halves[#halves], sf, S.gap), TOL), fmt(win:frame()))

-- 4. Maximize visits every screen in order and comes back to the first
win:moveToScreen(screens[1], false, false, 0)
win:setFrame({x = screens[1]:frame().x + 50, y = screens[1]:frame().y + 50, w = 600, h = 400}, 0)
S._last = {}
for i = 1, nScreens + 1 do
  S:snapWindow(win, "1")
  local wantScreen = ((i - 1) % nScreens) + 1
  local gotScreen = S:screenIndexOf(screens, win:screen())
  check("maximize press " .. i .. " is on screen " .. wantScreen, gotScreen == wantScreen, "got " .. gotScreen)
  local f = win:screen():frame()
  check("maximize press " .. i .. " fills the screen",
    frameNear(win:frame(), core.frameFor(FULL, f, S.gap), TOL), fmt(win:frame()) .. " vs " .. fmt(f))
end

-- 5. Portrait awareness on whatever portrait screens are attached
for i, s in ipairs(screens) do
  local f = s:frame()
  if f.h > f.w then
    local thirds = S:positionsFor(S.divisions["3"], f)
    check("thirds are bands on portrait screen " .. i, thirds[1].w == 1 and thirds[1].h < 1)
  end
end

-- 6a. Save records every visible standard window and persists it to disk
local tmp = os.tmpname()
local savedFile, savedWs = S.workspaceFile, S._workspaces
S.workspaceFile = tmp
S._workspaces = {}
local expect = 0
for _, w in ipairs(hs.window.visibleWindows()) do
  if w:isStandard() and w:isVisible() and not w:isMinimized() and w:application() then expect = expect + 1 end
end
local saved = S:saveWorkspace(9)
check("save records every visible window (" .. expect .. ")", saved == expect, "saved " .. saved)
check("workspace file written", hs.fs.attributes(tmp) ~= nil)
S._workspaces = {}
S:loadWorkspaces()
check("workspace reloads from disk",
  S._workspaces["9"] ~= nil and #S._workspaces["9"].windows == saved)

-- 6b. Restore puts a window back from its record, mapped onto its screen.
-- Hammerspoon hides its own windows from visibleWindows(), so the console's
-- record is injected rather than saved.
win:moveToScreen(screens[1], false, false, 0)
local sf1 = screens[1]:frame()
local wantFrame = core.frameFor(core.grid(2, 1)[1], sf1, 0)
S._workspaces["8"] = {saved = "test", windows = {{
  app = "Hammerspoon", bundle = "org.hammerspoon.Hammerspoon", title = win:title(),
  screen = screens[1]:name(), screenIndex = 1,
  rel = core.relativeFrame(wantFrame, sf1),
}}}
S:saveWorkspaces()
S._workspaces = {}
S:loadWorkspaces()
win:setFrame({x = sf1.x + 200, y = sf1.y + 150, w = 500, h = 400}, 0)
local restored = S:restoreWorkspace(8)
check("restore finds the saved window", restored == 1, "restored " .. restored)
check("restore puts the window back", frameNear(win:frame(), wantFrame, TOL),
  fmt(win:frame()) .. " vs " .. fmt(wantFrame))
os.remove(tmp)
S.workspaceFile, S._workspaces = savedFile, savedWs

-- 7. Tile the Hammerspoon app: the console lands on one of the tile cells
local app = hs.application.get("Hammerspoon")
S:tileApp(app)
local tf = win:screen():frame()
local count = 0
for _, w in ipairs(app:allWindows()) do
  if w:isStandard() and w:isVisible() and not w:isMinimized() then count = count + 1 end
end
local cells = core.tileFrames(count, tf, S.tileGap)
local onCell = false
for _, c in ipairs(cells) do if frameNear(win:frame(), c, TOL) then onCell = true end end
check("tile app puts the console on a tile cell (" .. count .. " windows)", onCell, fmt(win:frame()))

-- 8. Undo after a tile restores the pre-tile frame
local preTile = {x = sf1.x + 200, y = sf1.y + 150, w = 500, h = 400}
win:setFrame(preTile, 0)
S:tileApp(app)
S:undo()
check("undo reverts a tile", frameNear(win:frame(), preTile, TOL), fmt(win:frame()))

-- Put the console back where it was and close it
win:setFrame(original, 0)
hs.closeConsole()
finish()
