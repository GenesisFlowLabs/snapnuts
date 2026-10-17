-- SnapNuts core: pure geometry, no Hammerspoon dependency.
-- Everything here is testable with plain Lua (see tests/core_test.lua).
--
-- A "position" is a rectangle in screen fractions: {x, y, w, h}, each 0..1.
-- A "frame" is a rectangle in pixels: {x, y, w, h}.

local core = {}

local function round(v)
  return math.floor(v + 0.5)
end

-- Row-major grid of cols x rows cells, as exact fractions.
function core.grid(cols, rows)
  local out = {}
  for r = 0, rows - 1 do
    for c = 0, cols - 1 do
      out[#out + 1] = {x = c / cols, y = r / rows, w = 1 / cols, h = 1 / rows}
    end
  end
  return out
end

-- Join any number of position lists into a new list of copies.
function core.concat(...)
  local out = {}
  for _, list in ipairs({...}) do
    for _, p in ipairs(list) do
      out[#out + 1] = {x = p.x, y = p.y, w = p.w, h = p.h}
    end
  end
  return out
end

-- Pixel frame for a position on a screen frame.
-- Edges are rounded (not widths) so neighboring cells meet exactly.
-- gap: full gap against the screen edge, half a gap on each inner edge,
-- so two neighbors end up one gap apart.
function core.frameFor(pos, sf, gap)
  gap = gap or 0
  local eps = 1e-9
  local l = round(sf.w * pos.x)
  local r = round(sf.w * (pos.x + pos.w))
  local t = round(sf.h * pos.y)
  local b = round(sf.h * (pos.y + pos.h))

  local gl = (pos.x <= eps) and gap or gap / 2
  local gr = (pos.x + pos.w >= 1 - eps) and gap or gap / 2
  local gt = (pos.y <= eps) and gap or gap / 2
  local gb = (pos.y + pos.h >= 1 - eps) and gap or gap / 2

  local x1, x2 = l + gl, r - gr
  local y1, y2 = t + gt, b - gb
  return {
    x = round(sf.x + x1),
    y = round(sf.y + y1),
    w = round(x2) - round(x1),
    h = round(y2) - round(y1),
  }
end

-- Index of the position whose frame the window currently occupies
-- (all four edges within tol pixels), or nil if it is in none.
function core.matchPosition(positions, sf, gap, frame, tol)
  for i, pos in ipairs(positions) do
    local f = core.frameFor(pos, sf, gap)
    if math.abs(f.x - frame.x) <= tol
      and math.abs(f.y - frame.y) <= tol
      and math.abs(f.w - frame.w) <= tol
      and math.abs(f.h - frame.h) <= tol then
      return i
    end
  end
  return nil
end

-- Where the next press goes. n = cells in the division, current = the cell
-- the window is in now (nil = none), screenIndex/numScreens = where it is.
-- Returns index, screenIndex. After the last cell, the window moves to cell 1
-- on the next screen (wrapping), which on one screen means it stays.
function core.nextStep(n, current, screenIndex, numScreens)
  if current == nil then
    return 1, screenIndex
  end
  if current < n then
    return current + 1, screenIndex
  end
  return 1, (screenIndex % numScreens) + 1
end

-- Turn a division 90 degrees: columns become rows. Cell order is kept, so
-- "first press" on a portrait screen is the top band, not a thin left strip.
function core.transpose(positions)
  local out = {}
  for i, p in ipairs(positions) do
    out[i] = {x = p.y, y = p.x, w = p.h, h = p.w}
  end
  return out
end

-- The division as it should apply to this screen: unchanged on landscape,
-- transposed on portrait. The number still equals the division.
function core.orient(positions, sf)
  if sf.h > sf.w then
    return core.transpose(positions)
  end
  return positions
end

-- Human label for a position, used in the on-screen alert.
function core.describe(pos)
  local eps = 1e-6
  if pos.w >= 1 - eps and pos.h >= 1 - eps then
    return "Full"
  end
  local inset = pos.x > eps and pos.y > eps
    and pos.x + pos.w < 1 - eps and pos.y + pos.h < 1 - eps
  if inset then
    return string.format("Center %d%%", round(pos.w * 100))
  end
  local cols, rows = round(1 / pos.w), round(1 / pos.h)
  local c, r = round(pos.x / pos.w) + 1, round(pos.y / pos.h) + 1
  if rows == 1 then
    if cols == 2 then return ({"Left", "Right"})[c] end
    if cols == 3 then return ({"Left", "Center", "Right"})[c] end
    return string.format("Column %d/%d", c, cols)
  end
  if cols == 1 then
    if rows == 2 then return ({"Top", "Bottom"})[r] end
    if rows == 3 then return ({"Top", "Middle", "Bottom"})[r] end
    return string.format("Row %d/%d", r, rows)
  end
  if cols == 2 and rows == 2 then
    return ({"Top-left", "Top-right", "Bottom-left", "Bottom-right"})[(r - 1) * 2 + c]
  end
  return string.format("R%d C%d", r, c)
end

-- Grid shape for tiling n windows: as square as possible, wider than tall
-- on landscape, taller than wide on portrait.
function core.tileGrid(n, sf)
  local a = math.ceil(math.sqrt(n))
  local b = math.ceil(n / a)
  if sf.h > sf.w then
    return b, a
  end
  return a, b
end

-- One frame per window, tiled with `gap` around and between.
function core.tileFrames(n, sf, gap)
  gap = gap or 0
  local cols, rows = core.tileGrid(n, sf)
  local cw = (sf.w - gap * (cols + 1)) / cols
  local ch = (sf.h - gap * (rows + 1)) / rows
  local out = {}
  for i = 1, n do
    local r = math.ceil(i / cols)
    local c = ((i - 1) % cols) + 1
    out[i] = {
      x = round(sf.x + gap + (c - 1) * (cw + gap)),
      y = round(sf.y + gap + (r - 1) * (ch + gap)),
      w = round(cw),
      h = round(ch),
    }
  end
  return out
end

-- A frame expressed as fractions of its screen, so a saved layout can be
-- put back on a screen of a different size.
function core.relativeFrame(f, sf)
  return {
    x = (f.x - sf.x) / sf.w,
    y = (f.y - sf.y) / sf.h,
    w = f.w / sf.w,
    h = f.h / sf.h,
  }
end

function core.absoluteFrame(rel, sf)
  return {
    x = round(sf.x + rel.x * sf.w),
    y = round(sf.y + rel.y * sf.h),
    w = round(rel.w * sf.w),
    h = round(rel.h * sf.h),
  }
end

-- Bounding box of several frames: the whole desktop when given every screen.
function core.union(frames)
  local l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
  for _, f in ipairs(frames) do
    l = math.min(l, f.x); t = math.min(t, f.y)
    r = math.max(r, f.x + f.w); b = math.max(b, f.y + f.h)
  end
  return {x = l, y = t, w = r - l, h = b - t}
end

local function clamp(v, lo, hi)
  if lo > hi then return lo end
  return math.max(lo, math.min(hi, v))
end

-- Frame for a window stashed off the left or right edge of the WHOLE desktop
-- with `peek` pixels still showing. Stashing off the current screen's edge
-- would drop the window onto a neighboring screen. The edge belongs to the
-- screen that reaches furthest that way; the window keeps its y, moved only
-- as far as needed so the peeking strip is on that screen, because macOS may
-- refuse a frame that touches no screen at all.
function core.stashFrame(side, f, screenFrames, peek)
  local left = (side == "left")
  local edge, owner
  for _, sf in ipairs(screenFrames) do
    local e = left and sf.x or (sf.x + sf.w)
    if edge == nil or (left and e < edge) or (not left and e > edge) then
      edge, owner = e, sf
    end
  end
  -- Several screens can share the edge: prefer one the window already overlaps.
  for _, sf in ipairs(screenFrames) do
    local e = left and sf.x or (sf.x + sf.w)
    if e == edge and f.y < sf.y + sf.h and f.y + f.h > sf.y then owner = sf end
  end
  return {
    x = left and (edge - f.w + peek) or (edge - peek),
    y = clamp(f.y, owner.y, owner.y + owner.h - f.h),
    w = f.w,
    h = f.h,
  }
end

-- The screen one hop away (dir = 1 next, -1 previous), wrapping around.
function core.nextScreen(index, numScreens, dir)
  return ((index - 1 + dir) % numScreens) + 1
end

return core
