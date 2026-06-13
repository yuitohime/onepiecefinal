-- =========================================================================
-- AUTO COLLECT RAYLEIGH RINGS - MENU TÁCH BIỆT
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = (gethui and pcall(gethui) and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer

-- Xóa GUI cũ nếu có để tránh trùng lặp
if not pcall(function() local _ = CoreGui.Name end) then CoreGui = player:WaitForChild("PlayerGui") end
for _, gui in pairs(CoreGui:GetChildren()) do 
    if gui.Name == "AutoRings_Menu" then gui:Destroy() end 
end

-- Biến Global
_G.AutoRings = false

-- ============================
-- TẠO MENU UI
-- ============================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoRings_Menu"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 255, 150)

-- HEADER & KÉO THẢ
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30) 
Header.Active = true
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO NHẶT RINGS"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13

-- Đóng GUI
CloseBtn.Activated:Connect(function()
    _G.AutoRings = false
    ScreenGui:Destroy()
end)

-- Thuật toán Kéo Thả
local dragging, dragInput, dragStart, startPos
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
    if input == dragInput and dragging then 
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- NÚT BẬT/TẮT AUTO
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "Auto Rayleigh Rings [OFF]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.Activated:Connect(function()
    _G.AutoRings = not _G.AutoRings
    if _G.AutoRings then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        ToggleBtn.Text = "Auto Rayleigh Rings [ON]"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ToggleBtn.Text = "Auto Rayleigh Rings [OFF]"
    end
end)

-- ============================
-- HÀM TÌM VÀ SẮP XẾP RINGS
-- ============================
local function GetSortedRings()
    local ringsList = {}
    
    -- Quét tìm thư mục MapFolder -> Rings trong Workspace
    for _, desc in pairs(Workspace:GetDescendants()) do
        if desc.Name == "MapFolder" then
            local ringsFolder = desc:FindFirstChild("Rings")
            if ringsFolder then
                -- Lấy tất cả các Part có chữ "Rayleigh Ring"
                for _, ring in pairs(ringsFolder:GetChildren()) do
                    if ring:IsA("BasePart") and string.find(ring.Name, "Rayleigh Ring") then
                        table.insert(ringsList, ring)
                    end
                end
            end
            break -- Tìm thấy MapFolder rồi thì dừng vòng lặp tìm kiếm
        end
    end

    -- Sắp xếp theo thứ tự số đuôi (1 -> 8)
    table.sort(ringsList, function(a, b)
        -- Tách lấy số cuối cùng trong tên (VD: "Rayleigh Ring 1" -> lấy số 1)
        local numA = tonumber(string.match(a.Name, "%d+")) or 0
        local numB = tonumber(string.match(b.Name, "%d+")) or 0
        return numA < numB
    end)

    return ringsList
end

-- ============================
-- VÒNG LẶP AUTO NHẶT RINGS
-- ============================
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoRings then
            local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end

            local rings = GetSortedRings()
            
            -- Nếu tìm thấy Rings, bắt đầu dịch chuyển lần lượt
            if #rings > 0 then
                for i, ring in ipairs(rings) do
                    -- Kiểm tra xem auto còn bật không và nhân vật còn sống không
                    if not _G.AutoRings or not player.Character:FindFirstChild("HumanoidRootPart") then break end
                    
                    -- Dịch chuyển vào tâm của Ring
                    rootPart.CFrame = ring.CFrame
                    
                    -- Đợi 0.5s để server nhận diện đã chạm vào vòng trước khi bay sang vòng tiếp theo
                    task.wait(0.5) 
                end
            end
        end
    end
end)
