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
-- actions (تم ضبطها لتوافق AssettoServer)
-- ────────────────────────────────────────────────────────────────
local function setTime(seconds)
    playerTime = seconds
    if sim.isOnlineRace then
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local timeStr = string.format("%02d:%02d", hours, minutes)
        ac.sendChatMessage('/time ' .. timeStr)
    else
        ac.setWeatherTimeOffset(seconds - sim.timestamp, true)
    end
end

local function setWeather(id)
    currentWeather = id
    if sim.isOnlineRace then
        local weatherName = 'clear' 
        if id == 0 then weatherName = 'clear'
        elseif id == 1 then weatherName = 'few_clouds'
        elseif id == 2 then weatherName = 'clouds'
        elseif id == 3 then weatherName = 'overcast'
        elseif id == 4 then weatherName = 'rain'
        elseif id == 5 then weatherName = 'thunderstorm'
        end
        ac.sendChatMessage('/weather ' .. weatherName)
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

local function timeChangeHUD()
    local W  = 320
    local X0 = ui.getCursorX()   
    ui.dummy(vec2(W, 6))
    local y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Bold')
    local tSz = ui.measureDWriteText('TIME', 12)
    ui.dwriteDrawText('TIME', 12, vec2(X0 + (W - tSz.x) / 2, y), rgbm(0.4, 0.7, 1, 0.9))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Light')
    local bigTime = os.dateGlobal('%H:%M', playerTime)
    local bSz = ui.measureDWriteText(bigTime, 48)
    ui.dwriteDrawText(bigTime, 48, vec2(X0 + (W - bSz.x) / 2, y), rgbm(1, 1, 1, 1))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 60))
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial')
    local period = getTimePeriod(playerTime)
    local pSz = ui.measureDWriteText(period, 11)
    ui.dwriteDrawText(period, 11, vec2(X0 + (W - pSz.x) / 2, y), rgbm(0.55, 0.55, 0.65, 0.75))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))
    ui.pushItemWidth(W)
    ui.pushStyleColor(ui.StyleColor.FrameBg,          rgbm(0.08, 0.13, 0.22, 0.9))
    ui.pushStyleColor(ui.StyleColor.FrameBgHovered,   rgbm(0.12, 0.18, 0.28, 1))
    ui.pushStyleColor(ui.StyleColor.SliderGrab,       rgbm(0.25, 0.55, 1, 1))
    ui.pushStyleColor(ui.StyleColor.SliderGrabActive, rgbm(0.35, 0.65, 1, 1))
    local newTime = ui.slider('##time', playerTime, 0, 86400, '')
    ui.popStyleColor(4)
    ui.popItemWidth()
    if math.abs(newTime - playerTime) > 1 then setTime(newTime) end
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial')
    local maxSz = ui.measureDWriteText('24:00', 10)
    ui.dwriteDrawText('00:00', 10, vec2(X0,             y), rgbm(0.45, 0.45, 0.55, 0.65))
    ui.dwriteDrawText('24:00', 10, vec2(X0 + W - maxSz.x, y), rgbm(0.45, 0.45, 0.55, 0.65))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 18))
    ui.separator()
    ui.dummy(vec2(W, 8))
    local weathers = {}
    local currentWeatherName = ''
    for name, id in pairs(ac.WeatherType) do
        weathers[id] = name
        if id == currentWeather then currentWeatherName = name end
    end
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Bold')
    ui.dwriteDrawText('WEATHER', 11, vec2(X0, y), rgbm(0.4, 0.7, 1, 0.9))
    local wSz = ui.measureDWriteText(currentWeatherName, 11)
    ui.dwriteDrawText(currentWeatherName, 11, vec2(X0 + W - wSz.x, y), rgbm(0.8, 0.8, 0.9, 0.85))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 20))
    ui.pushItemWidth(W)
    ui.pushStyleColor(ui.StyleColor.FrameBg,        rgbm(0.08, 0.12, 0.2, 0.95))
    ui.pushStyleColor(ui.StyleColor.FrameBgHovered, rgbm(0.12, 0.17, 0.27, 1))
    local selId, changed = ui.combo('##weather', currentWeather, weathers)
    ui.popStyleColor(2)
    ui.popItemWidth()
    if changed then setWeather(selId) end
    ui.dummy(vec2(W, 10))
    
    -- ── التغيير هنا إلى 8M ─────────────────────────────────────
    y = ui.getCursorY()
    ui.pushDWriteFont('Arial;Weight=Light')
    local fSz = ui.measureDWriteText('8M', 10)
    ui.dwriteDrawText('8M', 10,
        vec2(X0 + W - fSz.x, y), rgbm(0.35, 0.35, 0.4, 0.65))
    ui.popDWriteFont()
    ui.dummy(vec2(W, 18))
end

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

function script.update(dt)
end
