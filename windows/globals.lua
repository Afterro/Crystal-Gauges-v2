local function Utils()
    local self = {}

    ---@type ac.StateSim
    Sim = ac.getSim()

    ---@type ac.StateCar?
    FocusedCar = ac.getCar(Sim.focusedCar)

    self.numSegments = 64

    self.lightBrightness = 0.1

    ---Class for drawing gauges
    function Draw()
        local draw = {}

        draw.startup = {
            -- Startup animation
            ongoing = true,
            -- Duration for startup stages
            startupStageLenght = .75,
            -- Current stage time
            startupCurrentTime = 0,
            -- Modifiers for each stage
            startupModifiers = { 0, 0, 0, 0, 0 },
            -- Current stage
            startupStage = 1,
        }

        draw.startup.startupCurrentTime = draw.startup.startupStageLenght

        function draw._handleStartup(dt)
            -- If player is in setup screen
            if Sim.cameraMode == ac.CameraMode.Start then return end

            if draw.startup.startupStage <= #draw.startup.startupModifiers and draw.startup.startupCurrentTime > 0 then
                draw.startup.startupCurrentTime = draw.startup.startupCurrentTime - dt

                draw.startup.startupModifiers[draw.startup.startupStage] = 1 -
                    (draw.startup.startupCurrentTime / draw.startup.startupStageLenght)

                draw.startup.startupModifiers[draw.startup.startupStage] = math.clamp(
                    draw.startup.startupModifiers[draw.startup.startupStage], 0, 1)
            else
                if draw.startup.startupStage <= #draw.startup.startupModifiers then
                    draw.startup.startupStage = draw.startup.startupStage + 1
                    draw.startup.startupCurrentTime = draw.startup.startupStageLenght
                end
            end

            if draw.startup.startupStage > #draw.startup.startupModifiers
            then
                draw.startup.ongoing = false
            end
        end

        function draw.GetPosRadial(angle, radius)
            return vec2(
                math.sin(math.rad(angle)),
                math.cos(math.rad(angle))
            ) * radius
        end

        --- Yes I know these are comepletely unnessecary  lmao

        ---Draws a circular gauge background
        ---@param center vec2 Gauge cente
        ---@param radius number Background radius
        ---@param color rgbm Background color
        function draw.RoundBackground(center, radius, color)
            ui.drawCircleFilled(
                center,
                radius,
                color,
                self.numSegments
            )
        end

        ---Draws a rectangular gauge background with rounded edges
        ---@param p1 vec2|number Gauge center
        ---@param p2 vec2|number Background radius
        ---@param color rgbm Background color
        ---@param rounding? number
        ---@param roundingFlags? ui.CornerFlags
        function draw.RectBackground(p1, p2, color, rounding, roundingFlags)
            if rounding == nil then rounding = 0 end
            if roundingFlags == nil then roundingFlags = ui.CornerFlags.All end
            ui.drawRectFilled(
                p1,
                p2,
                color,
                rounding,
                roundingFlags
            )
        end

        ---Draws an arc from `begin` degrees to `begin + span` degrees
        ---
        ---Used mainly for needles
        ---@param center number|vec2 Gauge center
        ---@param begin number Arc beginning in degrees
        ---@param span number Arc span in degrees
        ---@param radius number Arc radius
        ---@param pinLen {[1]:number, [2]:number } Length of pins, [1]=Begin, [2]=End
        ---@param width number Arc stroke width
        ---@param color rgbm Arc color
        ---@param rounded? boolean Should ends be rounded, defualt `true`
        function draw.DrawArc(

            center,
            begin,
            span,
            radius,
            pinLen,
            width,
            color,
            rounded
        )
            if rounded == nil then rounded = true end

            -- Pin round
            local pos = vec2(
                math.cos(math.rad(begin + 90)),
                math.sin(math.rad(begin + 90))
            ) * (radius - pinLen[1]) + center

            if rounded then
                ui.drawCircleFilled(
                    pos,
                    width / 2,
                    color,
                    self.numSegments
                )
            end

            -- Pin
            if (pinLen[1] ~= 0) then
                ui.pathLineTo(
                    pos
                )
            end


            -- Arc
            ui.pathArcTo(
                center,
                radius,
                math.rad(begin + 90),
                math.rad(begin + span + 90),
                self.numSegments
            )
            -- Pin
            pos = vec2(
                math.cos(math.rad(begin + span + 90)),
                math.sin(math.rad(begin + span + 90))
            ) * (radius - pinLen[2]) + center

            if (pinLen[2] ~= 0) then
                ui.pathLineTo(
                    pos
                )
            end

            ui.pathStroke(color, false, width)

            -- Pin round
            if rounded then
                ui.drawCircleFilled(
                    pos,
                    width / 2,
                    color,
                    self.numSegments
                )
            end

            ----
        end

        ---Draws dwrite text lol
        ---@param position vec2|number
        ---@param text string
        ---@param size integer
        ---@param color rgbm
        ---@param center? vec2 Offset for the text
        function draw.DrawText(
            position,
            text,
            size,
            color,
            center
        )
            local textSize = ui.measureDWriteText(text, size)

            if center == nil then
                center = textSize / 2
            else
                center = center * textSize
            end

            ui.dwriteDrawText(
                text,
                size,
                position - center,
                color
            )
        end

        ---Creates a radial gradient for gauges
        ---
        ---Rendered only once at startup
        ---### PERFORMANCE!!!!!!!1!!1111
        ---@param resolution number
        ---@param width number
        ---@param brightness? number
        ---@param name? string Name for the gradient
        ---@return ui.ExtraCanvas
        function draw.RadialGradient(
            resolution,
            width,
            brightness,
            name
        )
            local gradientCanvas = ui.ExtraCanvas(
                resolution,
                1,
                render.AntialiasingMode.none,
                render.TextureFormat.R8G8B8A8.UNorm
            )

            if brightness == nil then brightness = 1 end

            local center = resolution / 2
            width = width / 2

            gradientCanvas:update(function()
                local segments = self.numSegments
                local shades = segments
                for i = 1, shades, 1 do
                    ui.drawCircle(
                        center,
                        resolution / 2 - (width / 2) * (i / shades),
                        rgbm(1, 1, 1, 1 / shades * brightness),
                        segments,
                        width * (i / shades)
                    )
                end
            end
            )
            if name ~= nil then
                gradientCanvas:setName(name)
            end

            return gradientCanvas
        end

        ---Creates a gradient for gauges
        ---
        ---Rendered only once at startup
        ---@param resolution vec2|number
        ---@param brightness? number
        ---@param name? string Name for the gradient
        ---@return ui.ExtraCanvas
        function draw.HorizontalGradient(
            resolution,
            brightness,
            name
        )
            local gradientCanvas = ui.ExtraCanvas(
                resolution,
                1,
                render.AntialiasingMode.none,
                render.TextureFormat.R8G8B8A8.UNorm
            )
            if brightness == nil then brightness = 1 end

            gradientCanvas:update(function()
                local segments = self.numSegments
                local shades = segments
                for i = 1, shades, 1 do
                    ui.drawRectFilled(
                        vec2(0, 1) * resolution * (i / shades),
                        resolution,
                        rgbm(1, 1, 1, 1 / shades * brightness)
                    )
                end
            end
            )
            if name ~= nil then
                gradientCanvas:setName(name)
            end

            return gradientCanvas
        end

        ---Creates a gradient for gauges
        ---
        ---Rendered only once at startup
        ---@param resolution vec2|number
        ---@param brightness? number
        ---@param name? string Name for the gradient
        ---@return ui.ExtraCanvas
        function draw.VerticalGradient(
            resolution,
            brightness,
            name
        )
            local gradientCanvas = ui.ExtraCanvas(
                resolution,
                1,
                render.AntialiasingMode.none,
                render.TextureFormat.R8G8B8A8.UNorm
            )
            if brightness == nil then brightness = 1 end

            gradientCanvas:update(function()
                local segments = self.numSegments
                local shades = segments
                for i = 1, shades, 1 do
                    ui.drawRectFilled(
                        vec2(1, 0) * resolution * (i / shades),
                        resolution,
                        rgbm(1, 1, 1, 1 / shades * brightness)
                    )
                end
            end
            )
            if name ~= nil then
                gradientCanvas:setName(name)
            end

            return gradientCanvas
        end

        return draw
    end

    self.draw = Draw()

    self.draw.horizontalGradient = self.draw.HorizontalGradient(512, 1, "Horizontal Gradient")
    self.draw.verticalGradient = self.draw.VerticalGradient(1024, 1, "Vertical Gradient")

    function self.update(dt)
        self.draw._handleStartup(dt)

        local sunAngle = ac.getSunAngle()
        ac.debug("SunAngle", sunAngle)

        local sunBrightnessMod = math.clamp(1 - (sunAngle / 95), 0, .25) / .25
        ac.debug("Sun Angle mod", sunBrightnessMod)

        if FocusedCar.headlightsActive then
            self.lightBrightness = 1
        else
            self.lightBrightness = sunBrightnessMod
        end
    end

    return self
end

return Utils()
