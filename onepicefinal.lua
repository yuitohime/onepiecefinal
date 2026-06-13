-- =========================================================================
-- [MINI TESTER V6] ZERO FLICKER, NO TELEPORT, EXACT OPTION SEQUENCE
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
Title.Text = "🛠️ QUEST & SAM V6" Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold Title.TextSize = 12

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

local BtnRefresh = CreateButton("🔄 Quét Tất Cả Quest", Color3.fromRGB(40, 80, 150))
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
        if Scroll.Visible then
            Scroll.Position = UDim2.new(0, parentBtn.AbsolutePosition.X, 0, parentBtn.AbsolutePosition.Y + parentBtn.AbsoluteSize.Y + 2)
        end
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
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local pN = string.lower(obj.Parent and obj.Parent.Name or "")
            local oN = string.lower(obj.Name)
            if string.find(pN, "daily") or string.find(oN, "daily") then
                if not tempD[obj.Name] then tempD[obj.Name] = true table.insert(ListDaily, obj.Name) end
            elseif string.find(pN, "quest") or string.find(oN, "quest") then
                if not tempN[obj.Name] then tempN[obj.Name] = true table.insert(ListNormal, obj.Name) end
            end
        end
    end
    table.sort(ListNormal) table.sort(ListDaily)
    PopNormal(ListNormal) PopDaily(ListDaily)
    BtnRefresh.Text = "✅ Đã tải xong!"
    task.wait(1.5) BtnRefresh.Text = "🔄 Quét Tất Cả Quest"
end)

BtnSam.MouseButton1Click:Connect(function() AutoSam = not AutoSam BtnSam.Text = "Auto Sam: " .. (AutoSam and "ON" or "OFF") BtnSam.BackgroundColor3 = AutoSam and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(50, 50, 50) end)
BtnSamAmt.MouseButton1Click:Connect(function() if SamAmount == "x1" then SamAmount = "x10" else SamAmount = "x1" end BtnSamAmt.Text = "Sam Amount: " .. SamAmount end)
BtnNormal.MouseButton1Click:Connect(function() AutoNormal = not AutoNormal BtnNormal.Text = "Auto Normal Quest: " .. (AutoNormal and "ON" or "OFF") BtnNormal.BackgroundColor3 = AutoNormal and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(50, 50, 50) end)
BtnDaily.MouseButton1Click:Connect(function() AutoDaily = not AutoDaily BtnDaily.Text = "Auto Daily Quest: " .. (AutoDaily and "ON" or "OFF") BtnDaily.BackgroundColor3 = AutoDaily and Color3.fromRGB(150, 50, 150) or Color3.fromRGB(50, 50, 50) end)

-- ============================
-- LÕI XỬ LÝ (CORE ENGINE V6)
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

local function PassiveClick(btn)
    if not btn then return end
    pcall(function()
        local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "TouchTap"}
        for _, eventName in ipairs(events) do
            if btn[eventName] then
                pcall(function() firesignal(btn[eventName]) end)
                if getconnections then
                    for _, conn in ipairs(getconnections(btn[eventName])) do pcall(function() conn:Fire() end) end
                end
            end
        end
    end)
end

-- FIRE NPC (KHÔNG TELEPORT, TỪ XA)
local function FireNPC(npcName)
    if npcName == "" or npcName == "None" then return false end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == npcName and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local cd = obj.HumanoidRootPart:FindFirstChildOfClass("ClickDetector")
            if cd then 
                pcall(function() fireclickdetector(cd, 0) end)
                return true 
            end
        end
    end
    return false
end

local function HasActiveQuest()
    local questGui = LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
    if questGui and questGui:FindFirstChild("QuestsFrame") and questGui.QuestsFrame.Visible then
        local scroll = questGui.QuestsFrame:FindFirstChild("QuestsScroll")
        if scroll and scroll:FindFirstChild("Objective") and scroll.Objective.Text ~= "" then return true end
    end 
    return false
end

local lastClickTime = 0

task.spawn(function()
    while task.wait(0.2) do -- Tốc độ quét cực nhanh
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then continue end

        local questGui = pGui:FindFirstChild("QuestGui")
        if not questGui then continue end
        local dialogue = questGui:FindFirstChild("Dialogue")
        
        local isQuesting = AutoNormal or AutoDaily or AutoSam

        -- NẾU TẤT CẢ AUTO ĐỀU TẮT -> TRẢ LẠI MÀN HÌNH BÌNH THƯỜNG VÀ KHÔNG LÀM GÌ CẢ
        if not isQuesting then
            if dialogue and dialogue.Visible and dialogue.Position.X.Scale > 1 then
                pcall(function() dialogue.AnchorPoint = Vector2.new(0.5, 0.5) dialogue.Position = UDim2.new(0.5, 0, 0.5, 0) end)
            end
            continue -- Ngắt hoàn toàn đoạn code dưới, xóa dứt điểm lỗi nháy UI
        end

        -- NẾU ĐANG BẬT AUTO
        -- BƯỚC 1: KÍCH HOẠT NPC
        if not (dialogue and dialogue.Visible) then
            if tick() - lastClickTime > 2 then -- Chống spam lệnh gọi
                if AutoSam then 
                    FireNPC("Sam") lastClickTime = tick()
                elseif AutoNormal and not HasActiveQuest() then 
                    FireNPC(TargetNormal) lastClickTime = tick()
                elseif AutoDaily and not HasActiveQuest() then 
                    FireNPC(TargetDaily) lastClickTime = tick()
                end
            end
        end

        -- BƯỚC 2: XỬ LÝ BẢNG THOẠI NGẦM
        if dialogue and dialogue.Visible then
            -- Giấu bảng thoại đi (vì isQuesting đang = true)
            pcall(function() dialogue.Position = UDim2.new(5, 0, 5, 0) end) 
            
            local opts = dialogue:FindFirstChild("Options")
            if opts then
                local btnNext = opts:FindFirstChild("Next")
                local btnOpt = opts:FindFirstChild("Option")
                local btnOpt2 = opts:FindFirstChild("Option2")

                if AutoSam then
                    local txtOpt = btnOpt and GetFullText(btnOpt) or ""
                    
                    if string.find(txtOpt, "compasses") and not string.find(txtOpt, "buy") then
                        -- Màn hình 1: Bấm Option (Compasses)
                        PassiveClick(btnOpt)
                    elseif string.find(txtOpt, "claim") or string.find(txtOpt, "1") then
                        -- Màn hình 2: Bấm số lượng
                        if SamAmount == "x1" and btnOpt then 
                            PassiveClick(btnOpt)
                        elseif SamAmount == "x10" and btnOpt2 then 
                            PassiveClick(btnOpt2) 
                        end
                    end
                    task.wait(0.2)
                    
                elseif AutoNormal or AutoDaily then
                    -- Theo đúng chuẩn: Thấy Next bấm Next, thấy Option bấm Option
                    if btnNext and btnNext.Visible then 
                        PassiveClick(btnNext)
                    elseif btnOpt and btnOpt.Visible then 
                        PassiveClick(btnOpt) 
                    end
                    task.wait(0.2)
                end
            end
        end
    end
end)
