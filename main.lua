

local global_env = (getgenv and getgenv()) or _G
global_env.bullet_disconnected = false
global_env.signals = {}
global_env.hatlist = nil
global_env.bulletpart = nil
global_env.bulletattacking = false
if not global_env.CloneRigs then
	global_env.CloneRigs = {
		["R6"] = game:GetObjects("rbxassetid://8440552086")[1],
		['R15'] = game:GetObjects("rbxassetid://10213333320")[1]
	}
end
local speed = tick()
local Settings = global_env.Settings or {}
local lwait,ldelay,ldefer,lspawn = task.wait, task.delay, task.defer, task.spawn
local cf,cfangle,v3,ins,tickk,tonum = CFrame.new, CFrame.Angles, Vector3.new, table.insert, tick, tonumber
local ws,plrs,run_serv = game:GetService("Workspace"), game:GetService("Players"), game:GetService("RunService")
local stepped, heartbeat, renderstepped = run_serv.PreSimulation, run_serv.PostSimulation, run_serv.RenderStepped
local rbxsignals, offsets, antisleepcf, antisleepforce = {}, {}, cf(), Settings.AntiSleepForce or 1
local exclusionpart, camera = "", ws.CurrentCamera
local cameraCF,singlethreading = camera.CFrame, {["Collisions"] = {}, ["Properties"] = {}}
local v3_010, headangle, fakechar = v3(0,1,0), 0, nil

local plr = plrs.LocalPlayer
local char = plr.Character
do
	if char.Name == "RawInstance" then
		warn("already reanimated")
		return
	end

	if not char:FindFirstChildOfClass("Humanoid") then
		warn("no humanoid")
		return
	end

	if char:FindFirstChildOfClass("Humanoid").Health == 0 then
		warn("dead")
		return
	end
end

if Settings.HeadMovementMethod then
	local backup = char.PrimaryPart.CFrame
	char:BreakJoints()
	plr.Character = nil
	plr.CharacterAdded:Once(function(v)
		local char = v or plr.CharacterAdded:Wait()
		if char:WaitForChild("Animate") then
			char:FindFirstChild("Animate"):Destroy()
		end
	end)
	repeat lwait() until plr.Character
	char = plr.Character
	char:MoveTo(backup.Position)
	task.wait(0.25)
end


local char_gc, char_gd = char:GetChildren(), char:GetDescendants()
local realhum, rootpart = char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart") or realhum.RootPart
local rigtype = realhum.RigType.Name
char.Archivable = true



if Settings.Bullet then
	if rigtype == "R6" then
		exclusionpart = "Left Leg"
		
	else
		exclusionpart = "LeftUpperArm"
		
	end
end

local set_hidden_property = sethiddenproperty or function(target, property, value)
	pcall(function() target[property] = value end)
end

local function prepare_tweaks()
	local physics = settings()["Physics"]
	if plr:FindFirstChild("Backpack") then
		plr:FindFirstChild("Backpack"):ClearAllChildren()
	end
	plr.ReplicationFocus = ws
	physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
	physics.ThrottleAdjustTime = 1/0

	physics.AllowSleep = false
	physics.DisableCSGv2 = false
	physics.UseCSGv2 = true

	ws.Retargeting = "Disabled"
	ws.InterpolationThrottling = "Disabled"

	set_hidden_property(ws, "PhysicsSteppingMethod", "Adaptive")
	set_hidden_property(ws, "SignalBehavior", "Immediate")
	set_hidden_property(realhum, 'MoveDirectionInternal', v3(16000,16000,16000))
	for _,v in pairs(char_gd) do
		if v:IsA("BasePart") then
			v.Anchored = false
			v.AssemblyLinearVelocity = v3()
			v.AssemblyAngularVelocity = v3()
			set_hidden_property(v, "NetworkIsSleeping", false)
		end
	end
end

local function create_rig(rigtype)
	local fldr = Instance.new("Folder", ws:FindFirstChildOfClass("Terrain"))
	fldr.Name = game:GetService("HttpService"):GenerateGUID(false)
	local clonerig = global_env.CloneRigs[rigtype]:Clone()
	clonerig.Name = "RawInstance"
	clonerig.Parent = fldr
	for _, descendant in pairs(clonerig:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.Anchored = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
	return clonerig
end

local check_ownership; if isnetworkowner then
	check_ownership = function(part) return isnetworkowner(part) end
else
	check_ownership = function(part) return part.ReceiveAge == 0 end
end

local function get_mass(part)
	return (part.Size.X+part.Size.Y+part.Size.Z) / (part.Size.Magnitude/4.3219)
end

local function disable_collisions(part0, part1)
	local disable_or_no = Settings.FullNoclip and false or part1.CanCollide
	if part1.Name == "Head" or part1.Name == "Torso" or part1.Name == "UpperTorso" then
		disable_or_no = false
	end
	if not Settings.SingleThread then
		rbxsignals[part0.Name.."STEPPED"] = stepped:Connect(function()
			part0.CanCollide = false
			part0.CanTouch = false
			part0.CanQuery = false
			part1.CanCollide = disable_or_no
		end)
	else
		singlethreading.Collisions[part0.Name] = function()
			part0.CanCollide = false
			part0.CanTouch = false
			part0.CanQuery = false
			part1.CanCollide = disable_or_no
		end
	end
end

local function replicate_part(part, partTo, offset, unsingle)
	local random = math.random
	local target_instance = part:IsA("Accessory") and part.Handle or part
	local targetTo_instance = partTo:IsA("Accessory") and partTo.Handle or partTo
	local cframe_offset, clamp = offset or cf(), math.clamp
	local value, y_vel = Settings.VelocityForce or 10, 30
	local vel_calc = v3_010 * 25.1
	local calculated_Y = 30
	local getvelfrom = part.Name == "HumanoidRootPart" and fakechar:FindFirstChild("HumanoidRootPart") or targetTo_instance
	
	local movement_vel = v3(getvelfrom.Velocity.X/2.5,0,getvelfrom.Velocity.Z/2.5)

	ldelay(0.5, function() -- fix stability on load
		value = Settings.VelocityForce or 10
	end)

	disable_collisions(target_instance, targetTo_instance)
	local delivervel; if not Settings.DisableMovementVelocity then
		delivervel = function()
			return ((movement_vel*value)* get_mass(target_instance)) + v3_010*y_vel
		end
	else
		delivervel = function()
			return v3_010*25.335
		end
	end
	local cframeTo; if target_instance.Name == exclusionpart then
		cframeTo = function(part0, part1)
			if not global_env.bullet_disconnected then
				if (check_ownership(part0)) then
					part0.CFrame = part1.CFrame * cframe_offset * antisleepcf
					part0.RotVelocity = v3()
				end
			end
		end
	else
		cframeTo = function(part0, part1)
			if check_ownership(part0) then
				part0.CFrame = part1.CFrame * cframe_offset * antisleepcf
				part0.RotVelocity = v3()
			end
		end
	end
	if unsingle or (not Settings.SingleThread) then
		rbxsignals[part.Name.."HEARTBEAT"] = heartbeat:Connect(function()
			calculated_Y = tonum("26.".. random(2,6))
			target_instance.AssemblyLinearVelocity = delivervel()
			y_vel = math.clamp(getvelfrom.Velocity.Y*get_mass(target_instance), calculated_Y, 5000)
			movement_vel = v3(getvelfrom.Velocity.X/2.5,0,getvelfrom.Velocity.Z/2.5)
			cframeTo(target_instance, targetTo_instance)
		end)
	else
		singlethreading.Properties[part.Name] = function()
			calculated_Y = tonum("26.".. random(2,6))
			target_instance.AssemblyLinearVelocity = delivervel()
			y_vel = math.clamp(getvelfrom.Velocity.Y*get_mass(target_instance), calculated_Y, 5000)
			movement_vel = v3(getvelfrom.Velocity.X/2.5,0,getvelfrom.Velocity.Z/2.5)
			cframeTo(target_instance, targetTo_instance)
		end
	end
end

local function configure_welds(accessory, model)
	accessory.Parent = model
	local handle = accessory:FindFirstChild("Handle")
	local attachment = handle:FindFirstChildOfClass("Attachment")
	local weld = handle:FindFirstChildOfClass("Weld")

	if not weld then
		weld = Instance.new("Weld")
		weld.Parent = handle
	end
	if attachment then
		weld.C0 = attachment.CFrame
		weld.C1 = model:FindFirstChild(attachment.Name, true).CFrame
		weld.Part1 = model:FindFirstChild(attachment.Name, true).Parent
	else
		local head = model:FindFirstChild("Head") or model:FindFirstChildOfClass("Part")
		weld.C1 = cf(0, head.Size.Y / 2,0) * accessory.AttachmentPoint:Inverse()
		weld.Part1 = head
	end

	weld.Part0 = handle
	handle.CFrame = weld.Part1.CFrame*weld.C1*weld.C0:Inverse()
	handle.Transparency = 1
end

local function break_connectors(list)
	for _, connector in pairs(list) do
		if connector:IsA("BasePart") and connector.Name ~= "Handle" and connector.Name ~= "Head" and connector.Name ~= "Torso" and connector.Name ~= "UpperTorso" then
			connector:BreakJoints()
		elseif connector.Name == "Handle" then
			if Settings.KeepWeldedHair then
				local attachment = connector:FindFirstChildOfClass("Attachment")
				if attachment then
					if not table.find({"FaceCenterAttachment", "HatAttachment", "HairAttachment", "FaceFrontAttachment"}, attachment.Name) then
						connector:BreakJoints()
					end
				end
			elseif not Settings.KeepWeldedHair then
				connector:BreakJoints()
			end
		end
	end
end

local function camera_fix(subject)
	camera.CameraSubject = subject
	renderstepped:Once(function()
		camera.CFrame = cameraCF
	end)
end

-- [[ Start ]] --
prepare_tweaks()
local which_rig; if rigtype == "R6" or (rigtype == "R15" and Settings.R15ToR6) then
	which_rig = "R6"
elseif rigtype == "R15" and (not Settings.R15ToR6) then
	which_rig = "R15"
end

fakechar = create_rig(which_rig)
local fakehum = fakechar:FindFirstChildOfClass("Humanoid")
local fakeroot = fakechar.HumanoidRootPart
local fldr = fakechar.Parent
realhum:ChangeState(16)

fakeroot.CFrame = char.PrimaryPart.CFrame * cf(0,2,0)
fakehum:RemoveAccessories()
global_env.hatlist = Instance.new("Folder")
ldefer(function() -- AntiSleep stuff
	local COS, SIN, time = math.cos, math.sin, 0
	local antisleepforceY = antisleepforce*1.02
	ins(rbxsignals, stepped:Connect(function()
		time = time+1
		antisleepcf = cf(antisleepforce/110 * COS(time/7),antisleepforceY/110 * SIN(time/9),0)
		set_hidden_property(plr, "MaximumSimulationRadius", 1000 * #plrs:GetPlayers())
		set_hidden_property(plr, "SimulationRadius", plr.MaximumSimulationRadius)
	end))
end)

if Settings.HeadMovementMethod then
	local neck = char:FindFirstChild("Neck", true)
	local fakehead = fakechar:FindFirstChild("Head")
	table.insert(rbxsignals, heartbeat:Connect(function()
		neck:SetDesiredAngle(-fakeroot.CFrame:ToObjectSpace(fakehead.CFrame).RightVector.Z)
	end))
end
ldefer(function()
	if rigtype == "R6" or (rigtype == "R15" and (not Settings.R15ToR6)) then
		for _,v in pairs(char_gc) do
			if v:IsA("BasePart") and v.Name ~= "Head" and v.Name ~= "HumanoidRootPart" then
				offsets[v.Name] = {fakechar:FindFirstChild(v.Name)}
			end
		end

	elseif rigtype == "R15" and Settings.R15ToR6 then
		offsets = {
			["UpperTorso"] = {fakechar:FindFirstChild("Torso"), cf(0, 0.194, 0)},
			["LowerTorso"] = {fakechar:FindFirstChild("Torso"), cf(0, -0.79, 0)},
			["RightUpperArm"] = {fakechar:FindFirstChild("Right Arm"), cf(0, 0.4085, 0)},
			["RightLowerArm"] = {fakechar:FindFirstChild("Right Arm"), cf(0, -0.184, 0)},
			["RightHand"] = {fakechar:FindFirstChild("Right Arm"), cf(0, -0.83, 0)},
			["LeftUpperArm"] = {fakechar:FindFirstChild("Left Arm"), cf(0, 0.4085, 0)},
			["LeftLowerArm"] = {fakechar:FindFirstChild("Left Arm"), cf(0, -0.184, 0)},
			["LeftHand"] = {fakechar:FindFirstChild("Left Arm"), cf(0, -0.83, 0)},
			["RightUpperLeg"] = {fakechar:FindFirstChild("Right Leg"), cf(0, 0.575, 0)},
			["RightLowerLeg"] = {fakechar:FindFirstChild("Right Leg"), cf(0, -0.199, 0)},
			["RightFoot"] = {fakechar:FindFirstChild("Right Leg"), cf(0, -0.849, 0)},
			["LeftUpperLeg"] = {fakechar:FindFirstChild("Left Leg"), cf(0, 0.575, 0)},
			["LeftLowerLeg"] = {fakechar:FindFirstChild("Left Leg"), cf(0, -0.199, 0)},
			["LeftFoot"] = {fakechar:FindFirstChild("Left Leg"), cf(0, -0.849, 0)}
		}
	end

	do
		local head = char:FindFirstChild("Head")
		local fakehead = fakechar:FindFirstChild("Head")
		disable_collisions(head, fakehead)
	end


	for _,v in pairs(char_gd) do -- accessories
		if v:IsA("Accessory") then
			local accessory = v:Clone()
			accessory.Parent = fakechar

			configure_welds(accessory, fakechar)
			accessory:Clone().Parent = global_env.hatlist

			if v.Name ~= Settings.FlingHat then
				replicate_part(v, accessory)
				table.insert(rbxsignals, accessory:FindFirstChild("Handle").ChildRemoved:Connect(function(thing)
					if thing:IsA("SpecialMesh") or thing:IsA("Mesh") then
						local oghandle = v:FindFirstChild("Handle")
						if oghandle and oghandle:FindFirstChildOfClass(thing.ClassName) then
							oghandle:FindFirstChildOfClass(thing.ClassName):Destroy()
						end
					end
				end))
			end
		end
	end

	if exclusionpart ~= "" then
		local bullet = char:FindFirstChild(exclusionpart)
		local bullet_hat = char:FindFirstChild(Settings.FlingHat)
		local highlightpart = Instance.new("SelectionBox", bullet)
		highlightpart.Adornee = bullet
		highlightpart.Name = "bulletchecker"
		global_env.bulletpart = bullet
		if bullet_hat then
			local handle = bullet_hat.Handle
			local hatOffset = cf()
			local hatTo;
			if bullet_hat then
				handle:ClearAllChildren()
				hatOffset = cfangle(math.rad(90), 0, 0)
				hatTo = fakechar:FindFirstChild(exclusionpart)
		if bullet_hat and  rigtype == "R15" then 
				handle:BreakJoints()
				hatOffset = Settings.R15ToR6 and cf(0,0.375,0) or cf()
				hatTo = fakechar:FindFirstChild("LeftUpperArm") or fakechar:FindFirstChild(exclusionpart)
			end
			replicate_part(handle, hatTo, hatOffset)
		end
		end
end
	replicate_part(char:FindFirstChild("HumanoidRootPart"),char:FindFirstChild("UpperTorso") or fakechar:FindFirstChild("HumanoidRootPart"), cf(), true)
	break_connectors(char_gd)
	if not Settings.SingleThread then
		for i,v in pairs(offsets) do
			replicate_part(char:FindFirstChild(i), v[1], v[2])
		end
	else
		for i,v in pairs(offsets) do -- get all values n shit
			replicate_part(char:FindFirstChild(i), v[1], v[2])
		end
		ins(rbxsignals, stepped:Connect(function()
			for i,v in pairs(singlethreading.Collisions) do
				v()
			end
		end))

		ins(rbxsignals, heartbeat:Connect(function()
			for i,v in pairs(singlethreading.Properties) do
				v()
			end
		end))
	end

	plr.Character = fakechar
	char.Parent = fakechar
	camera_fix(fakehum)
	
	if Settings.EnableAnims then
		if rigtype == "R6" or (rigtype == "R15" and (not Settings.R15ToR6)) then
			pcall(function() fakechar:FindFirstChild("Animate"):Destroy() end)
			local animate = char:FindFirstChild("Animate"); if animate then
				animate.Parent = fakechar
				animate.Disabled = true
				animate.Disabled = false
			end
			for _,v in pairs(realhum:GetPlayingAnimationTracks()) do
				v:Stop()
			end
		elseif rigtype == "R15" and Settings.R15ToR6 then
			pcall(function() char:FindFirstChild("Animate"):Destroy() end)
			for _,v in pairs(realhum:GetPlayingAnimationTracks()) do
				v:Stop()
			end
			loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Gelatekussy/GelatekReanimate/main/Addons/Animations.lua"))()
		end
	else
		pcall(function() char:FindFirstChild("Animate"):Destroy() end)
		for _,v in pairs(realhum:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	end

	local function reset_event(dontkill)
		if global_env.hatlist then global_env.hatlist:Destroy() end
		for _,v in pairs(global_env.signals) do v:Disconnect() end
		for i,v in pairs(rbxsignals) do v:Disconnect() end
		camera.CameraSubject = realhum
		global_env.stopped = true; ldelay(0.5, function()
			global_env.stopped = false
		end)
		global_env.bulletpart = nil
		pcall(function()
			plr.Character = char
			char.Parent = ws
			if dontkill then
				char:BreakJoints()
			end
		end)
		fldr:Destroy()
		fakechar:Destroy()
	end

	local height = ws.FallenPartsDestroyHeight
	local spawnpoint = ws:FindFirstChildOfClass("SpawnLocation") and ws:FindFirstChildOfClass("SpawnLocation").Position or v3(0,20,0)
	ins(rbxsignals, stepped:Connect(function()
		if fakechar:FindFirstChild("HumanoidRootPart").Position.Y <= height + 150 then
			if not Settings.AntiVoid then
				reset_event(false)
			else
				fakechar:FindFirstChild("HumanoidRootPart").Velocity = v3()
				fakechar:MoveTo(spawnpoint)
			end
		end
	end))

	fakehum.Died:Once(function()
		reset_event(false)
	end)

	ins(rbxsignals, char:GetPropertyChangedSignal("Parent"):Connect(function(parent)
		if parent == nil then
			reset_event(true)
		end
	end))
end)

lspawn(function()
	local main = Instance.new("Frame")
	local gui = Instance.new("ScreenGui"); do
		local Corner = Instance.new("UICorner")
		local Shadow = Instance.new("ImageLabel")
		local TextLabel = Instance.new("TextLabel")
		local TextLabel_2 = Instance.new("TextLabel")
		local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		local TextLabel_3 = Instance.new("TextLabel")
		local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
		local TextButton = Instance.new("TextButton")
		local Corner_2 = Instance.new("UICorner")
		local TextLabel_4 = Instance.new("TextLabel")
		local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
		gui.Name = "Main"
		gui.Parent = game:GetService("CoreGui")
		main.Parent = gui
		main.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		main.Position = UDim2.new(0.738310993, 0, 1.2, 0)
		main.Size = UDim2.new(0.252637774, 0, 0.160366148, 0)
		Corner.CornerRadius = UDim.new(0, 2)
		Corner.Name = "Corner"
		Corner.Parent = main
		Shadow.Name = "Shadow"
		Shadow.Parent = main
		Shadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Shadow.BackgroundTransparency = 1.000
		Shadow.Position = UDim2.new(-0.0422867201, 0, -0.0389609225, 0)
		Shadow.Size = UDim2.new(1.08457363, 0, 1.08441401, 0)
		Shadow.ZIndex = -5
		Shadow.Image = "http://www.roblox.com/asset/?id=6906809185"
		Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Shadow.ImageTransparency = 0.600
		TextLabel.Parent = main
		TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.Position = UDim2.new(0.130384654, 0, 0.0649351403, 0)
		TextLabel.Size = UDim2.new(0.73430407, 0, 0.178190455, 0)
		TextLabel.Font = Enum.Font.Gotham
		TextLabel.Text = "Reanimated! (Version 1.2.252637774)"
		TextLabel.TextColor3 = Color3.fromRGB(243, 243, 243)
		TextLabel.TextScaled = true
		TextLabel.TextSize = 14.000
		TextLabel.TextWrapped = true
		TextLabel_2.Parent = main
		TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel_2.BackgroundTransparency = 1.000
		TextLabel_2.Position = UDim2.new(0.0712678283, 0, 0.449823439, 0)
		TextLabel_2.Size = UDim2.new(0.840714335, 0, 0.187152565, 0)
		TextLabel_2.Font = Enum.Font.Gotham
		TextLabel_2.Text = "Execution Speed: "..tostring(tickk()-speed)
		TextLabel_2.TextColor3 = Color3.fromRGB(134, 134, 134)
		TextLabel_2.TextScaled = true
		TextLabel_2.TextSize = 14.000
		TextLabel_2.TextWrapped = true
		UITextSizeConstraint.Parent = TextLabel_2
		UITextSizeConstraint.MaxTextSize = 25
		TextLabel_3.Parent = main
		TextLabel_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel_3.BackgroundTransparency = 1.000
		TextLabel_3.Position = UDim2.new(0.04762109, 0, 0.280025691, 0)
		TextLabel_3.Size = UDim2.new(0.891948998, 0, 0.178190455, 0)
		TextLabel_3.Font = Enum.Font.Gotham
		TextLabel_3.Text = "Reanimate by: Syntax"
		TextLabel_3.TextColor3 = Color3.fromRGB(243, 243, 243)
		TextLabel_3.TextScaled = true
		TextLabel_3.TextSize = 14.000
		TextLabel_3.TextWrapped = true
		UITextSizeConstraint_2.Parent = TextLabel_3
		UITextSizeConstraint_2.MaxTextSize = 25
		TextButton.Parent = main
		TextButton.BackgroundColor3 = Color3.fromRGB(74, 120, 60)
		TextButton.Position = UDim2.new(0.130057022, 0, 0.72707963, 0)
		TextButton.Size = UDim2.new(0.734630048, 0, 0.188472986, 0)
		TextButton.ZIndex = 2
		TextButton.Font = Enum.Font.Gotham
		TextButton.Text = " "
		TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TextButton.TextScaled = true
		TextButton.TextSize = 14.000
		TextButton.TextWrapped = true
		Corner_2.CornerRadius = UDim.new(0, 2)
		Corner_2.Name = "Corner"
		Corner_2.Parent = TextButton
		TextLabel_4.Parent = TextButton
		TextLabel_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel_4.BackgroundTransparency = 1.000
		TextLabel_4.Position = UDim2.new(0.0712679401, 0, 0.110013887, 0)
		TextLabel_4.Size = UDim2.new(0.870017171, 0, 0.743721008, 0)
		TextLabel_4.ZIndex = 2
		TextLabel_4.Font = Enum.Font.Gotham
		TextLabel_4.Text = "Copy Discord Invite"
		TextLabel_4.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel_4.TextScaled = true
		TextLabel_4.TextSize = 14.000
		TextLabel_4.TextWrapped = true
		UITextSizeConstraint_3.Parent = TextLabel_4
		UITextSizeConstraint_3.MaxTextSize = 25
		TextButton.MouseButton1Down:Once(function()
			setclipboard("https://discord.gg/3Qr97C4BDn")
			TextLabel_4.Text = "Copied to clipboard!"
		end)
	end
	lspawn(function()
		main:TweenPosition(UDim2.new(0.738310993, 0, 0.823268235, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 1)
		task.wait(3)
		main:TweenPosition(UDim2.new(0.738310993, 0, 1.2, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 1)
		task.wait(2)
		main:Destroy()
	end)
end)

if Settings.LoadLibrary then
	lspawn(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/toldblock/Gelatek/main/LoadLibrary.lua"))()
	end)
end

if Settings.Bullet and Settings.BulletOnLoad then lwait(1)
	local random = math.random
	local mouse = plr:GetMouse()
	local hue = Color3.fromHSV(0,0,0)
	local bulletforce = v3(15000,15000,15000)
	local highlight = char:FindFirstChild("bulletchecker", true)
	if not highlight then return end
	local bullet = highlight.Parent
	local attacking,bulletto = false, nil
	bullet.Transparency = 1

	ins(global_env.signals,heartbeat:Connect(function()
		hue = tickk() % 5/5
		if Settings.RainbowFlingPart then
		highlight.Color3 = Color3.fromHSV(hue, 1, 1)
		end
		if bullet.Parent and check_ownership(bullet) then
			if global_env.bulletattacking then
			    global_env.bullet_disconnected = true
				if mouse.Target ~= nil then
					bullet.CFrame = mouse.Hit * antisleepcf * cfangle(random(0,360),random(0,360),random(0,360))
					bullet.RotVelocity = bulletforce
				end
			else
			    global_env.bullet_disconnected = false
			end
		end
	end))
end
lwait(0.15)
