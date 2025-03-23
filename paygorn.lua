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

if getgenv().cache ~= nil then
	if getgenv().cache.button ~= nil then
		getgenv().cache.button:Destroy()
	end

	if getgenv().cache.ores ~= nil then
		for i,v in pairs(getgenv().cache.ores) do
			v:Destroy()
		end
	end
end



getgenv().cache = {
	ores = {},
}
local screen = Instance.new("ScreenGui", gethui())
screen.ResetOnSpawn = false

local button = Instance.new("TextButton", screen)
button.Position = UDim2.fromScale(0.5, 0.85)
button.AnchorPoint = Vector2.new(0.5, 0.85)
button.TextScaled = true
button.Text = "Scan"
button.BackgroundColor3 = Color3.fromRGB(255,255,255)
button.TextColor3 = Color3.fromRGB(0,0,0)
button.Size = UDim2.fromScale(0.2, 0.1)

local mbutton = Instance.new("TextButton", screen)
mbutton.Position = UDim2.fromScale(0.5, 0.7)
mbutton.AnchorPoint = Vector2.new(0.5, 0.7)
mbutton.TextScaled = true
mbutton.BackgroundColor3 = Color3.fromRGB(255,255,255)
mbutton.TextColor3 = Color3.fromRGB(0,0,0)
mbutton.Size = UDim2.fromScale(0.125, 0.065)

getgenv().cache.button = screen

local mining = false
local rad = 8
spawn(function()
	while task.wait() do
		if mining then
			mbutton.Text = "Stop mining"
		elseif not mining then
			mbutton.Text = "Start mining"
		end

		mbutton.Text = mbutton.Text..tostring("("..rad.."x"..rad..")")
	end
end)
local cmd = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds)
mbutton.MouseButton2Click:Connect(function()
	if rad < 16 then
		rad *= 2
	elseif rad == 16 then
		rad = 2
	end
end)
mbutton.MouseButton1Click:Connect(function()
	if not mining then
		mining = true
	elseif mining then
		mining = false
	end


	local foot = cmd.GetBlockAtFoot()
	if foot ~= nil then
		local pos = foot.Pos
		local c = 0
		local r2 = rad / 2
		for y = -pos.Y, 256 do
			for x = pos.X - r2 + 1, pos.X + r2 do
				for z = pos.Z - r2 + 1, pos.Z + r2 do
					local pos = Vector3int16.new(x,-y,z)
					game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Target"):FireServer(pos)
					game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("BlockWorlds_Break"):FireServer(pos)

				end
			end
			task.wait(0.2 * r2)
			c += 1
			if c == 6 then
				c = 0
				task.wait(0.15 * rad)
			end
			if not mining then
				break
			end
		end
	end

	if foot == nil then
		mining = false
	end
end)
button.Activated:Connect(function()
	for i,v in pairs(getgenv().cache.ores) do
		v:Destroy()
	end

	local Blocks = nil

	for i,v in pairs(workspace.__THINGS.BlockWorlds:GetChildren()) do
		if v.Name:find("Blocks") then
			Blocks = v
		end
	end

	local scanned = 0

	for i,v in pairs(Blocks:GetChildren()) do
		pcall(function()
			local display, color = false, Color3.fromRGB(0,0,0)
			local id = v:GetAttribute("id")

			for i2,v2 in pairs(blocks) do
				if i2 == id then
					display = true
					color = v2.color
				end
			end

			if display then
				local render = Instance.new("BillboardGui", v)
				render.Size = UDim2.fromScale(v.Size.X, v.Size.Y)
				render.ResetOnSpawn = false
				render.AlwaysOnTop = true
				local text = Instance.new("TextLabel", render)
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 0.5
				text.TextColor3 = Color3.fromRGB(255,255,255)
				text.BackgroundColor3 = color
				text.Text = id
				table.insert(getgenv().cache.ores, render)

			end
		end)
	end

end)
