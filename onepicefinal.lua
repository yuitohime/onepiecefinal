-- =========================================================================
-- [ULTIMATE MASTER] YUIHUB V22 - INTRO, FLY/TELEPORT, FAST MAP SWEEP, ANTI-AFK
-- =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local TargetGui = (gethui and pcall(gethui) and gethui()) or CoreGui
if not pcall(function() local _ = TargetGui.Name end) then TargetGui = LocalPlayer:WaitForChild("PlayerGui") end

-- Clean old GUI
for _, gui in pairs(TargetGui:GetChildren()) do if gui.Name == "YuiHub" then gui:Destroy() end end

-- Anti AFK Core
LocalPlayer.Idled:Connect(function()
    if _G.Yui and _G.Yui.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Global Settings
_G.Yui = {
    AntiAFK = true, MoveMethod = "Teleport", MoveSpeed = 300, HoverOnKill = true,
    AutoFarm = false, SelectedMobs = {}, SelectedWeapon = "None", FastAttack = false, AutoClick = false,
    AttackDist = 5, AttackPos = "Above", AutoSpawn = false,
    AutoSkill = {R=false, Z=false, X=false, C=false, V=false, B=false, N=false, F=false},
    HoldSkill = {R=false, Z=false, X=false, C=false, V=false, B=false, N=false, F=false}, HoldTime = 1,
    AutoHaki = {E=false, R=false, T=false},
    SelectedNormalQuest = "", AutoNormalQuest = false,
    SelectedDailyQuest = "", AutoDailyQuest = false, AutoAcceptQuest = false,
    CollectChest = false, CollectBarrel = false, CollectSpeed = 0.2, AutoFruit = false, CamUnderground = false,
    AutoJuice = false, JuiceDelay = 5, AutoDrink = false, DrinkDelay = 1,
    AutoEatApple = false, AppleDelay = 3, 
    WalkSpeed = 16, EnableWS = false, JumpPower = 50, EnableJP = false, 
    Fly = false, FlySpeed = 50, Noclip = false, WalkOnWater = false, InfJump = false,
    AutoGetRod = false, AutoFish = false, AutoPin = false,
    TargetPlayer = "None", AutoHunt = false, HuntDist = 5, ESPPlayer = false, Spectate = false,
    AutoRejoin = false, AutoExecute = false, ExecuteScript = "", 
    AutoLoadConfig = false, AutoLoadName = "", ConfigName = "Default",
    AutoHop = false, HopDelay = 3, ThemeColor = "Pink"
}

-- Config System
local ConfigFolder = "YuiHub_Configs"
if isfolder and not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
local CoreFile = ConfigFolder .. "/CoreSettings.json"

local function SaveCoreSettings()
    if writefile and HttpService then
        writefile(CoreFile, HttpService:JSONEncode({
            AutoRejoin = _G.Yui.AutoRejoin, AutoExecute = _G.Yui.AutoExecute, ExecuteScript = _G.Yui.ExecuteScript,
            AutoLoadConfig = _G.Yui.AutoLoadConfig, AutoLoadName = _G.Yui.AutoLoadName, LastConfig = _G.Yui.ConfigName,
            ThemeColor = _G.Yui.ThemeColor
        }))
    end
end

if isfile and isfile(CoreFile) then
    local data = HttpService:JSONDecode(readfile(CoreFile))
    if data.AutoRejoin ~= nil then _G.Yui.AutoRejoin = data.AutoRejoin end
    if data.AutoExecute ~= nil then _G.Yui.AutoExecute = data.AutoExecute end
    if data.ExecuteScript ~= nil then _G.Yui.ExecuteScript = data.ExecuteScript end
    if data.AutoLoadConfig ~= nil then _G.Yui.AutoLoadConfig = data.AutoLoadConfig end
    if data.AutoLoadName ~= nil then _G.Yui.AutoLoadName = data.AutoLoadName end
    if data.LastConfig ~= nil then _G.Yui.ConfigName = data.LastConfig end
    if data.ThemeColor ~= nil then _G.Yui.ThemeColor = data.ThemeColor end
end

-- Variables
local CurrentTarget = nil
local AllDropdowns = {}
local TimedBlacklist = {}
local ESPTracers = {}
local FlyBV, FlyBG = nil, nil
local ActiveTween = nil
_G.PinnedCFrame = nil
_G.SavedLocations = {}
_G.SavedCount = 0
_G.SelectedSavedCFrame = nil
local HakiStates = {E = false, R = false}

LocalPlayer.CharacterAdded:Connect(function() HakiStates.E = false HakiStates.R = false end)

-- Movement Handler (Teleport or Fly)
local function MoveTo(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if _G.Yui.MoveMethod == "Teleport" then
        if ActiveTween then ActiveTween:Cancel() ActiveTween = nil end
        root.CFrame = targetCFrame
        root.Velocity = Vector3.zero
    elseif _G.Yui.MoveMethod == "Fly (Tween)" then
        local dist = (root.Position - targetCFrame.Position).Magnitude
        if dist < 10 then 
            root.CFrame = targetCFrame 
        else
            local t = dist / _G.Yui.MoveSpeed
            local info = TweenInfo.new(t, Enum.EasingStyle.Linear)
            if ActiveTween then ActiveTween:Cancel() end
            ActiveTween = TweenService:Create(root, info, {CFrame = targetCFrame})
            ActiveTween:Play()
            ActiveTween.Completed:Wait()
        end
        root.Velocity = Vector3.zero
    end
end

-- Hover Mechanics
local HoverBV = Instance.new("BodyVelocity")
HoverBV.Name = "YuiHover" HoverBV.MaxForce = Vector3.zero HoverBV.Velocity = Vector3.zero
RunService.Heartbeat:Connect(function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        if HoverBV.Parent ~= root then HoverBV.Parent = root end
        if _G.Yui.AutoFarm and not CurrentTarget and _G.Yui.HoverOnKill then
            HoverBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            HoverBV.Velocity = Vector3.zero
        else
            HoverBV.MaxForce = Vector3.zero
        end
    end
end)

-- UI Interactions
local function BindTap(element, callback)
    local touchStart, startPos = 0, Vector2.new(0,0)
    element.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then 
            touchStart = tick() startPos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    element.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local endPos = Vector2.new(input.Position.X, input.Position.Y)
            if tick() - touchStart < 0.5 and (endPos - startPos).Magnitude < 10 then callback() end
        end
    end)
end

local function MakeDraggable(dragArea, targetFrame)
    local dragging, dragInput, dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = targetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Themes
local ThemeColors = {
    Pink = Color3.fromRGB(255, 85, 127), Red = Color3.fromRGB(255, 60, 60),
    Blue = Color3.fromRGB(80, 150, 255), Green = Color3.fromRGB(80, 255, 120),
    Purple = Color3.fromRGB(150, 80, 255), Orange = Color3.fromRGB(255, 170, 50)
}

local Theme = {
    MainBg = Color3.fromRGB(15, 15, 18), HeaderBg = Color3.fromRGB(22, 22, 25),
    BoxBg = Color3.fromRGB(20, 20, 23), Accent = ThemeColors[_G.Yui.ThemeColor] or ThemeColors.Pink,
    TextTitle = Color3.fromRGB(255, 255, 255), TextSub = Color3.fromRGB(140, 140, 140),
    Stroke = Color3.fromRGB(35, 35, 40), SelectedGreen = Color3.fromRGB(50, 255, 100)
}
local DynamicUIElements = {}

-- Create Base ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YuiHub" ScreenGui.Parent = TargetGui ScreenGui.ResetOnSpawn = false

-- =========================================================================
-- INTRO ANIMATION
-- =========================================================================
local IntroGui = Instance.new("ScreenGui", TargetGui)
IntroGui.Name = "YuiIntro" IntroGui.ResetOnSpawn = false

-- Loading Notification
local NotifFrame = Instance.new("Frame", IntroGui)
NotifFrame.Size = UDim2.new(0, 280, 0, 50)
NotifFrame.Position = UDim2.new(1, 20, 1, -80) -- Offscreen right
NotifFrame.BackgroundColor3 = Theme.HeaderBg
Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)
local NotifStroke = Instance.new("UIStroke", NotifFrame)
NotifStroke.Color = Theme.Accent
table.insert(DynamicUIElements, {Obj = NotifStroke, Prop = "Color"})

local Spinner = Instance.new("ImageLabel", NotifFrame)
Spinner.Size = UDim2.new(0, 30, 0, 30) Spinner.Position = UDim2.new(0, 10, 0, 10)
Spinner.BackgroundTransparency = 1 Spinner.Image = "rbxassetid://14457317772"
Spinner.ImageColor3 = Theme.Accent
table.insert(DynamicUIElements, {Obj = Spinner, Prop = "ImageColor3"})

local NotifText = Instance.new("TextLabel", NotifFrame)
NotifText.Size = UDim2.new(1, -55, 1, 0) NotifText.Position = UDim2.new(0, 50, 0, 0)
NotifText.BackgroundTransparency = 1 NotifText.Text = "Thanks for using YuiHub.\nPlease wait, loading..."
NotifText.TextColor3 = Theme.TextTitle NotifText.Font = Enum.Font.GothamBold NotifText.TextSize = 11 NotifText.TextXAlignment = Enum.TextXAlignment.Left

-- Laser Lines
local Lasers = {}
for i = 1, 4 do
    local L = Instance.new("Frame", IntroGui)
    L.BackgroundColor3 = Theme.Accent L.BorderSizePixel = 0 L.Visible = false
    table.insert(Lasers, L) table.insert(DynamicUIElements, {Obj = L, Prop = "BackgroundColor3"})
end

-- Play Intro
task.spawn(function()
    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -300, 1, -80)}):Play()
    local rotTween = TweenService:Create(Spinner, TweenInfo.new(1, Enum.EasingStyle.Linear), {Rotation = 360})
    rotTween.RepeatCount = -1 rotTween:Play()
    
    task.wait(2.5) -- Wait for load
    
    -- Laser Fire Animation
    for _, l in ipairs(Lasers) do l.Visible = true l.Size = UDim2.new(0,0,0,2) end
    Lasers[1].Position = UDim2.new(0,0,0,0) Lasers[2].Position = UDim2.new(1,0,0,0) Lasers[3].Position = UDim2.new(0,0,1,0) Lasers[4].Position = UDim2.new(1,0,1,0)
    
    local lsTween = TweenInfo.new(0.4, Enum.EasingStyle.Quint)
    TweenService:Create(Lasers[1], lsTween, {Size = UDim2.new(0.5,0,0,2)}):Play()
    TweenService:Create(Lasers[2], lsTween, {Size = UDim2.new(-0.5,0,0,2)}):Play()
    TweenService:Create(Lasers[3], lsTween, {Size = UDim2.new(0.5,0,0,2)}):Play()
    TweenService:Create(Lasers[4], lsTween, {Size = UDim2.new(-0.5,0,0,2)}):Play()
    task.wait(0.4)
    for _, l in ipairs(Lasers) do l:Destroy() end
    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(1, 20, 1, -80)}):Play()
    task.wait(0.5) IntroGui:Destroy()
    
    -- Show Main Gui
    ScreenGui.YuiMainFrame.Visible = true
end)

-- =========================================================================
-- MAIN GUI CONSTRUCTION
-- =========================================================================
local ESPFolder = Instance.new("Folder") ESPFolder.Name = "YuiESPFolder" ESPFolder.Parent = CoreGui

local OpenIcon = Instance.new("ImageButton", ScreenGui)
OpenIcon.Size = UDim2.new(0, 45, 0, 45) OpenIcon.Position = UDim2.new(0, 15, 0.5, -22) OpenIcon.BackgroundColor3 = Theme.HeaderBg
OpenIcon.Image = "rbxassetid://14457317772" OpenIcon.Visible = true OpenIcon.Active = true
Instance.new("UICorner", OpenIcon).CornerRadius = UDim.new(0, 8) 
local OpenStroke = Instance.new("UIStroke", OpenIcon) OpenStroke.Color = Theme.Accent table.insert(DynamicUIElements, {Obj = OpenStroke, Prop = "Color"})
MakeDraggable(OpenIcon, OpenIcon)

local MainFrame = Instance.new("Frame", ScreenGui) MainFrame.Name = "YuiMainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 380) MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190) MainFrame.BackgroundColor3 = Theme.MainBg MainFrame.BorderSizePixel = 0 MainFrame.Active = true MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8) Instance.new("UIStroke", MainFrame).Color = Theme.Stroke
MakeDraggable(MainFrame, MainFrame)

BindTap(OpenIcon, function() MainFrame.Visible = not MainFrame.Visible end)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, -20, 0, 60) Header.Position = UDim2.new(0, 10, 0, 10) Header.BackgroundColor3 = Theme.HeaderBg
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8) Instance.new("UIStroke", Header).Color = Theme.Stroke

local BlueLine = Instance.new("Frame", Header) BlueLine.Size = UDim2.new(0, 3, 0, 30) BlueLine.Position = UDim2.new(0, 15, 0, 15) BlueLine.BackgroundColor3 = Theme.Accent Instance.new("UICorner", BlueLine).CornerRadius = UDim.new(1, 0)
table.insert(DynamicUIElements, {Obj = BlueLine, Prop = "BackgroundColor3"})

local WelcomeText = Instance.new("TextLabel", Header) WelcomeText.Size = UDim2.new(0, 150, 0, 15) WelcomeText.Position = UDim2.new(0, 25, 0, 15) WelcomeText.BackgroundTransparency = 1 WelcomeText.Text = "Ultimate Script Hub" WelcomeText.TextColor3 = Theme.TextSub WelcomeText.Font = Enum.Font.Gotham WelcomeText.TextSize = 10 WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
local HubName = Instance.new("TextLabel", Header) HubName.Size = UDim2.new(0, 200, 0, 25) HubName.Position = UDim2.new(0, 25, 0, 25) HubName.BackgroundTransparency = 1 HubName.Text = "Yui HUB V22" HubName.TextColor3 = Theme.Accent HubName.Font = Enum.Font.GothamBold HubName.TextSize = 20 HubName.TextXAlignment = Enum.TextXAlignment.Left
table.insert(DynamicUIElements, {Obj = HubName, Prop = "TextColor3"})

local CloseBtn = Instance.new("TextButton", Header) CloseBtn.Size = UDim2.new(0, 30, 0, 30) CloseBtn.Position = UDim2.new(1, -35, 0, 15) CloseBtn.BackgroundTransparency = 1 CloseBtn.Text = "✕" CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80) CloseBtn.Font = Enum.Font.GothamBold CloseBtn.TextSize = 14
BindTap(CloseBtn, function() ScreenGui:Destroy() ESPFolder:Destroy() for _, line in pairs(ESPTracers) do if line then line:Remove() end end end)

local Sidebar = Instance.new("ScrollingFrame", MainFrame)
Sidebar.Size = UDim2.new(0, 130, 1, -85) Sidebar.Position = UDim2.new(0, 10, 0, 75) Sidebar.BackgroundTransparency = 1 Sidebar.ScrollBarThickness = 0
local SidebarLayout = Instance.new("UIListLayout", Sidebar) SidebarLayout.Padding = UDim.new(0, 5)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -155, 1, -85) ContentArea.Position = UDim2.new(0, 145, 0, 75) ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name, isActive)
    local TabBtn = Instance.new("TextButton", Sidebar) TabBtn.Size = UDim2.new(1, 0, 0, 30) TabBtn.BackgroundColor3 = isActive and Theme.BoxBg or Theme.MainBg TabBtn.Text = "  " .. name TabBtn.TextColor3 = isActive and Theme.TextTitle or Theme.TextSub TabBtn.Font = Enum.Font.GothamBold TabBtn.TextSize = 11 TabBtn.TextXAlignment = Enum.TextXAlignment.Left Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    local ActiveLine = Instance.new("Frame", TabBtn) ActiveLine.Size = UDim2.new(0, 3, 0.6, 0) ActiveLine.Position = UDim2.new(0, 0, 0.2, 0) ActiveLine.BackgroundColor3 = Theme.Accent ActiveLine.Visible = isActive Instance.new("UICorner", ActiveLine).CornerRadius = UDim.new(1, 0)
    table.insert(DynamicUIElements, {Obj = ActiveLine, Prop = "BackgroundColor3"})

    local Page = Instance.new("Frame", ContentArea) Page.Size = UDim2.new(1, 0, 1, 0) Page.BackgroundTransparency = 1 Page.Visible = isActive
    local LeftCol = Instance.new("ScrollingFrame", Page) LeftCol.Size = UDim2.new(0.49, 0, 1, 0) LeftCol.BackgroundTransparency = 1 LeftCol.ScrollBarThickness = 2 local LeftLayout = Instance.new("UIListLayout", LeftCol) LeftLayout.Padding = UDim.new(0, 8)
    local RightCol = Instance.new("ScrollingFrame", Page) RightCol.Size = UDim2.new(0.49, 0, 1, 0) RightCol.Position = UDim2.new(0.51, 0, 0, 0) RightCol.BackgroundTransparency = 1 RightCol.ScrollBarThickness = 2 local RightLayout = Instance.new("UIListLayout", RightCol) RightLayout.Padding = UDim.new(0, 8)

    LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftCol.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 10) end)
    RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightCol.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 10) end)

    table.insert(Tabs, {Btn = TabBtn, Line = ActiveLine, Page = Page})
    BindTap(TabBtn, function()
        for _, tab in pairs(Tabs) do tab.Btn.BackgroundColor3 = Theme.MainBg tab.Btn.TextColor3 = Theme.TextSub tab.Line.Visible = false tab.Page.Visible = false end
        TabBtn.BackgroundColor3 = Theme.BoxBg TabBtn.TextColor3 = Theme.TextTitle ActiveLine.Visible = true Page.Visible = true
        for _, dd in ipairs(AllDropdowns) do dd.Visible = false end
    end)
    Sidebar.CanvasSize = UDim2.new(0,0,0, SidebarLayout.AbsoluteContentSize.Y + 10)
    return LeftCol, RightCol
end

local function CreateSection(titleText, parentCol)
    local Box = Instance.new("Frame", parentCol) Box.BackgroundColor3 = Theme.BoxBg Box.Size = UDim2.new(1, 0, 0, 50) Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6) Instance.new("UIStroke", Box).Color = Theme.Stroke
    local Title = Instance.new("TextLabel", Box) Title.Size = UDim2.new(1, -20, 0, 20) Title.Position = UDim2.new(0, 10, 0, 5) Title.BackgroundTransparency = 1 Title.Text = titleText Title.TextColor3 = Theme.Accent Title.Font = Enum.Font.GothamBold Title.TextSize = 10 Title.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(DynamicUIElements, {Obj = Title, Prop = "TextColor3"})
    local Container = Instance.new("Frame", Box) Container.Size = UDim2.new(1, -20, 1, -30) Container.Position = UDim2.new(0, 10, 0, 25) Container.BackgroundTransparency = 1 local Layout = Instance.new("UIListLayout", Container) Layout.Padding = UDim.new(0, 6)
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Box.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 35) end)
    return Container
end

local function CreateToggle(labelText, default, parentBox, callback)
    local Frame = Instance.new("Frame", parentBox) Frame.Size = UDim2.new(1, 0, 0, 26) Frame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Frame) Label.Size = UDim2.new(1, -40, 1, 0) Label.BackgroundTransparency = 1 Label.Text = labelText Label.TextColor3 = Theme.TextTitle Label.Font = Enum.Font.GothamBold Label.TextSize = 10 Label.TextXAlignment = Enum.TextXAlignment.Left
    local Bg = Instance.new("TextButton", Frame) Bg.Size = UDim2.new(0, 32, 0, 16) Bg.Position = UDim2.new(1, -32, 0.5, -8) Bg.BackgroundColor3 = default and Theme.Accent or Theme.MainBg Bg.Text = "" Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0) Instance.new("UIStroke", Bg).Color = Theme.Stroke
    table.insert(DynamicUIElements, {Obj = Bg, Prop = "BackgroundColor3", IsToggle = true})
    local Knob = Instance.new("Frame", Bg) Knob.Size = UDim2.new(0, 12, 0, 12) Knob.Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local isOn = default
    BindTap(Bg, function()
        isOn = not isOn TweenService:Create(Knob, TweenInfo.new(0.2), {Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = isOn and Theme.Accent or Theme.MainBg}):Play() callback(isOn)
    end)
    return function(state)
        isOn = state Knob.Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) Bg.BackgroundColor3 = isOn and Theme.Accent or Theme.MainBg callback(isOn)
    end
end

local function CreateSlider(labelText, min, max, default, parentBox, callback, allowFloat)
    local Frame = Instance.new("Frame", parentBox) Frame.Size = UDim2.new(1, 0, 0, 35) Frame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Frame) Label.Size = UDim2.new(1, 0, 0, 15) Label.BackgroundTransparency = 1 Label.Text = labelText Label.TextColor3 = Theme.TextTitle Label.Font = Enum.Font.GothamBold Label.TextSize = 10 Label.TextXAlignment = Enum.TextXAlignment.Left
    local ValLabel = Instance.new("TextLabel", Frame) ValLabel.Size = UDim2.new(1, 0, 0, 15) ValLabel.BackgroundTransparency = 1 ValLabel.Text = tostring(default) ValLabel.TextColor3 = Theme.TextSub ValLabel.Font = Enum.Font.Gotham ValLabel.TextSize = 10 ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    local Track = Instance.new("Frame", Frame) Track.Size = UDim2.new(1, 0, 0, 4) Track.Position = UDim2.new(0, 0, 0, 22) Track.BackgroundColor3 = Theme.MainBg Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0) Instance.new("UIStroke", Track).Color = Theme.Stroke
    local Fill = Instance.new("Frame", Track) Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0) Fill.BackgroundColor3 = Theme.Accent Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    table.insert(DynamicUIElements, {Obj = Fill, Prop = "BackgroundColor3"})
    local Knob = Instance.new("TextButton", Fill) Knob.Size = UDim2.new(0, 10, 0, 10) Knob.Position = UDim2.new(1, -5, 0.5, -5) Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) Knob.Text = "" Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local drag = false
    local function update(input)
        local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(rel, 0, 1, 0) 
        local val = min + (max - min) * rel if not allowFloat then val = math.floor(val) else val = math.floor(val * 10) / 10 end
        ValLabel.Text = tostring(val) callback(val)
    end
    Knob.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = true end end)
    Track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = true update(inp) end end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end end)
    UserInputService.InputChanged:Connect(function(inp) if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then update(inp) end end)
    return function(val) val = math.clamp(val, min, max) Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0) ValLabel.Text = tostring(val) callback(val) end
end

local function CreateButton(text, parentBox, callback)
    local Btn = Instance.new("TextButton", parentBox) Btn.Size = UDim2.new(1, 0, 0, 24) Btn.BackgroundColor3 = Theme.MainBg Btn.TextColor3 = Theme.TextTitle Btn.Font = Enum.Font.GothamBold Btn.TextSize = 10 Btn.Text = text Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4) Instance.new("UIStroke", Btn).Color = Theme.Stroke
    BindTap(Btn, callback) return Btn
end

local function CreateTextBox(placeholder, parentBox, defaultText, callback)
    local Frame = Instance.new("Frame", parentBox) Frame.Size = UDim2.new(1, 0, 0, 24) Frame.BackgroundTransparency = 1
    local Box = Instance.new("TextBox", Frame) Box.Size = UDim2.new(1, 0, 1, 0) Box.BackgroundColor3 = Theme.MainBg Box.TextColor3 = Theme.TextTitle Box.Font = Enum.Font.Gotham Box.TextSize = 10 Box.PlaceholderText = placeholder Box.Text = defaultText or "" Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4) Instance.new("UIStroke", Box).Color = Theme.Stroke
    Box.FocusLost:Connect(function() callback(Box.Text) end) return function(str) Box.Text = str end
end

local function CreateDropdown(labelStr, defaultStr, parentBox, callback)
    local Frame = Instance.new("Frame", parentBox) Frame.Size = UDim2.new(1, 0, 0, 26) Frame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Frame) Label.Size = UDim2.new(0.4, 0, 1, 0) Label.BackgroundTransparency = 1 Label.Text = labelStr Label.TextColor3 = Theme.TextTitle Label.Font = Enum.Font.GothamBold Label.TextSize = 9 Label.TextXAlignment = Enum.TextXAlignment.Left
    local Btn = Instance.new("TextButton", Frame) Btn.Size = UDim2.new(0.6, 0, 1, 0) Btn.Position = UDim2.new(0.4, 0, 0, 0) Btn.BackgroundColor3 = Theme.MainBg Btn.TextColor3 = Theme.TextSub Btn.Font = Enum.Font.Gotham Btn.TextSize = 9 Btn.Text = defaultStr .. " ▼" Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4) Instance.new("UIStroke", Btn).Color = Theme.Stroke
    
    local FloatFrame = Instance.new("ScrollingFrame", ScreenGui) FloatFrame.Size = UDim2.new(0, 160, 0, 130) FloatFrame.BackgroundColor3 = Theme.HeaderBg FloatFrame.ZIndex = 999 FloatFrame.Visible = false FloatFrame.ScrollBarThickness = 2 Instance.new("UICorner", FloatFrame).CornerRadius = UDim.new(0, 4) 
    local Stroke = Instance.new("UIStroke", FloatFrame) Stroke.Color = Theme.Accent table.insert(DynamicUIElements, {Obj = Stroke, Prop = "Color"})
    local listLayout = Instance.new("UIListLayout", FloatFrame) table.insert(AllDropdowns, FloatFrame)
    RunService.RenderStepped:Connect(function() if FloatFrame.Visible then FloatFrame.Position = UDim2.new(0, Btn.AbsolutePosition.X - (160 - Btn.AbsoluteSize.X), 0, Btn.AbsolutePosition.Y + Btn.AbsoluteSize.Y + 2) end end)

    local isOpen = false
    BindTap(Btn, function() for _, dd in ipairs(AllDropdowns) do if dd~=FloatFrame then dd.Visible = false end end isOpen = not isOpen FloatFrame.Visible = isOpen end)

    local SearchBox = Instance.new("TextBox", FloatFrame) SearchBox.Size = UDim2.new(1, -10, 0, 25) SearchBox.BackgroundColor3 = Theme.MainBg SearchBox.TextColor3 = Theme.TextTitle SearchBox.PlaceholderText = "Search..." SearchBox.Text = "" SearchBox.Font = Enum.Font.Gotham SearchBox.TextSize = 10 Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0,4)
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(SearchBox.Text)
        for _, v in pairs(FloatFrame:GetChildren()) do if v:IsA("TextButton") then if q == "" or string.find(string.lower(v.Text), q) then v.Visible = true else v.Visible = false end end end
    end)

    local function populate(itemList)
        for _, v in pairs(FloatFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local h = 30
        for _, item in ipairs(itemList) do
            local b = Instance.new("TextButton", FloatFrame) b.Size = UDim2.new(1, 0, 0, 25) b.BackgroundColor3 = Theme.HeaderBg b.TextColor3 = Theme.TextTitle b.Text = "  " .. item b.Font = Enum.Font.Gotham b.TextSize = 9 b.TextXAlignment = Enum.TextXAlignment.Left b.ZIndex = 1000
            h = h + 25
            BindTap(b, function() Btn.Text = item .. " ▼" isOpen = false FloatFrame.Visible = false callback(item) end)
        end
        FloatFrame.CanvasSize = UDim2.new(0, 0, 0, h)
    end
    local function setText(str) Btn.Text = str .. " ▼" end return populate, setText
end

local function CreateMultiDropdown(labelStr, parentBox, globalList)
    local Frame = Instance.new("Frame", parentBox) Frame.Size = UDim2.new(1, 0, 0, 26) Frame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Frame) Label.Size = UDim2.new(0.4, 0, 1, 0) Label.BackgroundTransparency = 1 Label.Text = labelStr Label.TextColor3 = Theme.TextTitle Label.Font = Enum.Font.GothamBold Label.TextSize = 9 Label.TextXAlignment = Enum.TextXAlignment.Left
    local Btn = Instance.new("TextButton", Frame) Btn.Size = UDim2.new(0.6, 0, 1, 0) Btn.Position = UDim2.new(0.4, 0, 0, 0) Btn.BackgroundColor3 = Theme.MainBg Btn.TextColor3 = Theme.TextSub Btn.Font = Enum.Font.Gotham Btn.TextSize = 9 Btn.Text = "Select Multi ▼" Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4) Instance.new("UIStroke", Btn).Color = Theme.Stroke
    
    local FloatFrame = Instance.new("ScrollingFrame", ScreenGui) FloatFrame.Size = UDim2.new(0, 160, 0, 150) FloatFrame.BackgroundColor3 = Theme.HeaderBg FloatFrame.ZIndex = 999 FloatFrame.Visible = false FloatFrame.ScrollBarThickness = 2 Instance.new("UICorner", FloatFrame).CornerRadius = UDim.new(0, 4) 
    local Stroke = Instance.new("UIStroke", FloatFrame) Stroke.Color = Theme.Accent table.insert(DynamicUIElements, {Obj = Stroke, Prop = "Color"})
    local listLayout = Instance.new("UIListLayout", FloatFrame) table.insert(AllDropdowns, FloatFrame)
    RunService.RenderStepped:Connect(function() if FloatFrame.Visible then FloatFrame.Position = UDim2.new(0, Btn.AbsolutePosition.X - (160 - Btn.AbsoluteSize.X), 0, Btn.AbsolutePosition.Y + Btn.AbsoluteSize.Y + 2) end end)

    local isOpen = false
    BindTap(Btn, function() for _, dd in ipairs(AllDropdowns) do if dd~=FloatFrame then dd.Visible = false end end isOpen = not isOpen FloatFrame.Visible = isOpen end)

    local SearchBox = Instance.new("TextBox", FloatFrame) SearchBox.Size = UDim2.new(1, -10, 0, 25) SearchBox.BackgroundColor3 = Theme.MainBg SearchBox.TextColor3 = Theme.TextTitle SearchBox.PlaceholderText = "Search..." SearchBox.Text = "" SearchBox.Font = Enum.Font.Gotham SearchBox.TextSize = 10 Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0,4)
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(SearchBox.Text)
        for _, v in pairs(FloatFrame:GetChildren()) do if v:IsA("TextButton") then if q == "" or string.find(string.lower(v.Text), q) then v.Visible = true else v.Visible = false end end end
    end)

    local function populate(itemList)
        for _, v in pairs(FloatFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local h = 30
        for _, item in ipairs(itemList) do
            local isSelected = globalList[item]
            local b = Instance.new("TextButton", FloatFrame) b.Size = UDim2.new(1, 0, 0, 25) b.BackgroundColor3 = Theme.HeaderBg 
            b.TextColor3 = isSelected and Theme.SelectedGreen or Theme.TextTitle 
            b.Text = "  " .. item b.Font = Enum.Font.GothamBold b.TextSize = 9 b.TextXAlignment = Enum.TextXAlignment.Left b.ZIndex = 1000
            h = h + 25
            BindTap(b, function() globalList[item] = not globalList[item] b.TextColor3 = globalList[item] and Theme.SelectedGreen or Theme.TextTitle end)
        end
        FloatFrame.CanvasSize = UDim2.new(0, 0, 0, h)
    end
    return populate
end

local function UpdateThemeColor(colName)
    if ThemeColors[colName] then
        _G.Yui.ThemeColor = colName Theme.Accent = ThemeColors[colName]
        for _, item in pairs(DynamicUIElements) do
            if item.IsToggle then if item.Obj.BackgroundColor3 ~= Theme.MainBg then item.Obj[item.Prop] = Theme.Accent end
            else item.Obj[item.Prop] = Theme.Accent end
        end
    end
end

-- ============================
-- MENU TABS
-- ============================
local MainL, MainR = CreateTab("Main Farm", true)
local QuestL, QuestR = CreateTab("Quests", false)
local SkillL, SkillR = CreateTab("Skills & Haki", false)
local ResL, ResR = CreateTab("Resources", false)
local PlayerL, PlayerR = CreateTab("Player", false)
local BountyL, BountyR = CreateTab("Bounty & PvP", false)
local FishL, FishR = CreateTab("Fish & Teleport", false)
local ServerL, ServerR = CreateTab("Server & FPS", false)
local SetL, SetR = CreateTab("Settings", false)

local Setters = {}

-- MAIN FARM
local FarmSetBox = CreateSection("Farming Mechanics", MainL)
local UpdateMoveDrop, SetMoveDrop = CreateDropdown("Move Method", _G.Yui.MoveMethod, FarmSetBox, function(v) _G.Yui.MoveMethod = v end)
UpdateMoveDrop({"Teleport", "Fly (Tween)"})
Setters.MoveSpeed = CreateSlider("Move Speed", 50, 500, _G.Yui.MoveSpeed, FarmSetBox, function(v) _G.Yui.MoveSpeed = v end)
Setters.HoverOnKill = CreateToggle("Hover In Air On Kill", _G.Yui.HoverOnKill, FarmSetBox, function(v) _G.Yui.HoverOnKill = v end)

local FarmMobBox = CreateSection("Farming Mobs", MainR)
Setters.AutoSpawn = CreateToggle("Auto Spawn", false, FarmMobBox, function(v) _G.Yui.AutoSpawn = v end)
local UpdateMultiMob = CreateMultiDropdown("Select Mobs", FarmMobBox, _G.Yui.SelectedMobs)
CreateButton("Refresh Mobs (Level Only)", FarmMobBox, function()
    local temp, list = {}, {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and obj:FindFirstChild("HumanoidRootPart") then
                local rawName = string.lower(obj.Name)
                if string.find(rawName, "lv") or string.find(rawName, "level") then
                    local cleanName = string.gsub(obj.Name, "%[.-%]", "") cleanName = string.gsub(cleanName, "%d+$", "") cleanName = string.match(cleanName, "^%s*(.-)%s*$") or cleanName
                    if cleanName ~= "" and obj.Parent and not string.find(string.lower(obj.Parent.Name), "quest") then
                        if not temp[cleanName] then temp[cleanName] = true table.insert(list, cleanName) end
                    end
                end
            end
        end
    end
    table.sort(list) UpdateMultiMob(list)
end)
Setters.AutoFarm = CreateToggle("Auto Farm Mobs", false, FarmMobBox, function(v) _G.Yui.AutoFarm = v end)

local AtkBox = CreateSection("Attack Setting", MainL)
local UpdateWepDrop, SetWepDrop = CreateDropdown("Weapon", "None", AtkBox, function(v) _G.Yui.SelectedWeapon = v end)
CreateButton("Refresh Weapons", AtkBox, function()
    local t = {"None"} 
    for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do if v:IsA("Tool") then table.insert(t, v.Name) end end
    for _, v in pairs(LocalPlayer.Character:GetChildren()) do if v:IsA("Tool") then table.insert(t, v.Name) end end
    UpdateWepDrop(t)
end)
Setters.AutoClick = CreateToggle("Auto Mouse Click", false, AtkBox, function(v) _G.Yui.AutoClick = v end)
Setters.FastAttack = CreateToggle("Auto Fast Attack (Silent)", false, AtkBox, function(v) _G.Yui.FastAttack = v end)

local ConfigBox = CreateSection("Attack Position", MainR)
local UpdatePosDropdown, SetPosDrop = CreateDropdown("Position", "Above", ConfigBox, function(v) _G.Yui.AttackPos = v end)
UpdatePosDropdown({"Above", "Below", "Behind", "Front"})
Setters.AttackDist = CreateSlider("Distance", 1, 25, 5, ConfigBox, function(v) _G.Yui.AttackDist = v end)

-- QUEST
local QuestBox = CreateSection("Normal Quest", QuestL)
Setters.AutoNormalQuest = CreateToggle("Auto Normal Quest", false, QuestBox, function(v) _G.Yui.AutoNormalQuest = v end)
local UpdateNormalDrop, SetNormalDrop = CreateDropdown("Target NPC", "None", QuestBox, function(v) _G.Yui.SelectedNormalQuest = v end)

local DailyBox = CreateSection("Daily Quest", QuestR)
Setters.AutoDailyQuest = CreateToggle("Auto Daily Quest", false, DailyBox, function(v) _G.Yui.AutoDailyQuest = v end)
local UpdateDailyDrop, SetDailyDrop = CreateDropdown("Target Daily NPC", "None", DailyBox, function(v) _G.Yui.SelectedDailyQuest = v end)

Setters.AutoAcceptQuest = CreateToggle("Auto Accept Any Quest GUI", false, QuestL, function(v) _G.Yui.AutoAcceptQuest = v end)

CreateButton("Refresh All Quests", QuestL, function() 
    local nList, dList, tempN, tempD = {}, {}, {}, {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local pN, oN = string.lower(obj.Parent and obj.Parent.Name or ""), string.lower(obj.Name)
            if string.find(pN, "quest") or string.find(oN, "quest") then
                if not tempN[obj.Name] then tempN[obj.Name] = true table.insert(nList, obj.Name) end
            elseif string.find(pN, "daily") or string.find(oN, "daily") then
                if not tempD[obj.Name] then tempD[obj.Name] = true table.insert(dList, obj.Name) end
            end
        end
    end
    table.sort(nList) table.sort(dList)
    UpdateNormalDrop(nList) UpdateDailyDrop(dList)
end)

-- SKILLS & HAKI
local WepSkillBox = CreateSection("Normal Skills", SkillL)
Setters.SkillR = CreateToggle("Auto Skill [R]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.R = v end) 
Setters.SkillZ = CreateToggle("Auto Skill [Z]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.Z = v end) 
Setters.SkillX = CreateToggle("Auto Skill [X]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.X = v end) 
Setters.SkillC = CreateToggle("Auto Skill [C]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.C = v end) 
Setters.SkillV = CreateToggle("Auto Skill [V]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.V = v end) 
Setters.SkillB = CreateToggle("Auto Skill [B]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.B = v end) 
Setters.SkillN = CreateToggle("Auto Skill [N]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.N = v end) 
Setters.SkillF = CreateToggle("Auto Skill [F]", false, WepSkillBox, function(v) _G.Yui.AutoSkill.F = v end) 

local HoldSkillBox = CreateSection("Hold Skills", SkillR)
Setters.HoldTime = CreateSlider("Hold Time (s)", 1, 5, 1, HoldSkillBox, function(v) _G.Yui.HoldTime = v end)
Setters.HoldR = CreateToggle("Hold Skill [R]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.R = v end) 
Setters.HoldZ = CreateToggle("Hold Skill [Z]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.Z = v end) 
Setters.HoldX = CreateToggle("Hold Skill [X]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.X = v end) 
Setters.HoldC = CreateToggle("Hold Skill [C]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.C = v end) 
Setters.HoldV = CreateToggle("Hold Skill [V]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.V = v end) 
Setters.HoldB = CreateToggle("Hold Skill [B]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.B = v end) 
Setters.HoldN = CreateToggle("Hold Skill [N]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.N = v end) 
Setters.HoldF = CreateToggle("Hold Skill [F]", false, HoldSkillBox, function(v) _G.Yui.HoldSkill.F = v end) 

local HakiBox = CreateSection("Auto Haki", SkillL)
Setters.HakiE = CreateToggle("Armament Haki [E]", false, HakiBox, function(v) _G.Yui.AutoHaki.E = v end)
Setters.HakiR = CreateToggle("Observation Haki [R]", false, HakiBox, function(v) _G.Yui.AutoHaki.R = v end)
Setters.HakiT = CreateToggle("Conqueror Haki [T] (Spam)", false, HakiBox, function(v) _G.Yui.AutoHaki.T = v end)

-- RESOURCES
local SkyBaseBox = CreateSection("Fast Map Sweeper", ResL)
Setters.CamUnderground = CreateToggle("Hide Camera Underground", false, SkyBaseBox, function(v) _G.Yui.CamUnderground = v end)
Setters.CollectSpeed = CreateSlider("Sweep Delay (s)", 0.1, 2, 0.2, SkyBaseBox, function(v) _G.Yui.CollectSpeed = v end, true)
Setters.CollectChest = CreateToggle("Auto Chests (Wiggle Mode)", false, SkyBaseBox, function(v) _G.Yui.CollectChest = v end)
Setters.CollectBarrel = CreateToggle("Auto Barrels/Crates", false, SkyBaseBox, function(v) _G.Yui.CollectBarrel = v end)

local FruitBox = CreateSection("Auto Fruit", ResL)
Setters.AutoFruit = CreateToggle("Auto Collect Dropped Fruit", false, FruitBox, function(v) _G.Yui.AutoFruit = v end)

local JuiceBox = CreateSection("Juice & Drinks", ResR)
Setters.AutoJuice = CreateToggle("Auto Make Juice", false, JuiceBox, function(v) _G.Yui.AutoJuice = v end)
Setters.JuiceDelay = CreateSlider("Make Delay (s)", 1, 30, 5, JuiceBox, function(v) _G.Yui.JuiceDelay = v end)
Setters.AutoDrink = CreateToggle("Auto Drink All", false, JuiceBox, function(v) _G.Yui.AutoDrink = v end)
Setters.DrinkDelay = CreateSlider("Drink Delay (s)", 1, 10, 1, JuiceBox, function(v) _G.Yui.DrinkDelay = v end)

local AppleBox = CreateSection("Auto Golden Apple", ResR)
Setters.AutoEatApple = CreateToggle("Auto Eat All Apples", false, AppleBox, function(v) _G.Yui.AutoEatApple = v end)
Setters.AppleDelay = CreateSlider("Eat Delay (s)", 1, 10, 3, AppleBox, function(v) _G.Yui.AppleDelay = v end)

-- PLAYER
local MoveBox = CreateSection("Movement", PlayerL)
Setters.FlySpeed = CreateSlider("Fly Speed", 10, 300, 50, MoveBox, function(v) _G.Yui.FlySpeed = v end)
Setters.EnableWS = CreateToggle("WalkSpeed", false, MoveBox, function(v) _G.Yui.EnableWS = v end)
Setters.WalkSpeed = CreateSlider("Speed", 16, 300, 100, MoveBox, function(v) _G.Yui.WalkSpeed = v end)
Setters.EnableJP = CreateToggle("JumpPower", false, MoveBox, function(v) _G.Yui.EnableJP = v end)
Setters.JumpPower = CreateSlider("Power", 50, 500, 100, MoveBox, function(v) _G.Yui.JumpPower = v end)

local ExploitBox = CreateSection("Exploits", PlayerR)
Setters.InfJump = CreateToggle("Infinite Jump", false, ExploitBox, function(v) _G.Yui.InfJump = v end)
Setters.Noclip = CreateToggle("Noclip (Through walls)", false, ExploitBox, function(v) _G.Yui.Noclip = v end)
Setters.WalkOnWater = CreateToggle("Walk On Water", false, ExploitBox, function(v) _G.Yui.WalkOnWater = v end)

-- BOUNTY
local BountyBox = CreateSection("Player Tracker", BountyL)
local UpdatePlayerDrop, SetPlayerDrop = CreateDropdown("Target Player", "None", BountyBox, function(v) _G.Yui.TargetPlayer = v end)
CreateButton("Refresh Players", BountyBox, function()
    local t = {} for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end UpdatePlayerDrop(t)
end)
CreateButton("Teleport to Target", BountyBox, function()
    if _G.Yui.TargetPlayer ~= "None" then
        local p = Players:FindFirstChild(_G.Yui.TargetPlayer)
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then 
            MoveTo(p.Character.HumanoidRootPart.CFrame) 
        end
    end
end)
Setters.Spectate = CreateToggle("Spectate Target", false, BountyBox, function(v) 
    _G.Yui.Spectate = v if not v then workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") end
end)

local HuntBox = CreateSection("Auto Hunt & ESP", BountyR)
Setters.AutoHunt = CreateToggle("Auto Hunt Target (Aimbot)", false, HuntBox, function(v) _G.Yui.AutoHunt = v end)
Setters.HuntDist = CreateSlider("Hunt Distance", 1, 25, 5, HuntBox, function(v) _G.Yui.HuntDist = v end)
Setters.ESPPlayer = CreateToggle("ESP Players (Tracer + Dist)", false, HuntBox, function(v) 
    _G.Yui.ESPPlayer = v 
    if not v then 
        ESPFolder:ClearAllChildren() 
        for _, line in pairs(ESPTracers) do if line then line:Remove() end end
        ESPTracers = {}
    end
end)

-- FISH & TELEPORT
local FishBox = CreateSection("Fishing System", FishL)
Setters.AutoGetRod = CreateToggle("Auto Get Rod", false, FishBox, function(v) _G.Yui.AutoGetRod = v end)
Setters.AutoFish = CreateToggle("Auto Fish", false, FishBox, function(v) _G.Yui.AutoFish = v end)

local TeleBox = CreateSection("Teleports", FishR)
local UpdateIslandDrop, SetIslandDrop = CreateDropdown("Select Island", "None", TeleBox, function(v)
    if _G.Yui.SelectedIslandCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then MoveTo(_G.Yui.SelectedIslandCFrame) end
end)
local UpdateNPCDrop, SetNPCDrop = CreateDropdown("Select NPC", "None", TeleBox, function(v)
    if _G.Yui.SelectedNPCCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then MoveTo(_G.Yui.SelectedNPCCFrame) end
end)
CreateButton("Scan Map & NPCs", TeleBox, function()
    local tIsland, tNPC, iMap, nMap = {}, {}, {}, {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj) then
            if not nMap[obj.Name] then nMap[obj.Name] = obj.HumanoidRootPart.CFrame table.insert(tNPC, obj.Name) end
        end
        if obj:IsA("Model") or obj:IsA("Folder") then
            local pName = string.lower(obj.Name)
            if string.find(pName, "island") or string.find(pName, "town") or string.find(pName, "location") then
                local spawnPart = obj:FindFirstChildWhichIsA("BasePart", true)
                if spawnPart and not iMap[obj.Name] then iMap[obj.Name] = spawnPart.CFrame * CFrame.new(0, 10, 0) table.insert(tIsland, obj.Name) end
            end
        end
    end
    table.sort(tIsland) table.sort(tNPC)
    UpdateIslandDrop = CreateDropdown("Select Island", "None", TeleBox, function(v) if iMap[v] then MoveTo(iMap[v]) end end) UpdateIslandDrop(tIsland)
    UpdateNPCDrop = CreateDropdown("Select NPC", "None", TeleBox, function(v) if nMap[v] then MoveTo(nMap[v] * CFrame.new(0,0,3)) end end) UpdateNPCDrop(tNPC)
end)

local PinBox = CreateSection("Location Pins", FishL)
Setters.AutoPin = CreateToggle("Pin Location", false, PinBox, function(v) 
    _G.Yui.AutoPin = v 
    if v and _G.SelectedSavedCFrame then _G.PinnedCFrame = _G.SelectedSavedCFrame elseif v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then _G.PinnedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame end
end)
CreateButton("Save New Location", PinBox, function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        _G.SavedCount = _G.SavedCount + 1 local locName = "Loc_" .. _G.SavedCount _G.SavedLocations[locName] = char.HumanoidRootPart.CFrame
        local tList = {} for n, _ in pairs(_G.SavedLocations) do table.insert(tList, n) end UpdateSavedDrop(tList)
    end
end)
UpdateSavedDrop = CreateDropdown("Saved Locations", "None", PinBox, function(v) _G.SelectedSavedName = v _G.SelectedSavedCFrame = _G.SavedLocations[v] if _G.Yui.AutoPin then _G.PinnedCFrame = _G.SelectedSavedCFrame end end)
CreateButton("Teleport to Pin", PinBox, function() if _G.SelectedSavedCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then MoveTo(_G.SelectedSavedCFrame) end end)

-- SERVER & FPS
local ServerBox = CreateSection("Server Hopping", ServerL)
CreateButton("Hop Random Server", ServerBox, function()
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(res)
        if data and data.data then local s = data.data[math.random(1, #data.data)] TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end
    end
end)
CreateButton("Hop Low Player Server", ServerBox, function()
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        local res = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(res)
        if data and data.data then for _, v in ipairs(data.data) do if v.playing < v.maxPlayers and v.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer) break end end end
    end
end)
Setters.AutoHopServer = CreateToggle("Auto Hop Server", false, ServerBox, function(v) _G.Yui.AutoHop = v if Setters.AutoHopMain then Setters.AutoHopMain(v) end end)
Setters.HopDelay = CreateSlider("Delay Hop (Min 3s)", 3, 300, 10, ServerBox, function(v) _G.Yui.HopDelay = v end)

local OptBox = CreateSection("Optimization", ServerR)
CreateButton("Boost FPS", OptBox, function()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then v.Material = Enum.Material.SmoothPlastic v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
    end
    game:GetService("Lighting").GlobalShadows = false game:GetService("Lighting").FogEnd = 9e9
end)
CreateButton("Delete Map (Only Terrain)", OptBox, function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") and not v.Parent:FindFirstChild("Humanoid") then
            local n, p = string.lower(v.Name), string.lower(v.Parent.Name)
            if string.find(n, "tree") or string.find(n, "leaf") or string.find(n, "rock") or string.find(n, "wall") or string.find(p, "building") or string.find(p, "house") then
                v.Transparency = 1 v.CanCollide = false
            end
        end
    end
end)

-- SETTINGS
local SysBox = CreateSection("System Core", SetL)
Setters.AntiAFK = CreateToggle("Anti AFK (No Kick)", _G.Yui.AntiAFK, SysBox, function(v) _G.Yui.AntiAFK = v end)
Setters.AutoRejoin = CreateToggle("Auto Rejoin", _G.Yui.AutoRejoin, SysBox, function(v) _G.Yui.AutoRejoin = v SaveCoreSettings() end)
Setters.AutoExecute = CreateToggle("Auto Execute on Rejoin/Hop", _G.Yui.AutoExecute, SysBox, function(v) _G.Yui.AutoExecute = v SaveCoreSettings() end)
CreateTextBox("Paste Loadstring URL Here", SysBox, _G.Yui.ExecuteScript, function(text) _G.Yui.ExecuteScript = text SaveCoreSettings() end)
CreateButton("Reset All Toggles", SysBox, function() for _, func in pairs(Setters) do pcall(function() func(false) end) end end)

local ThemeBox = CreateSection("Theme Customizer", SetL)
local UpdateThemeDrop, SetThemeDrop = CreateDropdown("Color Accent", "Pink", ThemeBox, function(v) UpdateThemeColor(v) end)
UpdateThemeDrop({"Pink", "Red", "Blue", "Green", "Purple", "Orange"})
CreateButton("Save Theme Color", ThemeBox, function() SaveCoreSettings() end)

local ConfigBox2 = CreateSection("Configurations", SetR)
local ConfigInput = CreateTextBox("Enter New Config Name", ConfigBox2, "", function(text) _G.Yui.ConfigName = text end)

local function GetConfigList()
    local list = {}
    if listfiles then for _, file in pairs(listfiles(ConfigFolder)) do table.insert(list, file:gsub(ConfigFolder.."\\", ""):gsub(ConfigFolder.."/", ""):gsub(".json", "")) end end
    local found = false for _, n in ipairs(list) do if n == _G.Yui.ConfigName then found = true break end end
    if not found and _G.Yui.ConfigName ~= "" then table.insert(list, _G.Yui.ConfigName) end
    return list
end

local UpdateConfigDrop, SetConfigDrop = CreateDropdown("Select Config", _G.Yui.ConfigName, ConfigBox2, function(v) _G.Yui.ConfigName = v SaveCoreSettings() end)

CreateButton("Create New Config", ConfigBox2, function()
    if _G.Yui.ConfigName ~= "" and writefile and HttpService then 
        writefile(ConfigFolder .. "/" .. _G.Yui.ConfigName .. ".json", HttpService:JSONEncode(_G.Yui)) 
        UpdateConfigDrop(GetConfigList()) SetConfigDrop(_G.Yui.ConfigName) SaveCoreSettings() ConfigInput("")
    end
end)

CreateButton("Save / Overwrite Selected", ConfigBox2, function()
    if writefile and HttpService and _G.Yui.ConfigName ~= "" then writefile(ConfigFolder .. "/" .. _G.Yui.ConfigName .. ".json", HttpService:JSONEncode(_G.Yui)) UpdateConfigDrop(GetConfigList()) end
end)
CreateButton("Load Selected Config", ConfigBox2, function()
    if readfile and isfile and isfile(ConfigFolder .. "/" .. _G.Yui.ConfigName .. ".json") then
        local data = HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. _G.Yui.ConfigName .. ".json"))
        if data then for k, v in pairs(data) do _G.Yui[k] = v if Setters[k] then pcall(function() Setters[k](v) end) end end end
        if data.ThemeColor then UpdateThemeColor(data.ThemeColor) SetThemeDrop(data.ThemeColor) end
    end
end)

local AutoLoadStatus = Instance.new("TextLabel", ConfigBox2)
AutoLoadStatus.Size = UDim2.new(1, 0, 0, 15) AutoLoadStatus.BackgroundTransparency = 1
AutoLoadStatus.TextColor3 = Theme.SelectedGreen AutoLoadStatus.Font = Enum.Font.Gotham AutoLoadStatus.TextSize = 10
AutoLoadStatus.Text = _G.Yui.AutoLoadConfig and ("Auto Loading: " .. _G.Yui.AutoLoadName) or "Auto Load: OFF"

CreateButton("Set as Auto Load Config", ConfigBox2, function()
    _G.Yui.AutoLoadConfig = true _G.Yui.AutoLoadName = _G.Yui.ConfigName AutoLoadStatus.Text = "Auto Loading: " .. _G.Yui.AutoLoadName SaveCoreSettings()
end)
CreateButton("Remove Auto Load Config", ConfigBox2, function()
    _G.Yui.AutoLoadConfig = false _G.Yui.AutoLoadName = "" AutoLoadStatus.Text = "Auto Load: OFF" SaveCoreSettings()
end)

local function SilentClick(btn)
    if not btn then return end
    pcall(function() firesignal(btn.MouseButton1Click) end) pcall(function() firesignal(btn.Activated) end) pcall(function() for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end)
end

-- =========================================================================
-- [MASTER THREADS] 
-- =========================================================================

UserInputService.JumpRequest:Connect(function()
    if _G.Yui.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end
end)

RunService.Stepped:Connect(function()
    if _G.Yui.Noclip and LocalPlayer.Character then for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
end)

-- Walk On Water (Tạo bệ đỡ vô hình dính dưới chân tự nổi)
local WOWPad = Instance.new("Part")
WOWPad.Size = Vector3.new(5, 1, 5) WOWPad.Transparency = 1 WOWPad.Anchored = true WOWPad.CanCollide = false WOWPad.Parent = Workspace
RunService.Heartbeat:Connect(function()
    if _G.Yui.WalkOnWater and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local state = LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid"):GetState()
        if state == Enum.HumanoidStateType.Swimming then
            WOWPad.Position = root.Position - Vector3.new(0, 3, 0) WOWPad.CanCollide = true root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z) 
        else
            WOWPad.Position = root.Position - Vector3.new(0, 3.5, 0) WOWPad.CanCollide = true
        end
    else WOWPad.Position = Vector3.new(0, 99999, 0) WOWPad.CanCollide = false end
end)

-- ESP TRACERS & BOUNTY
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if _G.Yui.ESPPlayer then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
                local dist = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude) or 0
                local espName = "ESP_"..p.Name
                local bg = ESPFolder:FindFirstChild(espName)
                if not bg then
                    bg = Instance.new("BillboardGui", ESPFolder) bg.Name = espName bg.AlwaysOnTop = true bg.Size = UDim2.new(0, 100, 0, 40) bg.StudsOffset = Vector3.new(0, 2.5, 0)
                    local txt = Instance.new("TextLabel", bg) txt.Size = UDim2.new(1,0,1,0) txt.BackgroundTransparency = 1 txt.TextColor3 = Theme.Accent txt.Font = Enum.Font.GothamBold txt.TextSize = 12 txt.TextStrokeTransparency = 0
                    local hl = Instance.new("Highlight", bg) hl.FillTransparency = 1 hl.OutlineColor = Theme.Accent hl.Adornee = p.Character
                end
                bg.Adornee = p.Character:FindFirstChild("Head")
                bg.TextLabel.Text = p.Name .. " [" .. dist .. "m]"

                if Drawing then
                    if not ESPTracers[p.Name] then ESPTracers[p.Name] = Drawing.new("Line") ESPTracers[p.Name].Thickness = 1.5 ESPTracers[p.Name].Color = Theme.Accent ESPTracers[p.Name].Transparency = 0.8 end
                    local pos, onScreen = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                    if onScreen then ESPTracers[p.Name].From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y) ESPTracers[p.Name].To = Vector2.new(pos.X, pos.Y) ESPTracers[p.Name].Visible = true
                    else ESPTracers[p.Name].Visible = false end
                end
            else
                if ESPFolder:FindFirstChild("ESP_"..p.Name) then ESPFolder:FindFirstChild("ESP_"..p.Name):Destroy() end
                if ESPTracers[p.Name] then ESPTracers[p.Name]:Remove() ESPTracers[p.Name] = nil end
            end
        end
    end
    
    if _G.Yui.Spectate and _G.Yui.TargetPlayer ~= "None" then
        local p = Players:FindFirstChild(_G.Yui.TargetPlayer)
        if p and p.Character and p.Character:FindFirstChild("Humanoid") then cam.CameraSubject = p.Character.Humanoid end
    end
end)

-- CAMERA UNDERGROUND LOCK
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local isCollecting = _G.Yui.CollectChest or _G.Yui.CollectBarrel or _G.Yui.AutoFruit or _G.Yui.AutoJuice
    if _G.Yui.CamUnderground and isCollecting then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then cam.CameraType = Enum.CameraType.Scriptable cam.CFrame = CFrame.new(root.Position - Vector3.new(0, 5000, 0), root.Position - Vector3.new(0, 5001, 0)) end
    else
        if cam.CameraType == Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Custom cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") end
    end
end)

-- AUTO HUNT
task.spawn(function()
    while task.wait() do
        if _G.Yui.AutoHunt and _G.Yui.TargetPlayer ~= "None" then
            local p = Players:FindFirstChild(_G.Yui.TargetPlayer)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local offset = CFrame.new(0, 0, _G.Yui.HuntDist) MoveTo(p.Character.HumanoidRootPart.CFrame * offset)
            end
        end
    end
end)

-- FLASH COLLECTION & AUTO FRUIT
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local didAction = false

        -- [A] AUTO FRUIT
        if _G.Yui.AutoFruit and not didAction then
            local fruits = {}
            for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("Tool") and string.find(string.lower(obj.Name), "fruit") then table.insert(fruits, obj) end end
            for _, f in ipairs(fruits) do
                if not _G.Yui.AutoFruit then break end
                local handle = f:FindFirstChild("Handle") or f:FindFirstChildWhichIsA("BasePart")
                if handle then
                    MoveTo(handle.CFrame)
                    for _, cd in pairs(f:GetDescendants()) do if cd:IsA("ClickDetector") then fireclickdetector(cd, 1) end end
                    task.wait(_G.Yui.CollectSpeed)
                    didAction = true
                end
            end
        end

        -- [B] AUTO JUICE
        if _G.Yui.AutoJuice and not didAction then
            local bowls = {}
            for _, obj in pairs(Workspace:GetDescendants()) do if obj.Name == "JuicingBowl" and (not TimedBlacklist[obj] or tick() - TimedBlacklist[obj] > _G.Yui.JuiceDelay) then table.insert(bowls, obj) end end
            for _, b in ipairs(bowls) do
                if not _G.Yui.AutoJuice then break end
                local tPart = b:FindFirstChild("Bowl") or b:FindFirstChild("Mixer1")
                if tPart and tPart:IsA("BasePart") then
                    MoveTo(tPart.CFrame * CFrame.new(0, 1.5, 0))
                    for i=1, 5 do for _, pName in ipairs({"Bowl", "Mixer1", "Mixer2"}) do local p = b:FindFirstChild(pName) local cd = p and p:FindFirstChildOfClass("ClickDetector") if cd and fireclickdetector then fireclickdetector(cd, 1) end end end
                    TimedBlacklist[b] = tick() task.wait(_G.Yui.CollectSpeed) didAction = true
                end
            end
        end

        -- [C] AUTO CHEST (WIGGLE)
        if _G.Yui.CollectChest and not didAction then
            local chests = {}
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "TreasureChest" and (not TimedBlacklist[obj] or tick() - TimedBlacklist[obj] > _G.Yui.ChestDelay) then
                    local tPart = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
                    if tPart and tPart.Transparency < 1 then table.insert(chests, {Obj = obj, Part = tPart}) end
                end
            end
            for _, c in ipairs(chests) do
                if not _G.Yui.CollectChest then break end
                if c.Part.Transparency == 1 then continue end
                MoveTo(c.Part.CFrame * CFrame.new(0, 1, 0)) task.wait(_G.Yui.CollectSpeed / 2)
                MoveTo(c.Part.CFrame * CFrame.new(1, 1, 0)) -- Wiggle 1 stud
                if firetouchinterest then for i=1,10 do for _, part in ipairs(char:GetChildren()) do if part:IsA("BasePart") then firetouchinterest(part, c.Part, 0) firetouchinterest(part, c.Part, 1) end end end end
                TimedBlacklist[c.Obj] = tick() task.wait(_G.Yui.CollectSpeed / 2) didAction = true
            end
        end

        -- [D] AUTO BARREL
        if _G.Yui.CollectBarrel and not didAction then
            local barrels = {}
            for _, obj in pairs(Workspace:GetDescendants()) do
                if (obj.Name == "Barrel" or obj.Name == "Crate") and (not TimedBlacklist[obj] or tick() - TimedBlacklist[obj] > _G.Yui.BarrelDelay) then
                    local tPart = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
                    local cd = obj:FindFirstChildOfClass("ClickDetector")
                    if tPart and cd and tPart.Transparency < 1 then table.insert(barrels, {Obj = obj, Part = tPart, CD = cd}) end
                end
            end
            for _, b in ipairs(barrels) do
                if not _G.Yui.CollectBarrel then break end
                if b.Part.Transparency == 1 then continue end
                MoveTo(b.Part.CFrame * CFrame.new(0, 2, 0))
                if fireclickdetector then for i=1,5 do fireclickdetector(b.CD, 1) end end
                TimedBlacklist[b.Obj] = tick() task.wait(_G.Yui.CollectSpeed) didAction = true
            end
        end

        if not didAction then task.wait(0.1) end
    end
end)

local LastAttack = tick()

-- FARMING & ATTACK
task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local targetMobName = GetQuestMobName()

        if _G.Yui.AutoFarm and not _G.Yui.AutoHunt then
            pcall(function()
                local shortest = math.huge
                local target = nil

                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Parent and not string.find(string.lower(obj.Parent.Name), "quest") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local cleanName = string.gsub(obj.Name, "%[.-%]", "") cleanName = string.gsub(cleanName, "%d+$", "") cleanName = string.match(cleanName, "^%s*(.-)%s*$") or cleanName
                        if (_G.Yui.SelectedMobs[cleanName] or (targetMobName and string.find(obj.Name, targetMobName, 1, true))) and obj:FindFirstChild("HumanoidRootPart") then
                            local dist = (root.Position - obj.HumanoidRootPart.Position).Magnitude
                            if dist < shortest then shortest = dist target = obj end
                        end
                    end
                end
                
                CurrentTarget = target
                if target and target:FindFirstChild("HumanoidRootPart") then
                    local offset = CFrame.new(0, _G.Yui.AttackDist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    if _G.Yui.AttackPos == "Below" then offset = CFrame.new(0, -_G.Yui.AttackDist, 0) * CFrame.Angles(math.rad(90), 0, 0)
                    elseif _G.Yui.AttackPos == "Behind" then offset = CFrame.new(0, 0, _G.Yui.AttackDist)
                    elseif _G.Yui.AttackPos == "Front" then offset = CFrame.new(0, 0, -_G.Yui.AttackDist) * CFrame.Angles(0, math.rad(180), 0) end
                    
                    MoveTo(target.HumanoidRootPart.CFrame * offset)
                    for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                end
            end)
        else
            CurrentTarget = nil
        end

        local wantsAttack = _G.Yui.AutoClick or _G.Yui.FastAttack or (_G.Yui.AutoFarm and CurrentTarget) or (_G.Yui.AutoHunt and _G.Yui.TargetPlayer ~= "None")
        if wantsAttack and _G.Yui.SelectedWeapon ~= "None" then
            pcall(function()
                local toolToEquip = LocalPlayer.Backpack:FindFirstChild(_G.Yui.SelectedWeapon) or char:FindFirstChild(_G.Yui.SelectedWeapon)
                if toolToEquip and toolToEquip.Parent ~= char then char.Humanoid:EquipTool(toolToEquip) end
                
                local equippedTool = char:FindFirstChildOfClass("Tool")
                if equippedTool and equippedTool.Name == _G.Yui.SelectedWeapon then
                    if _G.Yui.FastAttack then
                        equippedTool:Activate()
                        for _, event in pairs(getconnections(equippedTool.Activated)) do event:Fire() end
                    elseif _G.Yui.AutoClick then
                        equippedTool:Activate()
                        if tick() - LastAttack >= 0.15 then
                            VirtualInputManager:SendMouseButtonEvent(200, 0, 0, true, game, 0)
                            VirtualInputManager:SendMouseButtonEvent(200, 0, 0, false, game, 0)
                            LastAttack = tick()
                        end
                    end
                end
            end)
        end
        
        if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
            for key, isEnabled in pairs(_G.Yui.AutoSkill) do
                if isEnabled then pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game) end) end
            end
        end

        -- HAKI
        if _G.Yui.AutoHaki.E and not HakiStates.E then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) HakiStates.E = true end
        if _G.Yui.AutoHaki.R and not HakiStates.R then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game) HakiStates.R = true end
        if _G.Yui.AutoHaki.T then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end
    end
end)

-- HOLD SKILL LOOP
local LastHoldTicks = {R=0, Z=0, X=0, C=0, V=0, B=0, N=0, F=0}
RunService.Heartbeat:Connect(function()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        for key, active in pairs(_G.Yui.HoldSkill) do
            if active and tick() - LastHoldTicks[key] > (_G.Yui.HoldTime + 0.5) then
                LastHoldTicks[key] = tick()
                task.spawn(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(_G.Yui.HoldTime)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                end)
            end
        end
    end
end)

-- AUTO LẤY CẦN VÀ CÂU CÁ
task.spawn(function()
    local function HandleDialogue(shouldHide)
        local questGui = LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
        if questGui then
            local dialogue = questGui:FindFirstChild("Dialogue")
            if dialogue and dialogue.Visible then
                if shouldHide then pcall(function() dialogue.Position = UDim2.new(5, 0, 5, 0) end) end
                local opts = dialogue:FindFirstChild("Options")
                if opts then
                    local btnNext = opts:FindFirstChild("Next") local btnOption = opts:FindFirstChild("Option") local btnOption2 = opts:FindFirstChild("Option2")
                    if btnNext and btnNext.Visible then SilentClick(btnNext) elseif btnOption and btnOption.Visible then SilentClick(btnOption) elseif btnOption2 and btnOption2.Visible then SilentClick(btnOption2) end
                end
            end
        end
    end

    while task.wait(0.5) do
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hrp = char.HumanoidRootPart
        local backpack = LocalPlayer:FindFirstChild("Backpack")

        if _G.Yui.AutoGetRod then
            local hasRod = false
            if char:FindFirstChildOfClass("Tool") and (string.find(string.lower(char:FindFirstChildOfClass("Tool").Name), "rod") or string.find(string.lower(char:FindFirstChildOfClass("Tool").Name), "fish")) then hasRod = true end
            if backpack then for _, t in pairs(backpack:GetChildren()) do if t:IsA("Tool") and (string.find(string.lower(t.Name), "rod") or string.find(string.lower(t.Name), "fish")) then hasRod = true end end end

            if hasRod then
                _G.Yui.AutoGetRod = false
            else
                local package = char:FindFirstChild("Package") or (backpack and backpack:FindFirstChild("Package"))
                if not package then
                    local fisherman = nil
                    for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("Model") and obj.Name == "Fisherman" and obj:FindFirstChild("HumanoidRootPart") then fisherman = obj break end end
                    if fisherman then
                        MoveTo(fisherman.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                        local cd = fisherman:FindFirstChildOfClass("ClickDetector", true) if cd then fireclickdetector(cd, 0) end HandleDialogue(true)
                    end
                else
                    if package.Parent == backpack then char.Humanoid:EquipTool(package) task.wait(0.5) end
                    VirtualUser:CaptureController() VirtualUser:ClickButton1(Vector2.new(0, 0))

                    local allNPCs = {}
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj) and obj.Name ~= "Fisherman" then table.insert(allNPCs, obj) end
                    end
                    for _, npc in ipairs(allNPCs) do
                        local stillHavePackage = char:FindFirstChild("Package") or (backpack and backpack:FindFirstChild("Package"))
                        if not stillHavePackage then break end
                        MoveTo(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) HandleDialogue(true) task.wait(0.3)
                    end
                end
            end
        end

        if _G.Yui.AutoFish then
            local rod = char:FindFirstChildOfClass("Tool")
            if not rod or not (string.find(string.lower(rod.Name), "rod") or string.find(string.lower(rod.Name), "fish")) then
                if backpack then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        local tName = string.lower(tool.Name)
                        if tool:IsA("Tool") and (string.find(tName, "rod") or string.find(tName, "fish") or string.find(tName, "pole")) then char.Humanoid:EquipTool(tool) rod = tool task.wait(1) break end
                    end
                end
            end
            if rod then
                local myID = tostring(LocalPlayer.UserId)
                local ropeName = "FishingRope_" .. myID
                local isCast = Workspace:FindFirstChild(ropeName, true) ~= nil
                if not isCast then VirtualUser:CaptureController() VirtualUser:ClickButton1(Vector2.new(0, 0)) task.wait(1.5) end
            end
        end
    end
end)

local CoreGuiS = game:GetService("CoreGui")
if CoreGuiS:FindFirstChild("RobloxPromptGui") then
    CoreGuiS.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if _G.Yui.AutoRejoin and child.Name == "ErrorPrompt" then
            task.wait(2)
            local ts = game:GetService("TeleportService")
            if _G.Yui.AutoExecute and queue_on_teleport and _G.Yui.ExecuteScript ~= "" then queue_on_teleport([[loadstring(game:HttpGet("]].._G.Yui.ExecuteScript..[["))()]]) end
            ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end

-- =========================================================================
-- AUTO LOAD CONFIGURATION
-- =========================================================================
task.spawn(function()
    task.wait(1)
    if _G.Yui.AutoLoadConfig and _G.Yui.AutoLoadName ~= "" and isfile and isfile(ConfigFolder .. "/" .. _G.Yui.AutoLoadName .. ".json") then
        local data = HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. _G.Yui.AutoLoadName .. ".json"))
        for k, v in pairs(data) do 
            _G.Yui[k] = v 
            if Setters[k] then pcall(function() Setters[k](v) end) end 
        end
        if data.ThemeColor then UpdateThemeColor(data.ThemeColor) SetThemeDrop(data.ThemeColor) end
    end
end)
