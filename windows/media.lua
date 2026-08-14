if FocusedCar == nil then
    ac.debug("ERROR", "No focused car found for media")
    return
end


local function Media()
    local self = {}

    local windowCenter = vec2()
    local settings = {
        backgroundColor = rgbm(0, 0, 0, .25),
        rounding = 15
    }
    local artistString = ""

    local currentlyPlaying = ac.currentlyPlaying()

    local function DrawInfo()
        -- Album cover

        if currentlyPlaying.hasCover then
            ui.beginTextureShade(currentlyPlaying) --ac.MusicData can be passed to render an album cover
            Globals.draw.RectBackground(0, windowCenter.y * 2,
                rgbm(1, 1, 1, 1 * Globals.lightBrightness * Globals.draw.startup.startupModifiers[2]), 5,
                ui.CornerFlags.Left)
            ui.endTextureShade(0, windowCenter.y * 2, true)
        end

        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=600;Style=Regular")
        if currentlyPlaying.trackDuration < 0 then
            -- Nothing playing
            Globals.draw.DrawText(
                vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, 5 * Globals.draw.startup.startupModifiers[4]),
                "Nothing playing",
                10,
                rgbm(1, 1, 1, 1 * Globals.lightBrightness * Globals.draw.startup.startupModifiers[4]),
                vec2(0, .5)
            )
            ui.popDWriteFont()
            return
        end


        -- Progress
        ui.beginPremultipliedAlphaTexture()
        ui.beginTextureShade(Globals.draw.horizontalGradient)
        ui.drawRectFilled(
            vec2(windowCenter.y * 2, 0),
            windowCenter.y * 2 +
            vec2(
                (currentlyPlaying.trackPosition / currentlyPlaying.trackDuration) *
                Globals.draw.startup.startupModifiers[3] *
                ((windowCenter.x * 2 - windowCenter.y * 2)),
                0
            ),
            rgbm(.5, .25, .75, .5) * Globals.lightBrightness
        )
        ui.endTextureShade(
            vec2(windowCenter.y * 2, 0),
            windowCenter.y * 2 +
            vec2(
                (currentlyPlaying.trackPosition / currentlyPlaying.trackDuration) *
                windowCenter.x * 2,
                0
            )
        )
        ui.endPremultipliedAlphaTexture()

        ui.drawRectFilled(
            windowCenter.y * 2 - vec2(0, 3),
            windowCenter.y * 2 +
            vec2(
                Globals.draw.startup.startupModifiers[3] *
                (windowCenter.x * 2 - windowCenter.y * 2), 0),
            rgbm(1, 1, 1, .1)
        )


        ui.drawRectFilled(
            windowCenter.y * 2 - vec2(0, 3),
            windowCenter.y * 2 +
            vec2(
                (currentlyPlaying.trackPosition / currentlyPlaying.trackDuration) *
                Globals.draw.startup.startupModifiers[3] *
                (windowCenter.x * 2 - windowCenter.y * 2), 0),
            rgbm(.5, .25, .75, 1) * Globals.lightBrightness
        )

        -- Text

        Globals.draw.DrawText(
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, -8 * Globals.draw.startup.startupModifiers[3]),
            currentlyPlaying.title,
            12,
            rgbm(1, 1, 1, 1 * Globals.lightBrightness * Globals.draw.startup.startupModifiers[3]),
            vec2(0, .5)
        )

        Globals.draw.DrawText(
            vec2(windowCenter.y * 2, windowCenter.y) + vec2(5, 5 * Globals.draw.startup.startupModifiers[4]),
            artistString,
            10,
            rgbm(1, 1, 1, 1 * Globals.lightBrightness * Globals.draw.startup.startupModifiers[4]),
            vec2(0, .5)
        )

        local positionMinutes = math.floor(currentlyPlaying.trackPosition / 60)
        local positionSeconds = math.floor(currentlyPlaying.trackPosition - positionMinutes * 60)
        local trackPositionString = string.format("%d:%02d", positionMinutes, positionSeconds)

        local durationMinutes = math.floor(currentlyPlaying.trackDuration / 60)
        local durationSeconds = math.floor(currentlyPlaying.trackDuration - 1 - durationMinutes * 60)
        local trackDurationString = string.format("%d:%02d", durationMinutes, durationSeconds)

        local totalDurationString = trackPositionString .. " / " .. trackDurationString

        Globals.draw.DrawText(
            vec2(0, windowCenter.y) +
            vec2(windowCenter.x * 2 - 5, 5 * Globals.draw.startup.startupModifiers[4]),
            totalDurationString,
            10,
            rgbm(1, 1, 1, 1 * Globals.lightBrightness * Globals.draw.startup.startupModifiers[4]),
            vec2(1, .5)
        )

        ui.popDWriteFont()
    end

    function self.window(dt)
        windowCenter = ui.windowSize() / 2
        currentlyPlaying = ac.currentlyPlaying()

        Globals.draw.RectBackground(0, windowCenter * 2,
            settings.backgroundColor * rgbm(1, 1, 1, Globals.draw.startup.startupModifiers[1]), 5)

        DrawInfo()

        artistString = currentlyPlaying.artist

        if not currentlyPlaying.isPlaying then
            artistString = "Right click to play"
            ui.drawIcon(ui.Icons.Play,
                0 + 10, windowCenter.y * 2 - 10
            )
        end

        if ui.windowHovered() then
            if currentlyPlaying.isPlaying then
                artistString = "Right click to pause"
                ui.drawIcon(ui.Icons.Pause,
                    0 + 10, windowCenter.y * 2 - 10
                )
            end

            if ui.mouseClicked(ui.MouseButton.Right) then
                ac.mediaPlayPause()
            end

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
