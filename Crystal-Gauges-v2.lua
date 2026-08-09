-- Instanciate gauges
local globals = require("windows.Globals")

local tacho = require("windows.tacho")
local minimap = require("windows.minimap")
local media = require("windows.media")
local inputsWindow = require("windows.inputs")

function script.windowTacho(dt)
    tacho.window(dt)
end

function script.tachoSettings(dt)
    tacho.settingsWindow(dt)
end

function script.windowMinimap(dt)
    minimap.window(dt)
end

function script.windowMedia(dt)
    media.window(dt)
end

function script.windowInputs(dt)
    inputsWindow.window(dt)
end

-- optional
-- function script.Draw3D(dt)
-- end

-- optional, standard available function
function script.update(dt)
    globals.update(dt)
end
