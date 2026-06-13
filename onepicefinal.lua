-- =========================================================================
-- AUTO QUEST & SAM - THANH KÉO (SLIDER), CHẾ ĐỘ GIỚI HẠN & AUTO TELEPORT
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = (gethui and pcall(gethui) and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer

if not pcall(function() local _ = CoreGui.Name end) then CoreGui = player:WaitForChild("PlayerGui") end
for _, gui in pairs(CoreGui:GetChildren()) do if gui.Name == "AutoQuest_Mini" then gui:Destroy() end end

-- ============================
-- BIẾN GLOBAL
-- ============================
_G.AutoNormal = false
_G.AutoDaily = false
_G.AutoSam = false
_G.SelectedNormal = ""
_G.SelectedDaily = ""

_G.ClickDelayMs = 500      -- Đơn vị ms (mặc định 500ms = 0.5s)
_G.QuestLimit = 10         -- Giới hạn số lần nhận
_G.CurrentQuestCount = 0   -- Đếm số lần đã nhận
_G.Mode = "Inf"            -- "Inf" (Vô hạn) hoặc "Limit" (Giới hạn)

local lastActionTime = 0
local function CanAct()
    return (tick() - lastActionTime) >= (_G.ClickDelayMs / 1000)
end
local function RegisterAction()
    lastActionTime = tick()
end

-- ============================
-- HÀM CẢM ỨNG CHUẨN
-- ============================
local function BindTap(element, callback)
    local debounce = false
    element.Activated:Connect(function()
        if not debounce then
            debounce = true callback() task.wait(0.1) debounce = false
        end
    end)
end

-- ============================
-- TẠO MENU UI
-- ============================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoQuest_Mini"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 430) -- Mở rộng tối đa để chứa đủ Sliders và Nút
MainFrame.Position = UDim2.new(0.5, -120, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 170, 255)

-- HEADER & KÉO THẢ
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30) 
Header.Active = true
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local HeaderCover = Instance.new("Frame", Header)
HeaderCover.Size = UDim2.new(1, 0, 0, 5)
HeaderCover.Position = UDim2.new(0, 0, 1, -5)
HeaderCover.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HeaderCover.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO QUEST & SAM PRO"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13

BindTap(CloseBtn, function()
    _G.AutoNormal = false _G.AutoDaily = false _G.AutoSam = false
    ScreenGui:Destroy()
end)

local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateDrag(input) end
end)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", ContentFrame)
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local spacer1 = Instance.new("Frame", ContentFrame) spacer1.Size = UDim2.new(1,0,0,1) spacer1.BackgroundTransparency = 1

-- ============================
-- HÀM TẠO THANH KÉO (SLIDER)
-- ============================
local function CreateSlider(parent, textStr, minVal, maxVal, currentVal, isLimitSlider)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(0.9, 0, 0, 35)
    Frame.BackgroundTransparency = 1

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, 0, 0, 15)
    Label.BackgroundTransparency = 1
    Label.Text = string.format(textStr, currentVal)
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SliderBg = Instance.new("Frame", Frame)
    SliderBg.Size = UDim2.new(1, 0, 0, 14)
    SliderBg.Position = UDim2.new(0, 0, 0, 18)
    SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 4)

    local SliderFill = Instance.new("Frame", SliderBg)
    local pct = (currentVal - minVal) / (maxVal - minVal)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

    local isDragging = false
    local function UpdateSlider(input)
        local posX = math.clamp(input.Position.X - SliderBg.AbsolutePosition.X, 0, SliderBg.AbsoluteSize.X)
        local percent = posX / SliderBg.AbsoluteSize.X
        local val = math.floor(minVal + (maxVal - minVal) * percent)
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        
        if isLimitSlider then
            _G.QuestLimit = val
            Label.Text = string.format(textStr, val) .. " (Đã nhận: " .. _G.CurrentQuestCount .. ")"
        else
            _G.ClickDelayMs = val
            Label.Text = string.format(textStr, val)
        end
    end

    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true UpdateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    return Label
end

-- TẠO 2 THANH KÉO
CreateSlider(ContentFrame, "Tốc độ Delay: %d ms", 0, 5000, _G.ClickDelayMs, false)
local LimitLabel = CreateSlider(ContentFrame, "Giới hạn nhận: %d lần", 1, 500, _G.QuestLimit, true)

-- ============================
-- 2 NÚT CHẾ ĐỘ PHÁT SÁNG
-- ============================
local ModeFrame = Instance.new("Frame", ContentFrame)
ModeFrame.Size = UDim2.new(0.9, 0, 0, 28)
ModeFrame.BackgroundTransparency = 1

local LimitBtn = Instance.new("TextButton", ModeFrame)
LimitBtn.Size = UDim2.new(0.48, 0, 1, 0)
LimitBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LimitBtn.Text = "CHẾ ĐỘ GIỚI HẠN"
LimitBtn.Font = Enum.Font.GothamBold
LimitBtn.TextSize = 10
Instance.new("UICorner", LimitBtn).CornerRadius = UDim.new(0, 4)
local LimitStroke = Instance.new("UIStroke", LimitBtn)
LimitStroke.Thickness = 2

local InfBtn = Instance.new("TextButton", ModeFrame)
InfBtn.Size = UDim2.new(0.48, 0, 1, 0)
InfBtn.Position = UDim2.new(0.52, 0, 0, 0)
InfBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InfBtn.Text = "CHẾ ĐỘ VÔ HẠN"
InfBtn.Font = Enum.Font.GothamBold
InfBtn.TextSize = 10
Instance.new("UICorner", InfBtn).CornerRadius = UDim.new(0, 4)
local InfStroke = Instance.new("UIStroke", InfBtn)
InfStroke.Thickness = 2

local function UpdateModeVisuals()
    if _G.Mode == "Limit" then
        LimitStroke.Color = Color3.fromRGB(0, 255, 255)
        LimitBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
        InfStroke.Color = Color3.fromRGB(50, 50, 50)
        InfBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        InfStroke.Color = Color3.fromRGB(255, 170, 0)
        InfBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
        LimitStroke.Color = Color3.fromRGB(50, 50, 50)
        LimitBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    LimitLabel.Text = "Giới hạn nhận: " .. _G.QuestLimit .. " lần (Đã nhận: " .. _G.CurrentQuestCount .. ")"
end
UpdateModeVisuals()

BindTap(LimitBtn, function() _G.Mode = "Limit" UpdateModeVisuals() end)
BindTap(InfBtn, function() _G.Mode = "Inf" UpdateModeVisuals() end)

-- ============================
-- CÁC NÚT ĐIỀU KHIỂN AUTO
-- ============================
local RefreshBtn = Instance.new("TextButton", ContentFrame)
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 22)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RefreshBtn.Text = "Làm Mới Danh Sách NPC"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

local NormalDropBtn = Instance.new("TextButton", ContentFrame)
NormalDropBtn.Size = UDim2.new(0.9, 0, 0, 22)
NormalDropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NormalDropBtn.Text = "Quest Thường: None ▼"
NormalDropBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
NormalDropBtn.Font = Enum.Font.GothamBold
NormalDropBtn.TextSize = 10
Instance.new("UICorner", NormalDropBtn).CornerRadius = UDim.new(0, 4)

local NormalToggle = Instance.new("TextButton", ContentFrame)
NormalToggle.Size = UDim2.new(0.9, 0, 0, 25)
NormalToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NormalToggle.Text = "Auto Thường [OFF]"
NormalToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NormalToggle.Font = Enum.Font.GothamBold
NormalToggle.TextSize = 11
Instance.new("UICorner", NormalToggle).CornerRadius = UDim.new(0, 4)

local DailyDropBtn = Instance.new("TextButton", ContentFrame)
DailyDropBtn.Size = UDim2.new(0.9, 0, 0, 22)
DailyDropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DailyDropBtn.Text = "Quest Daily: Auto Nhận Tất Cả ▼"
DailyDropBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
DailyDropBtn.Font = Enum.Font.GothamBold
DailyDropBtn.TextSize = 10
Instance.new("UICorner", DailyDropBtn).CornerRadius = UDim.new(0, 4)

local DailyToggle = Instance.new("TextButton", ContentFrame)
DailyToggle.Size = UDim2.new(0.9, 0, 0, 25)
DailyToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DailyToggle.Text = "Auto Daily [OFF]"
DailyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
DailyToggle.Font = Enum.Font.GothamBold
DailyToggle.TextSize = 11
Instance.new("UICorner", DailyToggle).CornerRadius = UDim.new(0, 4)

local SamToggle = Instance.new("TextButton", ContentFrame)
SamToggle.Size = UDim2.new(0.9, 0, 0, 28)
SamToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SamToggle.Text = "Auto NPC Sam [OFF]"
SamToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SamToggle.Font = Enum.Font.GothamBold
SamToggle.TextSize = 11
Instance.new("UICorner", SamToggle).CornerRadius = UDim.new(0, 4)
local SamStroke = Instance.new("UIStroke", SamToggle)
SamStroke.Color = Color3.fromRGB(255, 85, 255)
SamStroke.Thickness = 1

local function CreateDropScroll(parentBtn)
    local Scroll = Instance.new("ScrollingFrame", ScreenGui)
    Scroll.Size = UDim2.new(0, 198, 0, 150)
    Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Scroll.Visible = false
    Scroll.ZIndex = 10
    Scroll.Active = true
    Scroll.ScrollBarThickness = 3
    Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Scroll).Color = Color3.fromRGB(0, 170, 255)
    Instance.new("UIListLayout", Scroll)

    game:GetService("RunService").RenderStepped:Connect(function()
        if Scroll.Visible then
            Scroll.Position = UDim2.new(0, parentBtn.AbsolutePosition.X, 0, parentBtn.AbsolutePosition.Y + parentBtn.AbsoluteSize.Y + 2)
        end
    end)
    return Scroll
end
local NormalScroll = CreateDropScroll(NormalDropBtn)
local DailyScroll = CreateDropScroll(DailyDropBtn)

BindTap(RefreshBtn, function()
    local tempN, tempD = {}, {}
    local listNormal, listDaily = {}, {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Parent then
            local pName = string.lower(obj.Parent.Name)
            if string.find(pName, "quest") then
                if string.find(pName, "daily") then
                    if not tempD[obj.Name] then tempD[obj.Name] = true table.insert(listDaily, obj.Name) end
                else
                    if not tempN[obj.Name] then tempN[obj.Name] = true table.insert(listNormal, obj.Name) end
                end
            end
        end
    end
    table.sort(listNormal) table.sort(listDaily)
    
    for _, child in pairs(NormalScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, child in pairs(DailyScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    
    local hn = 0
    for _, qName in ipairs(listNormal) do
        local btn = Instance.new("TextButton", NormalScroll)
        btn.Size = UDim2.new(1, 0, 0, 30) btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = "  " .. qName btn.Font = Enum.Font.Gotham btn.TextSize = 11 btn.TextXAlignment = Enum.TextXAlignment.Left btn.ZIndex = 11
        hn = hn + 30
        BindTap(btn, function() _G.SelectedNormal = qName NormalDropBtn.Text = "Thường: " .. qName .. " ▼" NormalScroll.Visible = false end)
    end
    NormalScroll.CanvasSize = UDim2.new(0, 0, 0, hn)
    
    local hd = 0
    local autoAllBtn = Instance.new("TextButton", DailyScroll)
    autoAllBtn.Size = UDim2.new(1, 0, 0, 30) autoAllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 35) autoAllBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    autoAllBtn.Text = "  [Tự Nhận Tất Cả]" autoAllBtn.Font = Enum.Font.GothamBold autoAllBtn.TextSize = 11 autoAllBtn.TextXAlignment = Enum.TextXAlignment.Left autoAllBtn.ZIndex = 11
    hd = hd + 30
    BindTap(autoAllBtn, function() _G.SelectedDaily = "" DailyDropBtn.Text = "Daily: Auto Nhận Tất Cả ▼" DailyScroll.Visible = false end)

    for _, qName in ipairs(listDaily) do
        local btn = Instance.new("TextButton", DailyScroll)
        btn.Size = UDim2.new(1, 0, 0, 30) btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = "  " .. qName btn.Font = Enum.Font.Gotham btn.TextSize = 11 btn.TextXAlignment = Enum.TextXAlignment.Left btn.ZIndex = 11
        hd = hd + 30
        BindTap(btn, function() _G.SelectedDaily = qName DailyDropBtn.Text = "Daily: " .. qName .. " ▼" DailyScroll.Visible = false end)
    end
    DailyScroll.CanvasSize = UDim2.new(0, 0, 0, hd)
end)

BindTap(NormalDropBtn, function() NormalScroll.Visible = not NormalScroll.Visible DailyScroll.Visible = false end)
BindTap(DailyDropBtn, function() DailyScroll.Visible = not DailyScroll.Visible NormalScroll.Visible = false end)

BindTap(NormalToggle, function()
    _G.AutoNormal = not _G.AutoNormal
    NormalToggle.BackgroundColor3 = _G.AutoNormal and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(40, 40, 40)
    NormalToggle.Text = "Auto Thường " .. (_G.AutoNormal and "[ON]" or "[OFF]")
end)
BindTap(DailyToggle, function()
    _G.AutoDaily = not _G.AutoDaily
    DailyToggle.BackgroundColor3 = _G.AutoDaily and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(40, 40, 40)
    DailyToggle.Text = "Auto Daily " .. (_G.AutoDaily and "[ON]" or "[OFF]")
end)
BindTap(SamToggle, function()
    _G.AutoSam = not _G.AutoSam
    SamToggle.BackgroundColor3 = _G.AutoSam and Color3.fromRGB(255, 85, 255) or Color3.fromRGB(40, 40, 40)
    SamToggle.Text = "Auto NPC Sam " .. (_G.AutoSam and "[ON]" or "[OFF]")
end)

-- ============================
-- HÀM XỬ LÝ NHẬP NÚT & LOGIC GIỚI HẠN
-- ============================
local function HasActiveQuest()
    local questGui = player.PlayerGui:FindFirstChild("QuestGui")
    if questGui then
        local qFrame = questGui:FindFirstChild("QuestsFrame")
        if qFrame and qFrame.Visible then
            local scroll = qFrame:FindFirstChild("QuestsScroll")
            if scroll and scroll:FindFirstChild("QuestName") and scroll.QuestName.Text ~= "" then
                return true
            end
        end
    end
    return false
end

local function PassiveClick(btn)
    if not btn then return end
    pcall(function() firesignal(btn.MouseButton1Click) end)
    pcall(function() firesignal(btn.Activated) end)
    pcall(function() for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end)
end

local function IncrementQuestLimit()
    if _G.Mode == "Limit" then
        _G.CurrentQuestCount = _G.CurrentQuestCount + 1
        UpdateModeVisuals()

        if _G.CurrentQuestCount >= _G.QuestLimit then
            -- Tắt toàn bộ Auto khi đủ giới hạn
            _G.AutoSam = false 
            SamToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SamToggle.Text = "Auto NPC Sam [OFF]"
            
            _G.AutoDaily = false
            DailyToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            DailyToggle.Text = "Auto Daily [OFF]"
            
            _G.AutoNormal = false
            NormalToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            NormalToggle.Text = "Auto Thường [OFF]"
            
            _G.CurrentQuestCount = 0 -- Trả lại 0 cho lần chạy sau
            UpdateModeVisuals()
        end
    end
end

-- ============================
-- VÒNG LẶP AUTO CHÍNH
-- ============================
task.spawn(function()
    while task.wait(0.1) do
        local questGui = player.PlayerGui:FindFirstChild("QuestGui")
        if not questGui then continue end
        local dialogue = questGui:FindFirstChild("Dialogue")
        
        if not (_G.AutoNormal or _G.AutoDaily or _G.AutoSam) then continue end

        -- 1. BẢNG THOẠI ĐANG MỞ
        if dialogue and dialogue.Visible then
            local opts = dialogue:FindFirstChild("Options")
            if opts and CanAct() then 
                local btnNext = opts:FindFirstChild("Next")
                local btnOption = opts:FindFirstChild("Option")  
                local btnOption2 = opts:FindFirstChild("Option2") 
                local btnLeave = opts:FindFirstChild("Leave")

                if _G.AutoSam then
                    if btnOption and btnOption.Visible then 
                        PassiveClick(btnOption)
                        RegisterAction()
                        IncrementQuestLimit() -- Tăng biến đếm khi click Option thành công
                    elseif btnNext and btnNext.Visible then 
                        PassiveClick(btnNext)
                        RegisterAction()
                    end
                else
                    if btnNext and btnNext.Visible then 
                        PassiveClick(btnNext) RegisterAction()
                    elseif btnOption and btnOption.Visible then 
                        PassiveClick(btnOption) RegisterAction() IncrementQuestLimit()
                    elseif btnOption2 and btnOption2.Visible then 
                        PassiveClick(btnOption2) RegisterAction() IncrementQuestLimit()
                    elseif btnLeave and btnLeave.Visible then 
                        PassiveClick(btnLeave) RegisterAction() 
                    end
                end
            end
            continue 
        end

        -- 2. NHẬN NPC TỪ XA & TỰ ĐỘNG TELEPORT (SAM)
        if not HasActiveQuest() and CanAct() then 
            local hasClickedNPC = false

            if _G.AutoSam then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name == "Sam" and obj:IsA("Model") and obj.Parent then
                        local pName = string.lower(obj.Parent.Name)
                        if string.find(pName, "quest") then
                            local root = obj:FindFirstChild("HumanoidRootPart")
                            if root then
                                -- TỰ ĐỘNG TELEPORT ĐẾN SAM
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    player.Character.HumanoidRootPart.CFrame = root.CFrame
                                end

                                local cd = root:FindFirstChildOfClass("ClickDetector")
                                if cd and fireclickdetector then 
                                    fireclickdetector(cd, 0) 
                                    RegisterAction()
                                    hasClickedNPC = true
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if hasClickedNPC then continue end

            if _G.AutoDaily then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Parent then
                        local pName = string.lower(obj.Parent.Name)
                        if string.find(pName, "quest") and string.find(pName, "daily") then
                            if _G.SelectedDaily == "" or _G.SelectedDaily == obj.Name then
                                local root = obj:FindFirstChild("HumanoidRootPart")
                                if root then
                                    local cd = root:FindFirstChildOfClass("ClickDetector")
                                    if cd and fireclickdetector then 
                                        fireclickdetector(cd, 0) 
                                        RegisterAction()
                                        hasClickedNPC = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if hasClickedNPC then continue end

            if _G.AutoNormal and _G.SelectedNormal ~= "" then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name == _G.SelectedNormal and obj:IsA("Model") and obj.Parent then
                        local pName = string.lower(obj.Parent.Name)
                        if string.find(pName, "quest") and not string.find(pName, "daily") then
                            local root = obj:FindFirstChild("HumanoidRootPart")
                            if root then
                                local cd = root:FindFirstChildOfClass("ClickDetector")
                                if cd and fireclickdetector then 
                                    fireclickdetector(cd, 0) 
                                    RegisterAction()
                                end
                            end
                            break 
                        end
                    end
                end
            end
        end
    end
end)
