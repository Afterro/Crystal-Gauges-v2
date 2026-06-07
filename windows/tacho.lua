require("windows.globals")

function Tacho()
    local self = {}

    -- Meta values updated often or car dependant
    self.meta = {
        -- Startup animtamation
        startup = true,
        -- Duration for startup stages
        startupStageLenght = .75,
        -- Current stage time
        startupCurrentTime = 0,
        -- Modifiers for each stage
        startupModifiers = { 0, 0, 0, 0, 0 },
        -- Current stage
        startupStage = 1,

        -- Value needle ratio over the whole gauge range
        gaugeValueRatio = .5,
        -- Max value for this gauge
        maxValue = math.ceil(PlayerCar.rpmLimiter / 1000) * 1000,
        -- Max display value
        gaugeMaxDisplayValue = math.ceil(PlayerCar.rpmLimiter / 1000),
        -- Light up brightness dependant on the headlights state
        lightBrightness = 0.1,
        softLimitRatio = 0
    }
    self.meta.startupCurrentTime = self.meta.startupStageLenght

    self.settings = {
        radius = 128,
        backgroundColor = rgbm(0, 0, 0, .25),
        lightsOff = .1,
        lightsOn = 1,
        valueRange = {
            begin = 45,
            span = 270
        },
        value = {
            color = rgbm(1, 1, 1, 1),
            pinLengths = { 6, 40 },
            width = 4,
            background = {
                color = rgbm(.5, .5, .5, .25),
                pinLengths = { 6, 10 },
                width = 4
            },
            highlight = {
                color = rgbm(1, .0, 1, 1),
                offset = -2,
                width = 2
            },
            gradient = {
                width = 42,
                color = rgb(1, 0, 1)
            }
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

    self.gradientCanvas = draw.GetGradient(
        self.settings.radius,
        self.settings.valueRange.begin,
        self.settings.valueRange.span,
        self.settings.value.gradient.width,
        rgb(1, 1, 1),
        1,
        "Tacho Gradient"
    )

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
        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=600;Style=Italic")

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

    local function DrawIndicators()
        local backgroundColor = rgbm(0, 0, 0, .1 * stages[5] * self.meta.lightBrightness)

        -- High beams indicator
        local lightsPos = draw.GetPosRadial(0, 115 * math.clamp(stages[5] + .75, 0, 1))
        local lightsColor = rgbm(0, .25, 1, .5 * stages[5] * self.meta.lightBrightness)

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            5,
            backgroundColor
        )
        if PlayerCar.highBeams then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                5,
                lightsColor
            )
        end

        -- Left turn indicator
        local lightsPos = draw.GetPosRadial(-7, 115 * math.clamp(stages[5] + .75, 0, 1))
        local turningColor = rgbm(0, 1, 0, .25 * stages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            5,
            backgroundColor
        )
        if PlayerCar.turningLeftLights and PlayerCar.turningLightsActivePhase then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                5,
                turningColor
            )
        end

        -- Right turn indicator
        local lightsPos = draw.GetPosRadial(7, 115 * math.clamp(stages[5] + .75, 0, 1))

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            5,
            backgroundColor
        )
        if PlayerCar.turningRightLights and PlayerCar.turningLightsActivePhase then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                5,
                turningColor
            )
        end

        -- Handbrake indicator
        local lightsPos = draw.GetPosRadial(14, 115 * math.clamp(stages[5] + .75, 0, 1))
        local brakeColor = rgbm(1, 1, 0, .5 * stages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            5,
            backgroundColor
        )
        if PlayerCar.fuel / PlayerCar.maxFuel <= .1 then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                5,
                brakeColor
            )
        end

        -- Handbrake indicator
        local lightsPos = draw.GetPosRadial(-14, 115 * math.clamp(stages[5] + .75, 0, 1))
        local brakeColor = rgbm(1, 0, 0, .5 * stages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            5,
            backgroundColor
        )
        if PlayerCar.handbrake > 0 then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                5,
                brakeColor
            )
        end
    end

    local function DrawMileage()
        ui.pushDWriteFont(ui.DWriteFont("Comfortaa Light", "assets/fonts/Comfortaa-VariableFont_wght.ttf")
            :weight(600)
            :style(ui.DWriteFont.Style.Normal)
        )

        -- Decimal to the last digit for easier handling
        local mileage = PlayerCar.distanceDrivenTotalKm * 10
        if PlayerCar.prefersImperialUnits then
            mileage = mileage * 1.6
        end

        mileage               = math.round(mileage)
        local mileageStr      = string.format("%07d", mileage)
        local spaces          = 7

        local position        = vec2(
            0, 90
        )

        local fontSize        = 14

        local gap             = 3

        local stageColorMod   = rgbm(1, 1, 1, stages[5])
        local odoColor        = rgbm(1, 1, 1, self.meta.lightBrightness) * stageColorMod
        local odoColorDecimal = rgbm(1, 0, 1, self.meta.lightBrightness * .75) * stageColorMod


        local halfFont     = fontSize / 2
        local totalNumStep = halfFont + gap
        local centerOffset = totalNumStep * ((spaces - 1) / 2)


        local rectSize = vec2((centerOffset + halfFont) * 2, fontSize)
        -- Bacakground
        ui.drawRectFilled(
            windowCenter - rectSize / 2 + position * math.clamp(stages[5] + .75, 0, 1),
            windowCenter + rectSize / 2 + vec2(0, 2) + position * math.clamp(stages[5] + .75, 0, 1),
            self.settings.backgroundColor * .5 * rgbm(1, 1, 1, self.meta.lightBrightness) * stageColorMod,
            5
        )

        local zeroes         = true
        local zeroesAlphaMod = rgbm(1, 1, 1, .25)

        for i = 1, spaces, 1 do
            local num = string.sub(mileageStr, i, i)
            if num == "" then num = "0" end

            local finalColor = odoColor
            if i == spaces then finalColor = odoColorDecimal end
            if num ~= "0" then zeroes = false end -- End of trailing zeroes
            if zeroes then finalColor = finalColor * zeroesAlphaMod end

            local offset = vec2((totalNumStep * (i - 1)) - centerOffset, 0)

            -- Text
            draw.DrawText(
                windowCenter + position * math.clamp(stages[5] + .75, 0, 1) + offset,
                num,
                fontSize,
                finalColor
            )
        end
        ui.popDWriteFont()
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


        DrawIndicators()
        DrawSpeedAndGear()
        DrawRevNums()
        DrawMileage()

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
            (self.meta.maxValue - PlayerCar.rpmLimiter + self.settings.redline.soft.rpms) / self.meta.maxValue *
            stages[4],
            (self.settings.radius + self.settings.redline.soft.offset + self.settings.value.background.width / 2),
            { self.settings.redline.soft.pinLengths[1] * stages[4], self.settings.redline.soft.pinLengths[2] * stages[4] },
            self.settings.redline.soft.width,
            self.settings.redline.soft.color * rgbm(1, 1, 1, self.meta.lightBrightness * stages[3])
        )

        local gradientColor = rgbm(
            self.settings.value.gradient.color.r + self.meta.softLimitRatio,
            self.settings.value.gradient.color.g - self.meta.softLimitRatio,
            (self.settings.value.gradient.color.b - self.meta.softLimitRatio),
            1
        ) * self.meta.lightBrightness * stages[5]
        -- Value Gradient
        ui.beginPremultipliedAlphaTexture()
        ui.beginTextureShade(self.gradientCanvas)
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * self.meta.gaugeValueRatio,
            self.settings.radius * .5,
            { 0, 0 },
            self.settings.radius,
            gradientColor,
            false
        )
        ui.endTextureShade(0, windowSize, true)
        ui.endPremultipliedAlphaTexture()

        local highlightColor = rgbm(
            self.settings.value.highlight.color.r + self.meta.softLimitRatio,
            self.settings.value.highlight.color.g - self.meta.softLimitRatio,
            self.settings.value.highlight.color.b - self.meta.softLimitRatio,
            self.settings.value.highlight.color.mult
        ) * self.meta.lightBrightness
        -- Value Highlight
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * self.meta.gaugeValueRatio * stages[4],
            (self.settings.radius + self.settings.value.highlight.offset + self.settings.value.highlight.width / 2),
            { 0, 0 },
            self.settings.value.highlight.width,
            highlightColor,
            false
        )

        local valueColorMult = math.clamp(self.meta.lightBrightness, .5, 1)
        -- Value Needle
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin,
            self.settings.valueRange.span * self.meta.gaugeValueRatio * stages[4],
            (self.settings.radius + self.settings.value.width / 2),
            { self.settings.value.pinLengths[1] * stages[4], self.settings.value.pinLengths[2] * stages[4] },
            self.settings.value.width,
            self.settings.value.color *
            rgbm(valueColorMult, valueColorMult, valueColorMult, stages[3])
        )
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
        self.meta.softLimitRatio = (PlayerCar.rpm - PlayerCar.rpmLimiter + self.settings.redline.soft.rpms) /
            self.settings.redline.soft.rpms
        self.meta.softLimitRatio = math.clamp(self.meta.softLimitRatio * 2, 0, 1)
    end

    local function handleStartup(dt)
        -- If player is in setup screen
        if Sim.cameraMode == ac.CameraMode.Start then return end

        if self.meta.startupStage <= #self.meta.startupModifiers and self.meta.startupCurrentTime > 0 then
            self.meta.startupCurrentTime = self.meta.startupCurrentTime - dt

            self.meta.startupModifiers[self.meta.startupStage] = 1 -
                (self.meta.startupCurrentTime / self.meta.startupStageLenght)

            self.meta.startupModifiers[self.meta.startupStage] = math.clamp(
                self.meta.startupModifiers[self.meta.startupStage], 0, 1)
        else
            if self.meta.startupStage <= #self.meta.startupModifiers then
                self.meta.startupStage = self.meta.startupStage + 1
                self.meta.startupCurrentTime = self.meta.startupStageLenght
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
            vec2(self.settings.radius, self.settings.radius),
            vec2(self.settings.radius, self.settings.radius)
        )
    end

    return self
end

return Tacho()
