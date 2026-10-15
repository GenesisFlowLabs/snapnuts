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
-- Edges are rounded (not widths) so neighbouring cells meet exactly.
-- gap: full gap against the screen edge, half a gap on each inner edge,
-- so two neighbours end up one gap apart.
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

return core
