
local save = require(game:GetService("ReplicatedStorage").Library.Client.Save)
local mcmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
local bwc = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds.BlockWorldClient)
local MiningUtil = require(game.ReplicatedStorage.Library.Util.MiningUtil)
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

local Window = WindUI:CreateWindow({
	Title = "SUPER MEGA PET SIM FARM!!",
	Icon = "door-open",
	Author = "by sh0vel",
	Folder = "gayhub",
	Size = UDim2.fromOffset(780, 460),
	Transparent = false,
	Theme = "Dark",
	SideBarWidth = 120,
	--Background = "rbxassetid://13511292247", -- rbxassetid only
	HasOutline = true
})

local farm = Window:Tab({Title = 'Farm'})
local merchant = Window:Tab({Title = "Merchant"})

if getgenv().wtools ~= nil then
	pcall(function()
		for i,v in pairs(getgenv().wtools.ores) do
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
	ores = {}
}

local data = {
	mining = false,
	center = false,
	center_start_y_zero = true,
	merchant = false,
	only_ores_tnt = {},
	only_ores_tnt_chance = 0,
}
local scan = false
local rad = 10
local mode = "Default"


local cmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
local lcl = bwc.GetLocal()

spawn(function()
	while task.wait(0.1) do
		lcl = bwc.GetLocal()
	end
end)

farm:Toggle({
	Title = "Auto farm",
	Callback = function(val)
		data.mining = val

		local blocks = lcl
		local center_block = nil
		if blocks ~= nil and val then
			local player = game.Players.LocalPlayer

			if data.center then
				local center_block = nil
				for i = 0, 128 do
					local pos = Vector3int16.new(0, -i, 0)
					center_block = blocks:GetBlock(pos)

					if center_block ~= nil then
						break
					end
				end

				if center_block ~= nil then
					player.Character:SetPrimaryPartCFrame(center_block.Part.CFrame + Vector3.new(0, 4, 0))
				end
			end

			local current_block = center_block or mcmd.GetBlockUnderPlayer()
			local function GetTimeToBreak(block, extra)
				extra = extra or 0
				local player = game.Players.LocalPlayer
				local blockStrength = block:GetDirectory().Strength


				local selectedPickaxe = MiningUtil.GetSelectedPickaxe(player)
				local bestPickaxe = MiningUtil.GetBestPickaxe(player, true)

				if not selectedPickaxe or not bestPickaxe then
					return 0
				end


				local damagePerHit = MiningUtil.ComputeDamage(player, selectedPickaxe, bestPickaxe, block:GetDirectory())
				local miningSpeed = MiningUtil.ComputeSpeed(player, selectedPickaxe)
				local dps = damagePerHit * miningSpeed

				local baseTime = blockStrength / dps
				local pingCompensation = player:GetNetworkPing() / 2 
				local totalTime = baseTime + 0.001 + pingCompensation + extra


				local randomFactor = 1 + (math.random() * 0.05 - 0.025) 
				totalTime = totalTime * randomFactor

				return math.max(0.025, totalTime)
			end
			local function GetBlockUnder(pos)
				local x = pos.X
				local y = pos.Y
				local z = pos.Z

				local new_block = blocks:GetBlock(Vector3int16.new(x,y,z))
				if new_block == nil then
					repeat
						task.wait()
						y += 1
						new_block = blocks:GetBlock(Vector3int16.new(x,y,z))
					until y > 128 or new_block ~= nil
				end

				return new_block
			end




			if current_block ~= nil and mode == "Slices" then
				local reqY = 0
				local checked = false
				local rblocks = {}
				
				if data.center_start_y_zero == false then
					reqY = current_block.Pos.Y
					print(reqY)
				end

				while data.mining do
					if math.random(1, 15) ==1  then
						task.wait()
					end
					
					local function destroy(v, bns, tp)
						tp = tp or true
						bns = bns or Vector3int16.new(0,0,0)
						local b = 0
						local r = math.random(1,3)
						local cd = GetTimeToBreak(v, b)
						if tp then
							game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(v.Part.CFrame + Vector3.new(0, 5, 0))
						end
						game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(v.Pos)
						task.wait(cd/r)

						game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(v.Pos)
					end

					table.clear(rblocks)
					for z = -17, 17 do
						for x = -17, 17 do
							local rblock = blocks:GetBlock(Vector3int16.new(x, reqY, z))
							if rblock ~= nil then
								table.insert(rblocks, rblock)
							end
						end
					end


					for i,v in pairs(rblocks) do
						if data.mining == false then
							break
						end
						pcall(function()
							destroy(v)
						end)
					end

					if #rblocks == 0 then
						reqY -= 1
					end



				end

			end

			if current_block ~= nil and mode == "Only ores" then
				local y = 0

				local function destroy(blc)
					local id = blc.Part:GetAttribute("id")

					if isOre(id) then
						task.wait(0.05)
					end
					local cd = GetTimeToBreak(blc)
					game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(blc.Part.CFrame + Vector3.new(0, 5, 0))
					if isOre(id) then
						task.wait(0.1)
					end
					game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(blc.Pos)
					task.wait(cd + 0.005)
					game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(blc.Pos)
				end

				while task.wait() do
					if not data.mining then
						break
					end
					
					while data.mining  do
						task.wait()
						local temp_ores = {}
						for i,v in pairs(blocks.Blocks) do
							pcall(function()
								local id = v.Part:GetAttribute("id")

								if isOre(id) then
									table.insert(temp_ores, v)
								end
							end)
						end

						local smth_found = false

						if #temp_ores == 0 then
							local function remove_border(pos)
								local bblock = blocks:GetBlock(pos)

								if bblock ~= nil then
									destroy(bblock)
								end
							end

							remove_border(Vector3int16.new(-8, y, -8))
							remove_border(Vector3int16.new(7, y, -8))
							remove_border(Vector3int16.new(7, y, 7))
							remove_border(Vector3int16.new(-8, y, 7))

							for z = -18, 18, 2 do
								if not data.mining then
									break
								end
								for x = -18, 18, 2 do
									if not data.mining then
										break
									end
									local block = blocks:GetBlock(Vector3int16.new(x, y, z))
									if block ~= nil then
										smth_found = true
										local id = block.Part:GetAttribute("id")

										if not isOre(id) then
											local rng = math.random(0, 100)
											if data.only_ores_tnt_chance > rng then
												local save = save.GetSaves()[player]
												if save ~= nil then
													local consumables = save.Inventory.Consumable
													for i,v in pairs(consumables) do
														if table.find(data.only_ores_tnt, v.id) then
															local id = i
															game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(block.Part.CFrame + Vector3.new(0, 5, 0))
															local function spawn()
																local args = {
																	[1] = i,
																	[2] = 1
																}

																game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Consumables_Consume"):InvokeServer(unpack(args))

															end

															spawn()
															break
														end
													end
												end
											elseif data.only_ores_tnt_chance <= rng then
												destroy(block)
												local other_block = Vector3int16.new(x, y - 1, z)
												other_block = blocks:GetBlock(other_block)

												if other_block ~= nil then
													destroy(other_block)
												end

												local other_block2 = Vector3int16.new(x + 1, y, z + 1)
												other_block2 = blocks:GetBlock(other_block2)

												if other_block2 ~= nil then
													destroy(other_block2)
												end

												local other_block3 = Vector3int16.new(x + 1, y - 1, z + 1)
												other_block3 = blocks:GetBlock(other_block3)

												if other_block3 ~= nil then
													destroy(other_block3)
												end

											end

										end
									end
								end
							end


							if data.mining and smth_found then
								for i,v in pairs(blocks.Blocks) do
									if v.Pos.Y == y - 1 or v.Pos.Y == y or v.Pos.Y > y + 1 then
										local id = v.Part:GetAttribute("id")

										if not isOre(id) then
											v.Part:Destroy()
										end
									end
								end
							end
							local fnd = false
							if mcmd.GetBlockUnderPlayer() ~= nil then
								fnd = true
							end
							
							if not fnd then
								y = 0
								break
							end
							y -= 2
						elseif #temp_ores > 0 then
							for i,v in pairs(temp_ores) do
								if not data.mining then
									break
								end
								destroy(v)
							end
						end


					end
					
				end




			end

			if current_block ~= nil and mode == "Default" then
				local pos = current_block.Pos
				local c = 0
				local r2 = rad / 2
				for y = -pos.Y, 256 do
					if not data.mining then
						break
					end
					local maxX = pos.X + r2
					local minX = pos.X - r2 + 1
					local maxZ = pos.Z + r2
					local minZ = pos.Z - r2 + 1
					for x = pos.X - r2 + 1, pos.X + r2 do
						if not data.mining then
							break
						end
						for z = pos.Z - r2 + 1, pos.Z + r2 do
							if not data.mining then
								break
							end

							local pos = Vector3int16.new(x,-y,z)
							local new_block = blocks:GetBlock(pos)

							local function breakblock(pos)
								local new_block = blocks:GetBlock(pos)
								if new_block == nil then
									return
								end
								local cd = GetTimeToBreak(new_block, 0)
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(pos)
								task.wait(cd)
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(pos)
							end
							if new_block ~= nil then
								breakblock(pos)
								local function wclip(coord, b)
									if coord == "x" then
										if x + b <= maxX and x + b >= minX then
											breakblock(Vector3int16.new(x + b, -y, z))
										end
									elseif coord == "z" then
										if z + b <= maxZ and z + b >= minZ then
											breakblock(Vector3int16.new(x, -y, z + b))
										end

									end
								end

								wclip("x", 1)
								wclip("x", 2)
								wclip("z", 1)
							end
						end
					end
				end
			end

		end
	end,
})

farm:Toggle({
	Title = "Teleport to center",
	Callback = function(val)
		data.center = val
	end,
})

farm:Dropdown({
	Title = "Mining mode",
	Values = { "Default", "Slices", "Only ores"},
	Value = "Default",
	Callback = function(val)
		mode = val
	end
})

farm:Section({
	Title = "Slices mode options"
})

farm:Toggle({
	Title = "Start at 0 y",
	
	Callback = function(val)
		data.center_start_y_zero = val
	end,
})

farm:Section({
	Title = "Only ores options"
})

farm:Dropdown({
	Title = "Select tnt to use",
	Multi = true,
	AllowNone = true,
	Values = mining_event_items_short.tnts,
	Value = {},
	Callback = function(val)
		data.only_ores_tnt = dec_short_names("tnts", val)
	end,
})

farm:Slider({
	Title = "TNT Use chance",
	Value = {
		Min = 0,
		Max = 100,
		Default = 0,
	},

	Callback = function(val)
		data.only_ores_tnt_chance = val
	end,
})





merchant:Toggle({
	Title = "Auto buy mine merchant",

	Callback = function(val)
		data.merchant = val

		while data.merchant do
			task.wait(1)
			for i = 1, 6 do
				task.wait(0.1)
				local args = {
					[1] = "MiningMerchant",
					[2] = i
				}

				game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Merchant_RequestPurchase"):InvokeServer(unpack(args))

			end
		end
	end,
})
