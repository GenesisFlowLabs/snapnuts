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

return core
