

if getgenv().wtool ~= nil and getgenv().wtool.screen ~= nil then
	getgenv().wtool.screen:Destroy()
end

local screen = Instance.new("ScreenGui", gethui())
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Enabled = true

local bwc = require(game:GetService("ReplicatedStorage").Library.Client.MiningCmds.BlockWorldClient)


game:GetService("UserInputService").InputEnded:Connect(function(key)
	key = key.KeyCode

	if key == Enum.KeyCode.Delete then
		screen.Enabled = not screen.Enabled
	end
end)

local ores = {}

for i,v in pairs(game:GetService("ReplicatedStorage").__DIRECTORY.Blocks:GetChildren()) do
	if v.Name:find("Ore") then
		local id = require(v).DisplayName:split(" ")[1]
		table.insert(ores, id)
	end
end

table.sort(ores, function(a, b)
	return a > b
end)

local ui = {
	tabs = 0
}

ui.CreateToggleTab = function(data)
	local args = data.args or {}
	local func = data.func
	local name = data.name

	ui.tabs += 1
	local arg_count = 0
	local pos = UDim2.fromScale(ui.tabs * 0.125, 0.2)
	local pos2 = Vector2.new(ui.tabs * 0.125, 0.2)

	local bt = Instance.new("TextButton", screen)
	bt.Name = "Tab"..ui.tabs
	bt.Size = UDim2.fromScale(0.1, 0.065)
	bt.BorderSizePixel = 0  
	bt.Position = pos
	bt.AnchorPoint = pos2
	bt.Text = name
	bt.TextScaled = true
	bt.BorderSizePixel = 4

	local render_args = false
	local enabled = false

	spawn(function()
		while task.wait() do
			local color = if enabled then Color3.fromRGB(137, 255, 94) else Color3.fromRGB(255, 75, 75)
			bt.BackgroundColor3 = color
		end
	end)

	local args_render = {}




	local new = {}

	for i,v in pairs(args) do
		new[v] = false
	end

	args = new

	for i,v in pairs(args) do
		arg_count += 1
		local arg_enabled = false

		local arg = Instance.new("TextButton", screen)
		arg.BorderSizePixel = 0
		arg.Position = pos + UDim2.fromScale(0, (bt.Size.Y.Scale + 0.005) * arg_count)
		arg.AnchorPoint = pos2 + Vector2.new(0, (bt.Size.Y.Scale + 0.005) * arg_count)
		arg.Size = bt.Size
		arg.Text = i
		arg.TextSize = 16
		arg.BorderSizePixel = 2


		spawn(function()
			while task.wait() do
				local color = if arg_enabled then Color3.fromRGB(137, 255, 94) else Color3.fromRGB(255, 75, 75)
				arg.BackgroundColor3 = color
				arg.Visible = render_args
			end
		end)


		arg.Activated:Connect(function()
			arg_enabled = not arg_enabled
			args[i] = not args[i]
		end)
	end


	bt.MouseButton2Click:Connect(function()
		render_args = not render_args
	end)

	bt.MouseButton1Click:Connect(function() 
		enabled = not enabled
		func(enabled, args)
	end)




end
getgenv().wtool = {
	scans = {},
	data = {
		xray = false,
		mine = false,
		dstats = false,
	}
}

local colors = {
	Sapphire = Color3.fromRGB(0, 68, 255),
	Emerald = Color3.fromRGB(60, 255, 46),
	Rainbow = Color3.fromRGB(255, 240, 32),
	Amethyst = Color3.fromRGB(217, 103, 255),
	Ruby = Color3.fromRGB(255, 12, 12)
}

ui.CreateToggleTab({
	name = "Ore XRay",
	func = function(val, args)
		getgenv().wtool.data.xray = val
		for i,v in pairs(getgenv().wtool.scans) do
			v:Destroy()
		end
		
		if val == true then
			while getgenv().wtool.data.xray do
				task.wait(0.1)
				for i,v in pairs(getgenv().wtool.scans) do
					v:Destroy()
				end
				if getgenv().wtool.data.xray then
					local blocks = nil
					if bwc.GetLocal() then
						blocks = bwc.GetLocal().Blocks
					else
						print("player MUST be in mining location")
						return
					end
					
					for i,v in pairs(blocks) do
						local id = v.Part:GetAttribute("id")
						local display = false

						if args[id]  == true then
							display = true
						end


						if display == true then
							local render = Instance.new("BillboardGui", v.Part)
							render.Size = UDim2.fromScale(4.5, 4.5)
							render.AlwaysOnTop = true

							local t = Instance.new("Frame", render)
							t.Size = UDim2.fromScale(1, 1)
							t.BorderSizePixel = 2
							t.BorderColor3 = Color3.fromRGB(0,0,0)
							local t2 = Instance.new("TextLabel", t)
							t2.Size = UDim2.fromScale(1,1)
							t2.Text = id
							t2.TextScaled = true
							t2.BackgroundTransparency = 1
							t2.TextColor3 = Color3.fromRGB(255,255,255)
							local color = colors[id]
							t.BackgroundColor3 = color

							table.insert(getgenv().wtool.scans, render)
						end
					end
				end
			end
		end
	end,
	args = ores,
})

ui.CreateToggleTab({
	name = "Auto mine",
	args = ores,
	func = function(val, args)
		getgenv().wtool.data.mine = val
		
		spawn(function()
			while getgenv().wtool.data.mine do
				task.wait(0.2)
				local blocks = nil
				if bwc.GetLocal() then
					blocks = bwc.GetLocal().Blocks
				else
					print("player MUST be in mining location")
					return
				end
				
				local smth_found = false

				for i,v in pairs(blocks) do
					local cframe = v.CFrame
					local pos = v.Pos
					local id = v.Part:GetAttribute("id")


					if args[id] == true and getgenv().wtool.data.mine == true then
						smth_found = true
						local destroyed = false

						local t = 0.1
						v.Part.Changed:Once(function()
							destroyed = true
						end)
						repeat
							spawn(function()
								while not destroyed and getgenv().wtool.data.mine == true and args[id] == true do
									task.wait()
									game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(cframe)
								end
							end)
							pcall(function()
								task.wait()
								game:GetService("ReplicatedStorage").Network.BlockWorlds_Target:FireServer(pos)
								task.wait(t)
								game:GetService("ReplicatedStorage").Network.BlockWorlds_Break:FireServer(pos)
								task.wait(0.01)
							end)

							t += 0.3
						until destroyed or args[id] == false or getgenv().wtool.data.mine == false
					end
				end
				
				
				if not smth_found and getgenv().wtool.data.mine then
					for i = 1, 15 do
						local v = nil
						for i,v1 in pairs(blocks) do
							v = v1
							break
						end
						local cframe = v.CFrame
						local pos = v.Pos
						local id = v.Part:GetAttribute("id")
						
						local destroyed = false
						local t = 0.1
						v.Part.Changed:Once(function()
							destroyed = true
						end)
						
						if getgenv().wtool.data.mine == false then
							break
						end
						
						repeat
							spawn(function()
								while not destroyed and getgenv().wtool.data.mine == true do
									task.wait()
									game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(cframe)
								end
							end)
							pcall(function()
								game:GetService("ReplicatedStorage").Network.BlockWorlds_Target:FireServer(pos)
								task.wait(t)
								game:GetService("ReplicatedStorage").Network.BlockWorlds_Break:FireServer(pos)
								task.wait(0.01)
							end)

							t += 0.3
						until destroyed or args[id] == false or getgenv().wtool.data.mine == false
					end
				end
				
			end
		end)
	end,
})


getgenv().wtool.screen = screen
