if FocusedCar == nil then
    ac.debug("ERROR", "No focused car found for media")
    return
end


local function Inputs()
    local self = {}

    local windowCenter = vec2()
    self.settings = {
        backgroundColor = rgbm(0, 0, 0, .25),
    }

    local divisions = 4

    local sinceLastReportMs = 0
    local inputReportRangeSec = 5
    local framerate = 60
    local throttle = table.new(framerate * inputReportRangeSec, 0)

    local brake = table.new(framerate * inputReportRangeSec, 0)
    local clutch = table.new(framerate * inputReportRangeSec, 0)
    local handbrake = table.new(framerate * inputReportRangeSec, 0)
    local ffb = table.new(framerate * inputReportRangeSec, 0)

    local function cleanUpTelemetry(telemetry)
        if table.nkeys(telemetry) < framerate * inputReportRangeSec then
            for i = 1, framerate * inputReportRangeSec, 1 do
                telemetry[i] = 0
            end
        end
        if table.nkeys(telemetry) > framerate * inputReportRangeSec then
            table.remove(telemetry, 1)
        end
    end

    ---comment
    ---@param values any
    ---@param p1 any
    ---@param p2 any
    ---@param color any
    ---@param inverse? boolean
    local function drawPedalGraph(values, p1, p2, color, inverse)
        if inverse == nil then
            inverse = false
        end
        local pathPos = vec2()
        for curr = 1, table.nkeys(values) do
            local value = values[curr]
            if inverse then value = value else value = 1 - value end
            pathPos:set(curr / (framerate * inputReportRangeSec), value) -- Helps with GC - Yeah I looked at CMRT for optimization since I was at .5ms dt at one point... Gotta learn somehow i guess.
            ui.pathLineTo(p1 + p2 * pathPos)
        end
        ui.pathSimpleStroke(color, false, 2)
    end

    local function DrawInputs()
        local p1 = vec2(-1, 1)
        local p2 = windowCenter * 2 - vec2(-1, 2)

        for i = 0, divisions, 1 / divisions do
            ui.drawSimpleLine(vec2(
                    0, windowCenter.y * 2 * i
                ),
                vec2(
                    windowCenter.x * 2, windowCenter.y * 2 * i
                ), rgbm(1, 1, 1, .1), 1)
        end

        drawPedalGraph(throttle, p1, p2, rgbm.colors.lime)
        drawPedalGraph(clutch, p1, p2, rgbm.colors.cyan, true)
        drawPedalGraph(handbrake, p1, p2, rgbm.colors.yellow)
        drawPedalGraph(brake, p1, p2, rgbm.colors.red)
        -- drawPedalGraph(ffb, p1, p2, rgbm.colors.gray)
    end

    function self.window(dt)
        windowCenter = ui.windowSize() / 2
        Globals.draw.RectBackground(0, windowCenter * 2, self.settings.backgroundColor)

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


        DrawInputs()

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
