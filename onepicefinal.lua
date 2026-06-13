-- =========================================================================
-- [MINI TESTER V9] GIỮ NGUYÊN 100% LÕI CODE GỐC CỦA BẠN (KHÔNG ẨN UI)
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local TargetGui = (gethui and pcall(gethui) and gethui()) or CoreGui
if not pcall(function() local _ = TargetGui.Name end) then TargetGui = LocalPlayer:WaitForChild("PlayerGui") end

-- Xóa UI cũ
for _, v in pairs(TargetGui:GetChildren()) do
    if v.Name == "YuiQuestTester" then v:Destroy() end
end

-- ============================
-- GLOBAL VARIABLES
-- ============================
local AutoSam = false
local SamAmount = "x1"
local AutoNormal = false
local TargetNormal = ""
local AutoDaily = false
local TargetDaily = ""

local ListNormal = {}
local ListDaily = {}

-- ============================
-- TẠO UI KÉO THẢ & DANH SÁCH
-- ============================
local ScreenGui = Instance.new("ScreenGui", TargetGui)
ScreenGui.Name = "YuiQuestTester"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 360)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(80, 150, 255)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0) Title.BackgroundTransparency = 1
Title.Text = "🛠️ QUEST & SAM V9 (CORE GỐC)" Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold Title.TextSize = 11

local dragToggle, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true dragStart = input.Position startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Layout = Instance.new("UIListLayout", MainFrame)
Layout.Padding = UDim.new(0, 6) Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("Frame", MainFrame).Size = UDim2.new(1,0,0,10)

local function CreateButton(txt, defaultColor)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 28) btn.BackgroundColor3 = defaultColor
    btn.Text = txt btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local BtnRefresh = CreateButton("🔄 Làm Mới Danh Sách", Color3.fromRGB(40, 80, 150))
local BtnSam = CreateButton("Auto Sam: OFF", Color3.fromRGB(50, 50, 50))
local BtnSamAmt = CreateButton("Sam Amount: x1", Color3.fromRGB(80, 100, 150))
local BtnNormalDrop = CreateButton("Quest Thường: None ▼", Color3.fromRGB(30, 30, 35))
local BtnNormal = CreateButton("Auto Normal Quest: OFF", Color3.fromRGB(50, 50, 50))
local BtnDailyDrop = CreateButton("Quest Daily: None ▼", Color3.fromRGB(30, 30, 35))
local BtnDaily = CreateButton("Auto Daily Quest: OFF", Color3.fromRGB(50, 50, 50))

local function CreateDropdownMenu(parentBtn, isDaily)
    local Scroll = Instance.new("ScrollingFrame", ScreenGui)
    Scroll.Size = UDim2.new(0, 200, 0, 150)
    Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Scroll.Visible = false Scroll.ZIndex = 100
    Scroll.ScrollBarThickness = 2
    Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Scroll).Color = Color3.fromRGB(80, 150, 255)
    Instance.new("UIListLayout", Scroll)

    game:GetService("RunService").RenderStepped:Connect(function()
        if Scroll.Visible then Scroll.Position = UDim2.new(0, parentBtn.AbsolutePosition.X, 0, parentBtn.AbsolutePosition.Y + parentBtn.AbsoluteSize.Y + 2) end
    end)

    parentBtn.MouseButton1Click:Connect(function() Scroll.Visible = not Scroll.Visible end)

    local function Populate(listData)
        for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local height = 0
        for _, name in ipairs(listData) do
            local itemBtn = Instance.new("TextButton", Scroll)
            itemBtn.Size = UDim2.new(1, 0, 0, 25) itemBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            itemBtn.Text = "  " .. name itemBtn.TextColor3 = Color3.fromRGB(255,255,255)
            itemBtn.Font = Enum.Font.Gotham itemBtn.TextSize = 10 itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            itemBtn.ZIndex = 101 height = height + 25
            
            itemBtn.MouseButton1Click:Connect(function()
                if isDaily then TargetDaily = name; parentBtn.Text = "Daily: " .. name .. " ▼"
                else TargetNormal = name; parentBtn.Text = "Thường: " .. name .. " ▼" end
                Scroll.Visible = false
            end)
        end
        Scroll.CanvasSize = UDim2.new(0, 0, 0, height)
    end
    return Populate
end

local PopNormal = CreateDropdownMenu(BtnNormalDrop, false)
local PopDaily = CreateDropdownMenu(BtnDailyDrop, true)

BtnRefresh.MouseButton1Click:Connect(function()
    ListNormal, ListDaily = {}, {}
    local tempN, tempD = {}, {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Parent then
            local pName = string.lower(obj.Parent.Name)
            if string.find(pName, "quest") then
                if string.find(pName, "daily") then
                    if not tempD[obj.Name] then tempD[obj.Name] = true table.insert(ListDaily, obj.Name) end
                else
                    if not tempN[obj.Name] then tempN[obj.Name] = true table.insert(ListNormal, obj.Name) end
                end
            end
        end
    end
    table.sort(ListNormal) table.sort(ListDaily)
    PopNormal(ListNormal) PopDaily(ListDaily)
    BtnRefresh.Text = "✅ Đã tải xong!"
    task.wait(1.5) BtnRefresh.Text = "🔄 Làm Mới Danh Sách"
end)

BtnSam.MouseButton1Click:Connect(function() AutoSam = not AutoSam BtnSam.Text = "Auto Sam: " .. (AutoSam and "ON" or "OFF") BtnSam.BackgroundColor3 = AutoSam and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(50, 50, 50) end)
BtnSamAmt.MouseButton1Click:Connect(function() if SamAmount == "x1" then SamAmount = "x10" else SamAmount = "x1" end BtnSamAmt.Text = "Sam Amount: " .. SamAmount end)
BtnNormal.MouseButton1Click:Connect(function() AutoNormal = not AutoNormal BtnNormal.Text = "Auto Normal Quest: " .. (AutoNormal and "ON" or "OFF") BtnNormal.BackgroundColor3 = AutoNormal and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(50, 50, 50) end)
BtnDaily.MouseButton1Click:Connect(function() AutoDaily = not AutoDaily BtnDaily.Text = "Auto Daily Quest: " .. (AutoDaily and "ON" or "OFF") BtnDaily.BackgroundColor3 = AutoDaily and Color3.fromRGB(150, 50, 150) or Color3.fromRGB(50, 50, 50) end)

-- ============================
-- 100% LÕI XỬ LÝ CỦA BẠN (KHÔNG CHỈNH SỬA)
-- ============================

local function GetFullText(obj)
    local txt = ""
    for _, v in pairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            if v.Text and v.Text ~= "" then txt = txt .. " " .. string.lower(v.Text) end
        end
    end
    return txt
end

local function HasActiveQuest()
    local questGui = LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
    if questGui then
        local qFrame = questGui:FindFirstChild("QuestsFrame")
        if qFrame and qFrame.Visible then
            local scroll = qFrame:FindFirstChild("QuestsScroll")
            -- GIỮ NGUYÊN QuestName CHUẨN CỦA BẠN CHỐNG NHÁY UI
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

-- VÒNG LẶP CHÍNH THEO CẤU TRÚC GỐC
task.spawn(function()
    while task.wait(0.5) do
        -- Xác định mục tiêu giống code gốc
        local targetQuestName = nil
        if AutoSam then targetQuestName = "Sam"
        elseif AutoDaily and TargetDaily ~= "" then targetQuestName = TargetDaily
        elseif AutoNormal and TargetNormal ~= "" then targetQuestName = TargetNormal end

        if not targetQuestName then continue end

        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then continue end

        local questGui = pGui:FindFirstChild("QuestGui")
        if not questGui then continue end
        local dialogue = questGui:FindFirstChild("Dialogue")
        
        -- LÕI CHỌC NGẦM TỪ XA CỦA BẠN
        if not HasActiveQuest() and (not dialogue or not dialogue.Visible) then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == targetQuestName and obj:IsA("Model") and obj.Parent then
                    local pName = string.lower(obj.Parent.Name)
                    -- Chỉ chấp nhận nếu nằm trong thư mục Quest, Daily hoặc là Sam
                    if string.find(pName, "quest") or string.find(pName, "daily") or targetQuestName == "Sam" then
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

        -- LÕI BẤM BẢNG THOẠI (KHÔNG ẨN UI - ĐỂ NGUYÊN GIỮA MÀN HÌNH)
        if dialogue and dialogue.Visible then
            pcall(function() 
                dialogue.AnchorPoint = Vector2.new(0.5, 0.5) 
                dialogue.Position = UDim2.new(0.5, 0, 0.5, 0) 
            end)

            local opts = dialogue:FindFirstChild("Options")
            if opts then
                local btnNext = opts:FindFirstChild("Next")
                local btnOption = opts:FindFirstChild("Option")
                local btnOption2 = opts:FindFirstChild("Option2")

                if AutoSam then
                    local txtOpt2 = btnOption2 and GetFullText(btnOption2) or ""
                    
                    -- Chống bấm Buy Robux của bạn
                    if string.find(string.lower(txtOpt2), "buy") or string.find(string.lower(txtOpt2), "robux") then
                        if btnOption and btnOption.Visible then PassiveClick(btnOption) end
                    else
                        -- Bảng số lượng
                        if SamAmount == "x10" and btnOption2 and btnOption2.Visible then 
                            PassiveClick(btnOption2) 
                        elseif btnOption and btnOption.Visible then 
                            PassiveClick(btnOption) 
                        end
                    end
                else
                    -- Bấm Quest giống y hệt code gốc của bạn
                    if btnNext and btnNext.Visible then PassiveClick(btnNext)
                    elseif btnOption and btnOption.Visible then PassiveClick(btnOption)
                    elseif btnOption2 and btnOption2.Visible then PassiveClick(btnOption2) end
                end
            end
        end
    end
end)
