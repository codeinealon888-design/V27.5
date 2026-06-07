-- [[ V23 THE OMEGA HUB - ULTIMATE INTEGRATED SYSTEM (FIXED CAM) ]] --
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- เคลียร์ของเก่าป้องกัน UI ซ้อน
if CoreGui:FindFirstChild("V23_OmegaHub") then CoreGui.V23_OmegaHub:Destroy() end
if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("V23_OmegaHub") then LocalPlayer.PlayerGui.V23_OmegaHub:Destroy() end

local MenuState = { Visible = true, Minimized = false, CurrentTab = "Combat" }
local TpWindowState = { Minimized = false }
local SpecWindowState = { Minimized = false }
local FreecamWindowState = { Minimized = false }

-- // --- SETTINGS ENGINE --- // --
local AimbotSettings = {
    Enabled = false,
    WallCheck = true,
    Distance = 1000,
    AimPart = "Head",
    Smoothness = 0.9
}

local EspSettings = {
    Boxes = false,
    Skeleton = false
}

local MovementSettings = {
    SpeedEnabled = false,
    SpeedValue = 16,
    InfJump = false,
    Invisibility = false 
}

local TeleportSettings = {
    SavedPoints = {},
    GlideSpeed = 0.05
}

local SpectatorSettings = {
    Active = false,
    Following = false,
    CurrentIndex = 1,
    Connection = nil
}

local FreecamSettings = {
    Enabled = false,
    Speed = 1,
    _forward = false,
    _back = false,
    _left = false,
    _right = false,
    _up = false,
    _down = false,
}

local freecamConnection = nil
local cameraYaw = 0
local cameraPitch = 0

-- // --- CORE HELPER FUNCTIONS --- // --
local function GetOtherPlayers()
    local list = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then table.insert(list, v) end
    end
    return list
end

local function IsVisible(targetPart)
    if not AimbotSettings.WallCheck then return true end
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    rayParam.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local result = workspace:Raycast(origin, direction, rayParam)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestTarget()
    local target, dist = nil, AimbotSettings.Distance
    local mouseLoc = UserInputService:GetMouseLocation()

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            local part = v.Character:FindFirstChild(AimbotSettings.AimPart)
            
            if hum and hum.Health > 0 and part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mDist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                    if mDist < dist then
                        if IsVisible(part) then target = part; dist = mDist end
                    end
                end
            end
        end
    end
    return target
end

-- // --- [TELEPORT CORE LOGIC] --- // --
local function TeleportToPosition(pos, instant)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    if instant then
        hrp.CFrame = CFrame.new(pos)
    else
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                connection:Disconnect()
                return
            end
            local currentPos = hrp.Position
            local distance = (currentPos - pos).Magnitude
            if distance < 1 then
                hrp.CFrame = CFrame.new(pos)
                connection:Disconnect()
            else
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(pos), TeleportSettings.GlideSpeed)
            end
        end)
    end
end

-- // --- [SPECTATOR CORE LOGIC] --- // --
local function StopFollow()
    if SpectatorSettings.Connection then
        SpectatorSettings.Connection:Disconnect()
        SpectatorSettings.Connection = nil
    end
    SpectatorSettings.Following = false
    Camera.CameraType = Enum.CameraType.Custom
end

local function UpdateSpecLabel(label)
    local list = GetOtherPlayers()
    if #list == 0 then
        label.Text = "❌ ไม่มีผู้เล่นอื่น"
        return
    end
    local target = list[SpectatorSettings.CurrentIndex]
    if target then
        label.Text = "👤 " .. target.Name .. " (" .. SpectatorSettings.CurrentIndex .. "/" .. #list .. ")"
    end
end

local function FollowPlayer(player, statusLabel)
    StopFollow()
    if not player then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        statusLabel.Text = "⚠️ ไม่พบตัวละคร แต่กำลังรอส่อง..."
    end

    if FreecamSettings.Enabled then statusLabel.Text = "⚠️ กรุณาปิด Freecam ก่อน!" return end

    SpectatorSettings.Following = true
    Camera.CameraType = Enum.CameraType.Scriptable

    SpectatorSettings.Connection = RunService.RenderStepped:Connect(function()
        local c = player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(c.HumanoidRootPart.Position + Vector3.new(0, 5, 10), c.HumanoidRootPart.Position)
            statusLabel.Text = "👁️ กำลังล็อคกล้อง: " .. player.Name
        else
            statusLabel.Text = "⚠️ รอตัวละครเกิดใหม่..."
        end
    end)
end

local function TeleportToPlayer(player, statusLabel)
    if not player then return end
    local myChar = LocalPlayer.Character
    local targetChar = player.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
        myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(2, 0, 0)
        statusLabel.Text = "✅ วาปไปหา: " .. player.Name
    else
        statusLabel.Text = "⚠️ ไม่สามารถวาปได้"
    end
end

-- // --- [FREECAM CORE LOGIC - FIXED GLASS ANGLE] --- // --
local function EnableFreecam()
    if SpectatorSettings.Following then StopFollow() end
    Camera.CameraType = Enum.CameraType.Scriptable
    
    -- โคลนทิศทางเดิมของกล้องปัจจุบันมาเป็นจุดตั้งต้น ป้องกันกล้องสะบัดตอนกดเปิด
    local _, y, z = Camera.CFrame:ToOrientation()
    cameraYaw = y
    cameraPitch = _

    freecamConnection = RunService.RenderStepped:Connect(function()
        local move = Vector3.zero
        local camCF = Camera.CFrame

        -- คีย์บอร์ด (PC)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

        -- ปุ่มจำลอง (Mobile)
        if FreecamSettings._forward then move += camCF.LookVector end
        if FreecamSettings._back    then move -= camCF.LookVector end
        if FreecamSettings._left    then move -= camCF.RightVector end
        if FreecamSettings._right   then move += camCF.RightVector end
        if FreecamSettings._up      then move += Vector3.new(0,1,0) end
        if FreecamSettings._down    then move -= Vector3.new(0,1,0) end

        -- คำนวณตำแหน่งพิกัดใหม่
        local newPos = camCF.Position
        if move.Magnitude > 0 then
            newPos = newPos + move.Unit * FreecamSettings.Speed
        end

        -- คำนวณมุมหันแบบอิสระ ไม่เอา CFrame ไปคูณวนซ้ำ
        local delta = UserInputService:GetMouseDelta()
        cameraYaw = cameraYaw + math.rad(-delta.X * 0.3)
        -- ล็อกเป้าไม่ให้ก้มเงยเกิน 89 องศา (ป้องกันปัญหากล้องตีลังกาพลิกกลับหัว)
        cameraPitch = math.clamp(cameraPitch + math.rad(-delta.Y * 0.3), math.rad(-89), math.rad(89))

        -- สรุปผล CFrame: สร้างจากระนาบโลกโดยตรง หมดปัญหากล้องเบี้ยวเอียงข้างแน่นอน
        Camera.CFrame = CFrame.new(newPos) * CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)
    end)
end

local function DisableFreecam()
    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end
    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    for _, k in pairs({"_up","_down","_forward","_back","_left","_right"}) do
        FreecamSettings[k] = false
    end
    FreecamSettings.Enabled = false
end

-- // --- [ESP BOX & SKELETON SECTION] --- // --
local function CreateEspBox(player)
    pcall(function()
        local Box = Drawing.new("Square")
        Box.Visible = false; Box.Thickness = 2; Box.Transparency = 1; Box.Filled = false
        local function Update()
            local c
            c = RunService.RenderStepped:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and EspSettings.Boxes then
                    local RootPart = player.Character.HumanoidRootPart
                    local RootPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
                    if OnScreen then
                        local Scale = 1 / (RootPos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                        local Width, Height = 4 * Scale, 6 * Scale
                        Box.Size = Vector2.new(Width, Height)
                        Box.Position = Vector2.new(RootPos.X - Width / 2, RootPos.Y - Height / 2)
                        Box.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                        Box.Visible = true
                    else Box.Visible = false end
                else
                    Box.Visible = false
                    if not player.Parent then Box:Remove() c:Disconnect() end
                end
            end)
        end
        coroutine.wrap(Update)()
    end)
end

local function CreateLine()
    local l; pcall(function() l = Drawing.new("Line") l.Visible = false l.Color = Color3.new(1, 1, 1) l.Thickness = 1 l.Transparency = 1 end)
    return l
end

local function CreateHeadCircle()
    local c; pcall(function() c = Drawing.new("Circle") c.Visible = false c.Color = Color3.new(1, 1, 1) c.Thickness = 1 c.Transparency = 1 c.Filled = false c.Radius = 0 end)
    return c
end

local function CreateSkeleton(player)
    pcall(function()
        local Objects = {
            HeadCircle = CreateHeadCircle(), Spine = CreateLine(), UpperTorsoToLeftArm = CreateLine(), UpperTorsoToRightArm = CreateLine(),
            LeftArmToWrist = CreateLine(), RightArmToWrist = CreateLine(), LowerTorsoToLeftLeg = CreateLine(), LowerTorsoToRightLeg = CreateLine(),
            LeftLegToAnkle = CreateLine(), RightLegToAnkle = CreateLine()
        }

        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and EspSettings.Skeleton then
                local char = player.Character
                local isR15 = (char.Humanoid.RigType == Enum.HumanoidRigType.R15)
                local rgbColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                for _, obj in pairs(Objects) do if obj then obj.Color = rgbColor end end

                local parts = {}
                if isR15 then
                    parts = {
                        Head = char:FindFirstChild("Head"), UpperTorso = char:FindFirstChild("UpperTorso"), LowerTorso = char:FindFirstChild("LowerTorso"),
                        LeftUpperArm = char:FindFirstChild("LeftUpperArm"), LeftLowerArm = char:FindFirstChild("LeftLowerArm"),
                        RightUpperArm = char:FindFirstChild("RightUpperArm"), RightLowerArm = char:FindFirstChild("RightLowerArm"),
                        LeftUpperLeg = char:FindFirstChild("LeftUpperLeg"), LeftLowerLeg = char:FindFirstChild("LeftLowerLeg"),
                        RightUpperLeg = char:FindFirstChild("RightUpperLeg"), RightLowerLeg = char:FindFirstChild("RightLowerLeg")
                    }
                else
                    parts = {
                        Head = char:FindFirstChild("Head"), UpperTorso = char:FindFirstChild("Torso"), LowerTorso = char:FindFirstChild("Torso"),
                        LeftUpperArm = char:FindFirstChild("Left Arm"), LeftLowerArm = char:FindFirstChild("Left Arm"),
                        RightUpperArm = char:FindFirstChild("Right Arm"), RightLowerArm = char:FindFirstChild("Right Arm"),
                        LeftUpperLeg = char:FindFirstChild("Left Leg"), LeftLowerLeg = char:FindFirstChild("Left Leg"),
                        RightUpperLeg = char:FindFirstChild("Right Leg"), RightLowerLeg = char:FindFirstChild("Right Leg")
                    }
                end

                local function SetLine(line, p1, p2)
                    if line and p1 and p2 then
                        local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                        if on1 and on2 then
                            line.From = Vector2.new(pos1.X, pos1.Y); line.To = Vector2.new(pos2.X, pos2.Y); line.Visible = true; return
                        end
                    end
                    if line then line.Visible = false end
                end

                local function SetHead(circle, headPart)
                    if circle and headPart then
                        local pos, on = Camera:WorldToViewportPoint(headPart.Position)
                        if on then
                            circle.Position = Vector2.new(pos.X, pos.Y)
                            local dist = (Camera.CFrame.Position - headPart.Position).Magnitude
                            circle.Radius = math.clamp(80 / dist, 2, 15); circle.Visible = true; return
                        end
                    end
                    if circle then circle.Visible = false end
                end

                SetHead(Objects.HeadCircle, parts.Head)
                SetLine(Objects.Spine, parts.Head, parts.LowerTorso)
                SetLine(Objects.UpperTorsoToLeftArm, parts.UpperTorso, parts.LeftUpperArm)
                SetLine(Objects.UpperTorsoToRightArm, parts.UpperTorso, parts.RightUpperArm)
                if isR15 then
                    SetLine(Objects.LeftArmToWrist, parts.LeftUpperArm, parts.LeftLowerArm)
                    SetLine(Objects.RightArmToWrist, parts.RightUpperArm, parts.RightLowerArm)
                    SetLine(Objects.LeftLegToAnkle, parts.LeftUpperLeg, parts.LeftLowerLeg)
                    SetLine(Objects.RightLegToAnkle, parts.RightUpperLeg, parts.RightLowerLeg)
                end
                SetLine(Objects.LowerTorsoToLeftLeg, parts.LowerTorso, parts.LeftUpperLeg)
                SetLine(Objects.LowerTorsoToRightLeg, parts.LowerTorso, parts.RightUpperLeg)
            else
                for _, obj in pairs(Objects) do if obj then obj.Visible = false end end
                if not player.Parent then for _, obj in pairs(Objects) do if obj then obj:Remove() end end end
            end
        end)
    end)
end

-- // --- UNIVERSAL INVISIBILITY & MOVEMENT --- // --
local function HandleInvisibility()
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if MovementSettings.Invisibility then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Transparency = 1
                    elseif part:IsA("Decal") then part.Transparency = 1 end
                end
                char.HumanoidRootPart.CanCollide = false
            else
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Transparency = 0
                    elseif part:IsA("Decal") then part.Transparency = 0 end
                end
            end
        end
    end)
end

local function HandleMovement()
    RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if MovementSettings.SpeedEnabled then LocalPlayer.Character.Humanoid.WalkSpeed = MovementSettings.SpeedValue
            else if LocalPlayer.Character.Humanoid.WalkSpeed ~= 16 then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end
        end
    end)
    UserInputService.JumpRequest:Connect(function()
        if MovementSettings.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
coroutine.wrap(HandleMovement)()
coroutine.wrap(HandleInvisibility)()

-- // --- INITIALIZATION --- // --
for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateEspBox(v) CreateSkeleton(v) end end
Players.PlayerAdded:Connect(function(v) CreateEspBox(v) CreateSkeleton(v) end)

-- // --- UI HELPERS --- // --
local function MakeDraggable(ui)
    local dragging, dragInput, dragStart, startPos
    ui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = ui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    ui.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // --- MAIN FRAME SETUP --- // --
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "V23_OmegaHub"; ScreenGui.ResetOnSpawn = false
local UISuccess, _ = pcall(function() ScreenGui.Parent = CoreGui end)
if not UISuccess then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 580, 0, 350); MainFrame.Position = UDim2.new(0.5, -290, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(2, 4, 10); MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Thickness = 2.5; MakeDraggable(MainFrame)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 38); Header.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -100, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "OMEGA HUB v23 | Premium Edition"; Title.TextColor3 = Color3.fromRGB(0, 180, 255); Title.Font = Enum.Font.GothamBold; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Background
