local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
local saveModule = require(game:GetService("ReplicatedStorage").Library.Client.Save)
local save = {}

local mcmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
local bwc = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds.BlockWorldClient)
local MiningUtil = require(game.ReplicatedStorage.Library.Util.MiningUtil)
local comma = require(game:GetService("ReplicatedStorage").Library.Functions.Commas)
local PlayerPet = require(game:GetService("ReplicatedStorage").Library.Client.PlayerPet)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local cmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
local lcl = bwc.GetLocal()

local saveModule = require(game:GetService("ReplicatedStorage").Library.Client.Save)
save = saveModule.GetSaves()[game.Players.LocalPlayer]

local Window = Fluent:CreateWindow({
	Title = "sh0vel prod.",
	SubTitle = "version 0.2",
	TabWidth = 185,
	Size = UDim2.fromOffset(720, 520),
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.Delete -- Used when theres no MinimizeKeybind
})

local function client_notification(data)
	Fluent:Notify(data)
end

local current_ver = tostring(game:GetService("HttpService"):GenerateGUID(false))
getgenv().wtools_ver = current_ver
local function isActualScriptRunning()
	return getgenv().wtools_ver == current_ver
end

spawn(function()
	while task.wait(0.1) do
		if not isActualScriptRunning() then
			break
		end
		pcall(function()
			lcl = bwc.GetLocal()
		end)
	end
end)



local farm = Window:AddTab({Title = "Slime Event", Icon = "check"})
local pet = Window:AddTab({Title = "Pet", Icon = "cat"})
local egg = Window:AddTab({Title = "Egg Settings", Icon = "egg"})
local currency = Window:AddTab({Title = "Currency", Icon = "gem"})
local conf = Window:AddTab({Title = "Configuration", Icon = "settings"})

if getgenv().wtools ~= nil then
	pcall(function()
		for i,v in pairs(getgenv().wtools.ores) do
			v:Destroy()
		end
	end)
	
	pcall(function()
		for i,v in pairs(getgenv().wtools.fake_currency) do
			v:Destroy()
		end
	end)
end

local ores = {}
local ores_id = {}

local function isOre(id)
	if table.find(ores_id, id) then
		return true
	end

	if string.lower(id):find("chest") then
		return true
	end

	return false
end

local function client_notification(data)
	Fluent:Notify(data)
end


local mining_event_items_short = {
	tnts = {"Bejeweled TNT", "Bomb", "Nuclear TNT", "TNT", "TNT Crate"}
}

local mining_event_items_dec = {
	tnts = {
		["Bejeweled TNT"] = "Mining Bejeweled TNT Crate",
		["Bomb"] = "Mining Bomb",
		["Nuclear TNT"] = "Mining Nuclear TNT Crate",
		["TNT"] = "Mining TNT",
		["TNT Crate"] = "Mining TNT Crate"
	}
}

local function dec_short_names(tbl_id, val)
	local new_tbl = {}

	for i,v in pairs(mining_event_items_short[tbl_id]) do
		if table.find(val, v) then
			table.insert(new_tbl, mining_event_items_dec[tbl_id][v])
		end
	end

	return new_tbl
end


for i,v in pairs(game:GetService("ReplicatedStorage").__DIRECTORY.Blocks:GetChildren()) do
	if v.Name:find("Ore") then
		local id = require(v).DisplayName:split(" ")[1]
		ores[id] = require(v)
		table.insert(ores_id, id)
	end
end
local cache = Instance.new("Folder")
getgenv().wtools = {
	ores = {},
	fake_currency = {}
}


local data = {
	currency_stat = false,
	refresh_stat = 60,
	egg_open = 50,
	m_event_hatch = false,
	infinity_pet_speed = false,
}

local tasks = {
	["openegg"] = {
		init = function()
			local working = false


			return {
				start_open = function(egg, custom)
					working = true

					spawn(function()
						if custom then
							local egg_id = egg.Name
							while working and isActualScriptRunning() do
								task.wait()
								pcall(function()
									local ret = Network.Invoke("CustomEggs_Hatch", egg_id, math.floor(data.egg_open))
									local a = 250
									
									if ret == false then
										game.Players.LocalPlayer.Character.PrimaryPart.CFrame = egg.PrimaryPart.CFrame
										return
									end
									repeat
										task.wait(0.01)
										a+=1
									until workspace.CurrentCamera:FindFirstChild("Eggs") or a > 250 or not working or not isActualScriptRunning()
									for i = 1, 25 do
										game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.ButtonA, false, game.Players.LocalPlayer.PlayerGui)
										task.wait()
										game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.ButtonA, false, game.Players.LocalPlayer.PlayerGui)
									end
									repeat
										task.wait()
									until not workspace.CurrentCamera:FindFirstChild("Eggs") or not working or not isActualScriptRunning()
								end)
							end 
						elseif custom ~= true then
							
						end
					end)
				end,
				stop = function()
					working = false
				end,
			}
		end,
	}
} 

local function getWorld()
	local full = workspace.__THINGS.Eggs:FindFirstChildOfClass("Model").Name
	return "World "..full:split("World")[2]
end

local EggSystem = tasks.openegg.init()


if not isfolder("sh0velprod") then
	makefolder("sh0velprod")
end

if isfile("sh0velprod/Petsimulator99.conf") then
	local json = readfile("sh0velprod/Petsimulator99.conf")
	local source = game:GetService("HttpService"):JSONDecode(json)
	for i,v in pairs(source) do
		data[i] = v
	end
end

local scan = false
local rad = 10

pet:AddToggle("123", {
	Title = "Infinity Pet Speed",
	Default = data.infinity_pet_speed,
	
	Callback = function(val)
		data.infinity_pet_speed = val
	end,
})

local old_pet_formula = clonefunction(PlayerPet.CalculateSpeedMultiplier)

hookfunction(PlayerPet.CalculateSpeedMultiplier, function(...)
	if data.infinity_pet_speed then
		return math.huge
	end
	
	return old_pet_formula(...)
end)

farm:AddToggle("123",{
	Title = "Auto open event egg",
	Default = data.m_event_hatch,
	
	Callback = function(val)
		data.m_event_hatch = val
		
		EggSystem.stop()
		
		if data.m_event_hatch then
			local egg = nil
			
			for i,v in pairs(workspace.__THINGS.CustomEggs:GetChildren()) do
				pcall(function()
					if v.PriceHUD.PriceHUD:FindFirstChild("Factory Coins") then
						egg = v
					end
				end)
			end
			
			EggSystem.start_open(egg, true)
		end
	end,
})

conf:AddButton({
	Title = "Save configuration",
	Callback = function()
		local json = game:GetService("HttpService"):JSONEncode(data)
		writefile("sh0velprod/Petsimulator99.conf", json)

		client_notification({
			Title = "sh0vel prod.",
			Content = "Configuration saved!",
			Duration = 3
		})
	end,
})



currency:AddToggle("123", {
	Title = "Enable currency stats",
	Default = data.currency_stat,
	
	Callback = function(val)
		data.currency_stat = val
		if not val then
			pcall(function()
				for i,v in pairs(getgenv().wtools.fake_currency) do
					v:Destroy()
				end
			end)
		end
        local old_values = {}
		while data.currency_stat and isActualScriptRunning() do
			local suc, err = pcall(function()
				local display_currency = {"Diamonds"}
				local currency_path = game:GetService("Players").LocalPlayer.PlayerGui.MainLeft.Left.Currency
				
				for i,currency_type in pairs(display_currency) do
					local copy = nil
					if currency_path:FindFirstChild(currency_type) and not currency_path:FindFirstChild(currency_type.."fake") then
						copy = currency_path:FindFirstChild(currency_type):Clone()
						copy.Parent = currency_path
						copy.Size = UDim2.fromOffset(0, currency_path:FindFirstChild(currency_type).Size.Y.Offset / 1.25)
						copy.Name = currency_type.."fake"
						table.insert(getgenv().wtools.fake_currency, copy)
					end
					
					if currency_path:FindFirstChild(currency_type.."fake") then
						copy = currency_path:FindFirstChild(currency_type.."fake")
					end
					
					local found_currency = {}
					
					for i,v in pairs(save.Inventory.Currency) do
						if v.id == currency_type then
							found_currency = v
						end
					end
					
					if old_values[currency_type] == nil and found_currency ~= {} then
						old_values[currency_type] = found_currency._am or 0
					end
					
					if found_currency ~= {} then
						local val = found_currency._am
						local old_val = old_values[currency_type]
						copy[currency_type].Amount.Size = UDim2.new(0, 1233, 0.8, 0)
						copy[currency_type].Amount.TextXAlignment = Enum.TextXAlignment.Left
						copy[currency_type].Amount.Text = string.format("Farmed %s in %s seconds", comma(val - old_val), math.floor(data.refresh_stat))
						old_values[currency_type] = val
					end
				end
			end)
			
			print(err)
			
			task.wait(data.refresh_stat)
		end
	end,
})

currency:AddSlider("123", {
	Title = "Refresh Time",
	Min = 1,
	Max = 120,
	Default = data.refresh_stat,
	Rounding = 1,
	Callback = function(val)
		data.refresh_stat = val
	end,
})




egg:AddParagraph({
	Title = "Auto egg hatch settings",
	Context = "Set settings for auto hatch"
})

egg:AddSlider("123", {
	Title = "Egg Amount (ignore float value)",
	Default = data.egg_open,
	Min = 1,
	Rounding = 1,
	Max = 140,
	Callback = function(val)
		data.egg_open = val
	end,
})



