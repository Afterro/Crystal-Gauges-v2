require("windows.globals")

function Tacho()
    local self = {}

    local valueRatio = 0

    self.meta = {
        startup = true,
        startupTime = .75,
        startupCurrentTime = 0,
        startupModifiers = { 0, 0, 0, 0, 0 },
        startupStage = 1,

        gaugeValueRatio = .5,
        maxValue = math.ceil(PlayerCar.rpmLimiter / 1000) * 1000,
        gaugeMaxDisplayValue = math.ceil(PlayerCar.rpmLimiter / 1000),
        lightBrightness = 0.1
    }
    self.meta.startupCurrentTime = self.meta.startupTime

    self.settings = {
        radius = 128,
        backgroundColor = rgbm(0, 0, 0, .25),
        lightsOff = .05,
        lightsOn = 1,
        valueRange = {
            begin = 45,
            span = 270
        },
        value = {
            color = rgbm(1, 1, 1, 1),
            backgroundColor = rgbm(.25, .25, .25, 1),
            pinLengths = { 6, 40 },
            width = 4,
            background = {
                color = rgbm(.25, .25, .25, 1),
                pinLengths = { 6, 10 },
                width = 4
            },
            highlight = {
                color = rgbm(1, .0, 1, 1),
                offset = -2,
                width = 2
            },
        },
        redline = {
            soft = {
                rpms = 1000,
                color = rgbm(1, 0, 0, 1),
                pinLengths = { 10, 0 },
                offset = 0,
                width = 4
            },
            hard = {
                color = rgbm(.5, 0, 0, 1),
                pinLengths = { 6, 0 },
                offset = -4,
                width = 4
            }
        }
    }

    local stages = {}

    local windowSize = vec2()
    local windowCenter = vec2()
    local draw = Draw()

    local function DrawSpeedAndGear()
        local color = rgbm(1, 1, 1, self.meta.lightBrightness * stages[4])

        local speed = math.round(PlayerCar.poweredWheelsSpeed)
        if PlayerCar.prefersImperialUnits then
            speed = math.round(PlayerCar.poweredWheelsSpeed / 1.6)
        end

        draw.DrawText(
            windowCenter + vec2(0, -32) * math.clamp(stages[4] + .75, 0, 1),
            stringify(speed),
            54,
            color
        )

        ui.drawEllipseFilled(
            windowCenter,
            vec2(54 * stages[4], 1.5),
            color,
            54

        )

        local gearNum = math.round(PlayerCar.engagedGear)
        local gear = stringify(gearNum)
        if gearNum == 0 then
            gear = "N"
        else
            if gearNum == -1 then gear = "R" end
        end

        draw.DrawText(
            windowCenter + vec2(0, 26) * math.clamp(stages[4] + .75, 0, 1),
            gear,
            42,
            color
        )
    end

    local function DrawRevNums()
        local color = rgbm(1, 1, 1, self.meta.lightBrightness)

        local step = 1
        if self.meta.gaugeMaxDisplayValue % 10 == 0 then
            step = self.meta.gaugeMaxDisplayValue / 10
        end

        for i = 0, self.meta.gaugeMaxDisplayValue, step do
            local pos = vec2(
                math.cos(math.rad(90 + self.settings.valueRange.begin +
                    (self.settings.valueRange.span / self.meta.gaugeMaxDisplayValue) *
                    i)),
                math.sin(math.rad(90 + self.settings.valueRange.begin +
                    (self.settings.valueRange.span / self.meta.gaugeMaxDisplayValue) *
                    i))
            ) * (self.settings.radius - 20) * math.clamp(stages[3] + .5, 0, 1) + windowCenter

            draw.DrawText(pos, stringify(i), 16,
                color * rgbm(1, 1, 1, stages[3]))

            if PlayerCar.headlightsActive then
                ui.glowCircleFilled(
                    pos,
                    8,
                    rgbm(1, 1, 1, 1) * rgbm(1, 1, 1, stages[3])
                )
            end
        end

        ui.popDWriteFont()
    end

    local function DrawMileage()
        local mileage = PlayerCar.distanceDrivenTotalKm * 10
        if PlayerCar.prefersImperialUnits then
            mileage = mileage * 1.6
        end
        mileage = math.round(mileage)
        local mileageStr = string.format("%07d", mileage)

        local pos = vec2(
            0, 95
        )

        local gap = 10
        local fontSize = 12
        local rectSize = 14

        local stageColorMod = rgbm(1, 1, 1, stages[5])

        local spaces = 7
        for i = 1, spaces, 1 do
            local num = string.sub(mileageStr, i, i)
            if num == "" then num = "0" end

            local color = rgbm(1, 1, 1, self.meta.lightBrightness)
            if i == spaces then
                color = rgbm(1, .5, 0, self.meta.lightBrightness)
            end

            if num == "0" then
                color = color * rgbm(.5, .5, .5, self.meta.lightBrightness)
            end
            color = color * stageColorMod

            local offset = vec2((fontSize / 2 + gap) * (i - 1) - ((fontSize / 2 + gap) * (spaces - 1)) / 2, 0)

            ui.drawRectFilled(
                windowCenter + pos * math.clamp(stages[5] + .75, 0, 1) + offset - (rectSize / 2),
                windowCenter + pos * math.clamp(stages[5] + .75, 0, 1) + offset + (rectSize / 2),
                self.settings.backgroundColor * rgbm(1, 1, 1, self.meta.lightBrightness) * stageColorMod,
                2
            )

            draw.DrawText(
                windowCenter + pos * math.clamp(stages[5] + .75, 0, 1) + offset,
                num,
                fontSize,
                color
            )
        end
    end

    local function DrawGauge()
        draw.Background(
            windowCenter,
            self.settings.radius * stages[1],
            self.settings.backgroundColor * rgbm(1, 1, 1, stages[1])
        )
        ui.pushDWriteFont(
            "Varien:assets/fonts/Varien.ttf;Weight=400;Style=Regular")

        local speedSystem = "KM/H"
        if PlayerCar.prefersImperialUnits then
            speedSystem = "MPH"
        end
        draw.DrawText(
            windowCenter + vec2(0, -65) * math.clamp(stages[5] + .75, 0, 1),
            speedSystem,
            12,
            rgbm(1, 1, 1, self.meta.lightBrightness * stages[5])
        )

        -- Range background
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * stages[2],
            (self.settings.radius + self.settings.value.background.width / 2) * stages[1],
            { self.settings.value.background.pinLengths[1] * stages[1], self.settings.value.background.pinLengths[2] *
            stages[2] },
            self.settings.value.background.width,
            self.settings.value.background.color * rgbm(1, 1, 1, stages[1])
        )

        -- hard redline
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin + self.settings.valueRange.span,
            -self.settings.valueRange.span * ((self.meta.maxValue - PlayerCar.rpmLimiter) / self.meta.maxValue) *
            stages[4],
            (self.settings.radius + self.settings.redline.hard.offset + self.settings.value.background.width / 2),
            { self.settings.redline.hard.pinLengths[1] * stages[4], self.settings.redline.hard.pinLengths[2] * stages[5] },
            self.settings.redline.hard.width,
            self.settings.redline.hard.color * rgbm(1, 1, 1, self.meta.lightBrightness * stages[3])
        )

        -- Soft redline
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin + self.settings.valueRange.span,
            -self.settings.valueRange.span *
            ((self.meta.maxValue - PlayerCar.rpmLimiter + self.settings.redline.soft.rpms) / (self.meta.maxValue + self.settings.redline.soft.rpms)) *
            stages[4],
            (self.settings.radius + self.settings.redline.soft.offset + self.settings.value.background.width / 2),
            { self.settings.redline.soft.pinLengths[1] * stages[4], self.settings.redline.soft.pinLengths[2] * stages[4] },
            self.settings.redline.soft.width,
            self.settings.redline.soft.color * rgbm(1, 1, 1, self.meta.lightBrightness * stages[3])
        )

        -- Value Gradient
        -- NOTE:
        -- Highly unoptimised
        -- Eats from .02 to .1ms render
        -- I have no idea how else to handle a circular gradient like this one while also being accurate
        -- Reducing the count of arcs is faster but prodces less accurate gradient
        -- Quarter of width for count produces best noticeable quality for high width but eats alot
        -- 1/6 of width is probably best for high width
        -- Width <= 64, count = width / 3 is imo best

        local width = 64
        local count = width / 3
        local brightness = .5
        for i = 1, count, 1 do
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin,
                self.settings.valueRange.span * self.meta.gaugeValueRatio * stages[4],
                (self.settings.radius - width * stages[5] * (i / count) / 2),
                { 0, 0 },
                width * (i / count) * stages[5],
                rgbm(1, 0, 1, 1 / count * brightness * self.meta.lightBrightness),
                false
            )
        end


        -- Value Highlight
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * self.meta.gaugeValueRatio * stages[4],
            (self.settings.radius + self.settings.value.highlight.offset + self.settings.value.highlight.width / 2),
            { 0, 0 },
            self.settings.value.highlight.width,
            self.settings.value.highlight.color * self.meta.lightBrightness,
            false
        )

        -- Value Needle
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * self.meta.gaugeValueRatio * stages[4],
            (self.settings.radius + self.settings.value.width / 2),
            { self.settings.value.pinLengths[1] * stages[3], self.settings.value.pinLengths[2] * stages[3] },
            self.settings.value.width,
            self.settings.value.color *
            rgbm(1, 1, 1, stages[3])
        )

        DrawSpeedAndGear()

        ui.popDWriteFont()


        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=600;Style=Italic")

        DrawRevNums()

        DrawMileage()

        ui.popDWriteFont()
    end

    local function updateValues()
        windowSize = ui.windowSize()
        windowCenter = windowSize / 2

        if PlayerCar.headlightsActive then
            self.meta.lightBrightness = self.settings.lightsOn
        else
            self.meta.lightBrightness = self.settings.lightsOff
        end

        self.meta.gaugeValueRatio = PlayerCar.rpm / self.meta.maxValue
    end

    local function handleStartup(dt)
        -- If player is in setup screen
        if Sim.cameraMode == ac.CameraMode.Start then return end

        if self.meta.startupStage <= #self.meta.startupModifiers and self.meta.startupCurrentTime > 0 then
            self.meta.startupCurrentTime = self.meta.startupCurrentTime - dt

            self.meta.startupModifiers[self.meta.startupStage] = 1 -
                (self.meta.startupCurrentTime / self.meta.startupTime)

            self.meta.startupModifiers[self.meta.startupStage] = math.clamp(
                self.meta.startupModifiers[self.meta.startupStage], 0, 1)
        else
            if self.meta.startupStage <= #self.meta.startupModifiers then
                self.meta.startupStage = self.meta.startupStage + 1
                self.meta.startupCurrentTime = self.meta.startupTime
            end
        end

        if self.meta.startupStage > #self.meta.startupModifiers
        then
            self.meta.startup = false
        end
    end

    function self.window(dt)
        stages = {
            self.meta.startupModifiers[1],
            self.meta.startupModifiers[2],
            self.meta.startupModifiers[3],
            self.meta.startupModifiers[4],
            self.meta.startupModifiers[5]
        }

        updateValues()

        if self.meta.startup then
            handleStartup(dt)
        end

        if ui.windowHovered() then
            ui.drawRect(vec2(0, 0),
                windowSize,
                rgbm(1, 1, 1, 1),
                0,
                ui.CornerFlags.All,
                1
            )
        end


        DrawGauge()

        ac.setWindowSizeConstraints(
            "tacho",
            vec2(self.settings.radius, self.settings.radius) * 2.25,
            vec2(self.settings.radius, self.settings.radius) * 2.25
        )
    end

    return self
end

return Tacho()
