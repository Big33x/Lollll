local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Camera = Workspace.CurrentCamera


local fov_circle_outer = Drawing.new("Circle")
fov_circle_outer.Visible = true
fov_circle_outer.Thickness = 3
fov_circle_outer.Color = Color3.fromRGB(0, 0, 0)
fov_circle_outer.Position = Camera.ViewportSize / 2
fov_circle_outer.Radius = 121


local fov_circle_inner = Drawing.new("Circle")
fov_circle_inner.Visible = true
fov_circle_inner.Thickness = 1
fov_circle_inner.Color = Color3.fromRGB(255, 255, 255)
fov_circle_inner.Position = Camera.ViewportSize / 2
fov_circle_inner.Radius = 120


local snap_line_outer = Drawing.new("Line")
snap_line_outer.Visible = false
snap_line_outer.Color = Color3.fromRGB(0, 0, 0)
snap_line_outer.Thickness = 3


local snap_line_inner = Drawing.new("Line")
snap_line_inner.Visible = false
snap_line_inner.Color = Color3.fromRGB(255, 255, 255)
snap_line_inner.Thickness = 1


local Settings = {
    ["Combat"] = {
        ["Aimbot"] = {
            ["Enabled"]    = true,
            ["Mode"]       = "None",
            ["Target"]     = "None",
            ["Enabled2"]   = true,
            ["Fov Size"]   = 130,
            ["Resover"]    = true,
        }
        
    },
}
function to_viewport(pos)
    if typeof(pos) ~= "Vector3" then return Vector2.zero, false end
    local point, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(point.X, point.Y), on
end


local Classes = {
    ["PlayerClient"] = {},
    ["Character"] = {},
    ["BowClient"] = {},
    ["Camera"] = {},
    ["RangedWeaponClient"] = {},
    ["GetEquippedItem"] = {},
    ["FPS"] = {},
}


for _, v in pairs(getgc(true)) do
    if typeof(v) == "function" and islclosure(v) then
        local info = debug.getinfo(v)
        local name = string.match(info.short_src, "%.([%w_]+)$")
        if name and Classes[name] and info.name ~= nil then
            Classes[name][info.name] = info.func
        end
    end
end


local Players = debug.getupvalue(Classes.PlayerClient.updatePlayers, 1)


function CalculateBulletDrop(tPos, tVel, cPos, pSpeed, pDrop)
    if typeof(tPos) ~= "Vector3" or typeof(cPos) ~= "Vector3" or 
       typeof(tVel) ~= "Vector3" or typeof(pSpeed) ~= "number" or 
       typeof(pDrop) ~= "number" or pSpeed <= 0 or pDrop < 0 then
        return tPos
    end
    
    local dTT = (tPos - cPos).Magnitude  
    local tTT = dTT / pSpeed  
    local pTP = tPos + (tVel * tTT * 6.5)  
    local dP = -pDrop ^ (tTT * pDrop) + 1  
    local pPWD = pTP - Vector3.new(0, dP, 0) 
    local pHP = cPos + ((pTP - cPos).Unit * dTT)
    
    return pPWD, tTT, pHP
end




function IsSleeping(Player)
    local Animations = Player.AnimationController:GetPlayingAnimationTracks()
    for _, v in pairs(Animations) do
        if v.IsPlaying and v.Animation.AnimationId == "rbxassetid://13280887764" then
            return true
        end
    end
    return false
end


local target = nil


function GetClosestTarget(maxDistance)
    local closestTarget, targetVelocity, closestDistance = nil, nil, math.huge;


    local viewportCenter = Camera.ViewportSize / 2


    for i, v in pairs(Players) do
        if (v.model:FindFirstChild('HumanoidRootPart') and not IsSleeping(v.model)) and v.id ~= "635665" and v.id ~= "636336" then
            local distanceToPlayer = (v.model.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude;


            if (distanceToPlayer <= maxDistance) then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(v.model.Head.Position);


                if (onScreen) then
                    local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - viewportCenter).Magnitude;


                    if (distanceFromCenter < closestDistance and distanceFromCenter < fov_circle_inner.Radius) then
                        closestTarget = v
                        targetVelocity = v.velocityVector;
                        closestDistance = distanceFromCenter;
                    end
                end
            end
        end
    end;


    return closestTarget
end




RunService.Heartbeat:Connect(function()
    target = GetClosestTarget(1200)
    
    if target and target.model and target.model:FindFirstChild("Head") then
        local targetHeadPosition = target.model.Head.Position
        local targetScreenPosition, onScreen = to_viewport(targetHeadPosition)
        
        if onScreen then
            snap_line_outer.Visible = true
            snap_line_inner.Visible = true
            
            snap_line_outer.From = Camera.ViewportSize / 2
            snap_line_outer.To = targetScreenPosition
            
            snap_line_inner.From = Camera.ViewportSize / 2
            snap_line_inner.To = targetScreenPosition
        else
            snap_line_outer.Visible = false
            snap_line_inner.Visible = false
        end
    else
        snap_line_outer.Visible = false
        snap_line_inner.Visible = false
    end
end)




local projectileinfo = {
    AR15 = {Speed = 1300, Drop = 3},
    Blunderbuss = {Speed = 600, Drop = 3.5},
    Bow = {Speed = 300, Drop = 3},
    C9 = {Speed = 600, Drop = 3},
    Crossbow = {Speed = 450, Drop = 3},
    EnergyRifle = {Speed = 2000, Drop = 1.1},
    GaussRifle = {Speed = 3000, Drop = 2},
    HMAR = {Speed = 1000, Drop = 3.5},
    LeverActionRifle = {Speed = 1200, Drop = 1.5},
    M4A1 = {Speed = 1300, Drop = 4},
    PipePistol = {Speed = 500, Drop = 3},
    PipeSMG = {Speed = 600, Drop = 3},
    PumpShotgun = {Speed = 600, Drop = 2},
    SCAR = {Speed = 1300, Drop = 4},
    SVD = {Speed = 1400, Drop = 2},
    USP9 = {Speed = 600, Drop = 3},
    UZI = {Speed = 600, Drop = 3},
    RPG = {Speed = 700, Drop = 3},
}


function Get_info(wep)
    local info = projectileinfo[wep]
    if not info then
        warn("Weapon info not found for:", wep)
        return 0, 0
    end
    return info.Speed, info.Drop
end


local has_shot = 0
local oldfromOrientation
oldfromOrientation = hookfunction(CFrame.fromOrientation, newcclosure(function(p, y, r)
    if debug.info(3, "f") and debug.info(3, "n") == "fire" then
        local wepdata = getstack(3, 1)
        if not wepdata or not target or not target.model or IsSleeping(target.model) then
            return oldfromOrientation(p, y, r)
        end


        local origin = Camera.CFrame.Position
        local targetPosition = target.model:FindFirstChild("Head") and target.model.Head.Position
        local velocityVector = target.velocityVector
        local speed, drop = Get_info(wepdata.type)


        if not targetPosition then
            return oldfromOrientation(p, y, r)
        end


        local predictedPosition, tTT, pHP = CalculateBulletDrop(targetPosition, velocityVector, origin, speed, drop)
        local Head = target.model:FindFirstChild("Head") or target.model.PrimaryPart
        if not Head then
            return oldfromOrientation(p, y, r)
        end


        spawn(function()
            local startTime = tick()
            while has_shot == 1 do
                RunService.Heartbeat:Wait()
            end


            has_shot = 1
            local scaledTTT = (typeof(tTT) == "number") and ((tTT * 1.1) + ((tTT ^ 2 / tTT) - tTT)) or tTT


            while tick() - startTime < scaledTTT and Settings["Combat"]["Aimbot"]["Resover"] do
                Head.CFrame = CFrame.new(pHP)
                RunService.Heartbeat:Wait()
            end
            has_shot = 0
        end)


        return Camera.CFrame:Inverse() * CFrame.lookAt(origin, predictedPosition)
    end


    return oldfromOrientation(p, y, r)
end))
local DrRayLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/DrRay-UI-Library/main/DrRay.lua"))()
local window = DrRayLibrary:Load("DrRay", "Default")
local tab = DrRayLibrary.newTab("Main", "ImageIdHere")


    local Lighting = game:GetService("Lighting")


local DesiredColor = Color3.fromRGB(255, 255, 255)
local ambientenabled = false
local color = ambientenabled and DesiredColor or Lighting.Ambient 


if ambientenabled then 
    color = DesiredColor
end


local ambientFunc = {
    TimeOfDay = Lighting.TimeOfDay,
    Ambient = Lighting.Ambient,
    GlobalShadows = Lighting.GlobalShadows,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
}


local SpoofedAmbient2; SpoofedAmbient2 = hookmetamethod(game, "__index", newcclosure(function(self, string)
    if checkcaller() then 
        return SpoofedAmbient2(self, string)
    end
    if self == Lighting and ambientFunc[string] then
        return ambientFunc[string]
    end
    return SpoofedAmbient2(self, string)
end))


local SpoofedAmbient1; SpoofedAmbient1 = hookmetamethod(game, "__newindex", newcclosure(function(self, string, value)
    if checkcaller() then 
        return SpoofedAmbient1(self, string, value)
    end
    if self == Lighting then
        ambientFunc[string] = value
        if string == "Ambient" then
            color = ambientenabled and DesiredColor or value
            return SpoofedAmbient1(self, string, color)
        end
    end  


    return SpoofedAmbient1(self, string, value)
end))


tab.newButton("esp", "distance name and weapon", function()
local LocalPlayer = cloneref(game:GetService("Players").LocalPlayer)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera
local WorldToViewportPoint = Camera.WorldToViewportPoint
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Coregui = gethui() or cloneref(game:GetService("CoreGui"))
local gui = Instance.new("ScreenGui", Coregui)
--
while not game:IsLoaded() do task.wait() end
--
local Classes = {
        ["PlayerClient"] = {},
        ["Character"] = {},
        ["BowClient"] = {},
        ["Camera"] = {},
        ["RangedWeaponClient"] = {},
        ["GetEquippedItem"] = {},
        ["FPS"] = {},
}
--
for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" and islclosure(v) then
                local info = debug.getinfo(v)
                local name = string.match(info.short_src, "%.([%w_]+)$")
                if name and Classes[name] and info.name ~= nil then
                        Classes[name][info.name] = info.func
                end
        end
end
--
local Players = debug.getupvalue(Classes.PlayerClient.updatePlayers, 1)
--
function GetBoundingBox(Model)
        local cf, size = Model:GetBoundingBox()
        local halfSizeX, halfSizeY, halfSizeZ = size.X / 2, size.Y / 2, size.Z / 2
        local left, right = math.huge, -math.huge
        local top, bottom = math.huge, -math.huge
        for _, xSign in ipairs({1, -1}) do
            for _, ySign in ipairs({1, -1}) do
                for _, zSign in ipairs({1, -1}) do
                    local corner = cf * CFrame.new(halfSizeX * xSign, halfSizeY * ySign, halfSizeZ * zSign)
                    local screenPos, onScreen = Camera:WorldToScreenPoint(corner.Position)
                    if onScreen then
                        left = math.min(left, screenPos.X)
                        right = math.max(right, screenPos.X)
                        top = math.min(top, screenPos.Y)
                        bottom = math.max(bottom, screenPos.Y)
                    end
                end
            end
        end
    return math.floor(left), math.floor(right), math.floor(top), math.floor(bottom), size
end
--
local cache = {}
local HasEsp = {}
function CreateEsp(playertable)
        if not playertable then return end
        local drawings = {}
        drawings.innerline = Instance.new("Frame", gui);drawings.innerline.Visible = false;drawings.innerline.Transparency = 1;drawings.innerline.ZIndex = 9999;
        drawings.outerline = Instance.new("Frame", drawings.innerline);drawings.outerline.Visible = false;drawings.outerline.Size = UDim2.new(1,-2,1,-2);drawings.outerline.Transparency = 1;drawings.outerline.ZIndex = 9998;drawings.outerline.AnchorPoint = Vector2.new(.5,.5);drawings.outerline.Position = UDim2.new(.5,0,.5,0);
        drawings.Name = Instance.new("TextLabel", gui);drawings.Name.AnchorPoint = Vector2.new(0.5, 0.5);drawings.Name.BackgroundTransparency = 1.000;drawings.Name.Size = UDim2.new(0, 50, 0, 20);drawings.Name.TextSize = 13;drawings.Name.ZIndex = 9999;drawings.Name.TextColor3 = Color3.fromRGB(255, 255, 255);drawings.Name.Font = Enum.Font.Code;drawings.Name.RichText = true;drawings.Name.Visible = false;
        drawings.Contaner = Instance.new("Frame", gui);drawings.Contaner.AnchorPoint = Vector2.new(0, 0);drawings.Contaner.Size = UDim2.new(0, 35, 1, 0);drawings.Contaner.BackgroundTransparency = 1;drawings.Contaner.Visible = false;
        drawings.Distance = Instance.new("TextLabel", drawings.Contaner);drawings.Distance.BackgroundTransparency = 1;drawings.Distance.Size = UDim2.new(1, 0, 0, 8);drawings.Distance.TextSize = 13;drawings.Distance.TextColor3 = Color3.fromRGB(255, 255, 255);drawings.Distance.Font = Enum.Font.Code;drawings.Distance.Visible = false;drawings.Distance.TextXAlignment = Enum.TextXAlignment.Left;Instance.new("UIStroke", drawings.Distance);local w = Instance.new("UIStroke", drawings.Distance) w.Transparency = 0.2
        drawings.Sleep = Instance.new("TextLabel", drawings.Contaner);drawings.Sleep.BackgroundTransparency = 1;drawings.Sleep.Size = UDim2.new(1, 0, 0, 8);drawings.Sleep.TextSize = 13;drawings.Sleep.TextColor3 = Color3.fromRGB(255, 255, 255);drawings.Sleep.Font = Enum.Font.Code;drawings.Sleep.Visible = false;drawings.Sleep.TextXAlignment = Enum.TextXAlignment.Left; local q = Instance.new("UIStroke", drawings.Sleep) q.Transparency = 0.2
        drawings.Tool = Instance.new("TextLabel", gui);drawings.Tool.AnchorPoint = Vector2.new(0.5, 0.5);drawings.Tool.BackgroundTransparency = 1.000;drawings.Tool.Size = UDim2.new(0, 50, 0, 20);drawings.Tool.TextSize = 13;drawings.Tool.ZIndex = 9999;drawings.Tool.TextColor3 = Color3.fromRGB(255, 255, 255);drawings.Tool.Font = Enum.Font.Code;drawings.Tool.RichText = true;drawings.Tool.Visible = false;
        drawings.info = playertable
        local idk1 = Instance.new("UIStroke", drawings.innerline);idk1.Color = Color3.fromRGB(255, 255, 255);idk1.Thickness = 1;idk1.LineJoinMode = Enum.LineJoinMode.Miter
        local idk2 = Instance.new("UIStroke", drawings.outerline);idk2.Color = Color3.fromRGB(0, 0, 0);idk2.Thickness = 3;idk2.LineJoinMode = Enum.LineJoinMode.Miter;idk2.Transparency = 0.2
        local idk3 = Instance.new("UIStroke", drawings.Name);idk3.Color = Color3.fromRGB(0, 0, 0);idk3.Thickness = 1;idk3.LineJoinMode = Enum.LineJoinMode.Miter;idk3.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;idk3.Transparency = 0.2
        local idk4 = Instance.new("UIListLayout", drawings.Contaner);idk4.Padding = UDim.new(0, 4);
        local idk5 = Instance.new("UIStroke", drawings.Tool);idk5.Color = Color3.fromRGB(0, 0, 0);idk5.Thickness = 1;idk5.LineJoinMode = Enum.LineJoinMode.Miter;idk5.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;idk5.Transparency = 0.2
        HasEsp[playertable.model] = drawings
end
function RemoveEsp(PlayerTable)
    if not PlayerTable or not PlayerTable.model then return end
    local esp = HasEsp[PlayerTable.model]
        if not esp then return end
            for _, v in pairs(esp) do
                if type(v) ~= "table" then
                    v:Remove()
                end
            end
        cache[PlayerTable.model] = nil
        HasEsp[PlayerTable.model] = nil
    end
function UpdateEsp()
        for i, v in pairs(HasEsp) do
        local char = i
        local sleeping = #((char:FindFirstChild("AnimationController") and char.AnimationController.Animator:GetPlayingAnimationTracks()) or {}) > 0 and char.AnimationController.Animator:GetPlayingAnimationTracks()[1].Animation.AnimationId == "rbxassetid://13280887764" or false
            if char and gui ~= nil and char ~= nil and char:IsDescendantOf(game:GetService("Workspace")) and not sleeping then
            local Spos, on = Camera:WorldToScreenPoint(char.PrimaryPart.Position)
        local left, right, top, bottom, size = GetBoundingBox(char)
                        
        local distance = (Camera.CFrame.Position - char.PrimaryPart.Position).Magnitude
        if on then
                v.Name.Visible = true
                v.innerline.Visible = true
                v.outerline.Visible = true
                v.Contaner.Visible = true
                v.Distance.Visible = true
                v.Sleep.Visible = true
                v.Tool.Visible = true
                v.innerline.Size = UDim2.new(0, right - left  , 0, bottom - top ) 
                v.innerline.Position = UDim2.new(0, left , 0, top )
                v.Name.Position = UDim2.new(0, v.innerline.Position.X.Offset+v.innerline.Size.X.Offset/2,0,v.innerline.Position.Y.Offset - v.Name.TextBounds.Y / 1.5)
                v.Contaner.Position = UDim2.new(0, v.innerline.Position.X.Offset + v.innerline.Size.X.Offset + (v.Contaner.Size.X.Offset/2) + 3, 0, v.innerline.Position.Y.Offset + 1)
                v.Tool.Position = UDim2.new(0, v.innerline.Position.X.Offset+v.innerline.Size.X.Offset/2, 0, v.innerline.Position.Y.Offset + v.innerline.Size.Y.Offset + v.Tool.TextBounds.Y / 1.5)
                local tool = v.info.equippeditem and v.info.equippeditem.type or " "
                v.Name.Text =  v.info.id
                v.Distance.Text = math.floor(distance) .. "s"
                v.Sleep.Text = sleeping and "Sleep" or "Awake"
                v.Tool.Text = tostring(tool)
        else
                v.Tool.Visible = false
                v.Sleep.Visible = false
                v.Distance.Visible = false
                v.Contaner.Visible = false
                v.Name.Visible = false
                v.innerline.Visible = false
                v.outerline.Visible = false
            end
        else
            RemoveEsp({ model = char })
        end
    end
end
--
RunService.Stepped:Connect(function()
    UpdateEsp()        
         for i, v in pairs(Players) do
            if not table.find(cache,v) then
                CreateEsp(v)
                table.insert(cache,v)
            end
        end
    end)
end)
local Lighting = game:GetService("Lighting")


local DesiredColor = Color3.fromRGB(255, 255, 255)
local ambientenabled = false
local color = ambientenabled and DesiredColor or Lighting.Ambient 


local ambientFunc = {
    TimeOfDay = Lighting.TimeOfDay,
    Ambient = Lighting.Ambient,
    GlobalShadows = Lighting.GlobalShadows,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
}


local SpoofedAmbient2; SpoofedAmbient2 = hookmetamethod(game, "__index", newcclosure(function(self, string)
    if checkcaller() then 
        return SpoofedAmbient2(self, string)
    end
    if self == Lighting and ambientFunc[string] then
        return ambientFunc[string]
    end
    return SpoofedAmbient2(self, string)
end))


local SpoofedAmbient1; SpoofedAmbient1 = hookmetamethod(game, "__newindex", newcclosure(function(self, string, value)
    if checkcaller() then 
        return SpoofedAmbient1(self, string, value)
    end
    if self == Lighting then
        ambientFunc[string] = value
        if string == "Ambient" then
            color = ambientenabled and DesiredColor or value
            return SpoofedAmbient1(self, string, color)
        end
    end  
    return SpoofedAmbient1(self, string, value)
end))


-- Function to toggle real ambient lighting
local function toggleAmbient(state)
    ambientenabled = state
    if ambientenabled then
        Lighting.Ambient = DesiredColor
    else
        Lighting.Ambient = ambientFunc["Ambient"] -- Restore spoofed value
    end
end


-- Add toggle
tab.newToggle("Toggle Ambient", "Toggles the ambient lighting", ambientenabled, function(state)
    toggleAmbient(state)
end)




tab.newToggle("Toggle hbe", "Toggle hbe (hitbox expander)", true, function(toggleState)
    Hitbox = toggleState 
end) 
tab.newSlider("hitbox size", "hitbox expander slider", 7, false, function(num)
    headsize = num
end)




local function modifyPlayerHeads()
    for i, v in next, game.Workspace:GetChildren() do
        if v.Name == "Model" and v:FindFirstChild("Head") then
            local head = v.Head
            if head then
                local success, _ = pcall(function()
                    head.Size = Vector3.new(headsize, headsize, headsize)
                    head.Transparency = 0.5
                end)
                if not success then
                    warn("Failed to modify head for player:", v.Name)
                end
            end
        end
    end
end




game:GetService("RunService").RenderStepped:Connect(function()
    if Hitbox then
        modifyPlayerHeads()
    end
end)




for _, line in ipairs({
    " ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░",
    "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░",
    "░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░    ░▒▓██▓▒░",
    "░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░              ░▒▓██████▓▒░ ░▒▓██████▓▒░   ░▒▓██▓▒░",
    "░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░    ░▒▓██▓▒░",
    "░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓██▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░",
    " ░▒▓██████▓▒░   ░▒▓██▓▒░  ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓████████▓▒░▒▓████████▓▒░▒▓██▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓████████▓▒░"
}) do warn(line) end
