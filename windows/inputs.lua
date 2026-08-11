if FocusedCar == nil then
    ac.debug("ERROR", "No focused car found for media")
    return
end


local function Inputs()
    local self = {}

    local windowCenter = vec2()
    self.settings = {
        backgroundColor = rgbm(0, 0, 0, .25),
        inputsWidth = 100,
        strokeWidth = 2
    }

    local divisions = 4

    local sinceLastReportMs = 0
    local inputReportRangeSec = 3
    local framerate = 60
    local totalReports = framerate * inputReportRangeSec

    local throttle = table.new(totalReports, 0)
    local brake = table.new(totalReports, 0)
    local clutch = table.new(totalReports, 0)
    local handbrake = table.new(totalReports, 0)
    local ffb = table.new(totalReports, 0)

    local function cleanUpTelemetry(telemetry)
        if table.nkeys(telemetry) > totalReports then
            table.remove(telemetry, 1)
        elseif table.nkeys(telemetry) < totalReports then
            for i = 1, totalReports, 1 do
                telemetry[i] = 0
            end
        end
    end

    ---comment
    ---@param values any
    ---@param p1 any
    ---@param p2 any
    ---@param color any
    ---@param inverse? boolean
    local function DrawTelemetry(values, p1, p2, color, inverse)
        if inverse == nil then
            inverse = false
        end
        local pathPos = vec2()
        for curr = 1, table.nkeys(values) do
            local value = values[curr]
            if inverse then value = value else value = 1 - value end
            pathPos:set(curr / totalReports, value) -- Helps with GC - Yeah I looked at CMRT for optimization since I was at .5ms dt at one point... Gotta learn somehow i guess.
            ui.pathLineTo(p1 + p2 * pathPos + vec2(1, 0))
        end
        ui.pathStroke(color, false, self.settings.strokeWidth)
    end

    local function DrawPedalInput(value, p1, size, fullPressedHeight, color)
        local pedalP1 = p1 + vec2(0, fullPressedHeight)

        ui.drawRectFilled(p1, p1 + vec2(size.x, fullPressedHeight - 1), self.settings.backgroundColor)
        if value >= 1 then
            ui.drawRectFilled(p1, p1 + vec2(size.x, fullPressedHeight - 1), color)
        end

        ui.drawRectFilled(pedalP1, p1 + size, self.settings.backgroundColor)
        ui.drawRectFilled(pedalP1 + vec2(0, (size.y - fullPressedHeight) * (1 - value)), p1 + size, color)
    end

    local function DrawInput()
        local padding = 5
        local p1 = vec2(-1, 1) + padding
        local p2 = windowCenter * 2 -
            vec2(self.settings.inputsWidth, self.settings.strokeWidth + padding * 2)

        ui.drawRectFilled(padding, vec2(p2.x + padding, windowCenter.y * 2 - padding), self.settings.backgroundColor)

        for i = 1, divisions - 1, 1 do
            ui.drawSimpleLine(vec2(
                    padding, (p2.y + self.settings.strokeWidth) * (i / divisions) + padding
                ),
                vec2(
                    p2.x + padding, (p2.y + self.settings.strokeWidth) * (i / divisions) + padding
                ), rgbm(1, 1, 1, .1), 1)
        end

        DrawTelemetry(throttle, p1, p2, rgbm.colors.lime)
        DrawTelemetry(clutch, p1, p2, rgbm.colors.cyan, true)
        DrawTelemetry(handbrake, p1, p2, rgbm.colors.yellow)
        DrawTelemetry(brake, p1, p2, rgbm.colors.red)
        -- drawPedalGraph(ffb, p1, p2, rgbm.colors.gray)

        local pedalWidth = 8
        local fullPressedHeight = 3
        local offset = 1
        local pedalPos = vec2(windowCenter.x * 2 - self.settings.inputsWidth + padding + offset, padding)
        DrawPedalInput(
            1 - FocusedCar.clutch,
            pedalPos,
            vec2(pedalWidth, windowCenter.y * 2 - padding * 2),
            fullPressedHeight,
            rgbm.colors.cyan
        )
        DrawPedalInput(
            FocusedCar.brake,
            pedalPos + vec2(pedalWidth + offset, 0),
            vec2(pedalWidth, windowCenter.y * 2 - padding * 2),
            fullPressedHeight,
            rgbm.colors.red
        )
        DrawPedalInput(
            FocusedCar.gas,
            pedalPos + vec2(pedalWidth * 2 + offset * 2, 0),
            vec2(pedalWidth, windowCenter.y * 2 - padding * 2),
            fullPressedHeight,
            rgbm.colors.lime
        )
        DrawPedalInput(
            FocusedCar.handbrake,
            pedalPos + vec2(pedalWidth * 3 + offset * 3, 0),
            vec2(pedalWidth, windowCenter.y * 2 - padding * 2),
            fullPressedHeight,
            rgbm.colors.yellow
        )

        local ffbColor = rgbm.colors.gray
        if FocusedCar.ffbFinal >= 1 then ffbColor = rgbm.colors.red end
        local ffbValue = math.clamp(math.abs(FocusedCar.ffbFinal), 0, 1)

        DrawPedalInput(
            ffbValue,
            pedalPos + vec2(pedalWidth * 4 + offset * 4, 0),
            vec2(pedalWidth, windowCenter.y * 2 - padding * 2),
            fullPressedHeight,
            ffbColor
        )


        local wheelPos = vec2(windowCenter.x * 2 - self.settings.inputsWidth / 4, windowCenter.y)
        local wheelRadius = 18
        local wheelPosIndicatorLen = 20
        local wheelIndicatorThickness = 5
        local steer = FocusedCar.steer - 90
        local wheelColor = rgbm(1, 1, 1, 1)
        if FocusedCar.speedKmh < 1 and math.abs(steer + 90) > 90 then
            wheelColor = rgbm(1, 0, 0, 1)
        end
        ui.drawCircle(wheelPos, wheelRadius, self.settings.backgroundColor, 64, wheelIndicatorThickness)
        ui.pathArcTo(wheelPos, wheelRadius, math.rad(-wheelPosIndicatorLen / 2 + steer),
            math.rad(wheelPosIndicatorLen / 2 + steer), 32)
        ui.pathStroke(wheelColor, false, wheelIndicatorThickness)

        local gearNum = math.round(FocusedCar.gear)
        local gear = stringify(gearNum)
        if gearNum == 0 then
            gear = "N"
        else
            if gearNum == -1 then gear = "R" end
        end
        Globals.draw.DrawText(wheelPos, gear, 12, rgbm(1, 1, 1, 1))
    end

    function self.window(dt)
        windowCenter = ui.windowSize() / 2
        Globals.draw.RectBackground(0, windowCenter * 2, self.settings.backgroundColor, 5)

        -- Time to report inputs
        if sinceLastReportMs >= 1 / framerate then
            throttle[#throttle + 1] = FocusedCar.gas
            brake[#brake + 1] = FocusedCar.brake
            clutch[#clutch + 1] = FocusedCar.clutch
            handbrake[#handbrake + 1] = FocusedCar.handbrake
            ffb[#ffb + 1] = FocusedCar.ffbFinal
            sinceLastReportMs = 0
        end

        cleanUpTelemetry(throttle)
        cleanUpTelemetry(brake)
        cleanUpTelemetry(clutch)
        cleanUpTelemetry(handbrake)
        cleanUpTelemetry(ffb)


        DrawInput()

        if ui.windowHovered() then
            ui.drawRect(vec2(0, 0),
                windowCenter * 2,
                rgbm(1, 1, 1, 1),
                0,
                ui.CornerFlags.All,
                1
            )
        end
        sinceLastReportMs = sinceLastReportMs + dt
    end

    return self
end

return Inputs()
