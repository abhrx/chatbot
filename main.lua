--// Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Services
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Settings
local API_KEY = ""
local Personality = "You are a friendly Roblox player chatting with others."
local Enabled = false
local MAX_DISTANCE = 40

-- Model
local Model = "llama-3.1-8b-instant"

-- Systems
local SmartTrigger = true
local AntiRateLimit = true

-- Rate limits
local COOLDOWN = 6
local GLOBAL_DELAY = 3

local PlayerCooldowns = {}
local LastRequest = 0

-- Window
local Window = Rayfield:CreateWindow({
    Name = "AI Chatbot",
    LoadingTitle = "AI Chatbot",
    LoadingSubtitle = "made by abhroscurse <3",
    ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Main")

-- Instructions text bar
Tab:CreateParagraph({
    Title = "API Key Instructions (made by abhroscurse <3)",
    Content = "1) Go to https://console.groq.com\n2) Sign in or create an account\n3) Go to 'API Keys'\n4) Click 'Create API Key'\n5) Copy the key and paste it into the field below."
})

-- API Key input
Tab:CreateInput({
    Name = "Groq API Key",
    PlaceholderText = "Paste your API key here",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        API_KEY = text
    end
})

-- Personality input
Tab:CreateInput({
    Name = "Personality Prompt",
    PlaceholderText = "AI personality",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        Personality = text
    end
})

-- Model dropdown
Tab:CreateDropdown({
    Name = "Groq Model",
    Options = {
        "llama-3.1-8b-instant",
        "llama-3.3-70b-versatile",
        "mixtral-8x7b-32768",
        "gemma2-9b-it",
        "qwen/qwen3-32b"
    },
    CurrentOption = {"llama-3.1-8b-instant"},
    MultipleOptions = false,
    Callback = function(option)
        Model = option[1]
    end
})

-- Auto respond
Tab:CreateToggle({
    Name = "Auto Respond",
    CurrentValue = false,
    Callback = function(v)
        Enabled = v
    end
})

-- Smart trigger
Tab:CreateToggle({
    Name = "Smart Trigger System",
    CurrentValue = true,
    Callback = function(v)
        SmartTrigger = v
    end
})

-- Anti rate limit
Tab:CreateToggle({
    Name = "Anti Rate Limit",
    CurrentValue = true,
    Callback = function(v)
        AntiRateLimit = v
    end
})

-- Distance check
local function IsNearby(player)
    if not player.Character or not LocalPlayer.Character then return false end

    local a = player.Character:FindFirstChild("HumanoidRootPart")
    local b = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not a or not b then return false end

    return (a.Position - b.Position).Magnitude <= MAX_DISTANCE
end

-- Smart trigger
local function ShouldRespond(text)

    if not SmartTrigger then
        return true
    end

    text = string.lower(text)

    if string.find(text,"?") then return true end
    if string.find(text,string.lower(LocalPlayer.Name)) then return true end
    if string.find(text,"ai") or string.find(text,"bot") then return true end

    return false
end

-- Rate limit
local function RateLimit(player)

    if not AntiRateLimit then return false end

    local now = tick()

    if PlayerCooldowns[player.UserId] and now - PlayerCooldowns[player.UserId] < COOLDOWN then
        return true
    end

    if now - LastRequest < GLOBAL_DELAY then
        return true
    end

    PlayerCooldowns[player.UserId] = now
    LastRequest = now

    return false
end

-- Ask AI
local function Ask(prompt)

    local systemInstruction =
        Personality .. ". Keep responses under 200 characters so they fit in Roblox chat."

    local body = {
        model = Model,
        messages = {
            {role="system",content=systemInstruction},
            {role="user",content=prompt}
        },
        max_tokens = 80
    }

    local response = request({
        Url = "https://api.groq.com/openai/v1/chat/completions",
        Method = "POST",
        Headers = {
            ["Authorization"] = "Bearer "..API_KEY,
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(body)
    })

    if not response or not response.Body then return nil end

    local decoded = HttpService:JSONDecode(response.Body)

    if decoded.choices then
        return decoded.choices[1].message.content
    end
end

-- Chat listener
TextChatService.OnIncomingMessage = function(msg)

    if not Enabled then return end

    local player = Players:GetPlayerByUserId(msg.TextSource.UserId)

    if not player then return end
    if player == LocalPlayer then return end
    if not IsNearby(player) then return end

    local text = msg.Text

    if not ShouldRespond(text) then return end
    if RateLimit(player) then return end

    task.spawn(function()

        local reply = Ask(text)

        if reply then
            TextChatService.TextChannels.RBXGeneral:SendAsync(reply)
        end

    end)

end
