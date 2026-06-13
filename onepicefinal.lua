-- =========================================================================
-- AUTO QUEST & SAM - TELEPORT NPC & KÉO THẢ TOÀN MENU
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = (gethui and pcall(gethui) and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer

if not pcall(function() local _ = CoreGui.Name end) then CoreGui = player:WaitForChild("PlayerGui") end
for _, gui in pairs(CoreGui:GetChildren()) do if gui.Name == "AutoQuest_Mini" then gui:Destroy() end end

-- Biến Global Tách Biệt
_G.AutoNormal = false
_G.AutoDaily = false
_G.AutoSam = false
_G.SelectedNormal = ""
_G.SelectedDaily = ""
_G.ClickDelay = 1 

-- ============================
-- 1. HÀM CẢM ỨNG CHUẨN MOBILE
-- ============================
local function BindTap(element, callback)
    local debounce = false
    element.Activated:Connect(function()
        if not debounce then
            debounce = true
            callback()
            task.wait(0.1)
            debounce = false
        end
    end)
end

-- ============================
-- 2. TẠO MENU MINI (CÓ TELEPORT VÀ KÉO THẢ MỌI NƠI)
-- ============================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoQuest_Mini"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 230, 0, 340) -- Đã nới rộng thêm cho nút Teleport
MainFrame.Position = UDim2.new(0.5, -115, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 170, 255)

-- Thanh Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO QUEST & SAM"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

-- NÚT X ĐÓNG MENU
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13

BindTap(CloseBtn, function()
    _G.AutoNormal = false
    _G.AutoDaily = false
    _G.AutoSam = false
    ScreenGui:Destroy()
end)

-- NÂNG CẤP: KÉO THẢ TOÀN BỘ KHUNG (Bấm vào vùng đen nào cũng kéo được)
local dragToggle, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        local Delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
    end
end)

-- Khung chứa Nút
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", ContentFrame)
Layout.Padding = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local paddingSpacer = Instance.new("Frame", ContentFrame)
paddingSpacer.Size = UDim2.new(1, 0, 0, 2)
paddingSpacer.BackgroundTransparency = 1

-- NÚT DỊCH CHUYỂN
local TeleportBtn = Instance.new("TextButton", ContentFrame)
TeleportBtn.Size = UDim2.new(0.9, 0, 0, 25)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
TeleportBtn.Text = "✈ Dịch Chuyển Đến NPC"
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.TextSize = 11
Instance.new("UICorner", TeleportBtn).CornerRadius = UDim.new(0, 4)

-- KHUNG CHỈNH DELAY
local DelayFrame = Instance.new("Frame", ContentFrame)
DelayFrame.Size = UDim2.new(0.9, 0, 0, 25)
DelayFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", DelayFrame).CornerRadius = UDim.new(0, 4)

local DelayLabel = Instance.new("TextLabel", DelayFrame)
DelayLabel.Size = UDim2.new(0.65, 0, 1, 0)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Delay Bấm (giây):"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayLabel.Font = Enum.Font.GothamBold
DelayLabel.TextSize = 10

local DelayInput = Instance.new("TextBox", DelayFrame)
DelayInput.Size = UDim2.new(0.35, 0, 1, 0)
DelayInput.Position = UDim2.new(0.65, 0, 0, 0)
DelayInput.BackgroundTransparency = 1
DelayInput.Text = tostring(_G.ClickDelay)
DelayInput.TextColor3 = Color3.fromRGB(0, 255, 150)
DelayInput.Font = Enum.Font.GothamBold
DelayInput.TextSize = 11

DelayInput.FocusLost:Connect(function()
    local val = tonumber(DelayInput.Text)
    if val and val >= 0 then
        _G.ClickDelay = val
    else
        DelayInput.Text = tostring(_G.ClickDelay)
    end
end)

-- NÚT LÀM MỚI
local RefreshBtn = Instance.new("TextButton", ContentFrame)
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 25)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RefreshBtn.Text = "Làm Mới Danh Sách"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

-- NÚT QUEST THƯỜNG
local NormalDropBtn = Instance.new("TextButton", ContentFrame)
NormalDropBtn.Size = UDim2.new(0.9, 0, 0, 25)
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

-- NÚT QUEST DAILY
local DailyDropBtn = Instance.new("TextButton", ContentFrame)
DailyDropBtn.Size = UDim2.new(0.9, 0, 0, 25)
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

-- NÚT DÀNH RIÊNG CHO SAM
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

-- HÀM TẠO SCROLLING FRAME
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

-- ============================
-- 3. XỬ LÝ SỰ KIỆN MENU
-- ============================

-- LOGIC DỊCH CHUYỂN
BindTap(TeleportBtn, function()
    local targetName = ""
    if _G.AutoSam then 
        targetName = "Sam"
    elseif _G.SelectedDaily ~= "" then 
        targetName = _G.SelectedDaily
    elseif _G.SelectedNormal ~= "" then 
        targetName = _G.SelectedNormal
    end

    if targetName ~= "" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == targetName and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                if obj.Parent and string.find(string.lower(obj.Parent.Name), "quest") then
                    player.Character.HumanoidRootPart.CFrame = obj.HumanoidRootPart.CFrame
                    break
                end
            end
        end
    end
end)

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
-- 4. BỘ NÃO NHẬN QUEST TỰ ĐỘNG
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

task.spawn(function()
    while true do
        task.wait(_G.ClickDelay)
        
        local questGui = player.PlayerGui:FindFirstChild("QuestGui")
        if not questGui then continue end
        local dialogue = questGui:FindFirstChild("Dialogue")
        
        -- NHẬN TỪ XA
        if not HasActiveQuest() and (not dialogue or not dialogue.Visible) then
            
            -- 1. ƯU TIÊN CAO NHẤT: AUTO SAM
            if _G.AutoSam then
                local foundSam = false
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name == "Sam" and obj:IsA("Model") and obj.Parent then
                        local pName = string.lower(obj.Parent.Name)
                        if string.find(pName, "quest") then
                            local root = obj:FindFirstChild("HumanoidRootPart")
                            if root then
                                local cd = root:FindFirstChildOfClass("ClickDetector")
                                if cd and fireclickdetector then 
                                    fireclickdetector(cd, 0) 
                                    foundSam = true
                                end
                            end
                        end
                    end
                end
                if foundSam then continue end
            end

            -- 2. ƯU TIÊN TIẾP THEO: DAILY QUEST
            if _G.AutoDaily then
                local foundDaily = false
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
                                        foundDaily = true
                                    end
                                end
                            end
                        end
                    end
                end
                if foundDaily then continue end
            end

            -- 3. CUỐI CÙNG: QUEST THƯỜNG
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
                                end
                            end
                            break 
                        end
                    end
                end
            end
        end

        -- ==========================================
        -- TỰ ĐỘNG BẤM BẢNG THOẠI
        -- ==========================================
        if _G.AutoNormal or _G.AutoDaily or _G.AutoSam then
            if dialogue and dialogue.Visible then
                pcall(function() dialogue.Position = UDim2.new(5, 0, 5, 0) end)
                local opts = dialogue:FindFirstChild("Options")
                if opts then
                    local btnNext = opts:FindFirstChild("Next")
                    local btnOption = opts:FindFirstChild("Option")  -- Lựa chọn 1
                    local btnOption2 = opts:FindFirstChild("Option2") -- Lựa chọn 2
                    local btnLeave = opts:FindFirstChild("Leave")

                    if _G.AutoSam then
                        -- FIX TRIỆT ĐỂ SAM: Ưu tiên bấm Option (Lựa chọn 1) một cách tuyệt đối
                        if btnOption and btnOption.Visible then 
                            PassiveClick(btnOption)
                        -- Nếu màn hình tiếp theo không có chữ Option mà có chữ Next, thì bấm Next
                        elseif btnNext and btnNext.Visible then 
                            PassiveClick(btnNext)
                        end
                    else
                        if btnNext and btnNext.Visible then PassiveClick(btnNext)
                        elseif btnOption and btnOption.Visible then PassiveClick(btnOption)
                        elseif btnOption2 and btnOption2.Visible then PassiveClick(btnOption2)
                        elseif btnLeave and btnLeave.Visible then PassiveClick(btnLeave) end
                    end
                end
            end
        else
            if dialogue and dialogue.Visible and dialogue.Position.X.Scale == 5 then
                pcall(function() dialogue.Position = UDim2.new(0.5, 0, 0.8, 0) end) 
            end
        end
    end
end)
