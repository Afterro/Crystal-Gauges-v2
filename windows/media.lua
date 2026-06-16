local globals = require("windows.globals")
local sim = globals.Sim
local focusedCar = globals.focusedCar
if focusedCar == nil then
    ac.debug("ERROR", "No focused car found for media")
    return
end


function Media()
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
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, -8 * globals.draw.startup.startupModifiers[3]),
            currentlyPlaying.title,
            12,
            rgbm(1, 1, 1, 1 * globals.lightBrightness * globals.draw.startup.startupModifiers[3]),
            vec2(0, .5)
        )

        globals.draw.DrawText(
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, 5 * globals.draw.startup.startupModifiers[4]),
            currentlyPlaying.artist,
            10,
            rgbm(1, 1, 1, 1 * globals.lightBrightness * globals.draw.startup.startupModifiers[4]),
            vec2(0, .5)
        )

        ui.popDWriteFont()

        ui.beginTextureShade(currentlyPlaying)
        globals.draw.RectBackground(0, windowCenter.y * 2,
            rgbm(1, 1, 1, 1 * globals.lightBrightness * globals.draw.startup.startupModifiers[2]), settings.rounding,
            ui.CornerFlags.Left)
        ui.endTextureShade(0, windowCenter.y * 2, true)

        ui.drawRectFilled(
            windowCenter.y * 2 - vec2(0, 3),
            windowCenter.y * 2 +
            vec2(
                (currentlyPlaying.trackPosition / currentlyPlaying.trackDuration) *
                globals.draw.startup.startupModifiers[3] *
                windowCenter.x, 0),
            rgbm(1, 0, 1, 1 * globals.lightBrightness)
        )
    end

    function self.window(dt)
        windowCenter = ui.windowSize() / 2
        currentlyPlaying = ac.currentlyPlaying()

        globals.draw.RectBackground(0, windowCenter * 2,
            settings.backgroundColor * rgbm(1, 1, 1, globals.draw.startup.startupModifiers[1]), settings.rounding)

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

return Media()
