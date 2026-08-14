if FocusedCar == nil then
    ac.debug("ERROR", "No player found in tacho")
    return
end

local function Tacho()
    local self = {}

    -- Values updated often or car dependant
    -- Value needle ratio over the whole gauge range
    local gaugeValueRatio = .5
    -- currentRPM after interpolation
    local currentRPM = 0
    -- Max value for this gauge
    local maxValue = math.ceil(FocusedCar.rpmLimiter / 1000) * 1000
    local maxBoost = 0
    -- Max display value
    local gaugeMaxDisplayValue = math.ceil(FocusedCar.rpmLimiter / 1000)
    if FocusedCar.rpmLimiter % 1000 >= 500 or FocusedCar.rpmLimiter % 1000 == 0 then
        maxValue = maxValue + 1000
        gaugeMaxDisplayValue = gaugeMaxDisplayValue + 1
    end
    local softLimitRatio = 0

    self.settings = {
        radius = 100,
        backgroundColor = rgbm(0, 0, 0, .125),
        valueRange = {
            begin = 90,
            span = 270
        },
        value = {
            enabled = true,
            color = rgbm(1, 1, 1, 1),
            pinLengths = { 5, 32 },
            width = 3,
            offset = 0,
            background = {
                enabled = true,
                color = rgbm(.25, .25, .25, .5),
                pinLengths = { 0, 0 },
                offset = 0,
                width = 3
            },
            highlight = {
                enabled = true,
                color = rgbm(.5, .25, .75, 1),
                offset = -3,
                width = 3
            },
            gradient = {
                enabled = true,
                width = 32,
                assetScale = 5.12,
                color = rgbm(.5, .25, .75, .5)
            }
        },
        redline = {
            soft = {
                enabled = true,
                rpms = 1000,
                color = rgbm(.75, 0, 0, 1),
                pinLengths = { 5, 0 },
                offset = 0,
                width = 3
            },
            hard = {
                enabled = true,
                color = rgbm(.5, 0, 0, 1),
                pinLengths = { 0, 0 },
                offset = -3,
                width = 3
            }
        },
        revNumbers = {
            enabled = true,
            color = rgbm(.9, .9, .9, 1),
            size = 14,
            offset = 16
        }
    }

    local startupStages = {}

    local windowSize = vec2()
    local windowCenter = vec2()
    local draw = Globals.draw

    self.gradientCanvas = draw.RadialGradient(
        self.settings.radius,
        self.settings.value.gradient.width,
        self.settings.value.gradient.color.mult,
        "Tacho Gradient",
        self.settings.value.gradient.assetScale
    )

    self.revNumbersCanvasScale = 2
    self.revNumbersCanvas = nil


    local function DrawSpeedAndGear()
        local textColor = rgbm(1, 1, 1, Globals.lightBrightness * startupStages[4])
        local speedSystem = "KM/H"
        if FocusedCar.prefersImperialUnits then
            speedSystem = "MPH"
        end
        draw.DrawText(
            windowCenter + vec2(0, -50) * math.clamp(startupStages[4] + .75, 0, 1),
            speedSystem,
            9,
            textColor
        )
        local barColor = rgbm(1, 1, 1, Globals.lightBrightness * startupStages[3])
        local speedTextSize = 44

        local speed = math.round(FocusedCar.poweredWheelsSpeed)
        if FocusedCar.prefersImperialUnits then
            speed = math.round(FocusedCar.poweredWheelsSpeed / 1.6)
        end

        draw.DrawText(
            windowCenter + vec2(0, -24) * math.clamp(startupStages[4] + .75, 0, 1),
            stringify(speed),
            speedTextSize,
            textColor
        )


        ui.drawEllipseFilled(
            windowCenter + vec2(0, 5),
            vec2(32 * startupStages[3], 1),
            barColor,
            Globals.numSegments
        )

        local gearNum = math.round(FocusedCar.engagedGear)
        local gear = stringify(gearNum)
        local gearPos = windowCenter + vec2(0, 26) * math.clamp(startupStages[4] + .75, 0, 1)
        local gearTextSize = 34
        if gearNum == 0 then
            gear = "N"
        else
            if gearNum == -1 then gear = "R" end
        end

        draw.DrawText(
            gearPos,
            gear,
            gearTextSize,
            textColor
        )
    end

    local function UpdateRevNumsCanvas()
        if self.revNumbersCanvas == nil then
            self.revNumbersCanvas = ui.ExtraCanvas(windowSize * self.revNumbersCanvasScale)
        end
        self.revNumbersCanvas:update(function(dt)
            ui.pushDWriteFont(
                ui.DWriteFont("Comfortaa Light", "assets/fonts/Comfortaa-VariableFont_wght.ttf")
                :weight(600)
                :style(ui.DWriteFont.Style.Italic)
            )

            local step = 1
            if gaugeMaxDisplayValue % 10 == 0 then
                step = gaugeMaxDisplayValue / 10
            end

            for i = 0, gaugeMaxDisplayValue, step do
                local pos = vec2(
                        math.cos(math.rad(90 + self.settings.valueRange.begin +
                            (self.settings.valueRange.span / gaugeMaxDisplayValue) *
                            i)),
                        math.sin(math.rad(90 + self.settings.valueRange.begin +
                            (self.settings.valueRange.span / gaugeMaxDisplayValue) *
                            i))
                    ) * (self.settings.radius - self.settings.revNumbers.offset) * self.revNumbersCanvasScale +
                    windowCenter * self.revNumbersCanvasScale

                draw.DrawText(pos, stringify(i), self.settings.revNumbers.size * self.revNumbersCanvasScale,
                    self.settings.revNumbers.color) -- * rgbm(1, 1, 1, startupStages[3] * Globals.lightBrightness)
            end

            ui.popDWriteFont()
        end)

        self.revNumbersCanvas:setName("Rev Numbers" ..
            " (" .. math.round(self.revNumbersCanvas:memoryFootprint() / 1024 / 1024, 0) .. "MB)")
    end

    -- TODO:
    -- Move to a dedicated app
    local function DrawIndicators()
        local backgroundColor = rgbm(0, 0, 0, .1 * startupStages[5] * Globals.lightBrightness)
        local indicatorsRadius = 110
        local indicatorsSize = 5

        -- High beams indicator
        local lightsPos = draw.GetPosRadial(0, indicatorsRadius * math.clamp(startupStages[5] + .75, 0, 1))
        local lightsColor = rgbm(0, .25, 1, .75 * startupStages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            indicatorsSize,
            backgroundColor
        )
        if FocusedCar.highBeams then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                indicatorsSize,
                lightsColor
            )
        end

        -- ui.drawIcon(ui.Icons.Bulb, windowCenter + lightsPos - indicatorsSize / 2,
        --     windowCenter + lightsPos + indicatorsSize / 2, rgbm(1, 1, 1, 1))

        -- Left turn indicator
        local lightsPos = draw.GetPosRadial(-7, indicatorsRadius * math.clamp(startupStages[5] + .75, 0, 1))
        local turningColor = rgbm(0, 1, 0, .75 * startupStages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            indicatorsSize,
            backgroundColor
        )
        if FocusedCar.turningLeftLights and FocusedCar.turningLightsActivePhase then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                indicatorsSize,
                turningColor
            )
        end

        -- Right turn indicator
        local lightsPos = draw.GetPosRadial(7, indicatorsRadius * math.clamp(startupStages[5] + .75, 0, 1))

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            indicatorsSize,
            backgroundColor
        )
        if FocusedCar.turningRightLights and FocusedCar.turningLightsActivePhase then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                indicatorsSize,
                turningColor
            )
        end

        -- Fuel indicator
        local lightsPos = draw.GetPosRadial(14, indicatorsRadius * math.clamp(startupStages[5] + .75, 0, 1))
        local fuelColor = rgbm(1, 1, 0, .75 * startupStages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            indicatorsSize,
            backgroundColor
        )
        if FocusedCar.fuel / FocusedCar.maxFuel <= .15 then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                indicatorsSize,
                fuelColor
            )
        end

        -- Handbrake indicator
        local lightsPos = draw.GetPosRadial(-14, indicatorsRadius * math.clamp(startupStages[5] + .75, 0, 1))
        local brakeColor = rgbm(1, 0, 0, .75 * startupStages[5])

        ui.drawCircleFilled(
            windowCenter + lightsPos,
            indicatorsSize,
            backgroundColor
        )
        if FocusedCar.handbrake > 0 then
            ui.drawCircleFilled(
                windowCenter + lightsPos,
                indicatorsSize,
                brakeColor
            )
        end
    end

    local function DrawMileage()
        ui.pushDWriteFont(ui.DWriteFont("Comfortaa Light", "assets/fonts/Comfortaa-VariableFont_wght.ttf")
            :weight(600)
            :stretch(ui.DWriteFont.Stretch.Expanded)
        )

        -- Decimal to the last digit for easier handling
        local mileage = FocusedCar.distanceDrivenTotalKm * 10
        if FocusedCar.prefersImperialUnits then
            mileage = mileage * 1.6
        end

        mileage               = math.round(mileage)
        local mileageStr      = string.format("%07d", mileage)
        local spaces          = 7

        local position        = vec2(
            0, 55
        )

        local fontSize        = 12

        local gap             = 2

        local stageColorMod   = rgbm(1, 1, 1, startupStages[5])
        local odoColor        = rgbm(1, 1, 1, Globals.lightBrightness) * stageColorMod
        local odoColorDecimal = self.settings.value.highlight.color * rgbm(1, 1, 1, Globals.lightBrightness) *
            stageColorMod


        local halfFont     = fontSize / 2
        local totalNumStep = halfFont + gap
        local centerOffset = totalNumStep * ((spaces - 1) / 2)

        local rectSize     = vec2((centerOffset + halfFont) * 2, fontSize)
        -- Bacakground
        ui.drawRectFilled(
            windowCenter - rectSize / 2 + position * math.clamp(startupStages[5] + .75, 0, 1),
            windowCenter + rectSize / 2 + vec2(0, 2) + position * math.clamp(startupStages[5] + .75, 0, 1),
            rgbm(0, 0, 0, .125) * rgbm(1, 1, 1, Globals.lightBrightness) * stageColorMod,
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
                windowCenter + position * math.clamp(startupStages[5] + .75, 0, 1) + offset,
                num,
                fontSize,
                finalColor
            )
        end
        ui.popDWriteFont()
    end

    local function DrawBoost()
        if FocusedCar.turboCount < 1 then return end
        local boostBegin = -90 + 45 / 2
        local boostSpan = -45
        local radius = (self.settings.radius + 10) * startupStages[1]

        local currentBoost = FocusedCar.turboBoost
        if currentBoost > maxBoost then maxBoost = currentBoost end
        local boostRatio = currentBoost / maxBoost


        if maxBoost <= 0.01 then boostRatio = 0 end

        -- Background
        draw.DrawArc(
            windowCenter,
            boostBegin,
            boostSpan * startupStages[4],
            radius,
            { 0, 0 },
            self.settings.value.background.width,
            self.settings.value.background.color * rgbm(1, 1, 1, startupStages[1])
        )

        -- Value Needle
        draw.DrawArc(
            windowCenter,
            boostBegin,
            boostSpan * boostRatio * startupStages[4],
            radius,
            { 0, 0 },
            self.settings.value.width,
            self.settings.value.color * math.clamp(Globals.lightBrightness, .25, 1) *
            rgbm(1, 1, 1, startupStages[3])
        )
    end

    local function DrawFuel()
        local fuelBegin = 45 / 2
        local fuelSpan = 45
        local radius = (self.settings.radius) * startupStages[1]
        local fuelRatio = FocusedCar.fuel / FocusedCar.maxFuel

        -- Background
        draw.DrawArc(
            windowCenter,
            fuelBegin,
            fuelSpan * startupStages[4],
            radius,
            { 0, 0 },
            self.settings.value.background.width,
            self.settings.value.background.color * rgbm(1, 1, 1, startupStages[1])
        )

        local fuelColor = self.settings.value.color
        if FocusedCar.fuel / FocusedCar.maxFuel <= .15 then
            fuelColor = rgbm(1, 1, 0, 1)
        end
        -- Value Needle
        draw.DrawArc(
            windowCenter,
            fuelBegin,
            fuelSpan * fuelRatio * startupStages[4],
            radius,
            { 0, 0 },
            self.settings.value.width,
            fuelColor * math.clamp(Globals.lightBrightness, .25, 1) *
            rgbm(1, 1, 1, startupStages[3])
        )
    end

    local function DrawGauge()
        draw.RoundBackground(
            windowCenter,
            self.settings.radius * startupStages[1],
            self.settings.backgroundColor * rgbm(1, 1, 1, startupStages[1])
        )
        ui.pushDWriteFont(
            "Varien:assets/fonts/Varien.ttf;Weight=400;Style=Regular")

        DrawIndicators()
        DrawSpeedAndGear()
        -- DrawMileage()

        DrawBoost()
        DrawFuel()

        -- Range background
        if self.settings.value.background.enabled then
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin,
                self.settings.valueRange.span * startupStages[2],
                (self.settings.radius + self.settings.value.background.width / 2) * startupStages[1],
                { self.settings.value.background.pinLengths[1] * startupStages[1], self.settings.value.background
                .pinLengths
                [2] *
                startupStages[2] },
                self.settings.value.background.width,
                self.settings.value.background.color *
                rgbm(1, 1, 1, startupStages[1] * math.clamp(Globals.lightBrightness, .25, 1))
            )
        end

        local hardRedlineOffset = self.settings.redline.hard.offset * Globals.lightSwitchMod

        -- hard redline
        draw.DrawArc(
            windowCenter,
            self.settings.valueRange.begin + self.settings.valueRange.span,
            -self.settings.valueRange.span * ((maxValue - FocusedCar.rpmLimiter) / maxValue) *
            startupStages[4],
            self.settings.radius + self.settings.redline.hard.width / 2 + hardRedlineOffset,
            { self.settings.redline.hard.pinLengths[1] * startupStages[4], self.settings.redline.hard.pinLengths[2] *
            startupStages[5] },
            self.settings.redline.hard.width,
            self.settings.redline.hard.color * rgbm(1, 1, 1, Globals.lightBrightness * startupStages[3])
        )

        -- Soft redline
        if self.settings.redline.soft.enabled then
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin + self.settings.valueRange.span,
                -self.settings.valueRange.span *
                (maxValue - FocusedCar.rpmLimiter + self.settings.redline.soft.rpms) / maxValue *
                startupStages[4] * Globals.lightSwitchMod,
                self.settings.radius + self.settings.redline.soft.width / 2 + self.settings.redline.soft.offset,
                { self.settings.redline.soft.pinLengths[1] * startupStages[4] * Globals.lightSwitchMod, self.settings
                .redline.soft.pinLengths[2] *
                startupStages[4] * Globals.lightSwitchMod },
                self.settings.redline.soft.width,
                self.settings.redline.soft.color * rgbm(1, 1, 1, Globals.lightSwitchMod * startupStages[3])
            )
        end

        local gradientColor = rgbm(
            self.settings.value.gradient.color.r + softLimitRatio,
            self.settings.value.gradient.color.g - softLimitRatio,
            (self.settings.value.gradient.color.b - softLimitRatio),
            1
        ) * startupStages[5] * Globals.lightSwitchMod

        -- Value Gradient
        if self.settings.value.gradient.enabled and Globals.lightSwitchMod > 0.01 then
            ui.beginPremultipliedAlphaTexture()
            ui.beginTextureShade(self.gradientCanvas)
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin,
                self.settings.valueRange.span * gaugeValueRatio,
                self.settings.radius - self.settings.value.gradient.width / 2 +
                self.settings.value.gradient.width / 2 * (1 - Globals.lightSwitchMod),
                { 0, 0 },
                self.settings.value.gradient.width -
                self.settings.value.gradient.width * (1 - Globals.lightSwitchMod),
                gradientColor,
                false
            )
            -- ui.drawRectFilled(windowSize.x / 2 - self.settings.radius,
            --     windowSize.y - (windowSize.y / 2 - self.settings.radius), rgbm(1, 1, 1, 1))
            ui.endTextureShade(
            -- Account for outside padding
                windowSize.x / 2 - self.settings.radius,
                windowSize.y - (windowSize.y / 2 - self.settings.radius)
            )
            -- ui.drawCircleFilled(windowCenter, self.settings.radius, rgbm(1, 1, 1, 0), Globals.numSegments)
            ui.endPremultipliedAlphaTexture()
        end

        if self.revNumbersCanvas == nil then
            UpdateRevNumsCanvas()
        end

        ui.beginPremultipliedAlphaTexture()
        ui.beginTextureShade(self.revNumbersCanvas)
        ui.drawRectFilled(0, windowSize, rgbm(1, 1, 1, 1) * startupStages[3] * Globals.lightBrightness)
        ui.endTextureShade(0, windowSize)
        ui.endPremultipliedAlphaTexture()

        if self.settings.value.highlight.enabled then
            local highlightColor = rgbm(
                self.settings.value.highlight.color.r + softLimitRatio,
                self.settings.value.highlight.color.g - softLimitRatio,
                self.settings.value.highlight.color.b - softLimitRatio,
                self.settings.value.highlight.color.mult
            ) * Globals.lightSwitchMod
            -- Value Highlight
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin,
                self.settings.valueRange.span * gaugeValueRatio * startupStages[4],
                self.settings.radius + self.settings.value.highlight.width / 2 +
                self.settings.value.highlight.offset * Globals.lightSwitchMod,
                { 0, 0 },
                self.settings.value.highlight.width,
                highlightColor,
                false
            )
        end

        if self.settings.value.enabled then
            -- Value Needle
            draw.DrawArc(
                windowCenter,
                self.settings.valueRange.begin,
                self.settings.valueRange.span * gaugeValueRatio * startupStages[4],
                self.settings.radius + self.settings.value.width / 2 + self.settings.value.offset,
                { self.settings.value.pinLengths[1] * startupStages[4] *
                Globals.lightSwitchMod, self.settings.value.pinLengths[2] * startupStages[4] *
                Globals.lightSwitchMod },
                self.settings.value.width,
                self.settings.value.color * math.clamp(Globals.lightBrightness, .75, 1) *
                rgbm(1, 1, 1, startupStages[3])
            )
        end


        ui.popDWriteFont()
    end

    local function updateValues(dt)
        windowSize = ui.windowSize()
        windowCenter = windowSize / 2

        currentRPM = FocusedCar.rpm
        gaugeValueRatio = currentRPM / maxValue
        softLimitRatio = (currentRPM - FocusedCar.rpmLimiter + self.settings.redline.soft.rpms) /
            self.settings.redline.soft.rpms
        softLimitRatio = math.clamp(softLimitRatio, 0, 1)
    end

    function self.window(dt)
        startupStages = {
            Globals.draw.startup.startupModifiers[1],
            Globals.draw.startup.startupModifiers[2],
            Globals.draw.startup.startupModifiers[3],
            Globals.draw.startup.startupModifiers[4],
            Globals.draw.startup.startupModifiers[5]
        }

        ui.forceSimplifiedComposition(true) -- Gets rid of the blurry background
        updateValues(dt)

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

        ui.drawIcon(ui.Icons.Bulb, windowSize - 24, windowSize,
            rgbm(1, 0, 0, 1 - Globals.lightBrightness))

        ac.setWindowSizeConstraints(
            "tacho",
            self.settings.radius * 2 + 50,
            self.settings.radius * 2 + 50
        )
    end

    function self.settingsWindow(dt)
        ui.tabBar("tachoSettings", function()
            ui.tabItem("General", function()
                self.settings.radius = ui.slider("##radius", self.settings.radius, 64, 256, 'Radius: %.0fpx')

                ui.newLine()

                local changed = false
                self.settings.valueRange.begin = ui.slider("##from", self.settings.valueRange.begin, -180, 180,
                    'From: %.0fdeg')
                if ui.itemEdited() then
                    changed = true
                end
                self.settings.valueRange.span = ui.slider("##span", self.settings.valueRange.span, -360, 360,
                    'Span: %.0fdeg')
                if ui.itemEdited() then
                    changed = true
                end

                if changed then
                    UpdateRevNumsCanvas()
                end

                ui.newLine()

                ui.colorButton("Background color", self.settings.backgroundColor,
                    bit.bor(ui.ColorPickerFlags.PickerHueBar, ui.ColorPickerFlags.AlphaPreviewHalf,
                        ui.ColorPickerFlags.Float, ui.ColorPickerFlags.AlphaBar))
                ui.sameLine()
                ui.text("Background color (click)")
            end)
            ui.tabItem("Current value", function()
                ui.tabBar("tachoValue", function()
                    ui.tabItem("Needle", function()
                        if ui.checkbox("Enabled", self.settings.value.enabled) then
                            self.settings.value.enabled = not self.settings.value.enabled
                        end
                        if not self.settings.value.enabled then return end
                        ui.header("General")
                        self.settings.value.width = ui.slider("##width", self.settings.value.width, 1,
                            16,
                            'Width: %.0fpx')
                        self.settings.value.offset = ui.slider("##offset", self.settings.value.offset,
                            -self.settings.radius, self.settings.radius,
                            'Offset: %.0fpx')
                        ui.treeNode("Pins",
                            function()
                                self.settings.value.pinLengths[1] = ui.slider("##pin1",
                                    self.settings.value.pinLengths[1],
                                    -self.settings.radius, self.settings.radius,
                                    'Begin pin: %.0fpx')
                                self.settings.value.pinLengths[2] = ui.slider("##pin2",
                                    self.settings.value.pinLengths[2],
                                    -self.settings.radius, self.settings.radius,
                                    'End pin: %.0fpx')
                            end)

                        ui.colorButton("Color", self.settings.value.color,
                            bit.bor(ui.ColorPickerFlags.PickerHueBar, ui.ColorPickerFlags.AlphaPreviewHalf,
                                ui.ColorPickerFlags.Float, ui.ColorPickerFlags.AlphaBar))
                        ui.sameLine()
                        ui.text("Color (click)")
                    end)
                    ui.tabItem("Background", function()
                        if ui.checkbox("Enabled", self.settings.value.background.enabled) then
                            self.settings.value.background.enabled = not self.settings.value.background.enabled
                        end
                        if not self.settings.value.background.enabled then return end
                        self.settings.value.background.width = ui.slider("##width", self.settings.value.background.width,
                            1, 16,
                            'Width: %.0fpx')
                        ui.treeNode("Pins###pinsBackground",
                            function()
                                self.settings.value.background.pinLengths[1] = ui.slider("##pin1",
                                    self.settings.value.background.pinLengths[1],
                                    -self.settings.radius, self.settings.radius,
                                    'Begin pin: %.0fpx')
                                self.settings.value.background.pinLengths[2] = ui.slider("##pin2",
                                    self.settings.value.background.pinLengths[2],
                                    -self.settings.radius, self.settings.radius,
                                    'End pin: %.0fpx')
                            end)
                        ui.colorButton("Color", self.settings.value.background.color,
                            bit.bor(ui.ColorPickerFlags.PickerHueBar, ui.ColorPickerFlags.AlphaPreviewHalf,
                                ui.ColorPickerFlags.Float, ui.ColorPickerFlags.AlphaBar))
                        ui.sameLine()
                        ui.text("Color (click)")
                    end)
                    ui.tabItem("Highlight", function()
                        if ui.checkbox("Enabled", self.settings.value.highlight.enabled) then
                            self.settings.value.highlight.enabled = not self.settings.value.highlight.enabled
                        end
                        if not self.settings.value.highlight.enabled then return end
                        self.settings.value.highlight.width = ui.slider("##width",
                            self.settings.value.highlight.width,
                            1, 16,
                            'Width: %.0fpx')

                        self.settings.value.highlight.offset = ui.slider("##offset", self.settings.value.highlight
                            .offset,
                            -self.settings.radius, self.settings.radius,
                            'Offset: %.0fpx')

                        ui.colorButton("Color", self.settings.value.highlight.color,
                            bit.bor(ui.ColorPickerFlags.PickerHueBar, ui.ColorPickerFlags.AlphaPreviewHalf,
                                ui.ColorPickerFlags.Float, ui.ColorPickerFlags.AlphaBar))
                        ui.sameLine()
                        ui.text("Color (click)")
                    end)
                    ui.tabItem("Gradient", function()
                        if ui.checkbox("Enabled", self.settings.value.gradient.enabled) then
                            self.settings.value.gradient.enabled = not self.settings.value.gradient.enabled
                        end
                        if not self.settings.value.gradient.enabled then return end
                        local widthChanged = false
                        self.settings.value.gradient.width, widthChanged = ui.slider("##width",
                            self.settings.value.gradient.width,
                            1, self.settings.radius,
                            'Width: %.0fpx')
                        if widthChanged then
                            self.gradientCanvas = draw.RadialGradient(
                                self.settings.radius,
                                self.settings.value.gradient.width,
                                self.settings.value.gradient.color.mult,
                                "Tacho Gradient",
                                self.settings.value.gradient.assetScale
                            )
                        end

                        ui.colorButton("Color", self.settings.value.gradient.color,
                            bit.bor(ui.ColorPickerFlags.PickerHueBar, ui.ColorPickerFlags.AlphaPreviewHalf,
                                ui.ColorPickerFlags.Float))
                        ui.sameLine()
                        ui.text("Color (click)")
                    end)
                end)
            end)
        end)
    end

    return self
end

return Tacho()
