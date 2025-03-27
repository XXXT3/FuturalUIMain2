--[[
    FuturaUI Library
    A futuristic and responsive UI library for Roblox
    
    Features:
    - Split layout design (sections on left, content on right)
    - Responsive for both PC and mobile
    - Optional key system
    - Smooth animations and modern design
    - Easy to use API
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local FuturaUI = {}
FuturaUI.__index = FuturaUI

-- Constants
local TWEEN_SPEED = 0.25
local CORNER_RADIUS = UDim.new(0, 8) -- Slightly more rounded corners
local SHADOW_TRANSPARENCY = 0.7
local ACCENT_COLOR = Color3.fromRGB(0, 170, 255) -- Bright cyber blue
local BACKGROUND_COLOR = Color3.fromRGB(10, 15, 25) -- Darker background
local SECTION_COLOR = Color3.fromRGB(20, 25, 35) -- Darker sections
local TEXT_COLOR = Color3.fromRGB(255, 255, 255) -- Pure white text
local SUBTEXT_COLOR = Color3.fromRGB(200, 220, 255) -- Light blue tint for subtitles
local ELEMENT_COLOR = Color3.fromRGB(30, 35, 45) -- Slightly darker elements
local HOVER_COLOR_LIGHT = Color3.fromRGB(40, 120, 200) -- Blue highlight
local HOVER_COLOR_DARK = Color3.fromRGB(0, 100, 180) -- Darker blue for pressed

-- Utility Functions
local function MakeDraggable(frame, handle)
    local dragToggle = nil
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function UpdateInput(input)
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(frame, tweenInfo, {Position = newPosition}):Play()
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            UpdateInput(input)
        end
    end)
end

local function CreateShadow(instance, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.ZIndex = instance.ZIndex - 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 80, 150) -- Blue tinted shadow for cyber effect
    shadow.ImageTransparency = transparency or SHADOW_TRANSPARENCY
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = instance
    
    -- Add a glow effect for cybernetic feel
    local glow = Instance.new("ImageLabel")
    glow.Name = "CyberGlow"
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.ZIndex = instance.ZIndex - 2
    glow.Image = "rbxassetid://6014261993"
    glow.ImageColor3 = ACCENT_COLOR
    glow.ImageTransparency = 0.85
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(49, 49, 450, 450)
    glow.Parent = instance
    
    -- Create a subtle pulsing effect
    spawn(function()
        while glow and glow.Parent do
            local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            local tween = TweenService:Create(glow, tweenInfo, {ImageTransparency = 0.7})
            tween:Play()
            wait(6)
        end
    end)
    
    return shadow
end

local function CreateRoundCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or CORNER_RADIUS
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or ACCENT_COLOR
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    
    -- Add cyber line effect (optional decorative element)
    if parent:IsA("Frame") or parent:IsA("TextButton") then
        local cyberLine = Instance.new("Frame")
        cyberLine.Name = "CyberLine"
        cyberLine.BackgroundColor3 = color or ACCENT_COLOR
        cyberLine.BackgroundTransparency = 0.3
        cyberLine.BorderSizePixel = 0
        cyberLine.Size = UDim2.new(0.7, 0, 0, 1)
        cyberLine.Position = UDim2.new(0.15, 0, 1, -2)
        cyberLine.Parent = parent
        
        -- Create a subtle pulsing animation for the line
        spawn(function()
            while cyberLine and cyberLine.Parent do
                local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
                local tween = TweenService:Create(cyberLine, tweenInfo, {BackgroundTransparency = 0.7})
                tween:Play()
                wait(3)
            end
        end)
    end
    
    return stroke
end

local function CalculateTextSize(text, font, size, maxWidth)
    return TextService:GetTextSize(text, size, font, Vector2.new(maxWidth or math.huge, math.huge))
end

local function IsUsingMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

-- Library Component Creation Methods
function FuturaUI.new(title, keyRequired)
    local self = setmetatable({}, FuturaUI)
    
    -- State variables
    self.title = title or "FuturaUI"
    self.key = keyRequired
    self.keyVerified = not keyRequired
    self.sections = {}
    self.currentSection = nil
    self.isMobile = IsUsingMobile()
    self.toggled = true
    self.uiCreated = false
    self.elements = {}
    
    -- Create the UI when needed
    if not self.keyVerified then
        self:CreateKeySystem()
    else
        self:CreateUI()
    end
    
    return self
end

function FuturaUI:CreateUI()
    if self.uiCreated then return end
    
    -- Create the main GUI container
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "FuturaUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Determine where to parent the GUI
    if RunService:IsStudio() then
        self.gui.Parent = Player:WaitForChild("PlayerGui")
    else
        pcall(function() 
            self.gui.Parent = CoreGui
        end)
        if not self.gui.Parent then
            self.gui.Parent = Player:WaitForChild("PlayerGui")
        end
    end
    
    -- Create the main frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.BackgroundColor3 = BACKGROUND_COLOR
    self.mainFrame.Size = UDim2.new(0, 650, 0, 400)
    self.mainFrame.Position = UDim2.new(0.5, -325, 0.5, -200)
    self.mainFrame.Parent = self.gui
    CreateRoundCorner(self.mainFrame)
    CreateShadow(self.mainFrame, 0.5)
    
    -- Create title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.BackgroundColor3 = SECTION_COLOR
    self.titleBar.Size = UDim2.new(1, 0, 0, 40)
    self.titleBar.Parent = self.mainFrame
    CreateRoundCorner(self.titleBar)
    
    local titleCornerFix = Instance.new("Frame")
    titleCornerFix.Name = "CornerFix"
    titleCornerFix.BackgroundColor3 = SECTION_COLOR
    titleCornerFix.BorderSizePixel = 0
    titleCornerFix.Size = UDim2.new(1, 0, 0, 20)
    titleCornerFix.Position = UDim2.new(0, 0, 0.5, 0)
    titleCornerFix.Parent = self.titleBar
    
    -- Create title text
    self.titleText = Instance.new("TextLabel")
    self.titleText.Name = "TitleText"
    self.titleText.BackgroundTransparency = 1
    self.titleText.Position = UDim2.new(0, 15, 0, 0)
    self.titleText.Size = UDim2.new(1, -110, 1, 0)
    self.titleText.Font = Enum.Font.GothamBold
    self.titleText.Text = self.title
    self.titleText.TextColor3 = TEXT_COLOR
    self.titleText.TextSize = 18
    self.titleText.TextXAlignment = Enum.TextXAlignment.Left
    self.titleText.Parent = self.titleBar
    
    -- Create close button
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.BackgroundTransparency = 1
    self.closeButton.Position = UDim2.new(1, -40, 0, 0)
    self.closeButton.Size = UDim2.new(0, 40, 1, 0)
    self.closeButton.Font = Enum.Font.GothamBold
    self.closeButton.Text = "×"
    self.closeButton.TextColor3 = TEXT_COLOR
    self.closeButton.TextSize = 24
    self.closeButton.Parent = self.titleBar
    
    self.closeButton.MouseEnter:Connect(function()
        TweenService:Create(self.closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    
    self.closeButton.MouseLeave:Connect(function()
        TweenService:Create(self.closeButton, TweenInfo.new(0.2), {TextColor3 = TEXT_COLOR}):Play()
    end)
    
    self.closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- Create minimize button
    self.minimizeButton = Instance.new("TextButton")
    self.minimizeButton.Name = "MinimizeButton"
    self.minimizeButton.BackgroundTransparency = 1
    self.minimizeButton.Position = UDim2.new(1, -80, 0, 0)
    self.minimizeButton.Size = UDim2.new(0, 40, 1, 0)
    self.minimizeButton.Font = Enum.Font.GothamBold
    self.minimizeButton.Text = "-"
    self.minimizeButton.TextColor3 = TEXT_COLOR
    self.minimizeButton.TextSize = 24
    self.minimizeButton.Parent = self.titleBar
    
    self.minimizeButton.MouseEnter:Connect(function()
        TweenService:Create(self.minimizeButton, TweenInfo.new(0.2), {TextColor3 = ACCENT_COLOR}):Play()
    end)
    
    self.minimizeButton.MouseLeave:Connect(function()
        TweenService:Create(self.minimizeButton, TweenInfo.new(0.2), {TextColor3 = TEXT_COLOR}):Play()
    end)
    
    self.minimizeButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Create content container
    self.contentContainer = Instance.new("Frame")
    self.contentContainer.Name = "ContentContainer"
    self.contentContainer.BackgroundTransparency = 1
    self.contentContainer.Position = UDim2.new(0, 0, 0, 40)
    self.contentContainer.Size = UDim2.new(1, 0, 1, -40)
    self.contentContainer.Parent = self.mainFrame
    
    -- Create sections frame (left side)
    self.sectionsFrame = Instance.new("Frame")
    self.sectionsFrame.Name = "SectionsFrame"
    self.sectionsFrame.BackgroundColor3 = SECTION_COLOR
    self.sectionsFrame.Size = UDim2.new(0.25, 0, 1, 0)
    self.sectionsFrame.Parent = self.contentContainer
    CreateRoundCorner(self.sectionsFrame, UDim.new(0, 6))
    
    -- Fix left section corner
    local sectionCornerFix = Instance.new("Frame")
    sectionCornerFix.Name = "CornerFix"
    sectionCornerFix.BackgroundColor3 = SECTION_COLOR
    sectionCornerFix.BorderSizePixel = 0
    sectionCornerFix.Size = UDim2.new(0.5, 0, 0.05, 0)
    sectionCornerFix.Position = UDim2.new(0.5, 0, 0, 0)
    sectionCornerFix.Parent = self.sectionsFrame
    
    -- Create sections scroll frame
    self.sectionsScroll = Instance.new("ScrollingFrame")
    self.sectionsScroll.Name = "SectionsScroll"
    self.sectionsScroll.BackgroundTransparency = 1
    self.sectionsScroll.Position = UDim2.new(0, 0, 0, 10)
    self.sectionsScroll.Size = UDim2.new(1, 0, 1, -10)
    self.sectionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.sectionsScroll.ScrollBarThickness = 2
    self.sectionsScroll.ScrollBarImageColor3 = ACCENT_COLOR
    self.sectionsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    self.sectionsScroll.BorderSizePixel = 0
    self.sectionsScroll.Parent = self.sectionsFrame
    
    -- Create section list layout
    self.sectionsList = Instance.new("UIListLayout")
    self.sectionsList.Name = "SectionsList"
    self.sectionsList.Padding = UDim.new(0, 5)
    self.sectionsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.sectionsList.SortOrder = Enum.SortOrder.LayoutOrder
    self.sectionsList.Parent = self.sectionsScroll
    
    -- Create sections padding
    self.sectionsPadding = Instance.new("UIPadding")
    self.sectionsPadding.Name = "SectionsPadding"
    self.sectionsPadding.PaddingLeft = UDim.new(0, 10)
    self.sectionsPadding.PaddingRight = UDim.new(0, 10)
    self.sectionsPadding.PaddingTop = UDim.new(0, 10)
    self.sectionsPadding.PaddingBottom = UDim.new(0, 10)
    self.sectionsPadding.Parent = self.sectionsScroll
    
    -- Create content frame (right side)
    self.contentFrame = Instance.new("Frame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.BackgroundColor3 = BACKGROUND_COLOR
    self.contentFrame.Size = UDim2.new(0.75, 0, 1, 0)
    self.contentFrame.Position = UDim2.new(0.25, 0, 0, 0)
    self.contentFrame.Parent = self.contentContainer
    
    -- Create content scroll frame
    self.contentScroll = Instance.new("ScrollingFrame")
    self.contentScroll.Name = "ContentScroll"
    self.contentScroll.BackgroundTransparency = 1
    self.contentScroll.Position = UDim2.new(0, 10, 0, 10)
    self.contentScroll.Size = UDim2.new(1, -20, 1, -20)
    self.contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentScroll.ScrollBarThickness = 3
    self.contentScroll.ScrollBarImageColor3 = ACCENT_COLOR
    self.contentScroll.BorderSizePixel = 0
    self.contentScroll.Parent = self.contentFrame
    
    -- Create content list layout
    self.contentList = Instance.new("UIListLayout")
    self.contentList.Name = "ContentList"
    self.contentList.Padding = UDim.new(0, 8)
    self.contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.contentList.SortOrder = Enum.SortOrder.LayoutOrder
    self.contentList.Parent = self.contentScroll
    
    -- Create content padding
    self.contentPadding = Instance.new("UIPadding")
    self.contentPadding.Name = "ContentPadding"
    self.contentPadding.PaddingLeft = UDim.new(0, 10)
    self.contentPadding.PaddingRight = UDim.new(0, 10)
    self.contentPadding.PaddingTop = UDim.new(0, 10)
    self.contentPadding.PaddingBottom = UDim.new(0, 10)
    self.contentPadding.Parent = self.contentScroll
    
    -- Create mobile toggle button if on mobile
    if self.isMobile then
        self:CreateMobileToggle()
    end
    
    -- Make the UI draggable
    MakeDraggable(self.mainFrame, self.titleBar)
    
    -- Update UI elements
    self.contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.contentScroll.CanvasSize = UDim2.new(0, 0, 0, self.contentList.AbsoluteContentSize.Y + 20)
    end)
    
    self.sectionsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.sectionsScroll.CanvasSize = UDim2.new(0, 0, 0, self.sectionsList.AbsoluteContentSize.Y + 20)
    end)
    
    self.uiCreated = true
end

function FuturaUI:CreateMobileToggle()
    -- Create a toggle button for mobile users
    self.mobileToggle = Instance.new("ImageButton")
    self.mobileToggle.Name = "MobileToggle"
    self.mobileToggle.BackgroundColor3 = ACCENT_COLOR
    self.mobileToggle.Size = UDim2.new(0, 50, 0, 50)
    self.mobileToggle.Position = UDim2.new(0, 10, 0, 10)
    self.mobileToggle.AnchorPoint = Vector2.new(0, 0)
    self.mobileToggle.Image = "rbxassetid://7059346373" -- Menu icon
    self.mobileToggle.ImageColor3 = TEXT_COLOR
    self.mobileToggle.Parent = self.gui
    CreateRoundCorner(self.mobileToggle, UDim.new(1, 0))
    CreateShadow(self.mobileToggle)
    
    self.mobileToggle.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function FuturaUI:CreateKeySystem()
    -- Create the key system UI
    self.keyGui = Instance.new("ScreenGui")
    self.keyGui.Name = "FuturaUI_KeySystem"
    self.keyGui.ResetOnSpawn = false
    self.keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Determine where to parent the GUI
    if RunService:IsStudio() then
        self.keyGui.Parent = Player:WaitForChild("PlayerGui")
    else
        pcall(function() 
            self.keyGui.Parent = CoreGui
        end)
        if not self.keyGui.Parent then
            self.keyGui.Parent = Player:WaitForChild("PlayerGui")
        end
    end
    
    -- Create the key frame
    self.keyFrame = Instance.new("Frame")
    self.keyFrame.Name = "KeyFrame"
    self.keyFrame.BackgroundColor3 = BACKGROUND_COLOR
    self.keyFrame.Size = UDim2.new(0, 350, 0, 200)
    self.keyFrame.Position = UDim2.new(0.5, -175, 0.5, -100)
    self.keyFrame.Parent = self.keyGui
    CreateRoundCorner(self.keyFrame)
    CreateShadow(self.keyFrame, 0.5)
    
    -- Create key title
    self.keyTitle = Instance.new("TextLabel")
    self.keyTitle.Name = "KeyTitle"
    self.keyTitle.BackgroundTransparency = 1
    self.keyTitle.Position = UDim2.new(0, 0, 0, 20)
    self.keyTitle.Size = UDim2.new(1, 0, 0, 30)
    self.keyTitle.Font = Enum.Font.GothamBold
    self.keyTitle.Text = self.title .. " - Key System"
    self.keyTitle.TextColor3 = TEXT_COLOR
    self.keyTitle.TextSize = 18
    self.keyTitle.Parent = self.keyFrame
    
    -- Create key input
    self.keyInput = Instance.new("TextBox")
    self.keyInput.Name = "KeyInput"
    self.keyInput.BackgroundColor3 = ELEMENT_COLOR
    self.keyInput.Position = UDim2.new(0.5, -125, 0.5, -20)
    self.keyInput.Size = UDim2.new(0, 250, 0, 40)
    self.keyInput.Font = Enum.Font.Gotham
    self.keyInput.PlaceholderText = "Enter Key..."
    self.keyInput.PlaceholderColor3 = SUBTEXT_COLOR
    self.keyInput.Text = ""
    self.keyInput.TextColor3 = TEXT_COLOR
    self.keyInput.TextSize = 14
    self.keyInput.ClearTextOnFocus = false
    self.keyInput.Parent = self.keyFrame
    CreateRoundCorner(self.keyInput)
    
    -- Create submit button
    self.submitButton = Instance.new("TextButton")
    self.submitButton.Name = "SubmitButton"
    self.submitButton.BackgroundColor3 = ACCENT_COLOR
    self.submitButton.Position = UDim2.new(0.5, -75, 0.5, 30)
    self.submitButton.Size = UDim2.new(0, 150, 0, 40)
    self.submitButton.Font = Enum.Font.GothamBold
    self.submitButton.Text = "Submit"
    self.submitButton.TextColor3 = TEXT_COLOR
    self.submitButton.TextSize = 14
    self.submitButton.Parent = self.keyFrame
    CreateRoundCorner(self.submitButton)
    
    -- Create status label
    self.keyStatus = Instance.new("TextLabel")
    self.keyStatus.Name = "KeyStatus"
    self.keyStatus.BackgroundTransparency = 1
    self.keyStatus.Position = UDim2.new(0, 0, 1, -40)
    self.keyStatus.Size = UDim2.new(1, 0, 0, 30)
    self.keyStatus.Font = Enum.Font.Gotham
    self.keyStatus.Text = ""
    self.keyStatus.TextColor3 = SUBTEXT_COLOR
    self.keyStatus.TextSize = 14
    self.keyStatus.Parent = self.keyFrame
    
    -- Make the key frame draggable
    MakeDraggable(self.keyFrame, self.keyFrame)
    
    -- Submit key functionality
    self.submitButton.MouseButton1Click:Connect(function()
        self:CheckKey()
    end)
    
    -- Also check key when pressing enter
    self.keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self:CheckKey()
        end
    end)
    
    -- Hover effects
    self.submitButton.MouseEnter:Connect(function()
        TweenService:Create(self.submitButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(110, 160, 255)}):Play()
    end)
    
    self.submitButton.MouseLeave:Connect(function()
        TweenService:Create(self.submitButton, TweenInfo.new(0.2), {BackgroundColor3 = ACCENT_COLOR}):Play()
    end)
end

function FuturaUI:CheckKey()
    local inputKey = self.keyInput.Text
    
    if inputKey == "" then
        self.keyStatus.Text = "Please enter a key."
        self.keyStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    
    if inputKey == self.key then
        self.keyStatus.Text = "Key verified successfully!"
        self.keyStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Create a success animation
        TweenService:Create(self.keyFrame, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(40, 60, 40)}):Play()
        
        -- Wait for the animation to finish and create the main UI
        delay(1, function()
            self.keyVerified = true
            self.keyGui:Destroy()
            self:CreateUI()
        end)
    else
        self.keyStatus.Text = "Invalid key. Please try again."
        self.keyStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Create an error animation
        TweenService:Create(self.keyFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 30, 30)}):Play()
        delay(0.4, function()
            TweenService:Create(self.keyFrame, TweenInfo.new(0.2), {BackgroundColor3 = BACKGROUND_COLOR}):Play()
        end)
    end
end

function FuturaUI:Toggle()
    self.toggled = not self.toggled
    
    if self.toggled then
        -- Show the UI
        self.mainFrame.Visible = true
        TweenService:Create(self.mainFrame, TweenInfo.new(TWEEN_SPEED), {
            Position = UDim2.new(0.5, -325, 0.5, -200),
            Size = UDim2.new(0, 650, 0, 400)
        }):Play()
        
        if self.isMobile then
            TweenService:Create(self.mobileToggle, TweenInfo.new(TWEEN_SPEED), {
                Position = UDim2.new(0, 10, 0, 10)
            }):Play()
        end
    else
        -- Hide the UI
        TweenService:Create(self.mainFrame, TweenInfo.new(TWEEN_SPEED), {
            Position = UDim2.new(0.5, -325, 1, 50),
            Size = UDim2.new(0, 650, 0, 400)
        }):Play()
        
        if self.isMobile then
            TweenService:Create(self.mobileToggle, TweenInfo.new(TWEEN_SPEED), {
                Position = UDim2.new(0, 10, 1, -60)
            }):Play()
        end
        
        -- Delay hiding completely until animation finishes
        delay(TWEEN_SPEED, function()
            if not self.toggled then
                self.mainFrame.Visible = false
            end
        end)
    end
end

function FuturaUI:AddSection(name)
    -- Create a new section
    local section = {
        name = name,
        elements = {},
        contentFrame = nil,
        button = nil
    }
    
    -- Create the section button
    section.button = Instance.new("TextButton")
    section.button.Name = name .. "Button"
    section.button.BackgroundColor3 = ELEMENT_COLOR
    section.button.Size = UDim2.new(1, -20, 0, 40)
    section.button.Font = Enum.Font.GothamSemibold
    section.button.Text = name
    section.button.TextColor3 = TEXT_COLOR
    section.button.TextSize = 14
    section.button.Parent = self.sectionsScroll
    CreateRoundCorner(section.button)
    
    -- Create the section content frame
    section.contentFrame = Instance.new("Frame")
    section.contentFrame.Name = name .. "Content"
    section.contentFrame.BackgroundTransparency = 1
    section.contentFrame.Size = UDim2.new(1, 0, 0, 0)
    section.contentFrame.Parent = self.contentScroll
    section.contentFrame.Visible = false
    
    -- Create the section content list layout
    local contentList = Instance.new("UIListLayout")
    contentList.Name = "ContentList"
    contentList.Padding = UDim.new(0, 8)
    contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Parent = section.contentFrame
    
    -- Setup click handler
    section.button.MouseButton1Click:Connect(function()
        self:SelectSection(name)
    end)
    
    -- Hover effects
    section.button.MouseEnter:Connect(function()
        if self.currentSection ~= name then
            TweenService:Create(section.button, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_COLOR_LIGHT}):Play()
        end
    end)
    
    section.button.MouseLeave:Connect(function()
        if self.currentSection ~= name then
            TweenService:Create(section.button, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
        end
    end)
    
    -- Update content size when elements change
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.contentFrame.Size = UDim2.new(1, 0, 0, contentList.AbsoluteContentSize.Y)
        self.contentScroll.CanvasSize = UDim2.new(0, 0, 0, self.contentList.AbsoluteContentSize.Y + 20)
    end)
    
    -- Add section to the sections table
    table.insert(self.sections, section)
    
    -- Select this section if it's the first one
    if #self.sections == 1 then
        self:SelectSection(name)
    end
    
    -- Return the section for chaining
    return self
end

function FuturaUI:SelectSection(name)
    -- Hide all sections
    for _, section in pairs(self.sections) do
        section.contentFrame.Visible = false
        TweenService:Create(section.button, TweenInfo.new(0.2), {
            BackgroundColor3 = ELEMENT_COLOR,
            TextColor3 = TEXT_COLOR
        }):Play()
    end
    
    -- Find and show the selected section
    for _, section in pairs(self.sections) do
        if section.name == name then
            section.contentFrame.Visible = true
            TweenService:Create(section.button, TweenInfo.new(0.2), {
                BackgroundColor3 = ACCENT_COLOR,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            self.currentSection = name
            break
        end
    end
end

function FuturaUI:FindSection(name)
    for _, section in pairs(self.sections) do
        if section.name == name then
            return section
        end
    end
    return nil
end

-- UI Elements for Sections

function FuturaUI:AddLabel(sectionName, text)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    local labelFrame = Instance.new("Frame")
    labelFrame.Name = "LabelFrame"
    labelFrame.BackgroundTransparency = 1
    labelFrame.Size = UDim2.new(1, 0, 0, 30)
    labelFrame.Parent = section.contentFrame
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.Text = text
    label.TextColor3 = TEXT_COLOR
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = labelFrame
    
    -- Return the label for potential updates
    return label
end

function FuturaUI:AddButton(sectionName, text, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.BackgroundColor3 = ELEMENT_COLOR
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Font = Enum.Font.GothamSemibold
    button.Text = text
    button.TextColor3 = TEXT_COLOR
    button.TextSize = 14
    button.Parent = section.contentFrame
    CreateRoundCorner(button)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_COLOR_LIGHT}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
    end)
    
    -- Click effect and callback
    button.MouseButton1Click:Connect(function()
        -- Visual feedback
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = ACCENT_COLOR}):Play()
        delay(0.2, function()
            TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = ELEMENT_COLOR}):Play()
        end)
        
        -- Execute callback
        if callback then
            callback()
        end
    end)
    
    return button
end

function FuturaUI:AddToggle(sectionName, text, default, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = text .. "Toggle"
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.Parent = section.contentFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "Label"
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Position = UDim2.new(0, 0, 0, 0)
    toggleLabel.Size = UDim2.new(1, -60, 1, 0)
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.Text = text
    toggleLabel.TextColor3 = TEXT_COLOR
    toggleLabel.TextSize = 14
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "Button"
    toggleButton.BackgroundColor3 = ELEMENT_COLOR
    toggleButton.Position = UDim2.new(1, -50, 0.5, -12)
    toggleButton.Size = UDim2.new(0, 50, 0, 24)
    toggleButton.Parent = toggleFrame
    CreateRoundCorner(toggleButton, UDim.new(1, 0))
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Name = "Indicator"
    toggleIndicator.AnchorPoint = Vector2.new(0, 0.5)
    toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleIndicator.Position = UDim2.new(0, 4, 0.5, 0)
    toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
    toggleIndicator.Parent = toggleButton
    CreateRoundCorner(toggleIndicator, UDim.new(1, 0))
    
    -- State
    local toggled = default or false
    
    -- Update toggle state
    local function updateToggle()
        if toggled then
            TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = ACCENT_COLOR}):Play()
            TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 30, 0.5, 0)}):Play()
        else
            TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
            TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 4, 0.5, 0)}):Play()
        end
        
        if callback then
            callback(toggled)
        end
    end
    
    -- Initialize
    if toggled then
        toggleButton.BackgroundColor3 = ACCENT_COLOR
        toggleIndicator.Position = UDim2.new(0, 30, 0.5, 0)
    end
    
    -- Create a transparent button that covers the entire frame for better UX
    local clickHandler = Instance.new("TextButton")
    clickHandler.Name = "ClickHandler"
    clickHandler.BackgroundTransparency = 1
    clickHandler.Size = UDim2.new(1, 0, 1, 0)
    clickHandler.Text = ""
    clickHandler.Parent = toggleFrame
    
    -- Click handler
    clickHandler.MouseButton1Click:Connect(function()
        toggled = not toggled
        updateToggle()
    end)
    
    -- Return control functions
    return {
        SetValue = function(value)
            toggled = value
            updateToggle()
        end,
        GetValue = function()
            return toggled
        end
    }
end

function FuturaUI:AddSlider(sectionName, text, min, max, default, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    min = min or 0
    max = max or 100
    default = default or min
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = text .. "Slider"
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Size = UDim2.new(1, 0, 0, 60)
    sliderFrame.Parent = section.contentFrame
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Name = "Label"
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Position = UDim2.new(0, 0, 0, 0)
    sliderLabel.Size = UDim2.new(1, 0, 0, 20)
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.Text = text
    sliderLabel.TextColor3 = TEXT_COLOR
    sliderLabel.TextSize = 14
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = ACCENT_COLOR
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local sliderBackground = Instance.new("Frame")
    sliderBackground.Name = "Background"
    sliderBackground.BackgroundColor3 = ELEMENT_COLOR
    sliderBackground.Position = UDim2.new(0, 0, 0, 30)
    sliderBackground.Size = UDim2.new(1, 0, 0, 10)
    sliderBackground.Parent = sliderFrame
    CreateRoundCorner(sliderBackground, UDim.new(1, 0))
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.BackgroundColor3 = ACCENT_COLOR
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Parent = sliderBackground
    CreateRoundCorner(sliderFill, UDim.new(1, 0))
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "Button"
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.Position = UDim2.new(sliderFill.Size.X.Scale, -5, 0.5, 0)
    sliderButton.Size = UDim2.new(0, 15, 0, 15)
    sliderButton.Text = ""
    sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderButton.Parent = sliderBackground
    CreateRoundCorner(sliderButton, UDim.new(1, 0))
    
    -- State
    local value = default
    local dragging = false
    
    -- Update slider value
    local function updateSlider(newValue)
        value = math.clamp(newValue, min, max)
        local scale = (value - min) / (max - min)
        
        -- Update visual elements
        TweenService:Create(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(scale, 0, 1, 0)}):Play()
        TweenService:Create(sliderButton, TweenInfo.new(0.1), {Position = UDim2.new(scale, 0, 0.5, 0)}):Play()
        valueLabel.Text = tostring(math.floor(value))
        
        if callback then
            callback(value)
        end
    end
    
    -- Slider interaction
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    sliderBackground.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            
            -- Calculate value based on input position
            local scale = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
            local newValue = min + (max - min) * scale
            updateSlider(newValue)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            -- Calculate value based on input position
            local scale = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
            local newValue = min + (max - min) * scale
            updateSlider(newValue)
        end
    end)
    
    -- Initialize
    updateSlider(default)
    
    -- Return control functions
    return {
        SetValue = function(newValue)
            updateSlider(newValue)
        end,
        GetValue = function()
            return value
        end
    }
end

function FuturaUI:AddDropdown(sectionName, text, options, default, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    options = options or {}
    default = default or options[1] or ""
    
    -- Create a separate container for the dropdown to manage Z-index and layering
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Name = text .. "DropdownContainer"
    dropdownContainer.BackgroundTransparency = 1
    dropdownContainer.Size = UDim2.new(1, 0, 0, 70)
    dropdownContainer.ZIndex = 5 -- Base Z-index for container
    dropdownContainer.Parent = section.contentFrame
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = text .. "Dropdown"
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Size = UDim2.new(1, 0, 0, 70)
    dropdownFrame.ZIndex = 5 -- Match container Z-index
    dropdownFrame.Parent = dropdownContainer
    
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "Label"
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Position = UDim2.new(0, 0, 0, 0)
    dropdownLabel.Size = UDim2.new(1, 0, 0, 20)
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.Text = text
    dropdownLabel.TextColor3 = TEXT_COLOR
    dropdownLabel.TextSize = 14
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.ZIndex = 6 -- Increase Z-index by 1
    dropdownLabel.Parent = dropdownFrame
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "Button"
    dropdownButton.BackgroundColor3 = ELEMENT_COLOR
    dropdownButton.Position = UDim2.new(0, 0, 0, 25)
    dropdownButton.Size = UDim2.new(1, 0, 0, 40)
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Text = default
    dropdownButton.TextColor3 = TEXT_COLOR
    dropdownButton.TextSize = 14
    dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    dropdownButton.TextTruncate = Enum.TextTruncate.AtEnd
    dropdownButton.ZIndex = 6 -- Increase Z-index by 1
    dropdownButton.Parent = dropdownFrame
    CreateRoundCorner(dropdownButton)
    
    local paddingLeft = Instance.new("UIPadding")
    paddingLeft.Name = "PaddingLeft"
    paddingLeft.PaddingLeft = UDim.new(0, 10)
    paddingLeft.Parent = dropdownButton
    
    local expandIcon = Instance.new("ImageLabel")
    expandIcon.Name = "ExpandIcon"
    expandIcon.BackgroundTransparency = 1
    expandIcon.Position = UDim2.new(1, -30, 0.5, -8)
    expandIcon.Size = UDim2.new(0, 16, 0, 16)
    expandIcon.Image = "rbxassetid://6031091004"  -- Dropdown arrow
    expandIcon.ImageColor3 = TEXT_COLOR
    expandIcon.ZIndex = 7 -- Increase Z-index by 1
    expandIcon.Parent = dropdownButton
    
    -- Create a dropdown menu that will be parented to GuiBase when opened
    -- This ensures it's displayed on top of everything
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "Options"
    optionsFrame.BackgroundColor3 = ELEMENT_COLOR
    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
    optionsFrame.ClipsDescendants = true
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 100 -- Very high Z-index to ensure it's on top
    optionsFrame.Parent = self.guiBase -- Parent to the main GUI base instead of the button
    CreateRoundCorner(optionsFrame)
    
    -- Create a background overlay to prevent clicking through
    local overlay = Instance.new("Frame")
    overlay.Name = "DropdownOverlay"
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.7 -- Semi-transparent
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 99 -- Just below the dropdown menu
    overlay.Visible = false
    overlay.Parent = self.guiBase
    
    local optionsList = Instance.new("UIListLayout")
    optionsList.Name = "List"
    optionsList.Padding = UDim.new(0, 5)
    optionsList.SortOrder = Enum.SortOrder.LayoutOrder
    optionsList.Parent = optionsFrame
    
    local optionsPadding = Instance.new("UIPadding")
    optionsPadding.Name = "Padding"
    optionsPadding.PaddingTop = UDim.new(0, 5)
    optionsPadding.PaddingBottom = UDim.new(0, 5)
    optionsPadding.PaddingLeft = UDim.new(0, 10)
    optionsPadding.PaddingRight = UDim.new(0, 10)
    optionsPadding.Parent = optionsFrame
    
    -- State
    local expanded = false
    local selectedOption = default
    
    -- Create the options
    local optionButtons = {}
    for i, option in pairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option_" .. option
        optionButton.BackgroundTransparency = 1
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Font = Enum.Font.Gotham
        optionButton.Text = option
        optionButton.TextColor3 = TEXT_COLOR
        optionButton.TextSize = 14
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.ZIndex = 11
        optionButton.Parent = optionsFrame
        
        optionButton.MouseEnter:Connect(function()
            TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundTransparency = 0.9}):Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            selectedOption = option
            dropdownButton.Text = option
            
            -- Toggle dropdown state
            expanded = false
            TweenService:Create(optionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            delay(0.2, function()
                optionsFrame.Visible = false
            end)
            
            -- Handle callback
            if callback then
                callback(option)
            end
        end)
        
        table.insert(optionButtons, optionButton)
    end
    
    -- Update options frame height based on content
    optionsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded then
            optionsFrame.Size = UDim2.new(1, 0, 0, optionsList.AbsoluteContentSize.Y + 10)
        end
    end)
    
    -- Toggle dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        expanded = not expanded
        
        if expanded then
            -- Position the dropdown relative to the button in screen space
            local buttonAbsPos = dropdownButton.AbsolutePosition
            local buttonAbsSize = dropdownButton.AbsoluteSize
            
            optionsFrame.Position = UDim2.new(0, buttonAbsPos.X, 0, buttonAbsPos.Y + buttonAbsSize.Y + 5)
            optionsFrame.Size = UDim2.new(0, buttonAbsSize.X, 0, 0)
            
            -- Show overlay
            overlay.Visible = true
            overlay.ZIndex = 99
            
            -- Show dropdown
            optionsFrame.Visible = true
            TweenService:Create(optionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, buttonAbsSize.X, 0, optionsList.AbsoluteContentSize.Y + 10)}):Play()
            
            -- Add a click handler to the overlay to close dropdown when clicking outside
            overlay.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    expanded = false
                    TweenService:Create(optionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, buttonAbsSize.X, 0, 0)}):Play()
                    overlay.Visible = false
                    delay(0.2, function()
                        if not expanded then
                            optionsFrame.Visible = false
                        end
                    end)
                end
            end)
        else
            -- Hide dropdown and overlay
            TweenService:Create(optionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, optionsFrame.AbsoluteSize.X, 0, 0)}):Play()
            overlay.Visible = false
            delay(0.2, function()
                if not expanded then
                    optionsFrame.Visible = false
                end
            end)
        end
    end)
    
    -- Hover effects
    dropdownButton.MouseEnter:Connect(function()
        TweenService:Create(dropdownButton, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_COLOR_LIGHT}):Play()
    end)
    
    dropdownButton.MouseLeave:Connect(function()
        TweenService:Create(dropdownButton, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
    end)
    
    -- Return control functions
    return {
        SetValue = function(option)
            if table.find(options, option) then
                selectedOption = option
                dropdownButton.Text = option
                
                if callback then
                    callback(option)
                end
            end
        end,
        GetValue = function()
            return selectedOption
        end,
        Refresh = function(newOptions, keepValue)
            -- Clear existing options
            for _, btn in pairs(optionButtons) do
                btn:Destroy()
            end
            optionButtons = {}
            
            -- Update options list
            options = newOptions
            
            -- Reset value if needed
            if not keepValue or not table.find(newOptions, selectedOption) then
                selectedOption = newOptions[1] or ""
                dropdownButton.Text = selectedOption
            end
            
            -- Recreate options
            for i, option in pairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Name = "Option_" .. option
                optionButton.BackgroundTransparency = 1
                optionButton.Size = UDim2.new(1, 0, 0, 30)
                optionButton.Font = Enum.Font.Gotham
                optionButton.Text = option
                optionButton.TextColor3 = TEXT_COLOR
                optionButton.TextSize = 14
                optionButton.TextXAlignment = Enum.TextXAlignment.Left
                optionButton.ZIndex = 11
                optionButton.Parent = optionsFrame
                
                optionButton.MouseEnter:Connect(function()
                    TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundTransparency = 0.9}):Play()
                end)
                
                optionButton.MouseLeave:Connect(function()
                    TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    selectedOption = option
                    dropdownButton.Text = option
                    
                    -- Toggle dropdown state
                    expanded = false
                    TweenService:Create(optionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, optionsFrame.AbsoluteSize.X, 0, 0)}):Play()
                    overlay.Visible = false
                    delay(0.2, function()
                        optionsFrame.Visible = false
                    end)
                    
                    -- Handle callback
                    if callback then
                        callback(option)
                    end
                end)
                
                table.insert(optionButtons, optionButton)
            end
            
            -- Trigger callback if needed
            if callback and keepValue and selectedOption ~= "" then
                callback(selectedOption)
            end
        end
    }
end

function FuturaUI:AddTextbox(sectionName, text, placeholder, default, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    placeholder = placeholder or "Enter text..."
    default = default or ""
    
    local textboxFrame = Instance.new("Frame")
    textboxFrame.Name = text .. "Textbox"
    textboxFrame.BackgroundTransparency = 1
    textboxFrame.Size = UDim2.new(1, 0, 0, 70)
    textboxFrame.Parent = section.contentFrame
    
    local textboxLabel = Instance.new("TextLabel")
    textboxLabel.Name = "Label"
    textboxLabel.BackgroundTransparency = 1
    textboxLabel.Position = UDim2.new(0, 0, 0, 0)
    textboxLabel.Size = UDim2.new(1, 0, 0, 20)
    textboxLabel.Font = Enum.Font.Gotham
    textboxLabel.Text = text
    textboxLabel.TextColor3 = TEXT_COLOR
    textboxLabel.TextSize = 14
    textboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    textboxLabel.Parent = textboxFrame
    
    local textbox = Instance.new("TextBox")
    textbox.Name = "Input"
    textbox.BackgroundColor3 = ELEMENT_COLOR
    textbox.Position = UDim2.new(0, 0, 0, 25)
    textbox.Size = UDim2.new(1, 0, 0, 40)
    textbox.Font = Enum.Font.Gotham
    textbox.PlaceholderText = placeholder
    textbox.PlaceholderColor3 = SUBTEXT_COLOR
    textbox.Text = default
    textbox.TextColor3 = TEXT_COLOR
    textbox.TextSize = 14
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.ClearTextOnFocus = false
    textbox.Parent = textboxFrame
    CreateRoundCorner(textbox)
    
    local paddingLeft = Instance.new("UIPadding")
    paddingLeft.Name = "PaddingLeft"
    paddingLeft.PaddingLeft = UDim.new(0, 10)
    paddingLeft.Parent = textbox
    
    -- Focus effects
    textbox.Focused:Connect(function()
        TweenService:Create(textbox, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_COLOR_DARK}):Play()
    end)
    
    textbox.FocusLost:Connect(function(enterPressed)
        TweenService:Create(textbox, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
        
        if callback then
            callback(textbox.Text, enterPressed)
        end
    end)
    
    -- Return control functions
    return {
        SetValue = function(value)
            textbox.Text = value
            
            if callback then
                callback(value, false)
            end
        end,
        GetValue = function()
            return textbox.Text
        end
    }
end

function FuturaUI:AddColorPicker(sectionName, text, default, callback)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    default = default or Color3.fromRGB(255, 255, 255)
    
    local colorPickerFrame = Instance.new("Frame")
    colorPickerFrame.Name = text .. "ColorPicker"
    colorPickerFrame.BackgroundTransparency = 1
    colorPickerFrame.Size = UDim2.new(1, 0, 0, 40)
    colorPickerFrame.Parent = section.contentFrame
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Name = "Label"
    colorLabel.BackgroundTransparency = 1
    colorLabel.Position = UDim2.new(0, 0, 0, 0)
    colorLabel.Size = UDim2.new(1, -60, 1, 0)
    colorLabel.Font = Enum.Font.Gotham
    colorLabel.Text = text
    colorLabel.TextColor3 = TEXT_COLOR
    colorLabel.TextSize = 14
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorPickerFrame
    
    local colorDisplay = Instance.new("Frame")
    colorDisplay.Name = "Display"
    colorDisplay.BackgroundColor3 = default
    colorDisplay.Position = UDim2.new(1, -50, 0.5, -12)
    colorDisplay.Size = UDim2.new(0, 40, 0, 24)
    colorDisplay.Parent = colorPickerFrame
    CreateRoundCorner(colorDisplay)
    
    -- Create color selector (a more complex UI component)
    local colorSelector = Instance.new("Frame")
    colorSelector.Name = "ColorSelector"
    colorSelector.BackgroundColor3 = BACKGROUND_COLOR
    colorSelector.Position = UDim2.new(1, 10, 0, 0)
    colorSelector.Size = UDim2.new(0, 200, 0, 200)
    colorSelector.Visible = false
    colorSelector.ZIndex = 100
    colorSelector.Parent = colorPickerFrame
    CreateRoundCorner(colorSelector)
    CreateShadow(colorSelector)
    
    -- This is a simplified color picker with just RGB sliders
    -- In a full implementation, you might want a color gradient
    
    local redSlider = Instance.new("Frame")
    redSlider.Name = "RedSlider"
    redSlider.BackgroundTransparency = 1
    redSlider.Position = UDim2.new(0, 10, 0, 30)
    redSlider.Size = UDim2.new(1, -20, 0, 40)
    redSlider.ZIndex = 101
    redSlider.Parent = colorSelector
    
    local redLabel = Instance.new("TextLabel")
    redLabel.Name = "Label"
    redLabel.BackgroundTransparency = 1
    redLabel.Size = UDim2.new(0, 30, 0, 20)
    redLabel.Font = Enum.Font.GothamBold
    redLabel.Text = "R:"
    redLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    redLabel.TextSize = 14
    redLabel.ZIndex = 101
    redLabel.Parent = redSlider
    
    local redValue = Instance.new("TextLabel")
    redValue.Name = "Value"
    redValue.BackgroundTransparency = 1
    redValue.Position = UDim2.new(1, -40, 0, 0)
    redValue.Size = UDim2.new(0, 40, 0, 20)
    redValue.Font = Enum.Font.Gotham
    redValue.Text = tostring(math.floor(default.R * 255))
    redValue.TextColor3 = TEXT_COLOR
    redValue.TextSize = 14
    redValue.ZIndex = 101
    redValue.Parent = redSlider
    
    local redBack = Instance.new("Frame")
    redBack.Name = "Background"
    redBack.BackgroundColor3 = ELEMENT_COLOR
    redBack.Position = UDim2.new(0, 40, 0, 25)
    redBack.Size = UDim2.new(1, -90, 0, 10)
    redBack.ZIndex = 101
    redBack.Parent = redSlider
    CreateRoundCorner(redBack, UDim.new(1, 0))
    
    local redFill = Instance.new("Frame")
    redFill.Name = "Fill"
    redFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    redFill.Size = UDim2.new(default.R, 0, 1, 0)
    redFill.ZIndex = 102
    redFill.Parent = redBack
    CreateRoundCorner(redFill, UDim.new(1, 0))
    
    -- Green slider
    local greenSlider = Instance.new("Frame")
    greenSlider.Name = "GreenSlider"
    greenSlider.BackgroundTransparency = 1
    greenSlider.Position = UDim2.new(0, 10, 0, 80)
    greenSlider.Size = UDim2.new(1, -20, 0, 40)
    greenSlider.ZIndex = 101
    greenSlider.Parent = colorSelector
    
    local greenLabel = Instance.new("TextLabel")
    greenLabel.Name = "Label"
    greenLabel.BackgroundTransparency = 1
    greenLabel.Size = UDim2.new(0, 30, 0, 20)
    greenLabel.Font = Enum.Font.GothamBold
    greenLabel.Text = "G:"
    greenLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    greenLabel.TextSize = 14
    greenLabel.ZIndex = 101
    greenLabel.Parent = greenSlider
    
    local greenValue = Instance.new("TextLabel")
    greenValue.Name = "Value"
    greenValue.BackgroundTransparency = 1
    greenValue.Position = UDim2.new(1, -40, 0, 0)
    greenValue.Size = UDim2.new(0, 40, 0, 20)
    greenValue.Font = Enum.Font.Gotham
    greenValue.Text = tostring(math.floor(default.G * 255))
    greenValue.TextColor3 = TEXT_COLOR
    greenValue.TextSize = 14
    greenValue.ZIndex = 101
    greenValue.Parent = greenSlider
    
    local greenBack = Instance.new("Frame")
    greenBack.Name = "Background"
    greenBack.BackgroundColor3 = ELEMENT_COLOR
    greenBack.Position = UDim2.new(0, 40, 0, 25)
    greenBack.Size = UDim2.new(1, -90, 0, 10)
    greenBack.ZIndex = 101
    greenBack.Parent = greenSlider
    CreateRoundCorner(greenBack, UDim.new(1, 0))
    
    local greenFill = Instance.new("Frame")
    greenFill.Name = "Fill"
    greenFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    greenFill.Size = UDim2.new(default.G, 0, 1, 0)
    greenFill.ZIndex = 102
    greenFill.Parent = greenBack
    CreateRoundCorner(greenFill, UDim.new(1, 0))
    
    -- Blue slider
    local blueSlider = Instance.new("Frame")
    blueSlider.Name = "BlueSlider"
    blueSlider.BackgroundTransparency = 1
    blueSlider.Position = UDim2.new(0, 10, 0, 130)
    blueSlider.Size = UDim2.new(1, -20, 0, 40)
    blueSlider.ZIndex = 101
    blueSlider.Parent = colorSelector
    
    local blueLabel = Instance.new("TextLabel")
    blueLabel.Name = "Label"
    blueLabel.BackgroundTransparency = 1
    blueLabel.Size = UDim2.new(0, 30, 0, 20)
    blueLabel.Font = Enum.Font.GothamBold
    blueLabel.Text = "B:"
    blueLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    blueLabel.TextSize = 14
    blueLabel.ZIndex = 101
    blueLabel.Parent = blueSlider
    
    local blueValue = Instance.new("TextLabel")
    blueValue.Name = "Value"
    blueValue.BackgroundTransparency = 1
    blueValue.Position = UDim2.new(1, -40, 0, 0)
    blueValue.Size = UDim2.new(0, 40, 0, 20)
    blueValue.Font = Enum.Font.Gotham
    blueValue.Text = tostring(math.floor(default.B * 255))
    blueValue.TextColor3 = TEXT_COLOR
    blueValue.TextSize = 14
    blueValue.ZIndex = 101
    blueValue.Parent = blueSlider
    
    local blueBack = Instance.new("Frame")
    blueBack.Name = "Background"
    blueBack.BackgroundColor3 = ELEMENT_COLOR
    blueBack.Position = UDim2.new(0, 40, 0, 25)
    blueBack.Size = UDim2.new(1, -90, 0, 10)
    blueBack.ZIndex = 101
    blueBack.Parent = blueSlider
    CreateRoundCorner(blueBack, UDim.new(1, 0))
    
    local blueFill = Instance.new("Frame")
    blueFill.Name = "Fill"
    blueFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    blueFill.Size = UDim2.new(default.B, 0, 1, 0)
    blueFill.ZIndex = 102
    blueFill.Parent = blueBack
    CreateRoundCorner(blueFill, UDim.new(1, 0))
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.BackgroundColor3 = ACCENT_COLOR
    closeButton.Position = UDim2.new(0, 10, 1, -40)
    closeButton.Size = UDim2.new(1, -20, 0, 30)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "Close"
    closeButton.TextColor3 = TEXT_COLOR
    closeButton.TextSize = 14
    closeButton.ZIndex = 101
    closeButton.Parent = colorSelector
    CreateRoundCorner(closeButton)
    
    -- State
    local selectedColor = default
    local colorSelectorVisible = false
    
    -- Create draggable sliders
    local function createDraggableSlider(slider, fill, valueLabel, colorComponent)
        local back = slider:FindFirstChild("Background")
        local dragging = false
        
        local function updateSlider(scale)
            -- Clamp scale between 0 and 1
            scale = math.clamp(scale, 0, 1)
            
            -- Update fill
            fill.Size = UDim2.new(scale, 0, 1, 0)
            
            -- Update value label
            valueLabel.Text = tostring(math.floor(scale * 255))
            
            -- Update color
            if colorComponent == "R" then
                selectedColor = Color3.new(scale, selectedColor.G, selectedColor.B)
            elseif colorComponent == "G" then
                selectedColor = Color3.new(selectedColor.R, scale, selectedColor.B)
            else -- B
                selectedColor = Color3.new(selectedColor.R, selectedColor.G, scale)
            end
            
            -- Update color display
            colorDisplay.BackgroundColor3 = selectedColor
            
            -- Call callback
            if callback then
                callback(selectedColor)
            end
        end
        
        back.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                
                -- Calculate scale based on input position
                local scale = math.clamp((input.Position.X - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
                updateSlider(scale)
            end
        end)
        
        back.InputEnded:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                -- Calculate scale based on input position
                local scale = math.clamp((input.Position.X - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
                updateSlider(scale)
            end
        end)
    end
    
    createDraggableSlider(redSlider, redFill, redValue, "R")
    createDraggableSlider(greenSlider, greenFill, greenValue, "G")
    createDraggableSlider(blueSlider, blueFill, blueValue, "B")
    
    -- Toggle color selector
    colorDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            colorSelectorVisible = not colorSelectorVisible
            colorSelector.Visible = colorSelectorVisible
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        colorSelectorVisible = false
        colorSelector.Visible = false
    end)
    
    -- Return control functions
    return {
        SetValue = function(color)
            selectedColor = color
            colorDisplay.BackgroundColor3 = color
            
            -- Update slider positions
            redFill.Size = UDim2.new(color.R, 0, 1, 0)
            greenFill.Size = UDim2.new(color.G, 0, 1, 0)
            blueFill.Size = UDim2.new(color.B, 0, 1, 0)
            
            -- Update value labels
            redValue.Text = tostring(math.floor(color.R * 255))
            greenValue.Text = tostring(math.floor(color.G * 255))
            blueValue.Text = tostring(math.floor(color.B * 255))
            
            if callback then
                callback(color)
            end
        end,
        GetValue = function()
            return selectedColor
        end
    }
end

function FuturaUI:AddDivider(sectionName, text)
    local section = self:FindSection(sectionName)
    if not section then return end
    
    local dividerFrame = Instance.new("Frame")
    dividerFrame.Name = "Divider" .. (text and ("_" .. text) or "")
    dividerFrame.BackgroundTransparency = 1
    dividerFrame.Size = UDim2.new(1, 0, 0, 24)
    dividerFrame.Parent = section.contentFrame
    
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.BackgroundColor3 = ELEMENT_COLOR
    line.BorderSizePixel = 0
    
    -- Different layout based on whether text is provided
    if text and text ~= "" then
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Parent = dividerFrame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "Text"
        textLabel.BackgroundColor3 = BACKGROUND_COLOR
        textLabel.BackgroundTransparency = 0
        textLabel.Position = UDim2.new(0.5, 0, 0, 0)
        textLabel.AnchorPoint = Vector2.new(0.5, 0)
        textLabel.Size = UDim2.new(0, 0, 1, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextColor3 = SUBTEXT_COLOR
        textLabel.TextSize = 12
        textLabel.Text = " " .. text .. " "
        textLabel.Parent = dividerFrame
        
        -- Auto-size the label based on text
        local textSize = TextService:GetTextSize(textLabel.Text, 12, Enum.Font.GothamBold, Vector2.new(math.huge, math.huge))
        textLabel.Size = UDim2.new(0, textSize.X + 10, 1, 0)
    else
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Parent = dividerFrame
    end
    
    return dividerFrame
end

function FuturaUI:Destroy()
    -- Create closing animation
    TweenService:Create(self.mainFrame, TweenInfo.new(0.5), {
        Position = UDim2.new(0.5, -325, 1.2, 0),
        BackgroundTransparency = 1
    }):Play()
    
    -- Also fade out the mobile toggle if it exists
    if self.mobileToggle then
        TweenService:Create(self.mobileToggle, TweenInfo.new(0.5), {
            Position = UDim2.new(0, 10, 1.2, 0),
            BackgroundTransparency = 1
        }):Play()
    end
    
    -- Destroy the UI after animation completes
    delay(0.6, function()
        if self.gui then
            self.gui:Destroy()
        end
        if self.keyGui then
            self.keyGui:Destroy()
        end
    end)
end

function FuturaUI:Notify(title, message, duration)
    title = title or "Notification"
    message = message or ""
    duration = duration or 3
    
    -- Create notification container if it doesn't exist
    if not self.notificationContainer then
        self.notificationContainer = Instance.new("Frame")
        self.notificationContainer.Name = "NotificationContainer"
        self.notificationContainer.BackgroundTransparency = 1
        self.notificationContainer.Position = UDim2.new(1, -310, 0, 10)
        self.notificationContainer.Size = UDim2.new(0, 300, 1, -20)
        self.notificationContainer.Parent = self.gui
        
        local notificationList = Instance.new("UIListLayout")
        notificationList.Name = "NotificationList"
        notificationList.Padding = UDim.new(0, 10)
        notificationList.VerticalAlignment = Enum.VerticalAlignment.Top
        notificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
        notificationList.SortOrder = Enum.SortOrder.LayoutOrder
        notificationList.Parent = self.notificationContainer
    end
    
    -- Create the notification
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.BackgroundColor3 = BACKGROUND_COLOR
    notification.Size = UDim2.new(1, 0, 0, 80)
    notification.Position = UDim2.new(1, 0, 0, 0)
    notification.Parent = self.notificationContainer
    CreateRoundCorner(notification)
    CreateShadow(notification)
    
    -- Notification title
    local notificationTitle = Instance.new("TextLabel")
    notificationTitle.Name = "Title"
    notificationTitle.BackgroundTransparency = 1
    notificationTitle.Position = UDim2.new(0, 15, 0, 10)
    notificationTitle.Size = UDim2.new(1, -30, 0, 20)
    notificationTitle.Font = Enum.Font.GothamBold
    notificationTitle.Text = title
    notificationTitle.TextColor3 = TEXT_COLOR
    notificationTitle.TextSize = 16
    notificationTitle.TextXAlignment = Enum.TextXAlignment.Left
    notificationTitle.Parent = notification
    
    -- Notification message
    local notificationMessage = Instance.new("TextLabel")
    notificationMessage.Name = "Message"
    notificationMessage.BackgroundTransparency = 1
    notificationMessage.Position = UDim2.new(0, 15, 0, 35)
    notificationMessage.Size = UDim2.new(1, -30, 0, 40)
    notificationMessage.Font = Enum.Font.Gotham
    notificationMessage.Text = message
    notificationMessage.TextColor3 = SUBTEXT_COLOR
    notificationMessage.TextSize = 14
    notificationMessage.TextXAlignment = Enum.TextXAlignment.Left
    notificationMessage.TextYAlignment = Enum.TextYAlignment.Top
    notificationMessage.TextWrapped = true
    notificationMessage.Parent = notification
    
    -- Line at the top
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.BackgroundColor3 = ACCENT_COLOR
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0, 0)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Parent = notification
    
    -- Slide in animation
    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Countdown and slide out
    delay(duration, function()
        TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(1, 0, 0, 0)
        }):Play()
        
        delay(0.5, function()
            notification:Destroy()
        end)
    end)
    
    return notification
end

return FuturaUI
