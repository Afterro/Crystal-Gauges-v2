local globals = require("windows.globals")
local sim = globals.Sim
local focusedCar = globals.focusedCar
if focusedCar == nil then
    ac.debug("ERROR", "No focused car found for minimap")
    return
end


function Minimap()
    local self = {}

    local windowCenter = vec2()
    local settings = {
        backgroundColor = rgbm(0, 0, 0, .25),
        rounding = 15
    }

    local currentlyPlaying = ac.currentlyPlaying()

    local function DrawInfo()
        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=600;Style=Regular")

        globals.draw.DrawText(
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, -8),
            currentlyPlaying.title,
            12,
            rgbm(1, 1, 1, 1),
            vec2(0, .5)
        )
        globals.draw.DrawText(
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, 8),
            currentlyPlaying.artist,
            12,
            rgbm(1, 1, 1, 1),
            vec2(0, .5)
        )

        ui.drawImage(currentlyPlaying, 0, windowCenter.y * 2)
        ui.popDWriteFont()

        ui.drawRectFilled(
            windowCenter.y * 2 - vec2(0, 2),
            windowCenter.y * 2 +
            vec2((currentlyPlaying.trackPosition / currentlyPlaying.trackDuration) * windowCenter.x, 0),
            rgbm(1, 0, 1, 1)
        )
    end

    function self.window(dt)
        windowCenter = ui.windowSize() / 2
        currentlyPlaying = ac.currentlyPlaying()

        globals.draw.RectBackground(0, windowCenter * 2, settings.backgroundColor, settings.rounding)

        DrawInfo()

        if ui.windowHovered() then
            ui.drawRect(vec2(0, 0),
                windowCenter * 2,
                rgbm(1, 1, 1, 1),
                0,
                ui.CornerFlags.All,
                1
            )
        end
    end

    return self
end

return Minimap()
