-- SnapNuts core tests. Plain Lua, no Hammerspoon needed.
-- Run from anywhere:  lua tests/core_test.lua
local here = arg and arg[0] and arg[0]:match("(.*/)") or "./"
local ok, core = pcall(dofile, here .. "../SnapNuts.spoon/core.lua")
if not ok then
  print("FAIL: could not load core.lua :: " .. tostring(core))
  os.exit(1)
end

local passed, failed = 0, 0

local function fail(name, detail)
  failed = failed + 1
  print("FAIL: " .. name .. (detail and (" :: " .. tostring(detail)) or ""))
end

local function test(name, fn)
  local okRun, err = pcall(fn)
  if okRun then passed = passed + 1 else fail(name, err) end
end

local function near(a, b, tol)
  return math.abs(a - b) <= (tol or 1e-9)
end

local function assertEq(got, want, label)
  if got ~= want then
    error(string.format("%s: got %s, want %s", label or "value", tostring(got), tostring(want)), 2)
  end
end

local function assertNear(got, want, tol, label)
  if not near(got, want, tol) then
    error(string.format("%s: got %s, want %s", label or "value", tostring(got), tostring(want)), 2)
  end
end

local function assertPos(pos, x, y, w, h, label)
  assertNear(pos.x, x, 1e-9, (label or "pos") .. ".x")
  assertNear(pos.y, y, 1e-9, (label or "pos") .. ".y")
  assertNear(pos.w, w, 1e-9, (label or "pos") .. ".w")
  assertNear(pos.h, h, 1e-9, (label or "pos") .. ".h")
end

-- ------------------------------------------------------------
-- grid(cols, rows): row-major cells as exact fractions
-- ------------------------------------------------------------

test("grid(3,1) gives three vertical strips left to right", function()
  local g = core.grid(3, 1)
  assertEq(#g, 3, "count")
  assertPos(g[1], 0, 0, 1/3, 1, "g1")
  assertPos(g[2], 1/3, 0, 1/3, 1, "g2")
  assertPos(g[3], 2/3, 0, 1/3, 1, "g3")
end)

test("grid(2,2) is row-major: TL, TR, BL, BR", function()
  local g = core.grid(2, 2)
  assertEq(#g, 4, "count")
  assertPos(g[1], 0, 0, 0.5, 0.5, "TL")
  assertPos(g[2], 0.5, 0, 0.5, 0.5, "TR")
  assertPos(g[3], 0, 0.5, 0.5, 0.5, "BL")
  assertPos(g[4], 0.5, 0.5, 0.5, 0.5, "BR")
end)

test("concat joins position lists in order without sharing tables", function()
  local a, b = core.grid(2, 1), core.grid(1, 2)
  local c = core.concat(a, b)
  assertEq(#c, 4, "count")
  assertPos(c[1], 0, 0, 0.5, 1, "c1")
  assertPos(c[3], 0, 0, 1, 0.5, "c3")
  assertEq(c[1] == a[1], false, "copied, not aliased")
end)

-- ------------------------------------------------------------
-- frameFor(pos, screenFrame, gap): integer pixel frame
-- ------------------------------------------------------------

test("frameFor full position with no gap equals the screen frame", function()
  local sf = {x = 100, y = 50, w = 1920, h = 1049}
  local f = core.frameFor({x = 0, y = 0, w = 1, h = 1}, sf, 0)
  assertEq(f.x, 100, "x"); assertEq(f.y, 50, "y")
  assertEq(f.w, 1920, "w"); assertEq(f.h, 1049, "h")
end)

test("frameFor returns integers", function()
  local sf = {x = 0, y = 25, w = 1049, h = 1889}
  for _, pos in ipairs(core.grid(3, 3)) do
    local f = core.frameFor(pos, sf, 0)
    for _, k in ipairs({"x", "y", "w", "h"}) do
      if f[k] ~= math.floor(f[k]) then error(k .. " not integer: " .. f[k]) end
    end
  end
end)

test("adjacent cells share edges exactly on every common screen width", function()
  local widths = {1920, 1049, 1080, 1889, 2560, 3440, 5120, 1366, 1440, 1512, 1728, 999}
  for _, cols in ipairs({2, 3, 4}) do
    for _, w in ipairs(widths) do
      local sf = {x = 7, y = 3, w = w, h = 1000}
      local g = core.grid(cols, 1)
      local frames = {}
      for i, pos in ipairs(g) do frames[i] = core.frameFor(pos, sf, 0) end
      assertEq(frames[1].x, sf.x, cols .. " cols @" .. w .. " first.x")
      for i = 1, cols - 1 do
        assertEq(frames[i].x + frames[i].w, frames[i + 1].x,
          cols .. " cols @" .. w .. " edge " .. i)
      end
      assertEq(frames[cols].x + frames[cols].w, sf.x + sf.w, cols .. " cols @" .. w .. " last edge")
    end
  end
end)

test("adjacent rows share edges exactly on every common screen height", function()
  local heights = {1049, 1889, 1080, 1415, 2160, 900, 1117, 777}
  for _, rows in ipairs({2, 3, 4}) do
    for _, h in ipairs(heights) do
      local sf = {x = 0, y = 25, w = 1000, h = h}
      local g = core.grid(1, rows)
      local frames = {}
      for i, pos in ipairs(g) do frames[i] = core.frameFor(pos, sf, 0) end
      assertEq(frames[1].y, sf.y, rows .. " rows @" .. h .. " first.y")
      for i = 1, rows - 1 do
        assertEq(frames[i].y + frames[i].h, frames[i + 1].y,
          rows .. " rows @" .. h .. " edge " .. i)
      end
      assertEq(frames[rows].y + frames[rows].h, sf.y + sf.h, rows .. " rows @" .. h .. " last edge")
    end
  end
end)

test("gap leaves a full margin at the screen edge and one gap between neighbours", function()
  local sf = {x = 0, y = 0, w = 1000, h = 600}
  local g = core.grid(2, 1)
  local l = core.frameFor(g[1], sf, 8)
  local r = core.frameFor(g[2], sf, 8)
  assertEq(l.x, 8, "left margin")
  assertEq(l.y, 8, "top margin")
  assertEq(l.h, 600 - 16, "height inside margins")
  assertEq(r.x - (l.x + l.w), 8, "gap between")
  assertEq(r.x + r.w, 1000 - 8, "right margin")
end)

-- ------------------------------------------------------------
-- matchPosition(positions, sf, gap, frame, tol): which cell is the window in?
-- ------------------------------------------------------------

test("matchPosition finds the cell a window exactly occupies", function()
  local sf = {x = 0, y = 25, w = 1920, h = 1049}
  local g = core.grid(3, 1)
  local f = core.frameFor(g[2], sf, 0)
  assertEq(core.matchPosition(g, sf, 0, f, 16), 2, "index")
end)

test("matchPosition returns nil for a frame that is no cell", function()
  local sf = {x = 0, y = 25, w = 1920, h = 1049}
  local g = core.grid(3, 1)
  assertEq(core.matchPosition(g, sf, 0, {x = 300, y = 200, w = 700, h = 500}, 16), nil, "index")
end)

test("matchPosition tolerates small deviations but not large ones", function()
  local sf = {x = 0, y = 25, w = 1920, h = 1049}
  local g = core.grid(4, 2)
  local f = core.frameFor(g[6], sf, 0)
  local close = {x = f.x + 5, y = f.y - 3, w = f.w - 9, h = f.h + 2}
  local far = {x = f.x + 40, y = f.y, w = f.w, h = f.h}
  assertEq(core.matchPosition(g, sf, 0, close, 16), 6, "close")
  assertEq(core.matchPosition(g, sf, 0, far, 16), nil, "far")
end)

test("matchPosition prefers the first cell when two sets share a corner", function()
  -- Fourths = 4 strips + 4 quarters. A left strip and the TL quarter share (0,0).
  local sf = {x = 0, y = 0, w = 1920, h = 1049}
  local positions = core.concat(core.grid(4, 1), core.grid(2, 2))
  local strip = core.frameFor(positions[1], sf, 0)
  local quarter = core.frameFor(positions[5], sf, 0)
  assertEq(core.matchPosition(positions, sf, 0, strip, 16), 1, "strip")
  assertEq(core.matchPosition(positions, sf, 0, quarter, 16), 5, "quarter")
end)

-- ------------------------------------------------------------
-- nextStep(n, current, screenIndex, numScreens) -> index, screenIndex
-- ------------------------------------------------------------

test("nextStep starts at 1 on the same screen when the window is in no cell", function()
  local i, s = core.nextStep(3, nil, 2, 3)
  assertEq(i, 1, "index"); assertEq(s, 2, "screen")
end)

test("nextStep advances one cell on the same screen", function()
  local i, s = core.nextStep(3, 1, 2, 3)
  assertEq(i, 2, "index"); assertEq(s, 2, "screen")
end)

test("nextStep hops to the next screen after the last cell", function()
  local i, s = core.nextStep(3, 3, 2, 3)
  assertEq(i, 1, "index"); assertEq(s, 3, "screen")
end)

test("nextStep wraps from the last screen to the first", function()
  local i, s = core.nextStep(3, 3, 3, 3)
  assertEq(i, 1, "index"); assertEq(s, 1, "screen")
end)

test("nextStep on a single-cell division cycles screens", function()
  local i, s = core.nextStep(1, 1, 1, 2)
  assertEq(i, 1, "index"); assertEq(s, 2, "screen")
end)

test("nextStep on one screen stays put at the end of a single-cell division", function()
  local i, s = core.nextStep(1, 1, 1, 1)
  assertEq(i, 1, "index"); assertEq(s, 1, "screen")
end)

-- ------------------------------------------------------------
-- transpose / orient: portrait screens get the division turned 90 degrees
-- ------------------------------------------------------------

test("transpose turns vertical strips into horizontal bands", function()
  local t = core.transpose(core.grid(3, 1))
  local want = core.grid(1, 3)
  assertEq(#t, 3, "count")
  for i = 1, 3 do assertPos(t[i], want[i].x, want[i].y, want[i].w, want[i].h, "cell " .. i) end
end)

test("transpose keeps a 2x2 of quarters a 2x2 of quarters", function()
  local t = core.transpose(core.grid(2, 2))
  assertPos(t[1], 0, 0, 0.5, 0.5, "TL")
  assertPos(t[2], 0, 0.5, 0.5, 0.5, "second is now below, not right")
end)

test("orient leaves a landscape screen alone", function()
  local g = core.grid(3, 1)
  local o = core.orient(g, {x = 0, y = 0, w = 1920, h = 1049})
  assertEq(o == g, true, "same table on landscape")
end)

test("orient transposes on a portrait screen", function()
  local o = core.orient(core.grid(3, 1), {x = 0, y = 0, w = 1080, h = 1889})
  assertPos(o[2], 0, 1/3, 1, 1/3, "middle band")
end)

-- ------------------------------------------------------------
-- describe(pos): the label shown in the alert
-- ------------------------------------------------------------

test("describe names strips, bands, quarters, cells and centred positions", function()
  assertEq(core.describe({x = 0, y = 0, w = 1, h = 1}), "Full", "full")
  local halves = core.grid(2, 1)
  assertEq(core.describe(halves[1]), "Left", "left half")
  assertEq(core.describe(halves[2]), "Right", "right half")
  assertEq(core.describe(core.grid(3, 1)[2]), "Center", "center third")
  assertEq(core.describe(core.grid(4, 1)[2]), "Column 2/4", "fourth strip")
  local bands = core.grid(1, 2)
  assertEq(core.describe(bands[1]), "Top", "top band")
  assertEq(core.describe(bands[2]), "Bottom", "bottom band")
  assertEq(core.describe(core.grid(1, 3)[2]), "Middle", "middle band")
  assertEq(core.describe(core.grid(1, 4)[3]), "Row 3/4", "fourth band")
  local q = core.grid(2, 2)
  assertEq(core.describe(q[1]), "Top-left", "TL")
  assertEq(core.describe(q[4]), "Bottom-right", "BR")
  assertEq(core.describe(core.grid(3, 3)[6]), "R2 C3", "ninth cell")
  assertEq(core.describe({x = 0.1, y = 0.1, w = 0.8, h = 0.8}), "Center 80%", "centred")
end)

-- ------------------------------------------------------------
-- tileGrid / tileFrames: Tile All layout
-- ------------------------------------------------------------

test("tileGrid reproduces the original table for 1 to 12 windows", function()
  local sf = {x = 0, y = 0, w = 1920, h = 1049}
  local want = {
    [1] = {1, 1}, [2] = {2, 1}, [3] = {2, 2}, [4] = {2, 2},
    [5] = {3, 2}, [6] = {3, 2}, [7] = {3, 3}, [8] = {3, 3}, [9] = {3, 3},
    [10] = {4, 3}, [11] = {4, 3}, [12] = {4, 3},
  }
  for n, cr in pairs(want) do
    local c, r = core.tileGrid(n, sf)
    assertEq(c, cr[1], n .. " cols"); assertEq(r, cr[2], n .. " rows")
  end
end)

test("tileGrid grows past 12 windows instead of overflowing the screen", function()
  local c, r = core.tileGrid(13, {x = 0, y = 0, w = 1920, h = 1049})
  if c * r < 13 then error("13 windows need 13 cells, got " .. c .. "x" .. r) end
end)

test("tileGrid swaps columns and rows on a portrait screen", function()
  local c, r = core.tileGrid(6, {x = 0, y = 0, w = 1080, h = 1889})
  assertEq(c, 2, "cols"); assertEq(r, 3, "rows")
end)

test("tileFrames lays windows out with a gap around and between", function()
  local sf = {x = 0, y = 0, w = 1000, h = 1000}
  local frames = core.tileFrames(4, sf, 4)
  assertEq(#frames, 4, "count")
  assertEq(frames[1].x, 4, "f1.x"); assertEq(frames[1].y, 4, "f1.y")
  assertEq(frames[1].w, 494, "f1.w"); assertEq(frames[1].h, 494, "f1.h")
  assertEq(frames[2].x, 502, "f2.x"); assertEq(frames[2].y, 4, "f2.y")
  assertEq(frames[3].x, 4, "f3.x"); assertEq(frames[3].y, 502, "f3.y")
  assertEq(frames[4].x + frames[4].w, 996, "right margin")
end)

test("tileFrames returns exactly n frames even when the grid has spare cells", function()
  local frames = core.tileFrames(3, {x = 0, y = 0, w = 1000, h = 1000}, 4)
  assertEq(#frames, 3, "count")
  assertEq(frames[3].y, 502, "third window on the second row")
end)

-- ------------------------------------------------------------
-- relativeFrame / absoluteFrame: workspaces survive a monitor change
-- ------------------------------------------------------------

test("relativeFrame and absoluteFrame round-trip on the same screen", function()
  local sf = {x = 1920, y = 0, w = 1080, h = 1889}
  local f = {x = 2000, y = 100, w = 900, h = 700}
  local back = core.absoluteFrame(core.relativeFrame(f, sf), sf)
  assertEq(back.x, 2000, "x"); assertEq(back.y, 100, "y")
  assertEq(back.w, 900, "w"); assertEq(back.h, 700, "h")
end)

test("absoluteFrame maps a saved layout onto a different screen", function()
  local saved = core.relativeFrame({x = 0, y = 0, w = 960, h = 1049}, {x = 0, y = 0, w = 1920, h = 1049})
  local f = core.absoluteFrame(saved, {x = 100, y = 25, w = 2560, h = 1415})
  assertEq(f.x, 100, "x"); assertEq(f.w, 1280, "half of the new width")
  assertEq(f.h, 1415, "full new height")
end)

-- ------------------------------------------------------------
print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
