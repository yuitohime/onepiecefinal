-- =========================================================================
-- [MINI TESTER] AUTO QUEST & SAM ENGINE
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local TargetGui = (gethui and pcall(gethui) and gethui()) or CoreGui
if not pcall(function() local _ = TargetGui.Name end) then TargetGui = LocalPlayer:WaitForChild("PlayerGui") end

-- Xóa UI cũ nếu có
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

-- ============================
-- TẠO UI ĐƠN GIẢN & KÉO THẢ
-- ============================
local ScreenGui = Instance.new("ScreenGui", TargetGui)
ScreenGui.Name = "YuiQuestTester"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 280)
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
Title.Text = "🛠️ QUEST & SAM TESTER" Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold Title.TextSize = 12

-- Logic Kéo Thả (Draggable)
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
Layout.Padding = UDim.new(0, 8) Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("Frame", MainFrame).Size = UDim2.new(1,0,0,30) -- Spacer

local function CreateButton(txt, defaultColor)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30) btn.BackgroundColor3 = defaultColor
    btn.Text = txt btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local function CreateInput(placeholder)
    local box = Instance.new("TextBox", MainFrame)
    box.Size = UDim2.new(0.9, 0, 0, 30) box.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    box.Text = "" box.PlaceholderText = placeholder box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Font = Enum.Font.Gotham box.TextSize = 11
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(100, 100, 100)
    return box
end

-- UI Elements
local BtnSam = CreateButton("Auto Sam: OFF", Color3.fromRGB(50, 50, 50))
local BtnSamAmt = CreateButton("Sam Amount: x1", Color3.fromRGB(80, 100, 150))
local BoxNormal = CreateInput("Nhập tên NPC Quest Thường...")
local BtnNormal = CreateButton("Auto Normal Quest: OFF", Color3.fromRGB(50, 50, 50))
local BoxDaily = CreateInput("Nhập tên NPC Quest Daily...")
local BtnDaily = CreateButton("Auto Daily Quest: OFF", Color3.fromRGB(50, 50, 50))

-- UI Logic
BtnSam.MouseButton1Click:Connect(function()
    AutoSam = not AutoSam
    BtnSam.Text = "Auto Sam: " .. (AutoSam and "ON" or "OFF")
    BtnSam.BackgroundColor3 = AutoSam and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(50, 50, 50)
end)

BtnSamAmt.MouseButton1Click:Connect(function()
    if SamAmount == "x1" then SamAmount = "x10" else SamAmount = "x1" end
    BtnSamAmt.Text = "Sam Amount: " .. SamAmount
end)

BoxNormal.FocusLost:Connect(function() TargetNormal = BoxNormal.Text end)
BtnNormal.MouseButton1Click:Connect(function()
    AutoNormal = not AutoNormal
    BtnNormal.Text = "Auto Normal Quest: " .. (AutoNormal and "ON" or "OFF")
    BtnNormal.BackgroundColor3 = AutoNormal and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(50, 50, 50)
end)

BoxDaily.FocusLost:Connect(function() TargetDaily = BoxDaily.Text end)
BtnDaily.MouseButton1Click:Connect(function()
    AutoDaily = not AutoDaily
    BtnDaily.Text = "Auto Daily Quest: " .. (AutoDaily and "ON" or "OFF")
    BtnDaily.BackgroundColor3 = AutoDaily and Color3.fromRGB(150, 50, 150) or Color3.fromRGB(50, 50, 50)
end)

-- ============================
-- LÕI XỬ LÝ (CORE ENGINE)
-- ============================
local function GetFullText(obj)
    local txt = obj.Name or ""
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        if obj.Text and obj.Text ~= "" then txt = txt .. " " .. obj.Text end
    end
    for _, v in pairs(obj:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            if v.Text and v.Text ~= "" then txt = txt .. " " .. v.Text end
        end
    end
    return string.lower(txt)
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

local function FireNPC(npcName)
    if npcName == "" then return false end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == npcName and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local cd = obj.HumanoidRootPart:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd, 0) return true end
        end
    end
    return false
end

local function HasActiveQuest()
    local questGui = LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
    if questGui and questGui:FindFirstChild("QuestsFrame") and questGui.QuestsFrame.Visible then
        local scroll = questGui.QuestsFrame:FindFirstChild("QuestsScroll")
        if scroll then
            local objective = scroll:FindFirstChild("Objective")
            if objective and objective.Text ~= "" then return true end
        end
    end 
    return false
end

-- Vòng lặp nhận diện
task.spawn(function()
    while task.wait(0.5) do
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then continue end

        local questGui = pGui:FindFirstChild("QuestGui")
        if not questGui then continue end
        local dialogue = questGui:FindFirstChild("Dialogue")
        
        -- BƯỚC 1: KÍCH HOẠT NPC NGẦM TỪ XA
        if not (dialogue and dialogue.Visible) then
            if AutoSam then 
                FireNPC("Sam")
            elseif AutoNormal and not HasActiveQuest() then 
                FireNPC(TargetNormal)
            elseif AutoDaily and not HasActiveQuest() then 
                FireNPC(TargetDaily)
            end
        end

        -- BƯỚC 2: XỬ LÝ BẢNG THOẠI (XUYÊN THẤU)
        if dialogue and dialogue.Visible then
            local isQuesting = AutoNormal or AutoDaily or AutoSam
            
            -- Tàng hình bảng thoại nếu đang bật Auto
            if isQuesting then 
                pcall(function() dialogue.Position = UDim2.new(5, 0, 5, 0) end) 
            else 
                pcall(function() dialogue.AnchorPoint = Vector2.new(0.5, 0.5) dialogue.Position = UDim2.new(0.5, 0, 0.5, 0) end) 
            end

            local opts = dialogue:FindFirstChild("Options")
            if opts then
                if AutoSam then
                    local btnCompasses, btnAmount = nil, nil
                    for _, btn in pairs(opts:GetChildren()) do
                        if btn:IsA("TextButton") and btn.Visible then
                            local txt = GetFullText(btn)
                            if string.find(txt, "compasses") and not string.find(txt, "buy") then btnCompasses = btn
                            elseif string.find(txt, string.lower(SamAmount)) then btnAmount = btn end
                        end
                    end
                    -- Bấm ưu tiên
                    if btnCompasses then PassiveClick(btnCompasses) 
                    elseif btnAmount then PassiveClick(btnAmount) 
                    end
                    task.wait(0.2)
                    
                elseif AutoNormal or AutoDaily then
                    local btnAccept, btnNext = nil, nil
                    for _, btn in pairs(opts:GetChildren()) do
                        if btn:IsA("TextButton") and btn.Visible then
                            local txt = GetFullText(btn)
                            -- Nếu KHÔNG chứa các từ từ chối
                            if not string.find(txt, "nevermind") and not string.find(txt, "leave") and not string.find(txt, "no") then
                                if string.find(txt, "next") then btnNext = btn else btnAccept = btn end
                            end
                        end
                    end
                    -- Bấm ưu tiên
                    if btnAccept then PassiveClick(btnAccept) 
                    elseif btnNext then PassiveClick(btnNext) 
                    end
                    task.wait(0.2)
                end
            end
        end
    end
end)
