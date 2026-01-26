-- Rectangle Numpad System - Extended Cycling
-- Created by Shafen Khan - December 25, 2025
--
-- This extends Rectangle's capabilities with custom cycling logic
-- ⌘+Numpad 4 cycles through: 4 horizontal fourths + 4 corner quarters

-- Enable IPC for command-line debugging
require("hs.ipc")

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
  -- Check if window is already on target screen
  local currentScreen = win:screen()
  local needsMove = currentScreen:id() ~= screen:id()

  if needsMove then
    -- Move to target screen, then set frame after brief delay
    win:moveToScreen(screen, false, false, 0)
    hs.timer.doAfter(0.01, function()
      local f = win:screen():frame()
      win:setFrame({
        x = f.x + (f.w * pos.x),
        y = f.y + (f.h * pos.y),
        w = f.w * pos.w,
        h = f.h * pos.h
      })
    end)
  else
    -- Already on correct screen, set frame immediately
    local f = screen:frame()
    win:setFrame({
      x = f.x + (f.w * pos.x),
      y = f.y + (f.h * pos.y),
      w = f.w * pos.w,
      h = f.h * pos.h
    })
  end
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
-- HALVES: ⌘+Numpad 2
-- Left/Right halves, cycles across monitors
-- ============================================================

local halfPositions = {
  {x = 0,   y = 0, w = 0.5, h = 1},  -- 1: Left half
  {x = 0.5, y = 0, w = 0.5, h = 1},  -- 2: Right half
}

local currentHalfIndex = 0

hs.hotkey.bind({"cmd"}, "pad2", function()
  local wrapAround = false
  currentHalfIndex = currentHalfIndex + 1
  if currentHalfIndex > #halfPositions then
    currentHalfIndex = 1
    wrapAround = true
  end

  moveToPosition(halfPositions, currentHalfIndex, wrapAround)

  local labels = {"Left", "Right"}
  local screens = getSortedScreens()
  local screenInfo = " [" .. currentScreenIndex .. "/" .. #screens .. "]"
  hs.alert.show("Half " .. labels[currentHalfIndex] .. screenInfo, 0.5)
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

-- ============================================================
-- TILE ALL: ⌘+Pad* (numpad asterisk)
-- Organize all windows of the CURRENT APP in a grid
-- ============================================================

hs.hotkey.bind({"cmd"}, "pad*", function()
  -- Get the frontmost application
  local app = hs.application.frontmostApplication()
  if not app then
    hs.alert.show("No active app", 0.5)
    return
  end

  -- Get all windows of this app
  local allWindows = app:allWindows()

  -- Filter to visible, standard windows (exclude minimized, etc.)
  local validWindows = {}
  for _, win in ipairs(allWindows) do
    if win:isStandard() and win:isVisible() and not win:isMinimized() then
      table.insert(validWindows, win)
    end
  end

  local count = #validWindows
  if count == 0 then
    hs.alert.show("No windows to tile", 0.5)
    return
  end

  -- Get the screen of the first window
  local screen = validWindows[1]:screen()
  local f = screen:frame()

  -- Gap between windows (pixels)
  local gap = 4

  -- Calculate grid dimensions
  local cols, rows
  if count == 1 then cols, rows = 1, 1
  elseif count == 2 then cols, rows = 2, 1
  elseif count <= 4 then cols, rows = 2, 2
  elseif count <= 6 then cols, rows = 3, 2
  elseif count <= 9 then cols, rows = 3, 3
  else cols, rows = 4, 3 end

  -- Calculate cell dimensions accounting for gaps
  local cellWidth = (f.w - (gap * (cols + 1))) / cols
  local cellHeight = (f.h - (gap * (rows + 1))) / rows

  -- Position each window
  for i, win in ipairs(validWindows) do
    local row = math.ceil(i / cols)
    local col = ((i - 1) % cols) + 1

    win:setFrame({
      x = f.x + gap + ((col - 1) * (cellWidth + gap)),
      y = f.y + gap + ((row - 1) * (cellHeight + gap)),
      w = cellWidth,
      h = cellHeight
    })
  end

  local appName = app:name() or "App"
  hs.alert.show(string.format("Tiled %d %s windows (%dx%d)", count, appName, cols, rows), 0.5)
end)

-- ============================================================
-- UNDO: ⌘+Shift+Z
-- Restore previous window position (10 levels)
-- ============================================================

local undoHistory = {}
local maxUndoHistory = 10

-- Helper to record window state before moving
local function recordSnapshot(win)
  if not win then return end
  local snapshot = {
    window = win,
    frame = win:frame()
  }
  table.insert(undoHistory, snapshot)
  if #undoHistory > maxUndoHistory then
    table.remove(undoHistory, 1)
  end
end

-- Hook into moveToPosition to save snapshots
local originalMoveToPosition = moveToPosition
moveToPosition = function(positions, index, wrapAround)
  local win = hs.window.focusedWindow()
  if win then
    recordSnapshot(win)
  end
  return originalMoveToPosition(positions, index, wrapAround)
end

hs.hotkey.bind({"cmd", "shift"}, "z", function()
  if #undoHistory == 0 then
    hs.alert.show("Nothing to undo", 0.5)
    return
  end

  local snapshot = table.remove(undoHistory)
  if snapshot.window and snapshot.window:isVisible() then
    snapshot.window:setFrame(snapshot.frame)
    hs.alert.show("Undone!", 0.5)
  else
    hs.alert.show("Window no longer exists", 0.5)
  end
end)

-- ============================================================
-- WORKSPACES: Save/Restore window layouts
-- ⌘+Shift+S: Save current layout
-- ⌘+Shift+1-9: Restore saved layout
-- ============================================================

local workspaces = {}

local function saveWorkspace(slot)
  local windows = hs.window.visibleWindows()
  local data = {}

  for _, win in ipairs(windows) do
    if win:isStandard() and win:application() then
      table.insert(data, {
        appName = win:application():name(),
        windowTitle = win:title(),
        frame = {
          x = win:frame().x,
          y = win:frame().y,
          w = win:frame().w,
          h = win:frame().h
        },
        screenId = win:screen():id()
      })
    end
  end

  workspaces[slot] = data
  hs.alert.show("Workspace " .. slot .. " saved (" .. #data .. " windows)", 0.5)
end

local function restoreWorkspace(slot)
  local data = workspaces[slot]
  if not data then
    hs.alert.show("No workspace in slot " .. slot, 0.5)
    return
  end

  local restored = 0
  for _, winData in ipairs(data) do
    -- Find matching window by app name
    local app = hs.application.get(winData.appName)
    if app then
      local windows = app:allWindows()
      for _, win in ipairs(windows) do
        -- Match by title if possible, otherwise use first window
        if win:title() == winData.windowTitle or #windows == 1 then
          win:setFrame({
            x = winData.frame.x,
            y = winData.frame.y,
            w = winData.frame.w,
            h = winData.frame.h
          })
          restored = restored + 1
          break
        end
      end
    end
  end

  hs.alert.show("Workspace " .. slot .. " restored (" .. restored .. "/" .. #data .. " windows)", 0.5)
end

-- ⌘+Shift+S: Prompt for slot and save
hs.hotkey.bind({"cmd", "shift"}, "s", function()
  -- Use a simple chooser to pick slot
  local choices = {}
  for i = 1, 9 do
    local status = workspaces[i] and ("(" .. #workspaces[i] .. " windows)") or "(empty)"
    table.insert(choices, {
      text = "Slot " .. i .. " " .. status,
      slot = i
    })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      saveWorkspace(choice.slot)
    end
  end)
  chooser:choices(choices)
  chooser:placeholderText("Select slot to save workspace")
  chooser:show()
end)

-- ⌘+Shift+1 through ⌘+Shift+9: Restore workspaces
for i = 1, 9 do
  hs.hotkey.bind({"cmd", "shift"}, tostring(i), function()
    restoreWorkspace(i)
  end)
end

-- ============================================================
-- WINDOW STASHING: Hide windows at screen edges
-- ⌘+Shift+Left: Stash left
-- ⌘+Shift+Right: Stash right
-- ⌘+Shift+U: Unstash all
-- ============================================================

local stashedWindows = {}

local function stashWindow(side)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window", 0.5)
    return
  end

  local screen = win:screen()
  local f = screen:frame()
  local stashWidth = 15  -- Pixels visible when stashed

  -- Save original frame
  table.insert(stashedWindows, {
    side = side,
    window = win,
    originalFrame = win:frame()
  })

  -- Move window mostly off-screen
  local stashFrame
  if side == "left" then
    stashFrame = {
      x = f.x - win:frame().w + stashWidth,
      y = win:frame().y,
      w = win:frame().w,
      h = win:frame().h
    }
  else  -- right
    stashFrame = {
      x = f.x + f.w - stashWidth,
      y = win:frame().y,
      w = win:frame().w,
      h = win:frame().h
    }
  end

  win:setFrame(stashFrame)
  hs.alert.show("Stashed " .. side, 0.5)
end

local function unstashAll()
  if #stashedWindows == 0 then
    hs.alert.show("No stashed windows", 0.5)
    return
  end

  local count = 0
  for _, stash in ipairs(stashedWindows) do
    if stash.window and stash.window:isVisible() then
      stash.window:setFrame(stash.originalFrame)
      count = count + 1
    end
  end

  stashedWindows = {}
  hs.alert.show("Unstashed " .. count .. " windows", 0.5)
end

hs.hotkey.bind({"cmd", "shift"}, "left", function()
  stashWindow("left")
end)

hs.hotkey.bind({"cmd", "shift"}, "right", function()
  stashWindow("right")
end)

hs.hotkey.bind({"cmd", "shift"}, "u", function()
  unstashAll()
end)

-- ============================================================
-- STARTUP MESSAGE
-- ============================================================

print("SnapNuts: Full numpad system with multi-monitor cycling")
print("  ⌘+0: Tile All Windows")
print("  ⌘+1: Maximize (cycles monitors)")
print("  ⌘+2: Halves (2 positions)")
print("  ⌘+3: Thirds (3 positions)")
print("  ⌘+4: Fourths + Corners (8 positions)")
print("  ⌘+5: Center (cycles monitors)")
print("  ⌘+6: Sixths (6 positions)")
print("  ⌘+7: Almost Maximize (cycles monitors)")
print("  ⌘+8: Eighths (8 positions)")
print("  ⌘+9: Ninths (9 positions)")
print("  ⌘+Option+4: Sixteenths (16 positions)")
print("  ⌘+Shift+Z: Undo last snap")
print("  ⌘+Shift+S: Save workspace")
print("  ⌘+Shift+1-9: Restore workspace")
print("  ⌘+Shift+←/→: Stash window")
print("  ⌘+Shift+U: Unstash all")
