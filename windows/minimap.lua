if FocusedCar == nil then
    ac.debug("ERROR", "No focused car found for minimap")
    return
end


local function Minimap()
    local self = {}

    local trackData
    local trackCanvas
    local splineCanvas
    local mapCentredCanvas
    local displayZoom = .75
    local carScale = 1.75
    local focusedCarScale = 2
    local focusedCarCamRotation = 0
    local nameScale = 2
    local splineResolutionMultiplier = 1

    local function GetTrackData()
        local track = {
            path = nil,
            image_path = nil,
            size = 0,
            config = {},
            offset = vec2()
        }
        track.path = ac.getFolder(ac.FolderID.ContentTracks) ..
            "\\" .. ac.getTrackID() .. "\\" .. ac.getTrackLayout()
        track.image_path = track.path .. "\\" .. "map.png"
        track.size = ui.imageSize(track.image_path)

        track.config = ac.INIConfig.load(track.path .. "\\data\\map.ini"):mapSection("PARAMETERS",
            { SCALE_FACTOR = 1, Z_OFFSET = 1, X_OFFSET = 1, WIDTH = 500, HEIGHT = 500, MARGIN = 20, DRAWING_SIZE = 10, MAX_SIZE = 1000 })
        track.offset = vec2(track.config.X_OFFSET, track.config.Z_OFFSET)
        track.maxSize = track.size.x
        if track.size.y > track.maxSize then
            track.maxSize = track.size.y
        end

        return track
    end

    local function GenerateTrackCanvas(data)
        local canvas = ui.ExtraCanvas(data.maxSize)
        canvas:setName("Track")
        canvas:update(function(dt)
            ui.drawImage(data.image_path, 0, data.size)
        end)
        return canvas
    end

    local function GenerateTrackSplineCanvas()
        local res = trackData.maxSize * trackData.config.SCALE_FACTOR * splineResolutionMultiplier
        local detail = 1000
        local canvas = ui.ExtraCanvas(res)
        canvas:setName("AI Spline")
        canvas:update(function(dt)
            for i = 1, detail, 1 do
                local pos3 = ac.trackProgressToWorldCoordinate(i / detail, true)
                local pos2 = vec2(pos3.x, pos3.z) + trackData.offset
                ui.pathLineTo(pos2 * splineResolutionMultiplier)
            end
            ui.pathStroke(rgbm(0, 0, 0, 1), false, trackData.config.DRAWING_SIZE * splineResolutionMultiplier * 1.25)

            for i = 1, detail, 1 do
                local pos3 = ac.trackProgressToWorldCoordinate(i / detail, true)
                local pos2 = vec2(pos3.x, pos3.z) + trackData.offset
                ui.pathLineTo(pos2 * splineResolutionMultiplier)
            end
            ui.pathStroke(rgbm(1, 1, 1, 1), false, trackData.config.DRAWING_SIZE * splineResolutionMultiplier)
        end)
        return canvas
    end

    ---comment
    ---@param car ac.StateCar
    ---@param offset? vec2|number
    ---@param displayCarScale? number
    local function DrawCar(car, offset, displayCarScale)
        if not car.isActive or car:driverName():lower():startsWith("traffic") then return end
        if offset == nil then offset = 0 end
        if displayCarScale == nil then displayCarScale = carScale end

        local carPos = (vec2(car.position.x, car.position.z) + trackData.offset) / trackData.config.SCALE_FACTOR *
            displayZoom + offset
        local carRotation = math.deg(math.atan2(car.look.x, car.look.z))

        local color = rgbm(1, 1, 1, 1)

        if car.isAIControlled then
            color = rgbm(1, 1, 0, 1)
        end
        if ac.DriverTags(car:driverName()).friend then
            color = rgbm(0, 0.25, 1, 1)
        end
        if car.isUserControlled then
            color = rgbm(1, 0, 1, 1)
        end

        ui.beginOutline()
        ui.beginRotation()

        ui.drawIcon(ui.Icons.UpAlt, carPos - 5 * displayCarScale, carPos + 5 * displayCarScale, color)

        ui.endRotation(carRotation - 90)

        ui.endOutline(rgbm(0, 0, 0, 1), 1)

        if car.index == FocusedCar.index or car:driverName():lower():startsWith("traffic") then return end

        local nameOffset = vec2(0, 10)

        ui.beginRotation()
        ui.beginOutline()

        Globals.draw.DrawText(carPos + nameOffset * nameScale, car:driverName():split(" ")[1], 10 * nameScale,
            rgbm(1, 1, 1, 1))

        ui.endOutline(rgbm(0, 0, 0, 1), 1)
        ui.endPivotRotation(focusedCarCamRotation - 90, carPos)
    end

    local function DrawMapCentred()
        local windowCenter = ui.windowSize() / 2

        local playerMapPos = vec2(FocusedCar.position.x, FocusedCar.position.z) + trackData.offset
        local trackDrawPos = windowCenter - playerMapPos / trackData.config.SCALE_FACTOR * displayZoom

        local camForward = ac.getCameraForward()
        focusedCarCamRotation = math.deg(math.atan2(camForward.x, camForward.z))

        ui.beginRotation()


        if splineCanvas ~= nil then
            ui.drawImage(splineCanvas, trackDrawPos,
                trackDrawPos +
                splineCanvas:size() / trackData.config.SCALE_FACTOR / splineResolutionMultiplier * displayZoom)
        else
            ui.drawImage(trackCanvas, trackDrawPos,
                trackDrawPos + trackCanvas:size() * displayZoom)
        end
        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=Regular;Style=Regular")
        for _, car in ac.iterateCars() do
            -- We want to draw focused car last for it to be on top
            if car.index == FocusedCar.index then goto continue end
            DrawCar(car, trackDrawPos)
            ::continue::
        end
        DrawCar(FocusedCar, trackDrawPos, focusedCarScale)
        ui.popDWriteFont()

        ui.endPivotRotation(-focusedCarCamRotation - 90, windowCenter)
    end

    function self.window(dt)
        local windowCenter = ui.windowSize() / 2

        if mapCentredCanvas == nil then
            mapCentredCanvas = ui.ExtraCanvas(windowCenter * 2 * 2)
            mapCentredCanvas:setName("Map Centred")
        end

        mapCentredCanvas:clear()
        mapCentredCanvas:update(DrawMapCentred)

        Globals.draw.RectBackground(
            4,
            windowCenter * 2 - 4,
            rgbm(0, 0, 0, .125),
            5
        )
        ui.drawRect(
            2,
            windowCenter * 2 - 2,
            rgbm(1, 1, 1, .1),
            5,
            ui.CornerFlags.All,
            4
        )

        ui.beginTextureShade(mapCentredCanvas)
        ui.drawRectFilled(
            4,
            windowCenter * 2 - 4,
            rgbm(1, 1, 1, 1 * Globals.lightBrightness),
            5
        )
        ui.endTextureShade(0, windowCenter * 2)



        if ui.windowHovered() then
            local scroll = ui.mouseWheel()
            if ui.keyboardButtonDown(ui.KeyIndex.LeftShift) and ui.keyboardButtonDown(ui.KeyIndex.LeftControl) then
                nameScale = nameScale + scroll * .25
                nameScale = math.clamp(nameScale, .25, 20)
                ui.text("Name scale: " .. stringify(nameScale))
            elseif ui.keyboardButtonDown(ui.KeyIndex.LeftShift) then
                carScale = carScale + scroll * .05
                carScale = math.clamp(carScale, .05, 20)
                ui.text("Other car scale: " .. stringify(carScale))
            elseif ui.keyboardButtonDown(ui.KeyIndex.LeftControl) then
                focusedCarScale = focusedCarScale + scroll * .05
                focusedCarScale = math.clamp(focusedCarScale, .05, 20)
                ui.text("Focused car scale: " .. stringify(focusedCarScale))
            else
                displayZoom = displayZoom + ui.mouseWheel() * .05
                displayZoom = math.clamp(displayZoom, .05, 20)
                ui.text("Zoom: " .. stringify(displayZoom))
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

    local function _Init()
        trackData = GetTrackData()
        trackCanvas = GenerateTrackCanvas(trackData)

        -- Check if there even is an AI spline
        if ac.trackProgressToWorldCoordinate(.5, true).x ~= -1 then
            splineCanvas = GenerateTrackSplineCanvas()
        end
    end

    _Init()
    return self
end

return Minimap()
