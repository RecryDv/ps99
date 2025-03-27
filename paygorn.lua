local blocks = {
	Emerald = {
		color = Color3.fromRGB(0,255,128)
	},

	Amethyst = {
		color = Color3.fromRGB(113, 57, 255)
	},

	Rainbow = {
		color = Color3.fromRGB(255, 42, 14)
	}
}

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



local data = {
	mining = false,
	center = false,
	
}
local scan = false
local rad = 8


local cmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)

farm:Toggle({
	Title = "Auto farm",
	Callback = function(val)
		data.mining = val

		local blocks = bwc.GetLocal()
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
			local function GetTimeToBreak(block)
				local blockStrength = block:GetDirectory().Strength

				local selectedPickaxe = MiningUtil.GetSelectedPickaxe(player)
				local bestPickaxe = MiningUtil.GetBestPickaxe(player, true)

				if not selectedPickaxe or not bestPickaxe then
					return "no"
				end

				local damagePerHit = MiningUtil.ComputeDamage(player, selectedPickaxe, bestPickaxe, block:GetDirectory())
				local miningSpeed = MiningUtil.ComputeSpeed(player, selectedPickaxe)
				local dps = damagePerHit * miningSpeed

				return blockStrength / dps
			end


			if current_block ~= nil then
				local pos = current_block.Pos
				local c = 0
				local r2 = rad / 2
				for y = -pos.Y, 256 do
					if not data.mining then
						break
					end
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

							if new_block ~= nil then
								local cd = GetTimeToBreak(new_block) + 0.001
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(pos)
								task.wait(cd)
								game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(pos)

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
