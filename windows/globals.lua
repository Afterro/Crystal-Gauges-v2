Sim = ac.getSim()
PlayerCar = ac.getCar(Sim.focusedCar)
local numSegments = 64

---Class for drawing gauges
function Draw()
    local self = {}

    function self.GetPosRadial(angle, radius)
        return vec2(
            math.sin(math.rad(angle)),
            math.cos(math.rad(angle))
        ) * radius
    end

    ---Draws a circular gauge background
    ---@param center vec2 Gauge center
    ---@param radius number Background radius
    ---@param color rgbm Background color
    function self.Background(center, radius, color)
        ui.drawCircleFilled(
            center,
            radius,
            color,
            numSegments
        )
    end

    ---Draws an arc from `begin` degrees to `begin + span` degrees
    ---
    ---Used mainly for needles
    ---@param center number|vec2 Gauge center
    ---@param begin number Arc beginning in degrees
    ---@param span number Arc span in degrees
    ---@param radius number Arc radius
    ---@param pinLen {[1]:number, [2]:number } Length of pins, [1]=Begin, [2]=End
    ---@param width number Arc stroke width
    ---@param color rgbm Arc color
    ---@param rounded? boolean Should ends be rounded, defualt `true`
    function self.DrawArc(

        center,
        begin,
        span,
        radius,
        pinLen,
        width,
        color,
        rounded
    )
        if rounded == nil then rounded = true end

        -- Pin round
        local pos = vec2(
            math.cos(math.rad(begin + 90)),
            math.sin(math.rad(begin + 90))
        ) * (radius - pinLen[1]) + center

        if rounded then
            ui.drawCircleFilled(
                pos,
                width / 2,
                color,
                numSegments
            )
        end

        -- Pin
        if (pinLen[1] ~= 0) then
            ui.pathLineTo(
                pos
            )
        end


        -- Arc
        ui.pathArcTo(
            center,
            radius,
            math.rad(begin + 90),
            math.rad(begin + span + 90),
            numSegments
        )
        -- Pin
        pos = vec2(
            math.cos(math.rad(begin + span + 90)),
            math.sin(math.rad(begin + span + 90))
        ) * (radius - pinLen[2]) + center

        if (pinLen[2] ~= 0) then
            ui.pathLineTo(
                pos
            )
        end

        ui.pathStroke(color, false, width)

        -- Pin round
        if rounded then
            ui.drawCircleFilled(
                pos,
                width / 2,
                color,
                numSegments
            )
        end

        ----
    end

    ---comment
    ---@param position vec2
    ---@param text string
    ---@param size integer
    ---@param color rgbm
    function self.DrawText(
        position,
        text,
        size,
        color
    )
        local textSize = ui.measureDWriteText(text, size)
        ui.dwriteDrawText(
            text,
            size,
            position - textSize / 2,
            color
        )
    end

    ---Creates a gradient for gauges
    ---
    ---Rendered only once
    ---### PERFORMANCE!!!!!!!1!!1111
    ---@param resolution number Gauge center
    ---@param begin number Arc beginning in degrees
    ---@param span number Arc span in degrees
    ---@param width number
    ---@param color rgb Arc color
    ---@param brightness? number Should ends be rounded, defualt `true`
    ---@param name? string Name for the gradient
    function self.GetGradient(
        resolution,
        begin,
        span,
        width,
        color,
        brightness,
        name
    )
        local gradientCanvas = ui.ExtraCanvas(
            resolution,
            1,
            render.AntialiasingMode.none,
            render.TextureFormat.R8G8B8A8.UNorm
        )

        local center = resolution / 2

        gradientCanvas:update(function()
            for i = 1, numSegments, 1 do
                self.DrawArc(
                    center,
                    begin,
                    span,
                    resolution / 2 - (width / 2) * (i / numSegments) / 2,
                    { 0, 0 },
                    width * (i / numSegments),
                    rgbm(color.r, color.g, color.b, 1 / numSegments * brightness),
                    false
                )
            end
        end
        )
        if name ~= nil then
            gradientCanvas:setName(name)
        end

        return gradientCanvas
    end

    return self
end
