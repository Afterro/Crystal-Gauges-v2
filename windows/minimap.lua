local globals = require("windows.globals")
local player = globals.PlayerCar
if player == nil then
    ac.debug("ERROR", "No player found in tacho")
    return
end


function Minimap()
    local self = {}

    self.meta = {
    }
    local track_data
    local windowsize = 256
    local scale = 1.5

    local function GetTrack()
        local track = {
            path = nil,
            image_path = nil,
            config = {}
        }
        track.path = ac.getFolder(ac.FolderID.ContentTracks) ..
            "\\" .. ac.getTrackID() .. "\\" .. ac.getTrackLayout()
        track.image_path = track.path .. "\\" .. "map.png"
        track.size = ui.imageSize(track.image_path)

        track.config = ac.INIConfig.load(track.path .. "\\data\\map.ini"):mapSection("PARAMETERS",
            { SCALE_FACTOR = 1, Z_OFFSET = 1, X_OFFSET = 1, WIDTH = 500, HEIGHT = 500, MARGIN = 20, DRAWING_SIZE = 10, MAX_SIZE = 1000 })
        return track
    end

    local function DrawPlayer()
        local pos = vec2(player.position.x, player.position.z) +
            vec2(track_data.config.X_OFFSET, track_data.config.Z_OFFSET)
        pos = pos * scale
        local rawRotation = player.look

        local rotation = math.deg(math.atan2(math.rad(rawRotation.x), math.rad(rawRotation.z)))

        if rotation < 0 then
            rotation = rotation + 360
        end

        ui.beginRotation()
        ui.drawRectFilled(
            pos - vec2(2, 5) * scale,
            pos + vec2(2, 5) * scale,
            rgbm(1, 0, 0, 1)
        )
        ui.endRotation(rotation + 90)
    end

    function self.window(dt)
        track_data = GetTrack()
        ui.beginOutline()
        ui.drawImage(track_data.image_path, 0, vec2(track_data.config.WIDTH, track_data.config.HEIGHT) * scale)
        ui.endOutline(rgbm(0, 0, 0, 1), 1)
        DrawPlayer()
        ui.drawRect(0, vec2(track_data.config.WIDTH, track_data.config.HEIGHT) * scale, rgbm(1, 1, 1, 1))
    end

    return self
end

return Minimap()
