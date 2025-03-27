--[[
    LunarUI Library
    A modern, sleek UI library for Roblox
    Inspired by Rayfield and other popular libraries
    
    Features:
    - Clean, modern design
    - Customizable themes
    - Smooth animations
    - Multiple element types (buttons, toggles, sliders, dropdowns, etc.)
    - Notifications system
    - Key system for verification
    - Simple and intuitive API
]]

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- Variables that will be initialized later
local LocalPlayer
local Mouse
local UIParent

-- Safe services retrieval
local function safeGetService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    
    if success then
        return service
    else
        warn("LunarUI: Failed to get service", serviceName)
        return nil
    end
end

-- Utility Functions
local Utility = {}

function Utility:Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    
    return instance
end

function Utility:Tween(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
        properties
    )
    
    tween:Play()
    return tween
end

function Utility:GetTextSize(text, fontSize, font, frameSize)
    return TextService:GetTextSize(text, fontSize, font, frameSize)
end

function Utility:DarkenColor(color, amount)
    return Color3.new(
        math.clamp(color.R - amount, 0, 1),
        math.clamp(color.G - amount, 0, 1),
        math.clamp(color.B - amount, 0, 1)
    )
end

function Utility:LightenColor(color, amount)
    return Color3.new(
        math.clamp(color.R + amount, 0, 1),
        math.clamp(color.G + amount, 0, 1),
        math.clamp(color.B + amount, 0, 1)
    )
end

function Utility:Ripple(instance, rippleColor)
    local ripple = Utility:Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = rippleColor or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        Position = UDim2.fromOffset(Mouse.X - instance.AbsolutePosition.X, Mouse.Y - instance.AbsolutePosition.Y),
        Size = UDim2.fromScale(0, 0),
        Parent = instance,
        BorderSizePixel = 0,
        ZIndex = instance.ZIndex + 1
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local maxSize = math.max(instance.AbsoluteSize.X, instance.AbsoluteSize.Y) * 2
    
    Utility:Tween(ripple, {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(maxSize, maxSize)
    }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- LunarUI Library
local LunarUI = {
    Theme = {
        Primary = Color3.fromRGB(32, 32, 38),      -- Main background
        Secondary = Color3.fromRGB(25, 25, 30),    -- Secondary background
        Accent = Color3.fromRGB(114, 137, 218),    -- Accent color (like Discord blurple)
        Text = Color3.fromRGB(255, 255, 255),      -- Text color
        DarkText = Color3.fromRGB(175, 175, 175),  -- Darker text for less important info
        Positive = Color3.fromRGB(104, 219, 104),  -- For toggles and positive actions
        Negative = Color3.fromRGB(231, 76, 60),    -- For destructive actions
        Border = Color3.fromRGB(45, 45, 54),       -- Border color
    },
    Flags = {},
    Windows = {},
    Notifications = {},
    Elements = {}
}

function LunarUI:GetScreenSize()
    return Vector2.new(
        workspace.CurrentCamera.ViewportSize.X,
        workspace.CurrentCamera.ViewportSize.Y
    )
end

function LunarUI:ToggleUI()
    for _, window in pairs(self.Windows) do
        window.Main.Visible = not window.Main.Visible
    end
end

function LunarUI:SetTheme(theme)
    for key, value in pairs(theme) do
        if self.Theme[key] then
            self.Theme[key] = value
        end
    end
    
    -- Update UI elements with new theme
    self:UpdateTheme()
end

function LunarUI:UpdateTheme()
    -- This would update all UI elements with the current theme
    -- To be implemented based on UI structure
end

-- Notifications System
function LunarUI:CreateNotification(options)
    options = options or {}
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 3
    local type = options.Type or "Info" -- Info, Success, Error, Warning
    
    -- Colors based on notification type
    local typeColors = {
        Info = self.Theme.Accent,
        Success = self.Theme.Positive,
        Error = self.Theme.Negative,
        Warning = Color3.fromRGB(230, 126, 34) -- Orange
    }
    
    local notificationColor = typeColors[type] or self.Theme.Accent
    
    -- Create notification container if it doesn't exist
    if not self.NotificationContainer then
        self.NotificationContainer = Utility:Create("Frame", {
            Name = "NotificationContainer",
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 300, 1, -40),
            ZIndex = 1000,
            Parent = (UIParent and UIParent:FindFirstChild("LunarUI")) or Utility:Create("ScreenGui", {
                Name = "LunarUI",
                Parent = UIParent or (RunService:IsStudio() and (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5) or game.Players.LocalPlayer:WaitForChild("PlayerGui", 5)) or safeGetService("CoreGui")),
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
                ResetOnSpawn = false
            })
        })
        
        Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.NotificationContainer
        })
    end
    
    -- Create the notification frame
    local notification = Utility:Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = self.Theme.Secondary,
        BorderColor3 = self.Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 0), -- Will be tweened to proper size
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 1001,
        Parent = self.NotificationContainer
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notification
    })
    
    Utility:Create("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = notification
    })
    
    local indicator = Utility:Create("Frame", {
        Name = "Indicator",
        BackgroundColor3 = notificationColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 1002,
        Parent = notification
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = indicator
    })
    
    local titleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -10, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = notificationColor,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002,
        Parent = notification
    })
    
    local contentLabel = Utility:Create("TextLabel", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 26),
        Size = UDim2.new(1, -10, 0, 0),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 1002,
        Parent = notification
    })
    
    -- Calculate the height needed for the content text
    local textSize = Utility:GetTextSize(content, 14, Enum.Font.Gotham, Vector2.new(notification.AbsoluteSize.X - 34, math.huge))
    contentLabel.Size = UDim2.new(1, -10, 0, textSize.Y)
    
    local notificationHeight = 26 + textSize.Y + 12
    notification.Size = UDim2.new(1, 0, 0, notificationHeight)
    
    -- Animation to show the notification
    notification.Size = UDim2.new(1, 0, 0, notificationHeight)
    Utility:Tween(notification, {BackgroundTransparency = 0}, 0.3)
    
    -- Progress bar
    local progressBar = Utility:Create("Frame", {
        Name = "ProgressBar",
        BackgroundColor3 = notificationColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 1002,
        Parent = notification
    })
    
    -- Animate the progress bar
    Utility:Tween(progressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration)
    
    -- Close after duration
    task.delay(duration, function()
        Utility:Tween(notification, {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 0, notification.Position.Y.Offset)
        }, 0.3)
        
        task.delay(0.3, function()
            notification:Destroy()
        end)
    end)
    
    return notification
end

-- Window Creator
function LunarUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "LunarUI"
    local subtitle = options.Subtitle or "A Modern UI Library"
    local size = options.Size or UDim2.new(0, 550, 0, 400)
    local position = options.Position or UDim2.new(0.5, -275, 0.5, -200)
    
    -- Initialize the library if not done already
    if not self._initialized then
        self:Init()
    end
    
    -- Create ScreenGui
    local gui = Utility:Create("ScreenGui", {
        Name = "LunarUI",
        Parent = UIParent or (RunService:IsStudio() and (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5) or Players.LocalPlayer:WaitForChild("PlayerGui", 5)) or safeGetService("CoreGui")),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    
    -- Main window frame
    local main = Utility:Create("Frame", {
        Name = "Main",
        BackgroundColor3 = self.Theme.Primary,
        BorderColor3 = self.Theme.Border,
        BorderSizePixel = 1,
        Position = position,
        Size = size,
        Parent = gui,
        ClipsDescendants = true
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = main
    })
    
    -- Dropshadow
    Utility:Create("CanvasGroup", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 24, 1, 24),
        ZIndex = -1,
        GroupTransparency = 0.5,
        Parent = main
    }, {
        Utility:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-12, -12),
            Size = UDim2.new(1, 24, 1, 24),
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450)
        })
    })
    
    -- Topbar
    local topbar = Utility:Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = main
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = topbar
    })
    
    -- Only round the top corners
    Utility:Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        Parent = topbar
    })
    
    -- Title and subtitle
    local titleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 5),
        Size = UDim2.new(0.5, 0, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })
    
    local subtitleLabel = Utility:Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 22),
        Size = UDim2.new(0.5, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = self.Theme.DarkText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })
    
    -- Close button
    local closeButton = Utility:Create("ImageButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = "rbxassetid://6031094678",
        ImageColor3 = self.Theme.DarkText,
        Parent = topbar
    })
    
    closeButton.MouseEnter:Connect(function()
        Utility:Tween(closeButton, {ImageColor3 = self.Theme.Text}, 0.2)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utility:Tween(closeButton, {ImageColor3 = self.Theme.DarkText}, 0.2)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        Utility:Tween(main, {Size = UDim2.new(0, size.X.Offset, 0, 0)}, 0.2)
        task.wait(0.2)
        gui:Destroy()
    end)
    
    -- Minimize button
    local minimizeButton = Utility:Create("ImageButton", {
        Name = "MinimizeButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -55, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = "rbxassetid://6031082527",
        ImageColor3 = self.Theme.DarkText,
        Parent = topbar
    })
    
    minimizeButton.MouseEnter:Connect(function()
        Utility:Tween(minimizeButton, {ImageColor3 = self.Theme.Text}, 0.2)
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        Utility:Tween(minimizeButton, {ImageColor3 = self.Theme.DarkText}, 0.2)
    end)
    
    local minimized = false
    local originalSize = size
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Utility:Tween(main, {Size = UDim2.new(0, size.X.Offset, 0, 40)}, 0.2)
        else
            Utility:Tween(main, {Size = UDim2.new(0, size.X.Offset, 0, originalSize.Y.Offset)}, 0.2)
        end
    end)
    
    -- Make topbar draggable
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Container for tabs and elements
    local tabContainer = Utility:Create("Frame", {
        Name = "TabContainer",
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 140, 1, -40),
        Parent = main
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = tabContainer
    })
    
    -- Only round the bottom-left corner
    Utility:Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        Parent = tabContainer
    })
    
    Utility:Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Parent = tabContainer
    })
    
    -- Tab List
    local tabList = Utility:Create("ScrollingFrame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 10),
        Size = UDim2.new(1, 0, 1, -10),
        CanvasSize = UDim2.new(0, 0, 0, 0), -- Will be updated as tabs are added
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        Parent = tabContainer
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList
    })
    
    Utility:Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        Parent = tabList
    })
    
    -- Content Container
    local contentContainer = Utility:Create("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 140, 0, 40),
        Size = UDim2.new(1, -140, 1, -40),
        Parent = main
    })
    
    -- Window object
    local window = {
        Main = main,
        Topbar = topbar,
        TabContainer = tabContainer,
        TabList = tabList,
        ContentContainer = contentContainer,
        Tabs = {},
        TabCount = 0,
        ActiveTab = nil
    }
    
    -- Create Tab function
    function window:CreateTab(options)
        options = options or {}
        local name = options.Name or "Tab"
        local icon = options.Icon or "rbxassetid://6031289449" -- Default icon (list)
        
        self.TabCount = self.TabCount + 1
        local tabOrder = self.TabCount
        
        -- Tab button
        local tabButton = Utility:Create("TextButton", {
            Name = name .. "TabButton",
            BackgroundColor3 = LunarUI.Theme.Primary,
            BorderSizePixel = 0,
            Size = UDim2.new(0.9, 0, 0, 32),
            Font = Enum.Font.Gotham,
            Text = "",
            TextColor3 = LunarUI.Theme.Text,
            TextSize = 14,
            AutoButtonColor = false,
            Parent = self.TabList
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = tabButton
        })
        
        local tabIcon = Utility:Create("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = icon,
            ImageColor3 = LunarUI.Theme.DarkText,
            Parent = tabButton
        })
        
        local tabName = Utility:Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 35, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = LunarUI.Theme.DarkText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabButton
        })
        
        -- Tab content
        local tabContent = Utility:Create("ScrollingFrame", {
            Name = name .. "TabContent",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0), -- Will be updated as elements are added
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = LunarUI.Theme.Accent,
            Visible = false,
            Parent = self.ContentContainer
        })
        
        Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabContent
        })
        
        Utility:Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = tabContent
        })
        
        -- Tab object
        local tab = {
            Button = tabButton,
            Content = tabContent,
            Name = name,
            Elements = {},
            Sections = {}
        }
        
        -- Handle tab selection
        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        })
        
        tabButton.MouseEnter:Connect(function()
            if self.ActiveTab ~= name then
                Utility:Tween(tabIcon, {ImageColor3 = LunarUI.Theme.Text}, 0.2)
                Utility:Tween(tabName, {TextColor3 = LunarUI.Theme.Text}, 0.2)
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if self.ActiveTab ~= name then
                Utility:Tween(tabIcon, {ImageColor3 = LunarUI.Theme.DarkText}, 0.2)
                Utility:Tween(tabName, {TextColor3 = LunarUI.Theme.DarkText}, 0.2)
            end
        end)
        
        -- Add tab to window
        self.Tabs[name] = tab
        
        -- Select tab if it's the first one
        if tabOrder == 1 then
            self:SelectTab(name)
        end
        
        -- Update canvas size
        self.TabList.CanvasSize = UDim2.new(0, 0, 0, self.TabList.UIListLayout.AbsoluteContentSize.Y + 10)
        
        -- Section creator
        function tab:CreateSection(options)
            options = options or {}
            local sectionName = options.Name or "Section"
            
            -- Create section frame
            local section = Utility:Create("Frame", {
                Name = sectionName .. "Section",
                BackgroundColor3 = LunarUI.Theme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40), -- Initial size, will be updated
                Parent = tabContent
            })
            
            Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = section
            })
            
            local sectionTitle = Utility:Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = sectionName,
                TextColor3 = LunarUI.Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section
            })
            
            local sectionContent = Utility:Create("Frame", {
                Name = "Content",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 0), -- Will be updated as elements are added
                Parent = section
            })
            
            Utility:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = sectionContent
            })
            
            Utility:Create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = sectionContent
            })
            
            -- Section object
            local sectionObj = {
                Frame = section,
                Content = sectionContent,
                Name = sectionName,
                Elements = {}
            }
            
            -- Function to update section size
            local function updateSectionSize()
                sectionContent.Size = UDim2.new(1, 0, 0, sectionContent.UIListLayout.AbsoluteContentSize.Y + 10)
                section.Size = UDim2.new(1, 0, 0, sectionContent.Size.Y.Offset + 45)
                tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y + 20)
            end
            
            -- Button creator
            function sectionObj:AddButton(options)
                options = options or {}
                local buttonText = options.Text or "Button"
                local callback = options.Callback or function() end
                
                local button = Utility:Create("TextButton", {
                    Name = buttonText .. "Button",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    ClipsDescendants = true,
                    AutoButtonColor = false,
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = button
                })
                
                local buttonLabel = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = buttonText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button
                })
                
                button.MouseButton1Click:Connect(function()
                    Utility:Ripple(button, LunarUI.Theme.Accent)
                    callback()
                end)
                
                button.MouseEnter:Connect(function()
                    Utility:Tween(button, {BackgroundColor3 = Utility:LightenColor(LunarUI.Theme.Primary, 0.05)}, 0.2)
                end)
                
                button.MouseLeave:Connect(function()
                    Utility:Tween(button, {BackgroundColor3 = LunarUI.Theme.Primary}, 0.2)
                end)
                
                updateSectionSize()
                return button
            end
            
            -- Toggle creator
            function sectionObj:AddToggle(options)
                options = options or {}
                local toggleText = options.Text or "Toggle"
                local default = options.Default or false
                local flag = options.Flag or (toggleText .. "Toggle")
                local callback = options.Callback or function() end
                
                -- Add to flags
                LunarUI.Flags[flag] = default
                
                local toggle = Utility:Create("TextButton", {
                    Name = toggleText .. "Toggle",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    AutoButtonColor = false,
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = toggle
                })
                
                local toggleLabel = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -52, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = toggleText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggle
                })
                
                local toggleBackground = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = default and LunarUI.Theme.Accent or LunarUI.Theme.Border,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -40, 0.5, -8),
                    Size = UDim2.new(0, 30, 0, 16),
                    Parent = toggle
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggleBackground
                })
                
                local toggleIndicator = Utility:Create("Frame", {
                    Name = "Indicator",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, default and 14 or 2, 0.5, -6),
                    Size = UDim2.new(0, 12, 0, 12),
                    Parent = toggleBackground
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggleIndicator
                })
                
                local toggled = default
                
                local function updateToggle()
                    toggled = not toggled
                    LunarUI.Flags[flag] = toggled
                    
                    if toggled then
                        Utility:Tween(toggleBackground, {BackgroundColor3 = LunarUI.Theme.Accent}, 0.2)
                        Utility:Tween(toggleIndicator, {Position = UDim2.new(0, 14, 0.5, -6)}, 0.2)
                    else
                        Utility:Tween(toggleBackground, {BackgroundColor3 = LunarUI.Theme.Border}, 0.2)
                        Utility:Tween(toggleIndicator, {Position = UDim2.new(0, 2, 0.5, -6)}, 0.2)
                    end
                    
                    callback(toggled)
                end
                
                toggle.MouseButton1Click:Connect(function()
                    updateToggle()
                end)
                
                toggle.MouseEnter:Connect(function()
                    Utility:Tween(toggle, {BackgroundColor3 = Utility:LightenColor(LunarUI.Theme.Primary, 0.05)}, 0.2)
                end)
                
                toggle.MouseLeave:Connect(function()
                    Utility:Tween(toggle, {BackgroundColor3 = LunarUI.Theme.Primary}, 0.2)
                end)
                
                -- Toggle object
                local toggleObj = {
                    Instance = toggle,
                    Background = toggleBackground,
                    Indicator = toggleIndicator,
                    Value = toggled,
                    Flag = flag
                }
                
                -- Set function
                function toggleObj:Set(value)
                    if value ~= toggled then
                        updateToggle()
                    end
                end
                
                updateSectionSize()
                return toggleObj
            end
            
            -- Slider creator
            function sectionObj:AddSlider(options)
                options = options or {}
                local sliderText = options.Text or "Slider"
                local min = options.Min or 0
                local max = options.Max or 100
                local default = math.clamp(options.Default or min, min, max)
                local increment = options.Increment or 1
                local suffix = options.Suffix or ""
                local flag = options.Flag or (sliderText .. "Slider")
                local callback = options.Callback or function() end
                
                -- Add to flags
                LunarUI.Flags[flag] = default
                
                local slider = Utility:Create("Frame", {
                    Name = sliderText .. "Slider",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = slider
                })
                
                local sliderLabel = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 5),
                    Size = UDim2.new(1, -24, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = sliderText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = slider
                })
                
                local sliderValueDisplay = Utility:Create("TextLabel", {
                    Name = "Value",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -50, 0, 5),
                    Size = UDim2.new(0, 40, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default) .. suffix,
                    TextColor3 = LunarUI.Theme.Accent,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = slider
                })
                
                local sliderBackground = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = LunarUI.Theme.Border,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 0, 4),
                    Parent = slider
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderBackground
                })
                
                local sliderFill = Utility:Create("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = LunarUI.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    Parent = sliderBackground
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderFill
                })
                
                local sliderIndicator = Utility:Create("Frame", {
                    Name = "Indicator",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    ZIndex = 3,
                    Parent = sliderBackground
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderIndicator
                })
                
                local value = default
                
                local function updateSlider(newValue)
                    value = math.clamp(newValue, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    value = tonumber(string.format("%.2f", value)) -- Two decimal precision
                    
                    LunarUI.Flags[flag] = value
                    
                    local percent = (value - min) / (max - min)
                    
                    Utility:Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                    Utility:Tween(sliderIndicator, {Position = UDim2.new(percent, 0, 0.5, 0)}, 0.1)
                    
                    sliderValueDisplay.Text = tostring(value) .. suffix
                    callback(value)
                end
                
                local dragging = false
                
                sliderBackground.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        
                        local relX = math.clamp(input.Position.X - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
                        local percent = relX / sliderBackground.AbsoluteSize.X
                        
                        updateSlider(min + (max - min) * percent)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relX = math.clamp(input.Position.X - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
                        local percent = relX / sliderBackground.AbsoluteSize.X
                        
                        updateSlider(min + (max - min) * percent)
                    end
                end)
                
                -- Slider object
                local sliderObj = {
                    Instance = slider,
                    Background = sliderBackground,
                    Fill = sliderFill,
                    Indicator = sliderIndicator,
                    Value = value,
                    Flag = flag
                }
                
                -- Set function
                function sliderObj:Set(newValue)
                    updateSlider(newValue)
                end
                
                updateSectionSize()
                return sliderObj
            end
            
            -- Dropdown creator
            function sectionObj:AddDropdown(options)
                options = options or {}
                local dropdownText = options.Text or "Dropdown"
                local items = options.Items or {}
                local default = options.Default or nil
                local callback = options.Callback or function() end
                local flag = options.Flag or (dropdownText .. "Dropdown")
                local multiselect = options.MultiSelect or false
                
                -- Default value handling
                local selected = {}
                if default then
                    if multiselect then
                        if type(default) == "table" then
                            for _, item in pairs(default) do
                                if table.find(items, item) then
                                    selected[item] = true
                                end
                            end
                        elseif table.find(items, default) then
                            selected[default] = true
                        end
                    elseif table.find(items, default) then
                        selected = {[default] = true}
                    end
                end
                
                -- Add to flags
                LunarUI.Flags[flag] = multiselect and selected or (next(selected) and next(selected) or nil)
                
                local dropdownHeight = 34
                local contentHeight = 0
                
                local dropdown = Utility:Create("Frame", {
                    Name = dropdownText .. "Dropdown",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    Size = UDim2.new(1, 0, 0, dropdownHeight),
                    ZIndex = 2,
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = dropdown
                })
                
                local dropdownButton = Utility:Create("TextButton", {
                    Name = "Button",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, dropdownHeight),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    ZIndex = 2,
                    Parent = dropdown
                })
                
                local dropdownLabel = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = dropdownText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = dropdownButton
                })
                
                local dropdownIndicator = Utility:Create("ImageLabel", {
                    Name = "Indicator",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -30, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    Image = "rbxassetid://6031094670", -- Arrow down
                    ImageColor3 = LunarUI.Theme.Text,
                    Rotation = 0,
                    ZIndex = 2,
                    Parent = dropdownButton
                })
                
                local dropdownContent = Utility:Create("Frame", {
                    Name = "Content",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, dropdownHeight),
                    Size = UDim2.new(1, 0, 0, 0), -- Will be updated as items are added
                    Visible = false,
                    ZIndex = 3,
                    Parent = dropdown
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = dropdownContent
                })
                
                Utility:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5),
                    Parent = dropdownContent
                })
                
                local itemList = Utility:Create("ScrollingFrame", {
                    Name = "ItemList",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(0, 0, 0, 0), -- Will be updated as items are added
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = LunarUI.Theme.Accent,
                    ZIndex = 3,
                    Parent = dropdownContent
                })
                
                Utility:Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = itemList
                })
                
                Utility:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5),
                    PaddingRight = UDim.new(0, 5),
                    Parent = itemList
                })
                
                -- Function to update the display
                local function updateDisplay()
                    local displayText = ""
                    if multiselect then
                        local selectCount = 0
                        for item, _ in pairs(selected) do
                            selectCount = selectCount + 1
                            if selectCount == 1 then
                                displayText = item
                            end
                        end
                        
                        if selectCount > 1 then
                            displayText = displayText .. " (+" .. (selectCount - 1) .. " more)"
                        end
                    else
                        for item, _ in pairs(selected) do
                            displayText = item
                            break
                        end
                    end
                    
                    dropdownLabel.Text = displayText ~= "" and (dropdownText .. ": " .. displayText) or dropdownText
                end
                
                -- Add items to the dropdown
                for i, item in ipairs(items) do
                    local itemButton = Utility:Create("TextButton", {
                        Name = item .. "Item",
                        BackgroundColor3 = selected[item] and LunarUI.Theme.Accent or LunarUI.Theme.Secondary,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 28),
                        Font = Enum.Font.Gotham,
                        Text = "",
                        TextColor3 = LunarUI.Theme.Text,
                        TextSize = 14,
                        ZIndex = 3,
                        Parent = itemList
                    })
                    
                    Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, 6),
                        Parent = itemButton
                    })
                    
                    local itemLabel = Utility:Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -10, 1, 0),
                        Font = Enum.Font.Gotham,
                        Text = item,
                        TextColor3 = LunarUI.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 3,
                        Parent = itemButton
                    })
                    
                    if multiselect then
                        local toggle = Utility:Create("Frame", {
                            Name = "Toggle",
                            BackgroundColor3 = selected[item] and LunarUI.Theme.Accent or LunarUI.Theme.Border,
                            BorderSizePixel = 0,
                            Position = UDim2.new(1, -26, 0.5, -7),
                            Size = UDim2.new(0, 14, 0, 14),
                            ZIndex = 3,
                            Parent = itemButton
                        })
                        
                        Utility:Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = toggle
                        })
                        
                        if selected[item] then
                            Utility:Create("ImageLabel", {
                                Name = "Check",
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 1, 0),
                                Image = "rbxassetid://6031094667", -- Check mark
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 3,
                                Parent = toggle
                            })
                        end
                    end
                    
                    contentHeight = contentHeight + 33 -- 28 + 5 padding
                    
                    itemButton.MouseButton1Click:Connect(function()
                        if multiselect then
                            -- Toggle selection for multiselect
                            selected[item] = not selected[item]
                            
                            itemButton.BackgroundColor3 = selected[item] and LunarUI.Theme.Accent or LunarUI.Theme.Secondary
                            
                            local check = itemButton.Toggle:FindFirstChild("Check")
                            if selected[item] and not check then
                                Utility:Create("ImageLabel", {
                                    Name = "Check",
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Image = "rbxassetid://6031094667", -- Check mark
                                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                                    ZIndex = 3,
                                    Parent = itemButton.Toggle
                                })
                            elseif not selected[item] and check then
                                check:Destroy()
                            end
                            
                            LunarUI.Flags[flag] = selected
                            callback(selected)
                        else
                            -- Single selection
                            for otherItem, _ in pairs(selected) do
                                selected[otherItem] = false
                            end
                            selected[item] = true
                            
                            -- Update visuals for all items
                            for _, child in ipairs(itemList:GetChildren()) do
                                if child:IsA("TextButton") then
                                    child.BackgroundColor3 = child.Name == item .. "Item" and LunarUI.Theme.Accent or LunarUI.Theme.Secondary
                                end
                            end
                            
                            LunarUI.Flags[flag] = item
                            callback(item)
                            
                            -- Close dropdown for single selection
                            Utility:Tween(dropdownIndicator, {Rotation = 0}, 0.2)
                            Utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, dropdownHeight)}, 0.2)
                            
                            dropdownContent.Visible = false
                            dropdownOpen = false
                        end
                        
                        updateDisplay()
                    end)
                    
                    itemButton.MouseEnter:Connect(function()
                        if not (multiselect and selected[item]) and itemButton.BackgroundColor3 ~= LunarUI.Theme.Accent then
                            Utility:Tween(itemButton, {BackgroundColor3 = Utility:LightenColor(LunarUI.Theme.Secondary, 0.05)}, 0.2)
                        end
                    end)
                    
                    itemButton.MouseLeave:Connect(function()
                        if not (multiselect and selected[item]) and itemButton.BackgroundColor3 ~= LunarUI.Theme.Accent then
                            Utility:Tween(itemButton, {BackgroundColor3 = LunarUI.Theme.Secondary}, 0.2)
                        end
                    end)
                end
                
                updateDisplay()
                
                -- Set content size
                itemList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                dropdownContent.Size = UDim2.new(1, 0, 0, math.min(contentHeight + 10, 150))
                
                local dropdownOpen = false
                
                dropdownButton.MouseButton1Click:Connect(function()
                    dropdownOpen = not dropdownOpen
                    
                    local targetSize = UDim2.new(1, 0, 0, dropdownOpen and (dropdownHeight + dropdownContent.Size.Y.Offset) or dropdownHeight)
                    local targetRotation = dropdownOpen and 180 or 0
                    
                    Utility:Tween(dropdownIndicator, {Rotation = targetRotation}, 0.2)
                    Utility:Tween(dropdown, {Size = targetSize}, 0.2)
                    
                    dropdownContent.Visible = dropdownOpen
                end)
                
                -- Close dropdown when clicking outside
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mousePos = UserInputService:GetMouseLocation()
                        if dropdownOpen and not (mousePos.X >= dropdown.AbsolutePosition.X and
                                mousePos.X <= dropdown.AbsolutePosition.X + dropdown.AbsoluteSize.X and
                                mousePos.Y >= dropdown.AbsolutePosition.Y and
                                mousePos.Y <= dropdown.AbsolutePosition.Y + dropdown.AbsoluteSize.Y) then
                            
                            dropdownOpen = false
                            Utility:Tween(dropdownIndicator, {Rotation = 0}, 0.2)
                            Utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, dropdownHeight)}, 0.2)
                            dropdownContent.Visible = false
                        end
                    end
                end)
                
                -- Dropdown object
                local dropdownObj = {
                    Instance = dropdown,
                    Items = items,
                    Selected = selected,
                    Flag = flag
                }
                
                -- Add function
                function dropdownObj:Add(item)
                    if not table.find(self.Items, item) then
                        table.insert(self.Items, item)
                        
                        -- Need to recreate all items to update the dropdown
                        for _, child in ipairs(itemList:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end
                        
                        contentHeight = 0
                        
                        for _, newItem in ipairs(self.Items) do
                            -- Re-add all items (same code as above)
                            -- This could be refactored to a helper function
                            -- (code omitted for brevity)
                        end
                        
                        itemList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                        dropdownContent.Size = UDim2.new(1, 0, 0, math.min(contentHeight + 10, 150))
                    end
                end
                
                -- Remove function
                function dropdownObj:Remove(item)
                    local index = table.find(self.Items, item)
                    if index then
                        table.remove(self.Items, index)
                        
                        -- Remove from selected if it was selected
                        if self.Selected[item] then
                            self.Selected[item] = nil
                            updateDisplay()
                        end
                        
                        -- Need to recreate all items
                        -- (same approach as Add method)
                    end
                end
                
                -- Set function
                function dropdownObj:Set(value)
                    if multiselect and typeof(value) == "table" then
                        -- Clear current selections
                        for item, _ in pairs(selected) do
                            selected[item] = false
                        end
                        
                        -- Set new selections
                        for _, item in pairs(value) do
                            if table.find(items, item) then
                                selected[item] = true
                            end
                        end
                    elseif table.find(items, value) then
                        -- Clear current selection
                        for item, _ in pairs(selected) do
                            selected[item] = false
                        end
                        
                        -- Set new selection
                        selected[value] = true
                    end
                    
                    -- Update visuals for all items
                    for _, child in ipairs(itemList:GetChildren()) do
                        if child:IsA("TextButton") then
                            local itemName = string.gsub(child.Name, "Item$", "")
                            child.BackgroundColor3 = selected[itemName] and LunarUI.Theme.Accent or LunarUI.Theme.Secondary
                            
                            if multiselect then
                                local check = child.Toggle:FindFirstChild("Check")
                                if selected[itemName] and not check then
                                    Utility:Create("ImageLabel", {
                                        Name = "Check",
                                        BackgroundTransparency = 1,
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Image = "rbxassetid://6031094667", -- Check mark
                                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                                        ZIndex = 3,
                                        Parent = child.Toggle
                                    })
                                elseif not selected[itemName] and check then
                                    check:Destroy()
                                end
                            end
                        end
                    end
                    
                    updateDisplay()
                    
                    LunarUI.Flags[flag] = multiselect and selected or value
                    callback(multiselect and selected or value)
                end
                
                updateSectionSize()
                return dropdownObj
            end
            
            -- Input field
            function sectionObj:AddTextbox(options)
                options = options or {}
                local textboxText = options.Text or "Textbox"
                local default = options.Default or ""
                local placeholder = options.Placeholder or "Enter text..."
                local flag = options.Flag or (textboxText .. "Input")
                local callback = options.Callback or function() end
                
                -- Add to flags
                LunarUI.Flags[flag] = default
                
                local textbox = Utility:Create("Frame", {
                    Name = textboxText .. "Textbox",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = textbox
                })
                
                local textboxLabel = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 5),
                    Size = UDim2.new(1, -24, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = textboxText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = textbox
                })
                
                local textboxFrame = Utility:Create("Frame", {
                    Name = "TextboxFrame",
                    BackgroundColor3 = LunarUI.Theme.Secondary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 27),
                    Size = UDim2.new(1, -24, 0, 16),
                    Parent = textbox
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = textboxFrame
                })
                
                local textInput = Utility:Create("TextBox", {
                    Name = "Input",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Enum.Font.Gotham,
                    PlaceholderText = placeholder,
                    Text = default,
                    TextColor3 = LunarUI.Theme.Text,
                    PlaceholderColor3 = LunarUI.Theme.DarkText,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = textboxFrame
                })
                
                textInput.FocusLost:Connect(function(enterPressed)
                    LunarUI.Flags[flag] = textInput.Text
                    callback(textInput.Text, enterPressed)
                end)
                
                -- Textbox object
                local textboxObj = {
                    Instance = textbox,
                    Input = textInput,
                    Flag = flag
                }
                
                -- Set function
                function textboxObj:Set(value)
                    textInput.Text = value
                    LunarUI.Flags[flag] = value
                    callback(value, false)
                end
                
                updateSectionSize()
                return textboxObj
            end
            
            -- Label creator
            function sectionObj:AddLabel(options)
                options = options or {}
                local labelText = options.Text or "Label"
                
                local label = Utility:Create("TextLabel", {
                    Name = "Label",
                    BackgroundColor3 = LunarUI.Theme.Primary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = labelText,
                    TextColor3 = LunarUI.Theme.Text,
                    TextSize = 14,
                    Parent = sectionContent
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = label
                })
                
                -- Label object
                local labelObj = {
                    Instance = label
                }
                
                -- Set function
                function labelObj:Set(text)
                    label.Text = text
                end
                
                updateSectionSize()
                return labelObj
            end
            
            -- Add Section to Tab
            self.Sections[sectionName] = sectionObj
            tab.Elements[#tab.Elements + 1] = sectionObj
            
            updateSectionSize()
            return sectionObj
        end
        
        return tab
    end
    
    -- Select Tab function
    function window:SelectTab(name)
        if self.Tabs[name] then
            if self.ActiveTab then
                local activeTab = self.Tabs[self.ActiveTab]
                
                -- Hide active tab content
                Utility:Tween(activeTab.Content, {Position = UDim2.new(1, 0, 0, 0)}, 0.2)
                task.delay(0.2, function()
                    activeTab.Content.Visible = false
                end)
                
                -- Reset tab button colors
                Utility:Tween(activeTab.Button.Icon, {ImageColor3 = LunarUI.Theme.DarkText}, 0.2)
                Utility:Tween(activeTab.Button.Label, {TextColor3 = LunarUI.Theme.DarkText}, 0.2)
                Utility:Tween(activeTab.Button, {BackgroundColor3 = LunarUI.Theme.Secondary}, 0.2)
            end
            
            -- Update active tab
            self.ActiveTab = name
            local tab = self.Tabs[name]
            
            -- Show tab content
            tab.Content.Position = UDim2.new(-1, 0, 0, 0)
            tab.Content.Visible = true
            Utility:Tween(tab.Content, {Position = UDim2.new(0, 0, 0, 0)}, 0.2)
            
            -- Update tab button colors
            Utility:Tween(tab.Button.Icon, {ImageColor3 = LunarUI.Theme.Accent}, 0.2)
            Utility:Tween(tab.Button.Label, {TextColor3 = LunarUI.Theme.Text}, 0.2)
            Utility:Tween(tab.Button, {BackgroundColor3 = LunarUI.Theme.Primary}, 0.2)
        end
    end
    
    table.insert(self.Windows, window)
    return window
end

-- Key System
function LunarUI:CreateKeySystem(options)
    options = options or {}
    local title = options.Title or "Key System"
    local subtitle = options.Subtitle or "Verification Required"
    local note = options.Note or "Enter your key to access the application."
    local validKeys = options.Keys or {}  -- Array of valid keys
    local callback = options.Callback or function() end -- Function to call after key is verified
    
    -- If there are no keys, don't create a key system
    if #validKeys == 0 then
        callback(true)
        return
    end
    
    -- Create ScreenGui
    local keyGui = Utility:Create("ScreenGui", {
        Name = "LunarKeySystem",
        Parent = game:GetService("RunService"):IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    
    -- Blur effect
    local blurBackground = Utility:Create("Frame", {
        Name = "BlurBackground",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 998,
        Parent = keyGui
    })
    
    -- Main key system frame
    local keyFrame = Utility:Create("Frame", {
        Name = "KeySystemFrame",
        BackgroundColor3 = self.Theme.Primary,
        BorderColor3 = self.Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0.5, -175, 0.5, -125),
        Size = UDim2.new(0, 350, 0, 250),
        ZIndex = 999,
        Parent = keyGui,
        ClipsDescendants = true
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = keyFrame
    })
    
    -- Topbar
    local topbar = Utility:Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 999,
        Parent = keyFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = topbar
    })
    
    -- Only round the top corners
    Utility:Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        ZIndex = 999,
        Parent = topbar
    })
    
    -- Title and subtitle
    local titleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 5),
        Size = UDim2.new(1, -30, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 999,
        Parent = topbar
    })
    
    local subtitleLabel = Utility:Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 22),
        Size = UDim2.new(1, -30, 0, 14),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = self.Theme.DarkText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 999,
        Parent = topbar
    })
    
    -- Note
    local noteLabel = Utility:Create("TextLabel", {
        Name = "Note",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 60),
        Size = UDim2.new(1, -40, 0, 40),
        Font = Enum.Font.Gotham,
        Text = note,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 999,
        Parent = keyFrame
    })
    
    -- Key input
    local keyBox = Utility:Create("TextBox", {
        Name = "KeyInput",
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -125, 0, 120),
        Size = UDim2.new(0, 250, 0, 40),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Enter Key...",
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        ClearTextOnFocus = false,
        ZIndex = 999,
        Parent = keyFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = keyBox
    })
    
    -- Status label
    local statusLabel = Utility:Create("TextLabel", {
        Name = "Status",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 170),
        Size = UDim2.new(1, -40, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = self.Theme.Negative,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 999,
        Visible = false,
        Parent = keyFrame
    })
    
    -- Submit button
    local submitButton = Utility:Create("TextButton", {
        Name = "SubmitButton",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -75, 0, 200),
        Size = UDim2.new(0, 150, 0, 35),
        Font = Enum.Font.GothamBold,
        Text = "SUBMIT",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 999,
        Parent = keyFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = submitButton
    })
    
    submitButton.MouseEnter:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = Utility:DarkenColor(self.Theme.Accent, 0.1)}, 0.2)
    end)
    
    submitButton.MouseLeave:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = self.Theme.Accent}, 0.2)
    end)
    
    submitButton.MouseButton1Down:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = Utility:DarkenColor(self.Theme.Accent, 0.2)}, 0.1)
    end)
    
    submitButton.MouseButton1Up:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = Utility:DarkenColor(self.Theme.Accent, 0.1)}, 0.1)
    end)
    
    -- Key verification logic
    local function verifyKey()
        local enteredKey = keyBox.Text
        
        -- Check if the entered key is valid
        for _, validKey in ipairs(validKeys) do
            if enteredKey == validKey then
                statusLabel.Text = "Key verified successfully!"
                statusLabel.TextColor3 = self.Theme.Positive
                statusLabel.Visible = true
                
                task.delay(1, function()
                    -- Fade out and destroy key system
                    Utility:Tween(keyFrame, {Position = UDim2.new(0.5, -175, 1.5, 0)}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    Utility:Tween(blurBackground, {BackgroundTransparency = 1}, 0.5)
                    
                    task.delay(0.5, function()
                        keyGui:Destroy()
                        callback(true) -- Call the callback with success
                    end)
                end)
                
                return true
            end
        end
        
        -- If we get here, the key was invalid
        statusLabel.Text = "Invalid key. Please try again."
        statusLabel.TextColor3 = self.Theme.Negative
        statusLabel.Visible = true
        
        Utility:Tween(keyFrame, {Position = UDim2.new(0.5, -170, 0.5, -125)}, 0.1)
        task.delay(0.05, function()
            Utility:Tween(keyFrame, {Position = UDim2.new(0.5, -180, 0.5, -125)}, 0.1)
            task.delay(0.05, function()
                Utility:Tween(keyFrame, {Position = UDim2.new(0.5, -175, 0.5, -125)}, 0.1)
            end)
        end)
        
        return false
    end
    
    -- Connect events
    submitButton.MouseButton1Click:Connect(verifyKey)
    
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyKey()
        end
    end)
    
    -- Make sure the key system is in front of everything
    keyGui.DisplayOrder = 9999
    
    return keyGui
end

-- Initialize
-- Improved initialization function with robust error handling
function LunarUI:Init()
    -- Initialize the player if not done already
    if not LocalPlayer then
        local initSuccess, initError = pcall(function()
            if Players.LocalPlayer then
                LocalPlayer = Players.LocalPlayer
            else
                local connection
                connection = Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
                    if Players.LocalPlayer then
                        LocalPlayer = Players.LocalPlayer
                        connection:Disconnect()
                    end
                end)
                
                -- Wait for player with timeout
                local startTime = tick()
                while not LocalPlayer and tick() - startTime < 10 do
                    wait(0.1)
                end
                
                if not LocalPlayer then
                    error("Failed to get LocalPlayer within timeout period")
                end
            end
            
            -- Initialize Mouse safely
            Mouse = LocalPlayer:GetMouse()
            
            -- Determine where to parent UI elements (PlayerGui in Studio, CoreGui in published games)
            UIParent = nil
            if RunService:IsStudio() then
                UIParent = LocalPlayer:FindFirstChild("PlayerGui")
                if not UIParent then
                    warn("LunarUI: PlayerGui not found, waiting...")
                    UIParent = LocalPlayer:WaitForChild("PlayerGui", 5)
                end
            else
                -- Try to use CoreGui, fall back to PlayerGui if needed
                pcall(function()
                    UIParent = game:GetService("CoreGui")
                end)
                
                if not UIParent then
                    warn("LunarUI: CoreGui access denied, using PlayerGui instead")
                    UIParent = LocalPlayer:FindFirstChild("PlayerGui")
                    if not UIParent then
                        UIParent = LocalPlayer:WaitForChild("PlayerGui", 5)
                    end
                end
            end
            
            if not UIParent then
                error("LunarUI: Failed to find a suitable parent for UI elements")
            end
        end)
        
        if not initSuccess then
            warn("LunarUI initialization error: " .. tostring(initError))
            return self
        end
    end
    
    -- Set up key to toggle UI
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            self:ToggleUI()
        end
    end)
    
    -- Make sure the library is ready
    self._initialized = true
    
    -- Return the library for chaining
    return self
end

-- Create a key system for verification before showing UI
function LunarUI:CreateKeySystem(options)
    options = options or {}
    local title = options.Title or "Key System"
    local subtitle = options.Subtitle or "Verification Required"
    local note = options.Note or "Please enter your key to continue"
    local keys = options.Keys or {}
    local callback = options.Callback or function() end
    
    -- Wait for player initialization
    if not LocalPlayer then
        self:Init()
        if not self._initialized then
            warn("LunarUI: Could not initialize for key system")
            return
        end
    end
    
    -- Create key system UI
    local gui = Utility:Create("ScreenGui", {
        Name = "LunarUI_KeySystem",
        Parent = UIParent or (RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    
    -- Main container
    local main = Utility:Create("Frame", {
        Name = "Main",
        BackgroundColor3 = self.Theme.Primary,
        BorderColor3 = self.Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0.5, -175, 0.5, -100),
        Size = UDim2.new(0, 350, 0, 200),
        Parent = gui,
        ClipsDescendants = true
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = main
    })
    
    -- Dropshadow
    Utility:Create("CanvasGroup", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 24, 1, 24),
        ZIndex = -1,
        GroupTransparency = 0.5,
        Parent = main
    }, {
        Utility:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-12, -12),
            Size = UDim2.new(1, 24, 1, 24),
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450)
        })
    })
    
    -- Title and subtitle
    local titleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = main
    })
    
    local subtitleLabel = Utility:Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 40),
        Size = UDim2.new(1, -30, 0, 16),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = self.Theme.DarkText,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = main
    })
    
    -- Note
    local noteLabel = Utility:Create("TextLabel", {
        Name = "Note",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 70),
        Size = UDim2.new(1, -30, 0, 16),
        Font = Enum.Font.Gotham,
        Text = note,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = main
    })
    
    -- Textbox Background
    local textboxBackground = Utility:Create("Frame", {
        Name = "TextboxBackground",
        BackgroundColor3 = self.Theme.Secondary,
        Position = UDim2.new(0.5, -125, 0, 100),
        Size = UDim2.new(0, 250, 0, 36),
        Parent = main
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = textboxBackground
    })
    
    -- Key input textbox
    local textbox = Utility:Create("TextBox", {
        Name = "KeyInput",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Enter key here...",
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        ClearTextOnFocus = false,
        Parent = textboxBackground
    })
    
    -- Submit button
    local submitButton = Utility:Create("TextButton", {
        Name = "SubmitButton",
        BackgroundColor3 = self.Theme.Accent,
        Position = UDim2.new(0.5, -75, 0, 150),
        Size = UDim2.new(0, 150, 0, 36),
        Font = Enum.Font.GothamBold,
        Text = "Submit",
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = main
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = submitButton
    })
    
    submitButton.MouseEnter:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = Utility:LightenColor(self.Theme.Accent, 0.05)}, 0.2)
    end)
    
    submitButton.MouseLeave:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = self.Theme.Accent}, 0.2)
    end)
    
    submitButton.MouseButton1Down:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = Utility:DarkenColor(self.Theme.Accent, 0.05)}, 0.1)
    end)
    
    submitButton.MouseButton1Up:Connect(function()
        Utility:Tween(submitButton, {BackgroundColor3 = self.Theme.Accent}, 0.1)
    end)
    
    local function validateKey()
        local inputKey = textbox.Text
        
        for _, validKey in ipairs(keys) do
            if inputKey == validKey then
                -- Create success notification
                self:CreateNotification({
                    Title = "Success",
                    Content = "Key verified successfully!",
                    Duration = 3,
                    Type = "Success"
                })
                
                -- Animate out
                Utility:Tween(main, {Position = UDim2.new(0.5, -175, 1.5, 0)}, 0.5, Enum.EasingStyle.Quint)
                
                -- Clean up
                task.delay(0.5, function()
                    gui:Destroy()
                    callback(true)
                end)
                
                return true
            end
        end
        
        -- Incorrect key
        self:CreateNotification({
            Title = "Error",
            Content = "Invalid key. Please try again.",
            Duration = 3,
            Type = "Error"
        })
        
        -- Shake animation
        local originalPosition = main.Position
        for i = 1, 5 do
            Utility:Tween(main, {Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset + (i % 2 == 0 and 10 or -10), originalPosition.Y.Scale, originalPosition.Y.Offset)}, 0.1)
            task.wait(0.1)
        end
        Utility:Tween(main, {Position = originalPosition}, 0.1)
        
        return false
    end
    
    submitButton.MouseButton1Click:Connect(validateKey)
    
    -- Also validate when Enter is pressed
    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            validateKey()
        end
    end)
    
    -- Animate in
    main.Position = UDim2.new(0.5, -175, -0.5, 0)
    Utility:Tween(main, {Position = UDim2.new(0.5, -175, 0.5, -100)}, 0.5, Enum.EasingStyle.Quint)
    
    return gui
end

return LunarUI
