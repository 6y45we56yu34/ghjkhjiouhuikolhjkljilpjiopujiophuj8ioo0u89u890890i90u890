repeat wait() until game:IsLoaded()

shared.user = 'Sino1507'
shared.repo = 'Chat-Translator/main/src'
shared.entry = 'main.lua'

shared.useBloxstrapRPC = false

shared.import = function(path)
    local import
            
    local success, res = pcall(function()
            import = loadstring(
                        game:HttpGetAsync(
                            ("https://raw.githubusercontent.com/%s/%s/%s"):format(shared.user, shared.repo, path)
                        )
                    )()
        end)

    if not success then error(res) end 

    return import
end

shared.info = function(...)
    if shared.debugMode == true then return print('[DEBUG]',...) end
end

local Services = shared.import('modules/Services.lua')
Services:GetServices(
    {
        'HttpService',
        'Players',
        'Workspace',
        'ReplicatedStorage',
        'TextChatService',
        'StarterGui'
    }
)

local BloxstrapRPC = shared.import('modules/BloxstrapRPC.lua')
shared.BloxstrapRPC = BloxstrapRPC

local Connections = shared.import('modules/Connections.lua')

local ExploitSupport = shared.import('modules/ExploitSupport.lua')

if not ExploitSupport:Test(hookmetamethod, false) or not ExploitSupport:Test(hookfunction, false) or not ExploitSupport:Test(request, false) then
	shared.info('Exploit is not supported!')
    --error('Exploit is not supported!')
	return
end

shared.info('Everything mandetory is now imported. Beginning...')

local isoCodes = shared.import('modules/isoCodes.lua')
shared.info('Currently supported isoCodes:', shared.HttpService:JSONEncode(shared.isoCodes))

shared.currentISOin = 'en' -- DEFAULT ENGLISH ISO
shared.translateIn = true
shared.currentISOout = getfenv().DefaultLang -- DEFAULT ENGLISH ISO
shared.translateOut = true

local Translator = shared.import('modules/Translator.lua')
shared.Translator = Translator

local TestRequest = shared.Translator:Translate('Hallo', shared.currentISOout)
if TestRequest == 'error' then 
	shared.info('Translation does not seem to work right now!')
    --error('Translation does not seem to work right now!')
	return
end

shared.info('Translation is imported and working!')

local ChatHandler = shared.import('modules/ChatHandler.lua')
shared.ChatHandler = ChatHandler

shared.info('Starting hooks...')

shared.pending = false
function hookmetamethod(obj, met, func)
    setreadonly(getrawmetatable(game), false)
    local old = getrawmetatable(game).__namecall
    getrawmetatable(game).__namecall = newcclosure(function(self, ...)
        local args = {...}
        if getnamecallmethod() == met and self == obj and not checkcaller() and shared.pending == false then
            return func(unpack(args))
        end
        return old(self, ...)
    end)
    setreadonly(getrawmetatable(game), true)
end


if shared.Players.LocalPlayer.PlayerGui:FindFirstChild('Chat') then 
    local events = shared.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local sayMessageRequest = events:FindFirstChild('SayMessageRequest') 
    assert(events, 'Chat events were not found!')
    assert(sayMessageRequest, 'Chat events were not found!')

    shared.info('Game is using old chat method...')

    function sayMsg(msg, to)
        shared.pending = true
        sayMessageRequest:FireServer(msg, to)
        shared.pending = false
    end


    events:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
        if data == nil then return end
        if data.FromSpeaker == shared.Players.LocalPlayer.Name then return end -- Already hooked this 😎
		print(data.FromSpeaker)
        shared.info('Intercepted message:',data.Message,' | ',data.FromSpeaker)

        local msg = data.Message

        local result
        shared.translating = true
        task.spawn(function()
		if shared.currentISOout == shared.DefaultLang then
			result = {msg, shared.DefaultLang}
		else
		    result = ChatHandler:Handle(msg, false)
		end
            shared.info('Got result from ChatHandler:',result)
		
            if result ~= nil and next(result) ~= nil and result[1] ~= msg then 
                local text = result[1]
                local lang = result[2]
				shared.StarterGui:SetCore('ChatMakeSystemMessage',{
   					 Text = `[{lang} > {shared.currentISOout}] [{data.FromSpeaker}]: {text}`, 
					 Color = Color3.fromRGB(0, 145, 255)
				})
            end 
        end)
        shared.info('Translation-Thread was created...')
    end)

    hookmetamethod(sayMessageRequest, "FireServer", function(msg, to)
        shared.info('Intercepted message:',msg,' | ',to)
        shared.pending = true
        local result

        shared.translating = true
        task.spawn(function()
        	if shared.currentISOout == 
            result = ChatHandler:Handle(msg)
            shared.info('Got result from ChatHandler:',result)
            if result ~= nil and next(result) ~= nil then
                local text = result[1]
                sayMsg(text, to) 
            end 
            shared.pending = false
        end)

        shared.info('Translation-Thread was created...')
        return
    end)
end

shared.StarterGui:SetCore('ChatMakeSystemMessage',{
    Text = '{TRANSLATOR STARTED}', 
	Color = Color3.fromRGB(0, 145, 255)
})
