-- A handmade sponge chef, built entirely from shapes. No catalog assets needed.
-- Decorations follow the standard R6/R15 rig and never replace its joints.
local Costume = {}

local YELLOW = Color3.fromRGB(255, 224, 58)
local PORE = Color3.fromRGB(210, 170, 36)
local WHITE = Color3.fromRGB(255, 252, 233)
local BROWN = Color3.fromRGB(139, 82, 43)
local BLACK = Color3.fromRGB(35, 30, 25)
local RED = Color3.fromRGB(210, 54, 42)

local function decorate(model, rigPart, name, size, offset, color, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CFrame = rigPart.CFrame * offset
    part.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CostumeWeld"
    weld.Part0 = rigPart
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function frame(parent, name, x, y, width, height, color, round)
    local object = Instance.new("Frame")
    object.Name = name
    object.BorderSizePixel = 0
    object.Position = UDim2.fromOffset(x, y)
    object.Size = UDim2.fromOffset(width, height)
    object.BackgroundColor3 = color
    object.Parent = parent
    if round then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(round, 0)
        corner.Parent = object
    end
    return object
end

local function addFace(body)
    local surface = Instance.new("SurfaceGui")
    surface.Name = "SpongeFace"
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(512, 440)
    surface.LightInfluence = 0.15
    surface.AlwaysOnTop = false
    surface.Parent = body

    local pores = {
        { 31, 29, 41, 25 }, { 432, 24, 44, 31 }, { 71, 193, 26, 38 },
        { 438, 194, 28, 21 }, { 30, 351, 35, 45 }, { 439, 353, 41, 28 },
        { 206, 30, 20, 17 }, { 382, 389, 21, 15 }, { 102, 394, 22, 19 },
    }
    for index, pore in ipairs(pores) do
        frame(surface, "Pore" .. index, pore[1], pore[2], pore[3], pore[4], PORE, 0.5)
    end

    for index, eyeX in ipairs({ 121, 271 }) do
        local eye = frame(surface, "Eye" .. index, eyeX, 78, 120, 147, WHITE, 0.5)
        local outline = Instance.new("UIStroke")
        outline.Color = BLACK
        outline.Thickness = 3
        outline.Parent = eye
        frame(eye, "Iris", 36, 54, 52, 64, Color3.fromRGB(67, 173, 226), 0.5)
        frame(eye, "Pupil", 47, 65, 31, 44, BLACK, 0.5)
        frame(eye, "Glint", 52, 69, 10, 14, Color3.new(1, 1, 1), 0.5)
        for lashIndex = 1, 3 do
            local lash = frame(surface, "Eyelash", eyeX + 22 + (lashIndex - 1) * 34,
                54, 7, 29, BLACK, 0.3)
            lash.Rotation = (lashIndex - 2) * 25
        end
    end

    -- An open curved grin, with the yellow mask covering its upper half.
    frame(surface, "Smile", 143, 251, 226, 110, Color3.fromRGB(114, 55, 24), 0.5)
    frame(surface, "SmileMask", 140, 243, 232, 48, YELLOW)
    frame(surface, "LeftTooth", 224, 287, 29, 39, WHITE, 0.08)
    frame(surface, "RightTooth", 259, 287, 29, 39, WHITE, 0.08)
    for _, cheekX in ipairs({ 95, 374 }) do
        frame(surface, "Cheek", cheekX, 232, 46, 31, Color3.fromRGB(248, 180, 71), 0.5)
        frame(surface, "Freckle", cheekX + 5, 241, 7, 7, RED, 0.5)
        frame(surface, "Freckle", cheekX + 18, 247, 7, 7, RED, 0.5)
        frame(surface, "Freckle", cheekX + 30, 239, 7, 7, RED, 0.5)
    end
end

local function dressArms(character, model)
    for _, side in ipairs({ "Left", "Right" }) do
        local upper = character:FindFirstChild(side .. "UpperArm")
        local lower = character:FindFirstChild(side .. "LowerArm")
        local hand = character:FindFirstChild(side .. "Hand")
        local classic = character:FindFirstChild(side .. " Arm")
        if upper and lower and hand then
            decorate(model, upper, side .. "Sleeve", Vector3.new(0.58, 0.45, 0.62),
                CFrame.new(0, upper.Size.Y * 0.29, 0), WHITE)
            for _, limb in ipairs({ upper, lower }) do
                decorate(model, limb, side .. "Arm", Vector3.new(0.24, limb.Size.Y, 0.27),
                    CFrame.identity, YELLOW)
            end
            decorate(model, hand, side .. "Hand", Vector3.new(0.42, 0.43, 0.34),
                CFrame.identity, YELLOW, Enum.PartType.Ball)
        elseif classic then
            decorate(model, classic, side .. "Sleeve", Vector3.new(0.6, 0.46, 0.68),
                CFrame.new(0, classic.Size.Y * 0.35, 0), WHITE)
            decorate(model, classic, side .. "Arm", Vector3.new(0.25, classic.Size.Y * 0.8, 0.28),
                CFrame.new(0, -0.1, 0), YELLOW)
            decorate(model, classic, side .. "Hand", Vector3.new(0.42, 0.42, 0.34),
                CFrame.new(0, -classic.Size.Y * 0.45, 0), YELLOW, Enum.PartType.Ball)
        end
    end
end

local function dressLegs(character, model)
    for _, side in ipairs({ "Left", "Right" }) do
        local upper = character:FindFirstChild(side .. "UpperLeg")
        local lower = character:FindFirstChild(side .. "LowerLeg")
        local foot = character:FindFirstChild(side .. "Foot")
        local classic = character:FindFirstChild(side .. " Leg")
        if upper and lower and foot then
            decorate(model, upper, side .. "ShortLeg", Vector3.new(0.7, upper.Size.Y * 0.52, 0.76),
                CFrame.new(0, upper.Size.Y * 0.23, 0), BROWN)
            for _, limb in ipairs({ upper, lower }) do
                decorate(model, limb, side .. "Leg", Vector3.new(0.26, limb.Size.Y, 0.28),
                    CFrame.identity, YELLOW)
            end
            decorate(model, lower, side .. "Sock", Vector3.new(0.34, lower.Size.Y * 0.6, 0.36),
                CFrame.new(0, -lower.Size.Y * 0.2, 0), WHITE)
            decorate(model, lower, side .. "SockStripe", Vector3.new(0.35, 0.065, 0.37),
                CFrame.new(0, lower.Size.Y * 0.05, 0), RED)
            decorate(model, foot, side .. "Shoe", Vector3.new(0.65, 0.36, 1.05),
                CFrame.new(0, -0.04, -0.12), BLACK)
        elseif classic then
            decorate(model, classic, side .. "ShortLeg", Vector3.new(0.72, 0.43, 0.8),
                CFrame.new(0, classic.Size.Y * 0.38, 0), BROWN)
            decorate(model, classic, side .. "Leg", Vector3.new(0.28, classic.Size.Y * 0.85, 0.3),
                CFrame.new(0, -0.03, 0), YELLOW)
            decorate(model, classic, side .. "Sock", Vector3.new(0.35, 0.55, 0.38),
                CFrame.new(0, -classic.Size.Y * 0.28, 0), WHITE)
            decorate(model, classic, side .. "SockStripe", Vector3.new(0.36, 0.065, 0.39),
                CFrame.new(0, -classic.Size.Y * 0.17, 0), RED)
            decorate(model, classic, side .. "Shoe", Vector3.new(0.67, 0.38, 1.05),
                CFrame.new(0, -classic.Size.Y * 0.48, -0.17), BLACK)
        end
    end
end

function Costume.apply(character)
    if not character or not character.Parent then
        return nil
    end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso or not torso:IsA("BasePart") then
        return nil
    end
    local previous = character:FindFirstChild("SpongeChefCostume")
    if previous then
        previous:Destroy()
    end
    -- Hide only the actual rig, not a carried burger Tool or unrelated effects.
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            child:Destroy()
        elseif child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
            child.Transparency = 1
            for _, image in ipairs(child:GetDescendants()) do
                if image:IsA("Decal") or image:IsA("Texture") then
                    image.Transparency = 1
                end
            end
        end
    end

    local model = Instance.new("Model")
    model.Name = "SpongeChefCostume"
    model.Parent = character
    local width = math.clamp(torso.Size.X * 1.3, 2.35, 2.95)
    local body = decorate(model, torso, "Sponge", Vector3.new(width, 2.45, 1.02),
        CFrame.new(0, 0.62, 0), YELLOW)
    addFace(body)
    -- A small protruding nose keeps the face readable from an angle.
    decorate(model, torso, "Nose", Vector3.new(0.23, 0.4, 0.42),
        CFrame.new(0, 0.5, -0.67), YELLOW, Enum.PartType.Ball)
    decorate(model, torso, "Shirt", Vector3.new(width + 0.03, 0.37, 1.05),
        CFrame.new(0, -0.79, 0), WHITE)
    decorate(model, torso, "Shorts", Vector3.new(width + 0.04, 0.42, 1.07),
        CFrame.new(0, -1.18, 0), BROWN)
    decorate(model, torso, "TieKnot", Vector3.new(0.17, 0.17, 0.06),
        CFrame.new(0, -0.7, -0.56) * CFrame.Angles(0, 0, math.rad(45)), RED)
    decorate(model, torso, "Tie", Vector3.new(0.15, 0.34, 0.06),
        CFrame.new(0, -0.91, -0.56), RED)
    for _, x in ipairs({ -width * 0.32, width * 0.32 }) do
        decorate(model, torso, "BeltLoop", Vector3.new(0.29, 0.07, 0.04),
            CFrame.new(x, -1.07, -0.56), BLACK)
    end
    dressArms(character, model)
    dressLegs(character, model)
    character:SetAttribute("SpongeChefCostumeApplied", true)
    return model
end

return Costume
