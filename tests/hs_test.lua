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

-- Helpers for the multi-screen checks below
local function overlapWidth(f, s)
  local i = hs.geometry.intersectionRect(f, s:fullFrame())
  return (i.w > 0 and i.h > 0) and i.w or 0
end
local function desktop()
  local l, r = math.huge, -math.huge
  for _, s in ipairs(hs.screen.allScreens()) do
    local f = s:fullFrame()
    l = math.min(l, f.x); r = math.max(r, f.x + f.w)
  end
  return l, r
end

-- 9. Stash parks the window off the edge of the WHOLE desktop. On a rig with a
-- screen to the right, a screen-edge stash would dump the window onto it.
local primary = hs.screen.primaryScreen()
win:moveToScreen(primary, false, false, 0)
local psf = primary:frame()
local preStash = {x = psf.x + 200, y = psf.y + 100, w = 900, h = 600}
win:setFrame(preStash, 0)
S._stashed = {}
local okStash, errStash = pcall(function() S:stashSide("right", win) end)
if okStash then
  local f = win:frame()
  local _, right = desktop()
  check("stash right ends past the desktop's right edge", f.x >= right - S.stashPeek - TOL,
    fmt(f) .. " desktop right edge " .. right)
  local worst = 0
  for _, s in ipairs(hs.screen.allScreens()) do worst = math.max(worst, overlapWidth(f, s)) end
  check("stashed window shows at most the peek on any screen", worst <= S.stashPeek + TOL,
    "widest overlap " .. worst .. " px")
  S:unstashAll()
  check("unstash brings it back", frameNear(win:frame(), preStash, TOL), fmt(win:frame()))
else
  check("stash right (stashSide)", false, errStash)
end

-- 10. Send to the next / previous screen keeps the window's relative frame
if nScreens > 1 then
  win:moveToScreen(screens[1], false, false, 0)
  local s1 = screens[1]:frame()
  local start = {x = s1.x + math.floor(s1.w * 0.25), y = s1.y + math.floor(s1.h * 0.1),
                 w = math.floor(s1.w * 0.5), h = math.floor(s1.h * 0.6)}
  win:setFrame(start, 0)
  S._last = {}
  local okMove, errMove = pcall(function() S:moveToScreen(1, win) end)
  if okMove then
    local gotIdx = S:screenIndexOf(screens, win:screen())
    check("send next lands on screen 2", gotIdx == 2, "on " .. gotIdx)
    local want = core.absoluteFrame(core.relativeFrame(start, s1), screens[2]:frame())
    check("send next keeps the relative frame", frameNear(win:frame(), want, TOL),
      fmt(win:frame()) .. " vs " .. fmt(want))
    S:moveToScreen(-1, win)
    check("send previous comes back to screen 1 at the original frame",
      S:screenIndexOf(screens, win:screen()) == 1 and frameNear(win:frame(), start, TOL), fmt(win:frame()))

    -- 11. A snapped window keeps its CELL across the hop (oriented for the target)
    S._last = {}
    S:snapWindow(win, "2")  -- Left half on screen 1
    S:moveToScreen(1, win)
    local cell = core.frameFor(S:positionsFor(S.divisions["2"], screens[2]:frame())[1], screens[2]:frame(), S.gap)
    check("send next keeps the halves cell on the new screen", frameNear(win:frame(), cell, TOL),
      fmt(win:frame()) .. " vs " .. fmt(cell))

    -- 12. Undo after a hop goes back across screens
    S:undo()
    local back = core.frameFor(S:positionsFor(S.divisions["2"], s1)[1], s1, S.gap)
    check("undo after send returns to the previous screen's cell", frameNear(win:frame(), back, TOL), fmt(win:frame()))
  else
    check("send to next screen (moveToScreen)", false, errMove)
  end
end

-- Put the console back where it was and close it
win:setFrame(original, 0)
hs.closeConsole()
finish()
