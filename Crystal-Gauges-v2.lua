-- Instanciate gauges
local globals = require("windows.globals")

local tacho = require("windows.tacho")
local minimap = require("windows.minimap")

function script.windowTacho(dt)
    tacho.window(dt)
end

function script.tachoSettings(dt)
    tacho.settingsWindow(dt)
end

function script.windowMinimap(dt)
    minimap.window(dt)
end

-- -- optional
-- function script.Draw3D(dt)
--     -- draw something with the render. functions
-- end

-- optional, standard available function
function script.update(dt)
    globals.draw.update(dt)
end
