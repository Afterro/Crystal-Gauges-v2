function Globals()
    local globals = {}
    globals.Sim = ac.getSim()
    globals.focusedCar = ac.getCar(globals.Sim.focusedCar)
    globals.numSegments = 64

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
            if globals.Sim.cameraMode == ac.CameraMode.Start then return end

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

        ---Draws a circular gauge background
        ---@param center vec2 Gauge center
        ---@param radius number Background radius
        ---@param color rgbm Background color
        function draw.Background(center, radius, color)
            ui.drawCircleFilled(
                center,
                radius,
                color,
                globals.numSegments
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
                    globals.numSegments
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
                globals.numSegments
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
                    globals.numSegments
                )
            end

            ----
        end

        ---comment
        ---@param position vec2
        ---@param text string
        ---@param size integer
        ---@param color rgbm
        function draw.DrawText(
            position,
            text,
            size,
            color
        )
            local textSize = ui.measureDWriteText(text, size)
            ui.dwriteDrawText(
                text,
                size,
                position - textSize / 2,
                color
            )
        end

        ---Creates a gradient for gauges
        ---
        ---Rendered only once
        ---### PERFORMANCE!!!!!!!1!!1111
        ---@param resolution number
        ---@param width number
        ---@param brightness? number
        ---@param name? string Name for the gradient
        function draw.GetGradient(
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

            local center = resolution / 2
            width = width / 2

            gradientCanvas:update(function()
                local segments = globals.numSegments
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

        function draw.update(dt)
            if draw.startup.ongoing then
                draw._handleStartup(dt)
            end
        end

        return draw
    end

    globals.draw = Draw()

    return globals
end

return Globals()
