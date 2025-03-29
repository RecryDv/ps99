

local mcmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
local bwc = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds.BlockWorldClient)
local MiningUtil = require(game.ReplicatedStorage.Library.Util.MiningUtil)
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

local Window = WindUI:CreateWindow({
	Title = "SUPER MEGA PET SIM FARM!!",
	Icon = "door-open",
	Author = "by sh0vel",
	Folder = "gayhub",
	Size = UDim2.fromOffset(640, 460),
	Transparent = false,
	Theme = "Dark",
	SideBarWidth = 180,
	--Background = "rbxassetid://13511292247", -- rbxassetid only
	HasOutline = true
})

local farm = Window:Tab({Title = 'Farm'})
local xray = Window:Tab({Title = "XRay"})

if getgenv().wtools ~= nil then
	pcall(function()
		for i,v in pairs(getgenv().wtools.ores) do
			v:Destroy()
		end
	end)
end

local ores = {}
local ores_id = {}
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
	xray = false,
	xores = {}
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
				local extra = extra or 0
				local blockStrength = block:GetDirectory().Strength

				local selectedPickaxe = MiningUtil.GetSelectedPickaxe(player)
				local bestPickaxe = MiningUtil.GetBestPickaxe(player, true)

				if not selectedPickaxe or not bestPickaxe then
					return "no"
				end

				local damagePerHit = MiningUtil.ComputeDamage(player, selectedPickaxe, bestPickaxe, block:GetDirectory())
				local miningSpeed = MiningUtil.ComputeSpeed(player, selectedPickaxe)
				local dps = damagePerHit * miningSpeed

				return blockStrength / dps + 0.001 + player:GetNetworkPing() / 2.5 + extra
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

				while data.mining do
					if math.random(1, 15) ==1  then
						task.wait()
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
							local function destroy(bns, tp)
								tp = tp or true
								bns = bns or Vector3int16.new(0,0,0)
								local b = 0
								local r = math.random(1,5)
								local cd = GetTimeToBreak(v, b)
								if tp then
									game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(v.Part.CFrame + Vector3.new(0, 5, 0))
								end
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(v.Pos)
								task.wait(cd/r)
								
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(v.Pos)
							end

							destroy()
						end)
					end
					
					if #rblocks == 0 then
						reqY -= 1
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
	Values = { "Default", "Slices"},
	Value = "Default",
	Callback = function(val)
		mode = val
	end
})

xray:Dropdown({
	Title = "XRay Ores",
	Values = ores_id,
	Value = {},
	Multi = true,
	AllowNone = true,

	Callback = function(val)
		data.xores = val
	end,
})

xray:Toggle({
	Title = "Enable xray",
	Callback = function(val)

		data.xray = val
		local blocks = bwc.GetLocal()
		while not data.xray do
			for i,v in pairs(getgenv().wtools.ores) do
				v:Destroy()
			end
			task.wait()
		end

		while data.xray do
			task.wait(0.2)
			for i,v in pairs(getgenv().wtools.ores) do
				v:Destroy()
			end

			if lcl ~= nil then
				pcall(function()
					for i,v in pairs(blocks) do
						local suc, err = pcall(function()
							local part = v.Part
							local id = part:GetAttribute("id")

							if table.find(data.xores, id) then
								local module_data = ores[id] 
								local color = module_data.ParticleColor or Color3.fromRGB(255,255,255)		

								local render = Instance.new("BillboardGui", part)
								render.AlwaysOnTop = true
								render.Adornee = part
								render.Size = UDim2.fromScale(part.Size.X, part.Size.Y)

								local text = Instance.new("TextLabel", render)
								text.Size = UDim2.fromScale(1,1)
								text.BackgroundColor3 = color
								text.BackgroundTransparency = 0.5
								text.TextScaled = true
								text.Text = id
								text.TextColor3 = Color3.fromRGB(47, 47, 46)

								table.insert(getgenv().wtools.ores, render)
							end
						end)
					end
				end)
			end
			
			

		end
	end,
})
