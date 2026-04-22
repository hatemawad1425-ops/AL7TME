local sim = ac.getSim()
local playerTime     = sim.timestamp % 86400
local currentWeather = sim.weatherType

-- ────────────────────────────────────────────────────────────────
-- offline weather debug bridge
-- ────────────────────────────────────────────────────────────────
local debugWeatherControl = nil
if not sim.isOnlineRace then
    debugWeatherControl = ac.connect({
        ac.StructItem.key('weatherFXDebugOverride'),
        weatherType    = ac.StructItem.byte(),
        debugSupported = ac.StructItem.boolean()
    })
end

-- ────────────────────────────────────────────────────────────────
-- actions
-- ────────────────────────────────────────────────────────────────
local function setTime(seconds)
    playerTime = seconds
    if sim.isOnlineRace then
        ac.sendChatMessage('/time ' .. string.format('%.4f', seconds / 3600))
        ac.sendChatMessage('/ebweather ' .. currentWeather)
    else
        ac.setWeatherTimeOffset(seconds - sim.timestamp, true)
    end
end

local function setWeather(id)
    currentWeather = id
    if sim.isOnlineRace then
        ac.sendChatMessage('/ebweather ' .. id)
    else
        if debugWeatherControl then
            debugWeatherControl.weatherType = id
        end
    end
end

local function getTimePeriod(seconds)
    local h = math.floor(seconds / 3600)
    if     h <  6 then return 'AM \xC2\xB7 NIGHT'
    elseif h < 12 then return 'AM \xC2\xB7 MORNING'
    elseif h < 17 then return 'PM \xC2\xB7 AFTERNOON'
    elseif h < 21 then return 'PM \xC2\xB7 EVENING'
    else                return 'PM \xC2\xB7 NIGHT'
    end
end

-- ────────────────────────────────────────────────────────────────
-- HUD
-- ────────────────────────────────────────────────────────────────
local function timeChangeHUD()
    local W  = 320
    local X0 = ui.getCursorX()   -- ImGui left padding (~8px); all dwrite text is offset by this

    -- top padding
    ui.dummy(vec2(W, 6))

    -- ── TIME label ─────────────────────────────────────────────
    local y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Bold')
    local tSz = ui.measureDWriteText('TIME', 12)
    ui.dwriteDrawText('TIME', 12,
        vec2(X0 + (W - tSz.x) / 2, y), rgbm(0.4, 0.7, 1, 0.9))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))

    -- ── large HH:MM ────────────────────────────────────────────
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Light')
    local bigTime = os.dateGlobal('%H:%M', playerTime)
    local bSz = ui.measureDWriteText(bigTime, 48)
    ui.dwriteDrawText(bigTime, 48,
        vec2(X0 + (W - bSz.x) / 2, y), rgbm(1, 1, 1, 1))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 60))

    -- ── period ─────────────────────────────────────────────────
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial')
    local period = getTimePeriod(playerTime)
    local pSz = ui.measureDWriteText(period, 11)
    ui.dwriteDrawText(period, 11,
        vec2(X0 + (W - pSz.x) / 2, y), rgbm(0.55, 0.55, 0.65, 0.75))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))

    -- ── time slider ────────────────────────────────────────────
    ui.pushItemWidth(W)
    ui.pushStyleColor(ui.StyleColor.FrameBg,          rgbm(0.08, 0.13, 0.22, 0.9))
    ui.pushStyleColor(ui.StyleColor.FrameBgHovered,   rgbm(0.12, 0.18, 0.28, 1))
    ui.pushStyleColor(ui.StyleColor.SliderGrab,       rgbm(0.25, 0.55, 1, 1))
    ui.pushStyleColor(ui.StyleColor.SliderGrabActive, rgbm(0.35, 0.65, 1, 1))
    local newTime = ui.slider('##time', playerTime, 0, 86400, '')
    ui.popStyleColor(4)
    ui.popItemWidth()
    if math.abs(newTime - playerTime) > 1 then setTime(newTime) end

    -- ── 00:00 / 24:00 labels ───────────────────────────────────
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial')
    local maxSz = ui.measureDWriteText('24:00', 10)
    ui.dwriteDrawText('00:00', 10, vec2(X0,             y), rgbm(0.45, 0.45, 0.55, 0.65))
    ui.dwriteDrawText('24:00', 10, vec2(X0 + W - maxSz.x, y), rgbm(0.45, 0.45, 0.55, 0.65))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 18))

    ui.separator()
    ui.dummy(vec2(W, 8))

    -- ── WEATHER row ────────────────────────────────────────────
    local weathers = {}
    local currentWeatherName = ''
    for name, id in pairs(ac.WeatherType) do
        weathers[id] = name
        if id == currentWeather then currentWeatherName = name end
    end

    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Bold')
    ui.dwriteDrawText('WEATHER', 11,
        vec2(X0, y), rgbm(0.4, 0.7, 1, 0.9))
    local wSz = ui.measureDWriteText(currentWeatherName, 11)
    ui.dwriteDrawText(currentWeatherName, 11,
        vec2(X0 + W - wSz.x, y), rgbm(0.8, 0.8, 0.9, 0.85))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))

    -- ── weather combo ──────────────────────────────────────────
    ui.pushItemWidth(W)
    ui.pushStyleColor(ui.StyleColor.FrameBg,        rgbm(0.08, 0.12, 0.2, 0.95))
    ui.pushStyleColor(ui.StyleColor.FrameBgHovered, rgbm(0.12, 0.17, 0.27, 1))
    local selId, changed = ui.combo('##weather', currentWeather, weathers)
    ui.popStyleColor(2)
    ui.popItemWidth()
    if changed then setWeather(selId) end

    ui.dummy(vec2(W, 10))

    -- ── footer ─────────────────────────────────────────────────
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Light')
    local fSz = ui.measureDWriteText('EBDA3.Team', 10)
    ui.dwriteDrawText('EBDA3.Team', 10,
        vec2(X0 + W - fSz.x, y), rgbm(0.35, 0.35, 0.4, 0.65))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 18))
end

-- ────────────────────────────────────────────────────────────────
-- register UI
-- ────────────────────────────────────────────────────────────────
ui.registerOnlineExtra(
    ui.Icons.Eye,
    'Time Weather',
    nil,
    timeChangeHUD,
    nil,
    ui.OnlineExtraFlags.Tool,
    bit.bor(
        ui.WindowFlags.NoTitleBar,
        ui.WindowFlags.AlwaysAutoResize,
        ui.WindowFlags.NoBringToFrontOnFocus,
        ui.WindowFlags.NoFocusOnAppearing,
        ui.WindowFlags.NoBackground
    )
)

-- ────────────────────────────────────────────────────────────────
-- main loop
-- ────────────────────────────────────────────────────────────────
function script.update(dt)
end
