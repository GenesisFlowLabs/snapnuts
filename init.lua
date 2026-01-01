-- Rectangle Numpad System - Extended Cycling
-- Created by Shafen Khan - December 25, 2025
--
-- This extends Rectangle's capabilities with custom cycling logic
-- ⌘+Numpad 4 cycles through: 4 horizontal fourths + 4 corner quarters

hs.alert.show("Hammerspoon: Rectangle Numpad System loaded")

-- Disable all window animations for instant snapping
hs.window.animationDuration = 0

-- Position definitions for ⌘+4 extended cycling
-- First 4: horizontal fourths (1/4 width strips)
-- Last 4: 2x2 corner quarters
local fourPositions = {
  -- Horizontal fourths (positions 1-4)
  {x = 0,    y = 0, w = 0.25, h = 1},    -- 1: Left fourth
  {x = 0.25, y = 0, w = 0.25, h = 1},    -- 2: Center-left fourth
  {x = 0.5,  y = 0, w = 0.25, h = 1},    -- 3: Center-right fourth
  {x = 0.75, y = 0, w = 0.25, h = 1},    -- 4: Right fourth
  -- 2x2 corner quarters (positions 5-8)
  {x = 0,   y = 0,   w = 0.5, h = 0.5},  -- 5: Top-left
  {x = 0.5, y = 0,   w = 0.5, h = 0.5},  -- 6: Top-right
  {x = 0,   y = 0.5, w = 0.5, h = 0.5},  -- 7: Bottom-left
  {x = 0.5, y = 0.5, w = 0.5, h = 0.5},  -- 8: Bottom-right
}

-- Track current position (persists between presses)
local currentFourIndex = 0

-- Get all screens sorted left-to-right
local function getSortedScreens()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b)
    return a:frame().x < b:frame().x
  end)
  return screens
end

-- Move window to position on specified screen
local function moveToPositionOnScreen(win, pos, screen)
  local f = screen:frame()
  win:setFrame({
    x = f.x + (f.w * pos.x),
    y = f.y + (f.h * pos.y),
    w = f.w * pos.w,
    h = f.h * pos.h
  })
end

-- Track current screen index for cycling across displays
local currentScreenIndex = 1

-- Move window to position, cycling across displays when wrapping
local function moveToPosition(positions, index, wrapAround)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window!", 1)
    return false
  end

  local screens = getSortedScreens()
  local numScreens = #screens

  -- If wrapping around (index went past end), move to next screen
  if wrapAround and numScreens > 1 then
    currentScreenIndex = currentScreenIndex + 1
    if currentScreenIndex > numScreens then
      currentScreenIndex = 1
    end
  else
    -- Find which screen the window is currently on
    local winScreen = win:screen()
    for i, s in ipairs(screens) do
      if s:id() == winScreen:id() then
        currentScreenIndex = i
        break
      end
    end
  end

  local targetScreen = screens[currentScreenIndex]
  local pos = positions[index]

  moveToPositionOnScreen(win, pos, targetScreen)
  return true
end

-- ⌘+Numpad 4: Extended cycling (fourths + corners) with multi-monitor
hs.hotkey.bind({"cmd"}, "pad4", function()
  local wrapAround = false
  currentFourIndex = currentFourIndex + 1
  if currentFourIndex > #fourPositions then
    currentFourIndex = 1
    wrapAround = true  -- Wrapped around, move to next screen
  end

  moveToPosition(fourPositions, currentFourIndex, wrapAround)

  -- Visual feedback
  local labels = {
    "Fourth 1/4", "Fourth 2/4", "Fourth 3/4", "Fourth 4/4",
    "Corner TL", "Corner TR", "Corner BL", "Corner BR"
  }
  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show(labels[currentFourIndex] .. screenInfo, 0.5)
end)

-- Reset index when switching windows (optional behavior)
-- Uncomment if you want cycling to reset when you switch windows
-- hs.window.filter.new():subscribe(hs.window.filter.windowFocused, function()
--   currentFourIndex = 0
-- end)

-- ============================================================
-- SIXTEENTHS: ⌘+Shift+Numpad 4 (4² = 16)
-- 4x4 grid cycling through all 16 positions
-- ============================================================

local sixteenPositions = {
  -- Row 1 (top)
  {x = 0,    y = 0,    w = 0.25, h = 0.25},  -- 1:  Top-left
  {x = 0.25, y = 0,    w = 0.25, h = 0.25},  -- 2:  Top-center-left
  {x = 0.5,  y = 0,    w = 0.25, h = 0.25},  -- 3:  Top-center-right
  {x = 0.75, y = 0,    w = 0.25, h = 0.25},  -- 4:  Top-right
  -- Row 2
  {x = 0,    y = 0.25, w = 0.25, h = 0.25},  -- 5:  Upper-mid-left
  {x = 0.25, y = 0.25, w = 0.25, h = 0.25},  -- 6:  Upper-mid-center-left
  {x = 0.5,  y = 0.25, w = 0.25, h = 0.25},  -- 7:  Upper-mid-center-right
  {x = 0.75, y = 0.25, w = 0.25, h = 0.25},  -- 8:  Upper-mid-right
  -- Row 3
  {x = 0,    y = 0.5,  w = 0.25, h = 0.25},  -- 9:  Lower-mid-left
  {x = 0.25, y = 0.5,  w = 0.25, h = 0.25},  -- 10: Lower-mid-center-left
  {x = 0.5,  y = 0.5,  w = 0.25, h = 0.25},  -- 11: Lower-mid-center-right
  {x = 0.75, y = 0.5,  w = 0.25, h = 0.25},  -- 12: Lower-mid-right
  -- Row 4 (bottom)
  {x = 0,    y = 0.75, w = 0.25, h = 0.25},  -- 13: Bottom-left
  {x = 0.25, y = 0.75, w = 0.25, h = 0.25},  -- 14: Bottom-center-left
  {x = 0.5,  y = 0.75, w = 0.25, h = 0.25},  -- 15: Bottom-center-right
  {x = 0.75, y = 0.75, w = 0.25, h = 0.25},  -- 16: Bottom-right
}

local currentSixteenIndex = 0

-- ⌘+Option+Numpad 4: Sixteenths (4² = 16 positions) with multi-monitor
-- (Shift conflicts with macOS screenshot shortcut)
hs.hotkey.bind({"cmd", "alt"}, "pad4", function()
  local wrapAround = false
  currentSixteenIndex = currentSixteenIndex + 1
  if currentSixteenIndex > #sixteenPositions then
    currentSixteenIndex = 1
    wrapAround = true  -- Wrapped around, move to next screen
  end

  moveToPosition(sixteenPositions, currentSixteenIndex, wrapAround)

  -- Visual feedback with grid position
  local row = math.ceil(currentSixteenIndex / 4)
  local col = ((currentSixteenIndex - 1) % 4) + 1
  local screens = getSortedScreens()
  local screenInfo = ""
  if #screens > 1 then
    screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  end
  hs.alert.show(string.format("16ths: %d/16 (R%d C%d)%s", currentSixteenIndex, row, col, screenInfo), 0.5)
end)

-- ============================================================
-- EIGHTHS: ⌘+Numpad 8
-- 4x2 grid cycling through all 8 positions with multi-monitor
-- ============================================================

local eighthPositions = {
  -- Row 1 (top)
  {x = 0,    y = 0, w = 0.25, h = 0.5},  -- 1: Top-left
  {x = 0.25, y = 0, w = 0.25, h = 0.5},  -- 2: Top-center-left
  {x = 0.5,  y = 0, w = 0.25, h = 0.5},  -- 3: Top-center-right
  {x = 0.75, y = 0, w = 0.25, h = 0.5},  -- 4: Top-right
  -- Row 2 (bottom)
  {x = 0,    y = 0.5, w = 0.25, h = 0.5},  -- 5: Bottom-left
  {x = 0.25, y = 0.5, w = 0.25, h = 0.5},  -- 6: Bottom-center-left
  {x = 0.5,  y = 0.5, w = 0.25, h = 0.5},  -- 7: Bottom-center-right
  {x = 0.75, y = 0.5, w = 0.25, h = 0.5},  -- 8: Bottom-right
}

local currentEighthIndex = 0

hs.hotkey.bind({"cmd"}, "pad8", function()
  local wrapAround = false
  currentEighthIndex = currentEighthIndex + 1
  if currentEighthIndex > #eighthPositions then
    currentEighthIndex = 1
    wrapAround = true
  end

  moveToPosition(eighthPositions, currentEighthIndex, wrapAround)

  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Eighth " .. currentEighthIndex .. "/8" .. screenInfo, 0.5)
end)

-- ============================================================
-- MAXIMIZE: ⌘+Numpad 1
-- Full screen, cycles across monitors
-- ============================================================

local maximizePositions = {
  {x = 0, y = 0, w = 1, h = 1},  -- Full screen
}

local currentMaximizeIndex = 0

hs.hotkey.bind({"cmd"}, "pad1", function()
  local wrapAround = false
  currentMaximizeIndex = currentMaximizeIndex + 1
  if currentMaximizeIndex > #maximizePositions then
    currentMaximizeIndex = 1
    wrapAround = true
  end

  moveToPosition(maximizePositions, currentMaximizeIndex, wrapAround)

  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Maximize" .. screenInfo, 0.5)
end)

-- ============================================================
-- THIRDS: ⌘+Numpad 3
-- 3 vertical strips, cycles across monitors
-- ============================================================

local thirdPositions = {
  {x = 0,     y = 0, w = 0.333, h = 1},  -- 1: Left third
  {x = 0.333, y = 0, w = 0.334, h = 1},  -- 2: Center third
  {x = 0.667, y = 0, w = 0.333, h = 1},  -- 3: Right third
}

local currentThirdIndex = 0

hs.hotkey.bind({"cmd"}, "pad3", function()
  local wrapAround = false
  currentThirdIndex = currentThirdIndex + 1
  if currentThirdIndex > #thirdPositions then
    currentThirdIndex = 1
    wrapAround = true
  end

  moveToPosition(thirdPositions, currentThirdIndex, wrapAround)

  local labels = {"Left", "Center", "Right"}
  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Third " .. labels[currentThirdIndex] .. screenInfo, 0.5)
end)

-- ============================================================
-- CENTER: ⌘+Numpad 5
-- Single position, cycles across monitors
-- ============================================================

local centerPositions = {
  {x = 0.1, y = 0.1, w = 0.8, h = 0.8},  -- Centered (80% of screen)
}

local currentCenterIndex = 0

hs.hotkey.bind({"cmd"}, "pad5", function()
  local wrapAround = false
  currentCenterIndex = currentCenterIndex + 1
  if currentCenterIndex > #centerPositions then
    currentCenterIndex = 1
    wrapAround = true
  end

  moveToPosition(centerPositions, currentCenterIndex, wrapAround)

  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Center" .. screenInfo, 0.5)
end)

-- ============================================================
-- SIXTHS: ⌘+Numpad 6
-- 3x2 grid cycling through all 6 positions with multi-monitor
-- ============================================================

local sixthPositions = {
  -- Row 1 (top)
  {x = 0,    y = 0, w = 0.333, h = 0.5},  -- 1: Top-left
  {x = 0.333, y = 0, w = 0.334, h = 0.5},  -- 2: Top-center
  {x = 0.667, y = 0, w = 0.333, h = 0.5},  -- 3: Top-right
  -- Row 2 (bottom)
  {x = 0,    y = 0.5, w = 0.333, h = 0.5},  -- 4: Bottom-left
  {x = 0.333, y = 0.5, w = 0.334, h = 0.5},  -- 5: Bottom-center
  {x = 0.667, y = 0.5, w = 0.333, h = 0.5},  -- 6: Bottom-right
}

local currentSixthIndex = 0

hs.hotkey.bind({"cmd"}, "pad6", function()
  local wrapAround = false
  currentSixthIndex = currentSixthIndex + 1
  if currentSixthIndex > #sixthPositions then
    currentSixthIndex = 1
    wrapAround = true
  end

  moveToPosition(sixthPositions, currentSixthIndex, wrapAround)

  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Sixth " .. currentSixthIndex .. "/6" .. screenInfo, 0.5)
end)

-- ============================================================
-- ALMOST MAXIMIZE: ⌘+Numpad 7
-- Single position (90% centered), cycles across monitors
-- ============================================================

local almostMaxPositions = {
  {x = 0.05, y = 0.05, w = 0.9, h = 0.9},  -- 90% of screen, centered
}

local currentAlmostMaxIndex = 0

hs.hotkey.bind({"cmd"}, "pad7", function()
  local wrapAround = false
  currentAlmostMaxIndex = currentAlmostMaxIndex + 1
  if currentAlmostMaxIndex > #almostMaxPositions then
    currentAlmostMaxIndex = 1
    wrapAround = true
  end

  moveToPosition(almostMaxPositions, currentAlmostMaxIndex, wrapAround)

  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Almost Max" .. screenInfo, 0.5)
end)

-- ============================================================
-- NINTHS: ⌘+Numpad 9
-- 3x3 grid cycling through all 9 positions with multi-monitor
-- ============================================================

local ninthPositions = {
  -- Row 1 (top)
  {x = 0,     y = 0,     w = 0.333, h = 0.333},  -- 1: Top-left
  {x = 0.333, y = 0,     w = 0.334, h = 0.333},  -- 2: Top-center
  {x = 0.667, y = 0,     w = 0.333, h = 0.333},  -- 3: Top-right
  -- Row 2 (middle)
  {x = 0,     y = 0.333, w = 0.333, h = 0.334},  -- 4: Middle-left
  {x = 0.333, y = 0.333, w = 0.334, h = 0.334},  -- 5: Middle-center
  {x = 0.667, y = 0.333, w = 0.333, h = 0.334},  -- 6: Middle-right
  -- Row 3 (bottom)
  {x = 0,     y = 0.667, w = 0.333, h = 0.333},  -- 7: Bottom-left
  {x = 0.333, y = 0.667, w = 0.334, h = 0.333},  -- 8: Bottom-center
  {x = 0.667, y = 0.667, w = 0.333, h = 0.333},  -- 9: Bottom-right
}

local currentNinthIndex = 0

hs.hotkey.bind({"cmd"}, "pad9", function()
  local wrapAround = false
  currentNinthIndex = currentNinthIndex + 1
  if currentNinthIndex > #ninthPositions then
    currentNinthIndex = 1
    wrapAround = true
  end

  moveToPosition(ninthPositions, currentNinthIndex, wrapAround)

  local row = math.ceil(currentNinthIndex / 3)
  local col = ((currentNinthIndex - 1) % 3) + 1
  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show(string.format("Ninth %d/9 (R%d C%d)%s", currentNinthIndex, row, col, screenInfo), 0.5)
end)

print("SnapNuts: Full numpad system with multi-monitor cycling")
print("  ⌘+1: Maximize (cycles monitors)")
print("  ⌘+3: Thirds (3 positions)")
print("  ⌘+4: Fourths + Corners (8 positions)")
print("  ⌘+5: Center (cycles monitors)")
print("  ⌘+6: Sixths (6 positions)")
print("  ⌘+7: Almost Maximize (cycles monitors)")
print("  ⌘+8: Eighths (8 positions)")
print("  ⌘+9: Ninths (9 positions)")
print("  ⌘+Option+4: Sixteenths (16 positions)")
