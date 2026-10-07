-- Pomodial: a wind-up pomodoro timer with a Time Timer style dial.
--
-- Crank winds the dial (1 minute per 6°, a full turn is 60 minutes).
-- A starts/pauses, B resets the phase, left/right switches phase,
-- up/down nudges a minute. The gray wedge is the time left.

import "CoreLibs/graphics"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

-- Pomodoro rhythm, in minutes
local PHASES <const> = {
	focus = { label = "Focus", minutes = 25 },
	short = { label = "Short break", minutes = 5 },
	long  = { label = "Long break", minutes = 15 },
}
local ORDER <const> = { "focus", "short", "long" }
local LONG_EVERY <const> = 4

local DIAL_MINUTES <const> = 60
local DEG_PER_MINUTE <const> = 360 / DIAL_MINUTES

-- Layout (screen is 400x240). The dial is a square face in a rounded-square housing,
-- like a Time Timer.
local CX <const>, CY <const> = 120, 120
local HOUSING <const> = 116      -- half-size of the outer housing
local HOUSING_RADIUS <const> = 18
local FACE <const> = 98          -- half-size of the square face
local FAN_RADIUS <const> = 140   -- wedge radius, past the face corners; clipped to the face
local WEDGE_GRAY <const> = 0.5   -- dither density, the 1-bit stand-in for the red disc
local PANEL_X <const> = 248

local bigFont = gfx.font.new("fonts/Roobert-24-Medium") or gfx.getSystemFont(gfx.font.kVariantBold)
local dialFont = gfx.font.new("fonts/Roobert-10-Bold") or gfx.getSystemFont(gfx.font.kVariantBold)
local labelFont = gfx.getSystemFont(gfx.font.kVariantBold)
local smallFont = gfx.getSystemFont()

-- State
local phase = "focus"
local state = "set"        -- "set" | "running" | "paused"
local completed = 0        -- focus sessions finished in this cycle
local setMinutes = 0       -- unrounded crank position while setting
local remaining = 0        -- seconds left
local endsAt = nil         -- wall-clock end time while running
local flashUntil = 0

-- Wall clock, so the timer stays right even if the game is paused or the device sleeps.
-- Playdate Lua floats are 32-bit, so epoch seconds (~8e8) only resolve to 64 s steps;
-- subtract an integer base first to keep the float small and precise.
local EPOCH_BASE <const> = pd.getSecondsSinceEpoch()

local function now()
	local s, ms = pd.getSecondsSinceEpoch()
	return (s - EPOCH_BASE) + ms / 1000
end

-- Sounds
local tick = snd.synth.new(snd.kWaveSquare)
tick:setADSR(0, 0.015, 0, 0)
local bell = snd.synth.new(snd.kWaveSine)
bell:setADSR(0.005, 0.8, 0, 0.3)
local bell2 = snd.synth.new(snd.kWaveSine)
bell2:setADSR(0.005, 1.2, 0, 0.4)

local function ding()
	bell:playNote("E6", 0.7, 0.6)
	pd.timer.performAfterDelay(300, function() bell2:playNote("C6", 0.7, 1.0) end)
end

-- Phases
local function loadPhase(name)
	phase = name
	state = "set"
	setMinutes = PHASES[name].minutes
	remaining = setMinutes * 60
	endsAt = nil
	pd.setAutoLockDisabled(false)
	pd.display.setRefreshRate(30)
end

-- credit: whether a finished focus session counts toward the cycle
local function nextPhase(credit)
	if phase == "focus" then
		if credit then completed += 1 end
		if credit and completed % LONG_EVERY == 0 then loadPhase("long") else loadPhase("short") end
	else
		if phase == "long" then completed = 0 end
		loadPhase("focus")
	end
end

local function cyclePhase(step)
	if state == "running" then return end
	local i = 1
	for k, name in ipairs(ORDER) do
		if name == phase then i = k end
	end
	loadPhase(ORDER[(i - 1 + step) % #ORDER + 1])
end

local function start()
	if remaining <= 0 then return end
	state = "running"
	endsAt = now() + remaining
	-- Keep the screen on so the dial stays visible, like a desk timer
	pd.setAutoLockDisabled(true)
	pd.display.setRefreshRate(10)
end

local function pause()
	remaining = math.max(0, endsAt - now())
	state = "paused"
	pd.setAutoLockDisabled(false)
	pd.display.setRefreshRate(30)
end

local function finish()
	ding()
	nextPhase(true)
	flashUntil = now() + 2
end

local function wind(deltaMinutes)
	local before = math.floor(remaining / 60)
	if state == "set" then
		-- Snap to whole minutes while setting
		setMinutes = math.min(DIAL_MINUTES, math.max(0, setMinutes + deltaMinutes))
		remaining = math.floor(setMinutes + 0.5) * 60
	else
		remaining = math.min(DIAL_MINUTES * 60, math.max(0, remaining + deltaMinutes * 60))
	end
	if math.floor(remaining / 60) ~= before then tick:playNote(1800, 0.25, 0.02) end
end

-- Input
function pd.AButtonDown()
	if state == "running" then pause() else start() end
end

function pd.BButtonDown() loadPhase(phase) end
function pd.leftButtonDown() cyclePhase(-1) end
function pd.rightButtonDown() cyclePhase(1) end
function pd.upButtonDown() if state ~= "running" then wind(1) end end
function pd.downButtonDown() if state ~= "running" then wind(-1) end end

local menu = pd.getSystemMenu()
menu:addMenuItem("Skip phase", function() nextPhase(false) end)
menu:addMenuItem("New cycle", function()
	completed = 0
	loadPhase("focus")
end)

-- Drawing. Angles are degrees clockwise from 12 o'clock.
local function pointAt(deg, r)
	local a = math.rad(deg)
	return CX + r * math.sin(a), CY - r * math.cos(a)
end

-- Where a ray from the center at this angle meets a square of the given half-size,
-- pulled inward by `inset` pixels along the ray
local function squarePoint(deg, half, inset)
	local a = math.rad(deg)
	local dx, dy = math.sin(a), -math.cos(a)
	local t = half / math.max(math.abs(dx), math.abs(dy)) - (inset or 0)
	return CX + t * dx, CY + t * dy
end

-- Minutes run counterclockwise from 12, like a Time Timer:
-- the wedge ends at 12 and its edge sweeps clockwise toward it
local function minuteAngle(m)
	return 360 - m * DEG_PER_MINUTE
end

local function drawWedge(seconds)
	local deg = seconds / (DIAL_MINUTES * 60) * 360
	if deg <= 0.5 then return end
	gfx.setClipRect(CX - FACE, CY - FACE, FACE * 2, FACE * 2)
	gfx.setDitherPattern(WEDGE_GRAY, gfx.image.kDitherTypeBayer4x4)
	if deg >= 359.5 then
		gfx.fillRect(CX - FACE, CY - FACE, FACE * 2, FACE * 2)
	else
		local pts = { CX, CY }
		for d = 360 - deg, 360, 3 do
			local x, y = pointAt(d, FAN_RADIUS)
			pts[#pts + 1] = x
			pts[#pts + 1] = y
		end
		local x, y = pointAt(0, FAN_RADIUS)
		pts[#pts + 1] = x
		pts[#pts + 1] = y
		gfx.fillPolygon(table.unpack(pts))

		-- Crisp edges, like the rim of the disc
		gfx.setColor(gfx.kColorBlack)
		gfx.setLineWidth(2)
		local ex, ey = pointAt(360 - deg, FAN_RADIUS)
		gfx.drawLine(CX, CY, ex, ey)
		gfx.drawLine(CX, CY, x, y)
		gfx.setLineWidth(1)
	end
	gfx.setColor(gfx.kColorBlack)
	gfx.clearClipRect()
end

local function drawDial()
	-- Housing and face outline
	gfx.setLineWidth(3)
	gfx.drawRoundRect(CX - HOUSING, CY - HOUSING, HOUSING * 2, HOUSING * 2, HOUSING_RADIUS)
	gfx.setLineWidth(2)
	gfx.drawRect(CX - FACE, CY - FACE, FACE * 2, FACE * 2)

	-- Ticks and numbers are black with a white outline, so they read on the gray wedge too
	for m = 0, DIAL_MINUTES - 1 do
		local major = m % 5 == 0
		local width = major and 2 or 1
		local x1, y1 = squarePoint(minuteAngle(m), FACE, major and 10 or 5)
		local x2, y2 = squarePoint(minuteAngle(m), FACE, 2)
		gfx.setColor(gfx.kColorWhite)
		gfx.setLineWidth(width + 2)
		gfx.drawLine(x1, y1, x2, y2)
		gfx.setColor(gfx.kColorBlack)
		gfx.setLineWidth(width)
		gfx.drawLine(x1, y1, x2, y2)
	end

	gfx.setFont(dialFont)
	local h = dialFont:getHeight()
	for m = 0, DIAL_MINUTES - 5, 5 do
		local x, y = squarePoint(minuteAngle(m), FACE, 22)
		local label, top = tostring(m), y - h / 2
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		for ox = -1, 1 do
			for oy = -1, 1 do
				gfx.drawTextAligned(label, x + ox, top + oy, kTextAlignment.center)
			end
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
		gfx.drawTextAligned(label, x, top, kTextAlignment.center)
	end
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- Center knob
	gfx.setLineWidth(2)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(CX, CY, 9)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawCircleAtPoint(CX, CY, 9)
	gfx.fillCircleAtPoint(CX, CY, 3)
	gfx.setLineWidth(1)
end

local HINTS <const> = {
	set = "🎣 wind  Ⓐ start\n✛ phase",
	running = "Ⓐ pause\nⒷ reset",
	paused = "Paused\nⒶ resume  Ⓑ reset",
}

local function drawPanel()
	gfx.setFont(labelFont)
	gfx.drawText(PHASES[phase].label, PANEL_X, 30)

	local secs = math.max(0, math.ceil(remaining))
	gfx.setFont(bigFont)
	gfx.drawText(string.format("%02d:%02d", secs // 60, secs % 60), PANEL_X, 58)

	-- One dot per focus session in the cycle
	for i = 1, LONG_EVERY do
		local x = PANEL_X + 8 + (i - 1) * 22
		if i <= completed then
			gfx.fillCircleAtPoint(x, 120, 7)
		else
			gfx.drawCircleAtPoint(x, 120, 7)
		end
	end

	gfx.setFont(smallFont)
	gfx.drawTextInRect(HINTS[state], PANEL_X, 160, 400 - PANEL_X - 8, 70)
end

function pd.update()
	-- Always read the crank so turns made while running don't jump in later
	local change = pd.getCrankChange()
	if state == "running" then
		remaining = endsAt - now()
		if remaining <= 0 then finish() end
	elseif change ~= 0 then
		wind(change / DEG_PER_MINUTE)
	end

	gfx.clear()
	drawWedge(remaining)
	drawDial()
	drawPanel()

	local t = now()
	pd.display.setInverted(t < flashUntil and math.floor(t * 4) % 2 == 0)
	pd.timer.updateTimers()
end

loadPhase("focus")
