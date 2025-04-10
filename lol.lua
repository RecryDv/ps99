local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local UIC = Knit.GetController("UIController")
local DataController = Knit.GetController("DataController")
local RewardService = Knit.GetService("RewardService")
local TreeService = Knit.GetService("TreeService")
local player = game.Players.LocalPlayer
local Window = Fluent:CreateWindow({
	Title = "Fluent " .. Fluent.Version,
	SubTitle = "by dawid",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
	op = Window:AddTab({Title = "OP"}),
	aw = Window:AddTab({ Title = "Auto wood", Icon = "" }),
	misc = Window:AddTab({Title = "Misc"})
}

local function client_not(...)
	UIC:createNotification(...)
end

local function generate_toggle(val)
	return if val then "Enabled" else "Disabled"
end

local d = {
	aw = false,
	ac = false,
	aw_loc = "",
	ao = false,
	fs = false,
	wood = "",
	L_id = "",
}

Tabs.op:AddButton({
	Title = "Unlock auto rebirth",
	Callback = function()
		local RebirthModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Components.UI.Frames.RebirthFrame)
		local unlocked = RebirthModule.canAutoRebirth()
		
		if unlocked == true then
			client_not("Custom", "[sh0vel prod.] | Auto rebirth is already unlocked!", 3)
			return
		end
		hookfunction(RebirthModule.canAutoRebirth, function()
			return true
		end)
		
		client_not("Custom", "[sh0vel prod.] | Auto rebirth was unlocked!", 3)
	end,
})

Tabs.op:AddButton({
	Title = "Unlock insane farmer",
	Callback = function()
		local FarmerItemsModule = require(game.ReplicatedStorage.Shared.Values.FarmerItems)
		
		local t = 0
		pcall(function()
			t = FarmerItemsModule()
		end)
		local unlocked = (t == 1000000000)

		if unlocked == true then
			client_not("Custom", "[sh0vel prod.] | Insane farmer is already unlocked!", 3)
			return
		end
		hookfunction(FarmerItemsModule, function()
			return 1000000000
		end)

		client_not("Custom", "[sh0vel prod.] | Insane farmer was unlocked!", 3)
	end,
})

Tabs.misc:AddToggle("123", {
	Title = "Auto collect orbs",
	Callback = function(val)
		d.ao = val
		
		while d.ao do
			task.wait(0.01)
			
			for _, orb in pairs(workspace.Debris.Orbs:GetChildren()) do
				orb.CFrame = player.Character.PrimaryPart.CFrame
			end
		end
	end,
})

Tabs.misc:AddToggle("123", {
	Title = "Auto collect chest",
	Callback = function(val)
		d.ac = val
		
		while d.ac do
			task.wait()
			for _, world in pairs(workspace.Game.Maps:GetChildren()) do
				pcall(function()
					for _, chest in pairs(world.MiniChests:GetChildren()) do
						task.wait(0.05)
						local status = RewardService:claimMiniChest(chest:GetAttribute("miniChestId"),chest:GetAttribute("miniChestName"))
						if status == "success" then
							client_not("Custom", "[sh0vel prod.] | Claimed chest!")
						end
					end
				end)
			end
		end
	end,
})


Tabs.misc:AddToggle("123", {
	Title = "Auto collect falling stars",
	Callback = function(val)
		d.fs = val

		while d.fs do
			task.wait(0.01)

			for _, star in pairs(workspace.Debris:GetChildren()) do
				if star.Name == "FallingStar" then
					star.Hitbox.CFrame = player.Character.PrimaryPart.CFrame
				end
			end
		end
	end,
})

local trees_loc = {}

for _, location in pairs(workspace.Game.Maps:GetChildren()) do
	table.insert(trees_loc, location.Name)
end

Tabs.aw:AddDropdown("123", {
	Title = "Farm wood location",
	Values = trees_loc,
	Default = "",
	AllowNone = false,
	
	Callback = function(val)
		d.aw_loc = val
	end,
})

Tabs.aw:AddButton({
	Title = "Define lumber id",
	
	Callback = function()
		if d.L_id ~= "" then
			client_not("Custom", "[sh0vel prod.] | Lumber id is already defined!", 3)
			return
		end
		
		client_not("Custom", "[sh0vel prod.] | Cut any wood!", 5)
		local possible = ""
		
		local oldcall
		
		oldcall = hookmetamethod(game, "__namecall", function(self, ...)
			
			local Args = {...}
			local Method = getnamecallmethod()
			
			if Method == "FireServer" and #Args == 3 and typeof(Args[3]) == "string" then
				possible = Args[3]
			end
			
			return oldcall(self, ...)
		end)
		
		repeat
			task.wait()
		until possible ~= ""
		d.L_id = possible
		client_not("Custom", "[sh0vel prod.] | Done, Lumber Id is "..possible)
	end,
})

Tabs.aw:AddToggle("123", {
	Title = "Auto cut wood",
	Callback = function(val)
		d.aw = val
		client_not("Custom", "[sh0vel prod.] | Wood Cutting "..generate_toggle(val), 0.5)
		
		local function isbroken(tree)
			local broken = false
			local f = 0
			for i,v in pairs(tree:FindFirstChildOfClass("Model").PrimaryPart:GetChildren()) do
				f+=1
				if v:IsA("BillboardGui") and v.Enabled then
					broken = true
				end
			end
			
			if not broken and f == 0 then
				broken = false
			end
			
			return broken
		end
		
		if d.aw then
			if d.aw_loc == "" then
				client_not("Custom", "[sh0vel prod.] | Please select location!", 5)
				return
			end

			if not DataController:getData().isAxeEquipped then
				client_not("Custom", "[sh0vel prod.] | Equip your axe first!", 5)
				return
			end
			
			if d.L_id == "" then
				client_not("Custom", "[sh0vel prod.] | Unknown lumber id. Please click button 'Define lumber id'", 5)
				return
			end
		end
		
		local client_tree = ""
		
		while d.aw do
			task.wait()
			local trees = workspace.Game.Maps[d.aw_loc].Trees:GetChildren()
			local tree = trees[math.random(1, #trees)]
			client_tree = tostring(game:GetService("HttpService"):GenerateGUID(false))
			local current = client_tree
			
			local l_ID = TreeService:getLumberId()
			
			if not isbroken(tree) then
				local root = tree:FindFirstChildOfClass("Model")
				
				client_not("Custom", "[sh0vel prod.] | Teleporting to tree.", 2.5)
				
				spawn(function()
					while client_tree == current and d.aw do
						task.wait()
						game.Players.LocalPlayer.Character.PrimaryPart.CFrame = root.PrimaryPart.CFrame
					end
				end)
				
				repeat
					TreeService.damage2:Fire(
						tree:GetAttribute("groupId"),
						tree:GetAttribute("treeId"),
						d.L_id
					)
					task.wait()
				until not d.aw or isbroken(tree)
				client_not("Custom", "[sh0vel prod.] | Done with tree "..client_tree, 2.5)
			end
		end
	end,
})

client_not("Custom", "[sh0vel prod.] | Injected!",  5)
