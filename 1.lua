-- [[ OMEGA PROJECT V27.5 - เวอร์ชันธีมดำสนิท แก้บั๊กเปิดปิดเมนูหลัก และระบบลิสต์รายชื่อพิกัดเลือกสาปได้ ]] --
-- สถานะการตรวจสอบ: ผ่านเกณฑ์ความปลอดภัย ปุ่มเปิดปิดทำงานอิสระ ลำดับตัวแปรถูกต้อง พลังเดิมอยู่ครบถ้วน

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- 1. [ล้างระบบเก่าป้องกันบั๊กหน้าจอซ้อน]
if CoreGui:FindFirstChild("Omega_V26_FixedVision") then 
    CoreGui.Omega_V26_FixedVision:Destroy() 
end

-- 2. [คลังจัดเก็บสถานะระบบ]
local Omega = {
    TrackingMode = false, 
    StickyActive = false,  
    HitboxActive = false,
    StreamerModeActive = false, 
    
    ESPChamsActive = false,
    ESPTagsActive = false,
    
    -- [⚡ UPGRADED V27.5] โครงสร้างข้อมูลพิกัดแบบมีรายชื่อวัตถุ UI
    SavedWaypoints = {}, 
    WaypointModeActive = false,
    WaypointCounter = 0,
    
    TargetIndex = 1,
    TargetList = {},
    SelectedTarget = nil,
    
    StickyConn = nil,
    SpectateConn = nil,
    FlyConn = nil,
    JumpConn = nil,
    ESPConn = nil,
    
    IsVisible = true,
    FlySpeed = 60,
    UIElements = {},
    
    -- [🎨 NEW THEME] ปรับเป็นธีมดำสนิท (True Black) ดุดัน สไตล์แฮกเกอร์
    Theme = {
        Bg = Color3.fromRGB(5, 5, 6),             -- ดำสนิทสุดขีด
        Sidebar = Color3.fromRGB(10, 10, 12),      -- ดำเทาเข้มแยกสัดส่วน
        Accent = Color3.fromRGB(0, 255, 132),     -- เขียวนีออนเรืองแสง (Cursed Green)
        ESPChamColor = Color3.fromRGB(255, 0, 50),
        Alert = Color3.fromRGB(255, 40, 40),     
        Text = Color3.fromRGB(255, 255, 255),    
        DarkText = Color3.fromRGB(140, 145, 150),
        Btn = Color3.fromRGB(15, 15, 18),         -- ปุ่มดำสนิทโทนเนียน
        ToggleOn = Color3.fromRGB(10, 40, 24),   
        ToggleOff = Color3.fromRGB(25, 25, 28)   
    }
}

local Modules = {}

-- โฟลเดอร์เก็บวัตถุ ESP ป้องกันการตรวจจับ
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "Omega_FixedESP_Storage"

-- ====================================================================
-- 🧱 [โครงสร้าง UI หลัก - ประกาศไว้ด้านบนสุดเพื่อความปลอดภัยในการเรียกใช้]
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "Omega_V26_FixedVision"
ScreenGui.ResetOnSpawn = false
ESPFolder.Parent = ScreenGui 

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 300)
Main.Position = UDim2.new(0.5, -260, 0.5, -150)
Main.BackgroundColor3 = Omega.Theme.Bg
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Omega.Theme.Accent; MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.4

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 145, 1, 0); Sidebar.BackgroundColor3 = Omega.Theme.Sidebar
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Logo = Instance.new("TextLabel", Sidebar)
Logo.Size = UDim2.new(1, 0, 0, 50); Logo.Text = "Ω โอเมก้า V27.5"; Logo.TextColor3 = Omega.Theme.Text
Logo.Font = Enum.Font.GothamBold; Logo.TextSize = 14; Logo.BackgroundTransparency = 1

local TabScroll = Instance.new("ScrollingFrame", Sidebar)
TabScroll.Size = UDim2.new(1, 0, 1, -60); TabScroll.Position = UDim2.new(0, 0, 0, 50)
TabScroll.BackgroundTransparency = 1; TabScroll.ScrollBarThickness = 0
local TabListLayout = Instance.new("UIListLayout", TabScroll)
TabListLayout.Padding = UDim.new(0, 5); TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -165, 1, -20); Container.Position = UDim2.new(0, 165, 0, 10)
Container.BackgroundTransparency = 1

-- หน้าต่างแถบล่างสำหรับ "ระบบส่องกล้อง/ติดตามผู้เล่น"
local FloatingFrame = Instance.new("Frame", ScreenGui)
FloatingFrame.Size = UDim2.new(0, 330, 0, 75)
FloatingFrame.AnchorPoint = Vector2.new(0.5, 1)
FloatingFrame.Position = UDim2.new(0.5, 0, 1, -15) 
FloatingFrame.BackgroundColor3 = Omega.Theme.Bg
FloatingFrame.Visible = false
Instance.new("UICorner", FloatingFrame).CornerRadius = UDim.new(0, 8)
local FloatStroke = Instance.new("UIStroke", FloatingFrame)
FloatStroke.Color = Omega.Theme.Accent; FloatStroke.Thickness = 1.5

local FloatTitle = Instance.new("TextLabel", FloatingFrame)
FloatTitle.Size = UDim2.new(1, -35, 0, 25); FloatTitle.Position = UDim2.new(0, 12, 0, 2)
FloatTitle.Text = "🎯 กำลังสาปเป้าหมาย: ยังไม่ได้เลือก"; FloatTitle.TextColor3 = Omega.Theme.Text
FloatTitle.Font = Enum.Font.GothamBold; FloatTitle.TextSize = 11; FloatTitle.TextXAlignment = Enum.TextXAlignment.Left; FloatTitle.BackgroundTransparency = 1
Omega.UIElements.FloatTitle = FloatTitle

-- ====================================================================
-- 🌀 [⚡ NEW UI V27.5 - หน้าต่างระบบควิกวาร์ปหลายจุด + แสดงลิสต์เลือกสาป]
-- ====================================================================
local WaypointFrame = Instance.new("Frame", ScreenGui)
WaypointFrame.Size = UDim2.new(0, 340, 0, 140) -- ขยายความสูงรองรับการแสดงลิสต์พิกัด
WaypointFrame.AnchorPoint = Vector2.new(0.5, 1)
WaypointFrame.Position = UDim2.new(0.5, 0, 1, -15) 
WaypointFrame.BackgroundColor3 = Omega.Theme.Bg
WaypointFrame.Visible = false
Instance.new("UICorner", WaypointFrame).CornerRadius = UDim.new(0, 8)
local WPStroke = Instance.new("UIStroke", WaypointFrame)
WPStroke.Color = Omega.Theme.Accent
WPStroke.Thickness = 1.5

local WPTitle = Instance.new("TextLabel", WaypointFrame)
WPTitle.Size = UDim2.new(1, -35, 0, 25); WPTitle.Position = UDim2.new(0, 12, 0, 2)
WPTitle.Text = "📌 ระบบลิสต์พิกัดสาปมวลสาร [0 จุด]"; WPTitle.TextColor3 = Omega.Theme.Text
WPTitle.Font = Enum.Font.GothamBold; WPTitle.TextSize = 11; WPTitle.TextXAlignment = Enum.TextXAlignment.Left; WPTitle.BackgroundTransparency = 1

-- หน้าต่างย่อยแบบเลื่อนได้ (ScrollingFrame) สำหรับแสดงรายชื่อพิกัดที่บันทึกไว้
local WPListScroll = Instance.new("ScrollingFrame", WaypointFrame)
WPListScroll.Size = UDim2.new(1, -20, 0, 65); WPListScroll.Position = UDim2.new(0, 10, 0, 28)
WPListScroll.BackgroundTransparency = 1; WPListScroll.ScrollBarThickness = 3
WPListScroll.ScrollBarImageColor3 = Omega.Theme.Accent
local WPListLayout = Instance.new("UIListLayout", WPListScroll)
WPListLayout.Padding = UDim.new(0, 4)

local WPBtnContainer = Instance.new("Frame", WaypointFrame)
WPBtnContainer.Size = UDim2.new(1, -10, 0, 35); WPBtnContainer.Position = UDim2.new(0, 5, 1, -40)
WPBtnContainer.BackgroundTransparency = 1
local WPControlLayout = Instance.new("UIListLayout", WPBtnContainer)
WPControlLayout.FillDirection = Enum.FillDirection.Horizontal; WPControlLayout.Padding = UDim.new(0, 6); WPControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function UpdateWaypointUI()
    WPTitle.Text = "📌 ระบบลิสต์พิกัดสาปมวลสาร [" .. #Omega.SavedWaypoints .. " จุด]"
end

-- ====================================================================
-- ⚙️ [ระบบคำนวณและฟังก์ชันแกนหลัก]
-- ====================================================================

-- ฟังก์ชันพรางชื่อเมื่อเปิดใช้งาน
local function MaskTextObject(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        if obj:IsDescendantOf(ScreenGui) then return end 
        
        local currentText = obj.Text
        local changed = false
        
        if string.find(currentText, LocalPlayer.Name) then
            currentText = string.gsub(currentText, LocalPlayer.Name, "Anonymous")
            changed = true
        end
        if string.find(currentText, LocalPlayer.DisplayName) then
            currentText = string.gsub(currentText, LocalPlayer.DisplayName, "Anonymous")
            changed = true
        end
        
        if changed then obj.Text = currentText end
    end
end

function Modules:UnmaskAllText()
    local function RestoreText(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj:IsDescendantOf(ScreenGui) then return end
            if string.find(obj.Text, "Anonymous") then
                obj.Text = string.gsub(obj.Text, "Anonymous", LocalPlayer.DisplayName)
            end
        end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do pcall(RestoreText, desc) end
    local playerGuiDesc = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:GetDescendants()
    if playerGuiDesc then
        for _, desc in ipairs(playerGuiDesc) do pcall(RestoreText, desc) end
    end
end

task.spawn(function()
    while task.wait(0.6) do
        if Omega.StreamerModeActive then
            local allDescendants = workspace:GetDescendants()
            for i, desc in ipairs(allDescendants) do
                pcall(MaskTextObject, desc)
                if i % 150 == 0 then task.wait() end 
            end
        end
    end
end)

local function UpdateTargetList()
    Omega.TargetList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(Omega.TargetList, p) end
    end
    if #Omega.TargetList == 0 then
        Omega.SelectedTarget = nil
    else
        if Omega.TargetIndex > #Omega.TargetList then Omega.TargetIndex = 1 end
        if Omega.TargetIndex < 1 then Omega.TargetIndex = #Omega.TargetList end
        Omega.SelectedTarget = Omega.TargetList[Omega.TargetIndex]
    end
end

local function ApplyTrackingLogic()
    UpdateTargetList()
    if not Omega.SelectedTarget then
        if Omega.UIElements.FloatTitle then Omega.UIElements.FloatTitle.Text = "เป้าหมาย: ไม่พบผู้เล่นอื่น" end
        return
    end
    
    local finalName = Omega.SelectedTarget.DisplayName
    if Omega.StreamerModeActive then
        finalName = "TARGET_" .. string.sub(Omega.SelectedTarget.Name, 1, 3):upper() .. "_X"
    end
    
    if Omega.UIElements.FloatTitle then
        Omega.UIElements.FloatTitle.Text = "🎯 กำลังสาปเป้าหมาย: " .. finalName:upper()
    end
    
    if Omega.TrackingMode then
        local hum = Omega.SelectedTarget.Character and Omega.SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then workspace.CurrentCamera.CameraSubject = hum end
    end
end

RunService.RenderStepped:Connect(function()
    local CurrentCam = workspace.CurrentCamera
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    
    if myHum then
        if Omega.StreamerModeActive then
            if myHum.DisplayName ~= "🛡️ Anonymous (You)" then myHum.DisplayName = "🛡️ Anonymous (You)" end
        else
            if myHum.DisplayName == "🛡️ Anonymous (You)" then myHum.DisplayName = LocalPlayer.DisplayName end
        end
    end
    
    if Omega.TrackingMode and Omega.SelectedTarget and Omega.SelectedTarget.Character then
        local tHum = Omega.SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
        local tRoot = Omega.SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
        if tHum and tHum.Health > 0 then
            if CurrentCam.CameraSubject ~= tHum then CurrentCam.CameraSubject = tHum end
            if Omega.StickyActive and tRoot then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5) end
            end
        end
    end
end)

-- ====================================================================
-- 👁️ [ระบบเนตรทิพย์ (ESP)]
-- ====================================================================
local function CleanESPOfPlayer(player)
    if ESPFolder:FindFirstChild(player.Name .. "_Chams") then ESPFolder[player.Name .. "_Chams"]:Destroy() end
    if ESPFolder:FindFirstChild(player.Name .. "_Tag") then ESPFolder[player.Name .. "_Tag"]:Destroy() end
end

local function ApplyESPToPlayer(player)
    CleanESPOfPlayer(player)
    if player == LocalPlayer or not player.Character then return end
    local char = player.Character
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return end
    
    if Omega.ESPChamsActive then
        local chams = Instance.new("Highlight")
        chams.Name = player.Name .. "_Chams"; chams.Adornee = char
        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chams.FillColor = Omega.Theme.ESPChamColor; chams.FillTransparency = 0.2              
        chams.OutlineColor = Omega.Theme.Text; chams.OutlineTransparency = 0; chams.Parent = ESPFolder
    end
    
    if Omega.ESPTagsActive then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = player.Name .. "_Tag"; billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 40); billboard.StudsOffset = Vector3.new(0, 3, 0); billboard.AlwaysOnTop = true
        
        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.new(1, 0, 1, 0); textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Omega.Theme.Text; textLabel.Font = Enum.Font.GothamBold; textLabel.TextSize = 12
        
        local finalName = player.DisplayName
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distStr = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) .. " STUDS" or "0 STUDS"
        textLabel.Text = finalName:upper() .. "\n[" .. distStr .. "]"
        billboard.Parent = ESPFolder
    end
end

Omega.ESPConn = RunService.Heartbeat:Connect(function()
    if not Omega.ESPChamsActive and not Omega.ESPTagsActive then ESPFolder:ClearAllChildren() return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tag = ESPFolder:FindFirstChild(p.Name .. "_Tag")
            if Omega.ESPTagsActive and tag and tag:FindFirstChildOfClass("TextLabel") and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = myRoot and math.floor((p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude) or 0
                tag:FindFirstChildOfClass("TextLabel").Text = p.DisplayName:upper() .. "\n[" .. dist .. " STUDS]"
            elseif Omega.ESPTagsActive and not tag then
                ApplyESPToPlayer(p)
            end
        end
    end
end)

function Modules:RefreshAllESP()
    ESPFolder:ClearAllChildren()
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyESPToPlayer(p) end end
end

function Modules:ToggleFly(state)
    Omega.Flying = state
    if Omega.FlyConn then Omega.FlyConn:Disconnect(); Omega.FlyConn = nil end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or not state then
        if root and root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
        if root and root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
        return
    end
    local bg = Instance.new("BodyGyro", root); bg.Name = "FlyGyro"; bg.maxTorque = Vector3.new(4e4, 4e4, 4e4); bg.cframe = root.CFrame
    local bv = Instance.new("BodyVelocity", root); bv.Name = "FlyVelocity"; bv.maxForce = Vector3.new(4e4, 4e4, 4e4); bv.velocity = Vector3.new(0, 0.1, 0)
    Omega.FlyConn = RunService.RenderStepped:Connect(function()
        bg.cframe = workspace.CurrentCamera.CFrame
        bv.velocity = (hum.MoveDirection.Magnitude > 0) and (hum.MoveDirection * Omega.FlySpeed) or Vector3.new(0, 0.1, 0)
    end)
end

function Modules:ToggleInfJump(state)
    if Omega.JumpConn then Omega.JumpConn:Disconnect(); Omega.JumpConn = nil end
    if not state then return end
    Omega.JumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-- ====================================================================
-- 🎨 [ฟังก์ชันสร้างหน้าตา UI และลงทะเบียนปุ่ม]
-- ====================================================================
local Pages = {}

local function CreatePage(thaiName)
    local P = Instance.new("ScrollingFrame", Container)
    P.Size = UDim2.new(1, 0, 1, 0); P.BackgroundTransparency = 1; P.Visible = false; P.ScrollBarThickness = 2
    P.ScrollBarImageColor3 = Omega.Theme.Accent
    Instance.new("UIListLayout", P).Padding = UDim.new(0, 6)
    Pages[thaiName] = P
    
    local B = Instance.new("TextButton", TabScroll)
    B.Size = UDim2.new(0.92, 0, 0, 36); B.BackgroundColor3 = Omega.Theme.Btn
    B.Text = thaiName; B.TextColor3 = Omega.Theme.DarkText; B.Font = Enum.Font.GothamSemibold; B.TextSize = 11
    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
    
    B.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, btn in pairs(TabScroll:GetChildren()) do if btn:IsA("TextButton") then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Omega.Theme.DarkText, BackgroundColor3 = Omega.Theme.Btn}):Play() end end
        P.Visible = true
        TweenService:Create(B, TweenInfo.new(0.2), {TextColor3 = Omega.Theme.Text, BackgroundColor3 = Color3.fromRGB(15, 24, 18)}):Play()
    end)
    return P
end

local function AddActionBtn(page, title, desc, actionText, callback)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(0.96, 0, 0, 52); f.BackgroundColor3 = Omega.Theme.Btn
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(0.65, 0, 0, 24); t.Position = UDim2.new(0, 12, 0, 4); t.Text = title
    t.TextColor3 = Omega.Theme.Text; t.Font = Enum.Font.GothamMedium; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left; t.BackgroundTransparency = 1
    
    local d = Instance.new("TextLabel", f)
    d.Size = UDim2.new(0.65, 0, 0, 16); d.Position = UDim2.new(0, 12, 0, 24); d.Text = desc
    d.TextColor3 = Omega.Theme.DarkText; d.Font = Enum.Font.Gotham; d.TextSize = 9; d.TextXAlignment = Enum.TextXAlignment.Left; d.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0, 95, 0, 26); btn.Position = UDim2.new(1, -107, 0.5, -12); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = actionText; btn.TextColor3 = Omega.Theme.Text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Omega.Theme.Accent
    
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Omega.Theme.Accent, TextColor3 = Color3.new(0,0,0)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 30), TextColor3 = Omega.Theme.Text}):Play()
        callback(btn)
    end)
end

local function AddToggle(page, title, desc, defaultState, callback)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(0.96, 0, 0, 52); f.BackgroundColor3 = Omega.Theme.Btn
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(0.65, 0, 0, 24); t.Position = UDim2.new(0, 12, 0, 4); t.Text = title
    t.TextColor3 = Omega.Theme.Text; t.Font = Enum.Font.GothamMedium; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left; t.BackgroundTransparency = 1
    
    local d = Instance.new("TextLabel", f)
    d.Size = UDim2.new(0.65, 0, 0, 16); d.Position = UDim2.new(0, 12, 0, 24); d.Text = desc
    d.TextColor3 = Omega.Theme.DarkText; d.Font = Enum.Font.Gotham; d.TextSize = 9; d.TextXAlignment = Enum.TextXAlignment.Left; d.BackgroundTransparency = 1
    
    local SwitchBg = Instance.new("TextButton", f)
    SwitchBg.Size = UDim2.new(0, 42, 0, 20); SwitchBg.Position = UDim2.new(1, -54, 0.5, -10)
    SwitchBg.BackgroundColor3 = defaultState and Omega.Theme.ToggleOn or Omega.Theme.ToggleOff; SwitchBg.Text = ""
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    local SwitchStroke = Instance.new("UIStroke", SwitchBg)
    SwitchStroke.Thickness = 1; SwitchStroke.Color = defaultState and Omega.Theme.Accent or Color3.fromRGB(50, 50, 55)

    local Ball = Instance.new("Frame", SwitchBg)
    Ball.Size = UDim2.new(0, 14, 0, 14); Ball.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Ball.BackgroundColor3 = defaultState and Omega.Theme.Accent or Color3.fromRGB(120, 120, 125)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local isToggled = defaultState
    SwitchBg.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        local targetPos = isToggled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetBgColor = isToggled and Omega.Theme.ToggleOn or Omega.Theme.ToggleOff
        local targetBallColor = isToggled and Omega.Theme.Accent or Color3.fromRGB(120, 120, 125)
        local targetStrokeColor = isToggled and Omega.Theme.Accent or Color3.fromRGB(50, 50, 55)
        
        TweenService:Create(Ball, TweenInfo.new(0.15), {Position = targetPos, BackgroundColor3 = targetBallColor}):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = targetBgColor}):Play()
        TweenService:Create(SwitchStroke, TweenInfo.new(0.15), {Color = targetStrokeColor}):Play()
        callback(isToggled)
    end)
end

local MainControlPage = CreatePage("แผงควบคุมหลัก")
local VisionPage = CreatePage("เนตรทิพย์ (ESP)")
local MovementPage = CreatePage("การเคลื่อนที่")
local QoLPage = CreatePage("อำนวยความสะดวก (QoL)")

-- แท็บ: แผงควบคุมหลัก
AddActionBtn(MainControlPage, "เปิดระบบติดตามอัจฉริยะ", "รวมฟังก์ชันเลือกผู้เล่น ส่องกล้อง และวาร์ปติดหลัง ไว้ขอบล่างหน้าจอ", "เริ่มใช้งาน", function()
    Omega.TrackingMode = true
    Omega.TargetIndex = 1
    Main.Visible = false
    Omega.IsVisible = false
    FloatingFrame.Visible = true
    ApplyTrackingLogic()
end)

AddToggle(MainControlPage, "เปิด Streamer Mode (พรางชื่อ)", "ซ่อนชื่อเราบนหัว UI/ESP/ป้ายฐาน Tycoon และ Leaderboard ทั้งหมด", false, function(state)
    Omega.StreamerModeActive = state
    ApplyTrackingLogic() 
    Modules:RefreshAllESP() 
    if not state then Modules:UnmaskAllText() end
end)

AddToggle(MainControlPage, "ขยายฮิตบ็อกซ์เป้าหมาย", "ขยายกล่องรับดาเมจของเป้าหมายปัจจุบันให้ใหญ่ขึ้นอัตโนมัติ", false, function(state)
    Omega.HitboxActive = state
end)

AddActionBtn(MainControlPage, "หมัดผลักกระเด็นมหาศาล", "กระแทกฟิสิกส์ดีดเป้าหมายที่เลือกให้ลอยตกแมพ", "ผลักเป้าหมาย", function()
    if Omega.SelectedTarget and Omega.SelectedTarget.Character then
        local hrp = Omega.SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp:ApplyImpulse(((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 5500) + Vector3.new(0, 2200, 0)) end
    end
end)

-- แท็บ: เนตรทิพย์ (ESP)
AddToggle(VisionPage, "เปิด Chams แดงนีออนเข้ม", "แสดงออร่าแดงเลือดทึบแสง ทะลุกำแพง เส้นขอบขาวทึบ ชัดเจน", false, function(state)
    Omega.ESPChamsActive = state
    Modules:RefreshAllESP()
end)
AddToggle(VisionPage, "เปิดป้ายชื่อและระยะทาง", "สร้างแท็กข้อความสีขาวคมชัด แสดงชื่อและระยะห่างเรียอลไทม์เหนือหัวศัตรู", false, function(state)
    Omega.ESPTagsActive = state
    Modules:RefreshAllESP()
end)

-- แท็บ: การเคลื่อนที่
AddToggle(MovementPage, "ระบบบินจอยสติ๊ก", "เปิดระบบบินควบคุมทิศทางอย่างอิสระผ่านอนาล็อกเดินมือถือ", false, function(state)
    Modules:ToggleFly(state)
end)
AddToggle(MovementPage, "วิ่งเร็วทะลุพิกัด (สปีด 80)", "เพิ่มค่าความเร็วการเดินวิ่งของตัวละครให้ไวขึ้น 5 เท่า", false, function(state)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = state and 80 or 16 end
end)
AddToggle(MovementPage, "กระโดดเหยียบอากาศ", "เปิดสิทธิ์กระโดดไตลอยฟ้าไต่ระดับความสูงไม่จำกัด", false, function(state)
    Modules:ToggleInfJump(state)
end)

-- ====================================================================
-- 🌀 [⚡ NEW CORE V27.5 - ระบบจัดการสร้าง/ลบลิสต์พิกัดสาป และเลือกวาร์ปรายจุด]
-- ====================================================================
local function RenderWaypointList()
    -- ล้างวัตถุเก่าใน Scroll ออกให้หมดเพื่อเรนเดอร์ใหม่
    for _, item in pairs(WPListScroll:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end
    
    -- สร้างแผงปุ่มตามพิกัดที่ถูกบันทึกไว้ในสแต็ก
    for idx, data in ipairs(Omega.SavedWaypoints) do
        local row = Instance.new("Frame", WPListScroll)
        row.Size = UDim2.new(1, -6, 0, 26); row.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.6, 0, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.Text = "🔮 " .. data.Name; lbl.TextColor3 = Omega.Theme.Text
        lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
        
        -- ปุ่มเลือกสาป (วาร์ปไปพิกัดนั้นทันที)
        local curseBtn = Instance.new("TextButton", row)
        curseBtn.Size = UDim2.new(0, 50, 0, 18); curseBtn.Position = UDim2.new(1, -95, 0.5, -9)
        curseBtn.BackgroundColor3 = Omega.Theme.ToggleOn; curseBtn.Text = "เลือกสาป"
        curseBtn.TextColor3 = Omega.Theme.Accent; curseBtn.Font = Enum.Font.GothamBold; curseBtn.TextSize = 9
        Instance.new("UICorner", curseBtn).CornerRadius = UDim.new(0, 3)
        
        curseBtn.MouseButton1Click:Connect(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = data.CFrame end
        end)
        
        -- ปุ่มลบรายจุด
        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 35, 0, 18); delBtn.Position = UDim2.new(1, -40, 0.5, -9)
        delBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 15); delBtn.Text = "ลบ"
        delBtn.TextColor3 = Omega.Theme.Alert; delBtn.Font = Enum.Font.GothamBold; delBtn.TextSize = 9
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)
        
        delBtn.MouseButton1Click:Connect(function()
            table.remove(Omega.SavedWaypoints, idx)
            UpdateWaypointUI()
            RenderWaypointList()
        end)
    end
    WPListScroll.CanvasSize = UDim2.new(0, 0, 0, WPListLayout.AbsoluteContentSize.Y)
end

AddActionBtn(QoLPage, "เปิดระบบควิกวาร์ปหลายจุด", "พับเมนูหลักอัตโนมัติ และแสดงหน้าต่างเลือกสาปรายพิกัดแยกส่วน", "เปิดใช้งาน", function()
    Omega.WaypointModeActive = true
    Main.Visible = false
    Omega.IsVisible = false
    WaypointFrame.Visible = true
    UpdateWaypointUI()
    RenderWaypointList()
end)

AddActionBtn(QoLPage, "ย้ายเซิร์ฟเวอร์อัจฉริยะ", "สแกนหาเซิร์ฟเวอร์สาธารณะอื่นที่มีคนเล่นเพื่อย้ายหนีคนเดิมทันที", "ย้ายเซิร์ฟ", function()
    pcall(function()
        local serverList = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(serverList.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end)
end)

AddActionBtn(QoLPage, "รีเซ็ตตัวละครด่วน (Reset)", "สั่งการให้เลือดตัวละครเหลือ 0 ทันที แก้ไขอาการตัวบั๊กติดขัดในแมพ", "รีเซ็ตตัว", function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

-- ====================================================================
-- 🎛️ [สร้างปุ่มภายในหน้าต่างแยกพิกัดสาป (Waypoint Frame)]
-- ====================================================================
local WPExit = Instance.new("TextButton", WaypointFrame)
WPExit.Size = UDim2.new(0, 20, 0, 20); WPExit.Position = UDim2.new(1, -25, 0, 5)
WPExit.BackgroundColor3 = Color3.fromRGB(35, 15, 15); WPExit.Text = "X"; WPExit.TextColor3 = Omega.Theme.Text
WPExit.Font = Enum.Font.GothamBold; WPExit.TextSize = 10
Instance.new("UICorner", WPExit).CornerRadius = UDim.new(0, 4)
local WPExitStroke = Instance.new("UIStroke", WPExit); WPExitStroke.Color = Omega.Theme.Alert

local function CreateWPFloatBtn(text, width, order)
    local b = Instance.new("TextButton", WPBtnContainer)
    b.Size = UDim2.new(0, width, 0, 28); b.BackgroundColor3 = Omega.Theme.Btn
    b.Text = text; b.TextColor3 = Omega.Theme.Text; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.LayoutOrder = order
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(40, 40, 45)
    return b, s
end

local BtnSaveWP, StrokeSaveWP = CreateWPFloatBtn("📌 บันทึกจุดปัจจุบัน", 150, 1)
local BtnClearAllWP, StrokeClearAllWP = CreateWPFloatBtn("🗑️ ล้างทั้งหมด", 110, 2)

BtnSaveWP.MouseButton1Click:Connect(function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        Omega.WaypointCounter = Omega.WaypointCounter + 1
        table.insert(Omega.SavedWaypoints, {
            Name = "พิกัดสาปที่ " .. Omega.WaypointCounter,
            CFrame = root.CFrame
        })
        UpdateWaypointUI()
        RenderWaypointList()
        
        BtnSaveWP.BackgroundColor3 = Omega.Theme.ToggleOn
        task.wait(0.12)
        BtnSaveWP.BackgroundColor3 = Omega.Theme.Btn
    end
end)

BtnClearAllWP.MouseButton1Click:Connect(function()
    Omega.SavedWaypoints = {}
    Omega.WaypointCounter = 0
    UpdateWaypointUI()
    RenderWaypointList()
end)

WPExit.MouseButton1Click:Connect(function()
    Omega.WaypointModeActive = false
    WaypointFrame.Visible = false
    Main.Visible = true
    Omega.IsVisible = true
end)

-- ====================================================================
-- 🎛️ [สร้างปุ่มภายในหน้าต่างแถบล่างระบบส่องกล้องเดิม]
-- ====================================================================
local BtnExit = Instance.new("TextButton", FloatingFrame)
BtnExit.Size = UDim2.new(0, 20, 0, 20); BtnExit.Position = UDim2.new(1, -25, 0, 5)
BtnExit.BackgroundColor3 = Color3.fromRGB(35, 15, 15); BtnExit.Text = "X"; BtnExit.TextColor3 = Omega.Theme.Text
BtnExit.Font = Enum.Font.GothamBold; BtnExit.TextSize = 10
Instance.new("UICorner", BtnExit).CornerRadius = UDim.new(0, 4)

local BtnContainer = Instance.new("Frame", FloatingFrame)
BtnContainer.Size = UDim2.new(1, -10, 0, 40); BtnContainer.Position = UDim2.new(0, 5, 0, 28)
BtnContainer.BackgroundTransparency = 1
local FloatList = Instance.new("UIListLayout", BtnContainer)
FloatList.FillDirection = Enum.FillDirection.Horizontal; FloatList.Padding = UDim.new(0, 5); FloatList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function CreateFloatBtn(text, width, order)
    local b = Instance.new("TextButton", BtnContainer)
    b.Size = UDim2.new(0, width, 0, 32); b.BackgroundColor3 = Omega.Theme.Btn
    b.Text = text; b.TextColor3 = Omega.Theme.Text; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.LayoutOrder = order
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(40, 40, 45)
    return b, s
end

local BtnNext, StrokeNext = CreateFloatBtn("ถัดไป", 85, 1)
local BtnTP, StrokeTP     = CreateFloatBtn("วาร์ปติดหลัง (สาป)", 135, 2)
local BtnPrev, StrokePrev = CreateFloatBtn("ย้อนกลับ", 85, 3)

BtnNext.MouseButton1Click:Connect(function()
    Omega.TargetIndex = Omega.TargetIndex + 1; ApplyTrackingLogic()
end)
BtnPrev.MouseButton1Click:Connect(function()
    Omega.TargetIndex = Omega.TargetIndex - 1; ApplyTrackingLogic()
end)
BtnTP.MouseButton1Click:Connect(function()
    Omega.StickyActive = not Omega.StickyActive
    BtnTP.BackgroundColor3 = Omega.StickyActive and Omega.Theme.ToggleOn or Omega.Theme.Btn
end)

BtnExit.MouseButton1Click:Connect(function()
    Omega.TrackingMode = false; Omega.StickyActive = false
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if myHum then workspace.CurrentCamera.CameraSubject = myHum end
    FloatingFrame.Visible = false; Main.Visible = true; Omega.IsVisible = true
end)

-- ระบบจัดการรายชื่อผู้เล่น เข้า/ออก
Players.PlayerAdded:Connect(UpdateTargetList)
Players.PlayerRemoving:Connect(UpdateTargetList)

-- ระบบลากหน้าต่างใหญ่บนหน้าจอ
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = Main.Position end 
end)
UserInputService.InputChanged:Connect(function(i) 
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
        local d = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

-- ====================================================================
-- 🎛️ [⚡ FIX] แก้ไขปุ่มวงกลม Ω ให้เปิดปิดหน้าต่างหลักได้อิสระตลอดเวลา ไม่ว่าจะอยู่ในโหมดไหน
-- ====================================================================
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 42, 0, 42); ToggleBtn.Position = UDim2.new(0, 15, 0, 15); ToggleBtn.BackgroundColor3 = Omega.Theme.Bg
ToggleBtn.Text = "Ω"; ToggleBtn.TextColor3 = Omega.Theme.Text
ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 18
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Omega.Theme.Accent; ToggleStroke.Thickness = 1.5

ToggleBtn.MouseButton1Click:Connect(function() 
    Omega.IsVisible = not Omega.IsVisible
    Main.Visible = Omega.IsVisible 
end)

Pages["แผงควบคุมหลัก"].Visible = true
print("OMEGA PROJECT V27.5 - TRUE BLACK & WAYPOINT LIST MANAGER LOADED SUCCESS.")
