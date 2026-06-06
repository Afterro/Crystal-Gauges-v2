Sim = ac.getSim()
PlayerCar = ac.getCar(Sim.focusedCar)
local numSegments = 64

function Draw()
    local self = {}

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
    ---@param center vec2 Gauge center
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


        ---- Needle background

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

    return self
end
