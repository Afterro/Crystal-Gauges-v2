local globals = require("windows.globals")
local sim = globals.Sim
local focusedCar = globals.focusedCar
if focusedCar == nil then
    ac.debug("ERROR", "No focused car found for minimap")
    return
end


function Minimap()
    local self = {}

    local trackData
    local trackCanvas
    local splineCanvas
    local mapCentredCanvas
    local displayZoom = 3
    local carScale = 1
    local focusedCarCamRotation = 0
    local splineResolutionMultiplier = 3

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
            ui.pathStroke(rgbm(0, 0, 0, 1), true, trackData.config.DRAWING_SIZE * splineResolutionMultiplier * 1.25)

            for i = 1, detail, 1 do
                local pos3 = ac.trackProgressToWorldCoordinate(i / detail, true)
                local pos2 = vec2(pos3.x, pos3.z) + trackData.offset
                ui.pathLineTo(pos2 * splineResolutionMultiplier)
            end
            ui.pathStroke(rgbm(1, 1, 1, 1), true, trackData.config.DRAWING_SIZE * splineResolutionMultiplier)
        end)
        return canvas
    end

    ---comment
    ---@param car ac.StateCar
    ---@param offset? vec2|number
    local function DrawCar(car, offset)
        if not car.isActive then return end
        if offset == nil then offset = 0 end

        local carPos = (vec2(car.position.x, car.position.z) + trackData.offset) * displayZoom + offset
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

        local colliders = ac.getCarColliders(car.index, true)

        ui.beginOutline()
        ui.beginRotation()
        for index, value in ipairs(colliders) do
            local collider = value

            local carSize = vec2(collider.position.x, collider.position.z) +
                vec2(collider.size.x, collider.size.z) / 2 * displayZoom * carScale

            ui.drawRectFilled(
                carPos - carSize,
                carPos + carSize,
                color
            )
        end

        ui.endRotation(carRotation - 90)

        ui.endOutline(rgbm(0, 0, 0, 1), 1)

        if car.index == focusedCar.index then return end

        local nameOffset = vec2(0, 10)

        ui.beginRotation()
        ui.beginOutline()

        globals.draw.DrawText(carPos + nameOffset, car:driverName():split(" ")[1], 10, rgbm(1, 1, 1, 1))

        ui.endOutline(rgbm(0, 0, 0, 1), 1)
        ui.endPivotRotation(focusedCarCamRotation - 90, carPos)
    end

    local function DrawMapCentred()
        local windowCenter = ui.windowSize() / 2

        local playerMapPos = vec2(focusedCar.position.x, focusedCar.position.z) + trackData.offset
        local trackDrawPos = windowCenter - playerMapPos / trackData.config.SCALE_FACTOR * displayZoom

        local camForward = ac.getCameraForward()
        focusedCarCamRotation = math.deg(math.atan2(camForward.x, camForward.z))

        ui.beginRotation()


        if splineCanvas ~= nil then
            ui.drawImage(splineCanvas, trackDrawPos,
                trackDrawPos + splineCanvas:size() / splineResolutionMultiplier * displayZoom)
        else
            ui.drawImage(trackCanvas, trackDrawPos,
                trackDrawPos + trackCanvas:size() * displayZoom)
        end
        ui.pushDWriteFont(
            "Comfortaa Light:assets/fonts/Comfortaa-VariableFont_wght.ttf;Weight=Regular;Style=Regular")
        for _, car in ac.iterateCars() do
            DrawCar(car, trackDrawPos)
        end
        ui.popDWriteFont()
        ui.endPivotRotation(-focusedCarCamRotation - 90, windowCenter)
    end

    function self.window(dt)
        local windowCenter = ui.windowSize() / 2

        if mapCentredCanvas == nil then
            mapCentredCanvas = ui.ExtraCanvas(windowCenter * 2)
        end

        mapCentredCanvas:clear()
        mapCentredCanvas:update(DrawMapCentred)

        globals.draw.Background(windowCenter, 128, rgbm(0, 0, 0, .25))

        ui.beginTextureShade(mapCentredCanvas)
        ui.drawCircleFilled(windowCenter, 124, rgbm(1, 1, 1, 1), globals.numSegments)
        ui.endTextureShade(0, windowCenter * 2)



        if ui.windowHovered() then
            local scroll = ui.mouseWheel()
            if ui.keyboardButtonDown(ui.KeyIndex.LeftShift) then
                carScale = carScale + scroll * .25
                carScale = math.clamp(carScale, .25, 20)
                ui.text("Car scale: " .. stringify(carScale))
            else
                displayZoom = displayZoom + ui.mouseWheel() * .25
                displayZoom = math.clamp(displayZoom, .25, 20)
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
