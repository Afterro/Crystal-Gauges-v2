-- Instanciate gauges
local globals = require("windows.globals")

local tacho = require("windows.tacho")

function script.windowTacho(dt)
    tacho.window(dt)
end

-- -- optional
-- function script.Draw3D(dt)
--     -- draw something with the render. functions
-- end

-- optional, standard available function
function script.update(dt)
    globals.draw.update(dt)
end
