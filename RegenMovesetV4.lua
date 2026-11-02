-- StarterPlayer > StarterPlayerScripts > RegenMovesetV4 (LocalScript)
-- REGENERATION SYSTEM — ULTRA VISUAL & PROCEDURAL ANIMATION OVERHAUL
-- 100% LOCAL | SINGLE LOCALSCRIPT | ZERO SERVER DEPENDENCIES | ZERO NEON / ZERO ARTIFICIAL GLOW

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. CONFIGURAÇÕES BIOMECÂNICAS E PALETA ORGÂNICA (ZERO NEON / ZERO BRILHO)
--------------------------------------------------------------------------------
local CFG = {
	Cooldown = {
		Jump       = 6.5,
		Noclip     = 9.5,
		Grapple    = 4.5,
		HeadThrow  = 7.5,
		ArmControl = 8.5,
		AccelRegen = 11.0,
		ProneRegen = 9.0,
	},
	Jump = {
		UpVelocity    = 178, -- Impulso vertical massivo
		ForwardSpeed  = 44,
		CrawlDuration = 4.6,
		CrawlSpeed    = 19.5,
	},
	Noclip = {
		Duration = 4.0,
		Speed    = 25.5,
	},
	Grapple = {
		Range          = 185,
		PreTensionTime = 0.28,
		PullSpeed      = 112,
	},
	HeadThrow = {
		Speed          = 128,
		UpwardBias     = 17,
		Gravity        = 134,
		MaxFlightTime  = 2.6,
		PostImpactWait = 0.68,
	},
	ArmControl = {
		Duration   = 5.6,
		CrawlSpeed = 20.5,
		HopImpulse = 44.0,
	},
	PassiveRegen = {
		HealPerSecond = 4.5,
		PulseInterval = 1.75,
	},
	MaxDrops = 48,
}

local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local QUALITY = IS_MOBILE and {
	strands      = 3,
	segs         = 7,
	frags        = 3,
	muscleBands  = 4,
	vertebrae    = 5,
	subDrops     = 4,
	puddleLobes  = 5,
	dermalPlates = 4,
} or {
	strands      = 4,
	segs         = 11,
	frags        = 5,
	muscleBands  = 6,
	vertebrae    = 7,
	subDrops     = 6,
	puddleLobes  = 8,
	dermalPlates = 4,
}

-- Paleta estritamente natural e opaca: osso seco, cartilagem, medula, fibras musculares e derme
local COL = {
	Bone         = Color3.fromRGB(226, 216, 198),
	BoneDark     = Color3.fromRGB(186, 173, 154),
	Periosteum   = Color3.fromRGB(206, 192, 176),
	Cartilage    = Color3.fromRGB(198, 185, 172),
	Marrow       = Color3.fromRGB(128, 24, 28),
	MuscleDeep   = Color3.fromRGB(106, 18, 24),
	Muscle       = Color3.fromRGB(146, 32, 38),
	MuscleMid    = Color3.fromRGB(168, 46, 52),
	MuscleFascia = Color3.fromRGB(178, 134, 128),
	Tendon       = Color3.fromRGB(190, 158, 146),
	Nerve        = Color3.fromRGB(210, 188, 158),
	Blood        = Color3.fromRGB(104, 13, 19),
	BloodDark    = Color3.fromRGB(64, 8, 12),
	ViscousCore  = Color3.fromRGB(80, 10, 15),
	Subdermis    = Color3.fromRGB(162, 72, 70),
	Dust         = Color3.fromRGB(136, 128, 118),
}

local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

--------------------------------------------------------------------------------
-- 2. MATEMÁTICA AVANÇADA, CURVAS BIOMECÂNICAS E SOLUCIONADORES DINÂMICOS
--------------------------------------------------------------------------------
local PI  = math.pi
local TAU = PI * 2

local function clamp(x, a, b)
	return x < a and a or (x > b and b or x)
end

local function clamp01(x)
	return x < 0 and 0 or (x > 1 and 1 or x)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function inv(a, b, x)
	if math.abs(b - a) < 1e-6 then return x >= b and 1 or 0 end
	return clamp01((x - a) / (b - a))
end

local function smooth(a, b, x)
	local t = inv(a, b, x)
	return t * t * (3 - 2 * t)
end

local function smoother(a, b, x)
	local t = inv(a, b, x)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function outCubic(x)
	x = clamp01(x)
	return 1 - (1 - x) ^ 3
end

local function inCubic(x)
	x = clamp01(x)
	return x * x * x
end

local function outQuart(x)
	x = clamp01(x)
	return 1 - (1 - x) ^ 4
end

local function outQuint(x)
	x = clamp01(x)
	return 1 - (1 - x) ^ 5
end

local function inOutQuad(x)
	x = clamp01(x)
	return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 * 0.5
end

local function inOutCubic(x)
	x = clamp01(x)
	return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 * 0.5
end

local function outBack(x, k)
	x = clamp01(x)
	k = k or 1.48
	local i = x - 1
	return 1 + (k + 1) * i * i * i + k * i * i
end

local function spring(x, damp, freq)
	x = clamp01(x)
	if x >= 1 then return 1 end
	damp = damp or 5.8
	freq = freq or 12.0
	return 1 - math.exp(-damp * x) * math.cos(freq * x)
end

local function bell(x)
	return math.sin(PI * clamp01(x))
end

local function rand(a, b)
	return a + math.random() * (b - a)
end

local function flat(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 1e-3 and f.Unit or Vector3.new(0, 0, -1)
end

local function safeUnit(v, fallback)
	return v.Magnitude > 1e-4 and v.Unit or (fallback or Vector3.yAxis)
end

-- Oscilador Harmônico Vetorial de 2ª Ordem (Inércia, Peso, Overshoot e Resistência)
local SpringVec3 = {}
SpringVec3.__index = SpringVec3

function SpringVec3.new(init, freq, damp)
	return setmetatable({
		pos    = init or Vector3.zero,
		vel    = Vector3.zero,
		target = init or Vector3.zero,
		freq   = freq or 15.0,
		damp   = damp or 0.76,
	}, SpringVec3)
end

function SpringVec3:Step(dt, newTarget)
	if newTarget then self.target = newTarget end
	local f = self.freq
	local d = self.damp
	local g = self.target
	local x = self.pos
	local v = self.vel
	local acc = (g - x) * (f * f) - v * (2 * d * f)
	self.vel = v + acc * dt
	self.pos = x + self.vel * dt
	return self.pos
end

function SpringVec3:Impulse(velDelta)
	self.vel = self.vel + velDelta
end

function SpringVec3:Reset(val)
	self.pos = val or Vector3.zero
	self.target = self.pos
	self.vel = Vector3.zero
end

--------------------------------------------------------------------------------
-- 3. GERENCIADOR DE MEMÓRIA (MAID) E ESTADO DO SISTEMA
--------------------------------------------------------------------------------
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ list = {} }, Maid)
end

function Maid:Add(item)
	table.insert(self.list, item)
	return item
end

function Maid:Clean()
	for i = #self.list, 1, -1 do
		local x = self.list[i]
		if typeof(x) == "RBXScriptConnection" then
			x:Disconnect()
		elseif typeof(x) == "Instance" then
			pcall(function() x:Destroy() end)
		elseif type(x) == "function" then
			pcall(x)
		end
	end
	table.clear(self.list)
end

local S = {
	gen               = 0,
	busy              = nil,
	cd                = {},
	char              = nil,
	hum               = nil,
	root              = nil,
	r6                = false,
	cancelAim         = false,
	endEarly          = false,
	integrity         = 1.0,
	lastHealth        = 100,
	passivePulseTimer = 0,
}

local function alive(gen)
	return S.gen == gen
		and S.char ~= nil
		and S.char.Parent ~= nil
		and S.hum ~= nil
		and S.hum.Health > 0
		and S.root ~= nil
		and S.root.Parent ~= nil
end

--------------------------------------------------------------------------------
-- 4. DIRETOR DE CÂMERA CINEMATOGRÁFICA (SUAVE, ORGÂNICA E NÃO-INTRUSIVA)
--------------------------------------------------------------------------------
local CamDirector = {
	offsetSpring = SpringVec3.new(Vector3.zero, 13.0, 0.82),
	fovSpring    = SpringVec3.new(Vector3.new(70, 0, 0), 11.0, 0.85),
	rollSpring   = SpringVec3.new(Vector3.zero, 14.0, 0.78),
	shakeTrauma  = 0,
	shakeDecay   = 2.8,
	shakeSeed    = math.random(1, 1000),
	targetOffset = Vector3.zero,
	targetFovAdd = 0,
	targetRoll   = 0,
	baseFov      = 70,
	active       = false,
}

function CamDirector:AddTrauma(amount, decayRate)
	self.shakeTrauma = clamp(self.shakeTrauma + amount, 0, 1.25)
	self.shakeDecay = decayRate or 2.8
end

function CamDirector:SetStage(offsetVec, fovDelta, rollRad, freq)
	self.targetOffset = offsetVec or Vector3.zero
	self.targetFovAdd = fovDelta or 0
	self.targetRoll   = rollRad or 0
	if freq then
		self.offsetSpring.freq = freq
	else
		self.offsetSpring.freq = 13.0
	end
	self.active = true
end

function CamDirector:ClearStage()
	self.targetOffset = Vector3.zero
	self.targetFovAdd = 0
	self.targetRoll   = 0
	self.offsetSpring.freq = 11.0
end

function CamDirector:Step(dt)
	local hum = S.hum
	local cam = Workspace.CurrentCamera
	if not hum or not hum.Parent then return end

	-- Decaimento contínuo de trauma de impacto (Perlin Noise multi-eixo, sem saltos aleatórios brutos)
	local shakeVec = Vector3.zero
	local shakeRoll = 0
	if self.shakeTrauma > 0.001 then
		self.shakeTrauma = math.max(0, self.shakeTrauma - self.shakeDecay * dt)
		local mag = self.shakeTrauma * self.shakeTrauma
		local t = os.clock() * 22.0
		shakeVec = Vector3.new(
			math.noise(t, self.shakeSeed) * mag * 0.85,
			math.noise(t, self.shakeSeed + 31.7) * mag * 0.85,
			math.noise(t, self.shakeSeed + 67.3) * mag * 0.45
		)
		shakeRoll = math.noise(t * 0.8, self.shakeSeed + 99.1) * mag * 0.06
	end

	local curOff = self.offsetSpring:Step(dt, self.targetOffset)
	local curRollVec = self.rollSpring:Step(dt, Vector3.new(self.targetRoll, 0, 0))
	local curFovVec = self.fovSpring:Step(dt, Vector3.new(self.targetFovAdd, 0, 0))

	hum.CameraOffset = curOff + shakeVec

	if cam and cam.CameraType == Enum.CameraType.Custom then
		local desiredFov = clamp(self.baseFov + curFovVec.X, 52, 92)
		if math.abs(cam.FieldOfView - desiredFov) > 0.05 or math.abs(curFovVec.X) > 0.05 then
			cam.FieldOfView = desiredFov
		end
		local totalRoll = curRollVec.X + shakeRoll
		if math.abs(totalRoll) > 0.0008 then
			cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, totalRoll)
		end
	end
end

local function ShakeCamera(hum, intensity, duration)
	local decay = duration and duration > 0.05 and (intensity / duration) * 1.45 or 3.0
	CamDirector:AddTrauma(clamp(intensity * 1.35, 0.08, 1.15), decay)
end

local function Animate(ctx, dur, fn)
	local t0 = os.clock()
	local last = t0
	while true do
		if not alive(ctx.gen) then
			error("CANCEL", 0)
		end
		local now = os.clock()
		local dt = math.min(now - last, 0.05)
		last = now
		local elapsed = now - t0
		local p = dur > 0 and clamp01(elapsed / dur) or 1
		local stop = fn(p, elapsed, dt)
		if stop == true or p >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
end

local function Wait(ctx, sec)
	Animate(ctx, sec, function() end)
end

--------------------------------------------------------------------------------
-- 5. MAPEAMENTO ANATÔMICO E SOLUCIONADOR ARTICULAR DE 2ª ORDEM (R6 E R15)
--------------------------------------------------------------------------------
local GROUPS_R6 = {
	Torso = { "Torso" },
	Head  = { "Head" },
	LArm  = { "Left Arm" },
	RArm  = { "Right Arm" },
	LLeg  = { "Left Leg" },
	RLeg  = { "Right Leg" },
}

local GROUPS_R15 = {
	Torso = { "LowerTorso", "UpperTorso" },
	Head  = { "Head" },
	LArm  = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	RArm  = { "RightUpperArm", "RightLowerArm", "RightHand" },
	LLeg  = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
	RLeg  = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}

local function Group(name)
	if not S.char then return {} end
	local map = S.r6 and GROUPS_R6 or GROUPS_R15
	local list = map[name] or {}
	local out = {}
	for _, partName in ipairs(list) do
		local p = S.char:FindFirstChild(partName)
		if p and p:IsA("BasePart") then
			table.insert(out, p)
		end
	end
	return out
end

local function Concat(...)
	local out = {}
	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			table.insert(out, v)
		end
	end
	return out
end

local function GetUpperTorso()
	if not S.char then return S.root end
	return S.char:FindFirstChild("UpperTorso") or S.char:FindFirstChild("Torso") or S.root
end

local function GetLowerTorso()
	if not S.char then return S.root end
	return S.char:FindFirstChild("LowerTorso") or S.char:FindFirstChild("Torso") or S.root
end

-- Decompõe CFrame rotacional em vetor eixo-ângulo (espaço tangente so(3)) para física de mola angular real
local function CFToAxisAngleVec(cf)
	local axis, angle = cf:ToAxisAngle()
	if angle ~= angle or axis.Magnitude < 1e-5 then
		return Vector3.zero
	end
	return axis.Unit * angle
end

local function AxisAngleVecToCF(v)
	local mag = v.Magnitude
	if mag < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(v / mag, mag)
end

-- Controlador de Pose Procedural com Dinâmica Angular de 2ª Ordem e Compensação Cinemática R6/R15
local function CreatePoseController(ctx)
	local motors = {}
	local origC0 = {}
	local jointSprings = {}
	local r6Virtual = {
		WaistPos = Vector3.zero,
		WaistRot = CFrame.identity,
		LElbow   = 0,
		RElbow   = 0,
		LKnee    = 0,
		RKnee    = 0,
	}

	local function registerAlias(alias, motor, freq, damp)
		if motor and motor:IsA("Motor6D") then
			motors[alias] = motor
			if not origC0[motor] then
				origC0[motor] = motor.C0
			end
			jointSprings[alias] = {
				posSpring = SpringVec3.new(Vector3.zero, freq or 18.0, damp or 0.74),
				rotSpring = SpringVec3.new(Vector3.zero, freq or 18.0, damp or 0.74),
				targetPos = Vector3.zero,
				targetRot = Vector3.zero,
			}
		end
	end

	if S.r6 then
		local root  = S.char:FindFirstChild("HumanoidRootPart")
		local torso = S.char:FindFirstChild("Torso")
		if root then
			registerAlias("Root", root:FindFirstChild("RootJoint"), 16.0, 0.76)
		end
		if torso then
			registerAlias("Neck",      torso:FindFirstChild("Neck"),           20.0, 0.72)
			registerAlias("RShoulder", torso:FindFirstChild("Right Shoulder"), 18.5, 0.72)
			registerAlias("LShoulder", torso:FindFirstChild("Left Shoulder"),  18.5, 0.72)
			registerAlias("RHip",      torso:FindFirstChild("Right Hip"),      17.0, 0.75)
			registerAlias("LHip",      torso:FindFirstChild("Left Hip"),       17.0, 0.75)
		end
	else
		local lt   = S.char:FindFirstChild("LowerTorso")
		local ut   = S.char:FindFirstChild("UpperTorso")
		local head = S.char:FindFirstChild("Head")
		local rua  = S.char:FindFirstChild("RightUpperArm")
		local rla  = S.char:FindFirstChild("RightLowerArm")
		local rh   = S.char:FindFirstChild("RightHand")
		local lua  = S.char:FindFirstChild("LeftUpperArm")
		local lla  = S.char:FindFirstChild("LeftLowerArm")
		local lh   = S.char:FindFirstChild("LeftHand")
		local rul  = S.char:FindFirstChild("RightUpperLeg")
		local rll  = S.char:FindFirstChild("RightLowerLeg")
		local rf   = S.char:FindFirstChild("RightFoot")
		local lul  = S.char:FindFirstChild("LeftUpperLeg")
		local lll  = S.char:FindFirstChild("LeftLowerLeg")
		local lf   = S.char:FindFirstChild("LeftFoot")

		if lt   then registerAlias("Root",      lt:FindFirstChild("Root"),           16.0, 0.78) end
		if ut   then registerAlias("Waist",     ut:FindFirstChild("Waist"),          17.0, 0.75) end
		if head then registerAlias("Neck",      head:FindFirstChild("Neck"),         21.0, 0.70) end
		if rua  then registerAlias("RShoulder", rua:FindFirstChild("RightShoulder"), 19.0, 0.72) end
		if rla  then registerAlias("RElbow",    rla:FindFirstChild("RightElbow"),    22.0, 0.68) end
		if rh   then registerAlias("RWrist",    rh:FindFirstChild("RightWrist"),     24.0, 0.66) end
		if lua  then registerAlias("LShoulder", lua:FindFirstChild("LeftShoulder"),  19.0, 0.72) end
		if lla  then registerAlias("LElbow",    lla:FindFirstChild("LeftElbow"),     22.0, 0.68) end
		if lh   then registerAlias("LWrist",    lh:FindFirstChild("LeftWrist"),      24.0, 0.66) end
		if rul  then registerAlias("RHip",      rul:FindFirstChild("RightHip"),      17.5, 0.75) end
		if rll  then registerAlias("RKnee",     rll:FindFirstChild("RightKnee"),     20.0, 0.72) end
		if rf   then registerAlias("RAnkle",    rf:FindFirstChild("RightAnkle"),     22.0, 0.70) end
		if lul  then registerAlias("LHip",      lul:FindFirstChild("LeftHip"),       17.5, 0.75) end
		if lll  then registerAlias("LKnee",     lll:FindFirstChild("LeftKnee"),      20.0, 0.72) end
		if lf   then registerAlias("LAnkle",    lf:FindFirstChild("LeftAnkle"),      22.0, 0.70) end
	end

	local animateScript = S.char:FindFirstChild("Animate")
	local wasAnimateEnabled = animateScript and animateScript:IsA("LocalScript") and not animateScript.Disabled

	local ctrl = {}

	function ctrl:SuppressDefaultAnimations(suppress)
		if animateScript and animateScript:IsA("LocalScript") then
			animateScript.Disabled = suppress and true or false
		end
		if suppress and S.hum then
			local animator = S.hum:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					pcall(function() track:Stop(0.10) end)
				end
			end
		end
	end

	-- Aplica pose com mola física real (inércia + overshoot) e tradução cinemática inteligente para R6
	local function applyMotorTransform(alias, pOff, rOff, responsiveness)
		local m = motors[alias]
		if not m or not m.Parent then return end
		local base = origC0[m]
		if not base then return end

		local js = jointSprings[alias]
		local finalPos = pOff
		local finalRot = rOff

		if js then
			local dt = 1 / 60
			if responsiveness and responsiveness > 0 then
				js.posSpring.freq = lerp(10.0, 28.0, clamp01(responsiveness))
				js.rotSpring.freq = lerp(10.0, 28.0, clamp01(responsiveness))
			end
			finalPos = js.posSpring:Step(dt, pOff)
			local rotVec = js.rotSpring:Step(dt, CFToAxisAngleVec(rOff))
			finalRot = AxisAngleVecToCF(rotVec)
		end

		if S.r6 then
			-- Em R6, a orientação original dos motores usa eixos rotacionados; aplicamos a rotação no espaço mundo da junta
			if alias == "Root" or alias == "Neck" then
				local rx, ry, rz = finalRot:ToEulerAnglesXYZ()
				m.C0 = CFrame.new(base.Position + finalPos) * base.Rotation * CFrame.Angles(-rx, -rz, -ry)
			elseif alias == "RShoulder" or alias == "RHip" then
				local rx, ry, rz = finalRot:ToEulerAnglesXYZ()
				m.C0 = CFrame.new(base.Position + finalPos) * base.Rotation * CFrame.Angles(-rz, ry, rx)
			elseif alias == "LShoulder" or alias == "LHip" then
				local rx, ry, rz = finalRot:ToEulerAnglesXYZ()
				m.C0 = CFrame.new(base.Position + finalPos) * base.Rotation * CFrame.Angles(rz, ry, -rx)
			else
				m.C0 = CFrame.new(base.Position + finalPos) * finalRot * base.Rotation
			end
		else
			m.C0 = CFrame.new(base.Position + finalPos) * finalRot * base.Rotation
		end
	end

	function ctrl:SetJoint(alias, posOffset, rotCF, alpha, responsiveness)
		alpha = alpha or 1
		local pOff = (posOffset or Vector3.zero) * alpha
		local rOff = CFrame.identity:Lerp(rotCF or CFrame.identity, alpha)

		if S.r6 then
			-- Em R6, simula Waist combinando com Root, e simula Elbows/Knees deslocando e flexionando o membro pai
			if alias == "Waist" then
				r6Virtual.WaistPos = pOff
				r6Virtual.WaistRot = rOff
				applyMotorTransform("Root", pOff * 0.65, rOff, responsiveness)
				return
			elseif alias == "LElbow" or alias == "RElbow" then
				local rx = select(1, rOff:ToEulerAnglesXYZ())
				if alias == "LElbow" then r6Virtual.LElbow = rx else r6Virtual.RElbow = rx end
				return
			elseif alias == "LKnee" or alias == "RKnee" then
				local rx = select(1, rOff:ToEulerAnglesXYZ())
				if alias == "LKnee" then r6Virtual.LKnee = rx else r6Virtual.RKnee = rx end
				return
			elseif alias == "LShoulder" and math.abs(r6Virtual.LElbow) > 0.01 then
				rOff = rOff * CFrame.Angles(r6Virtual.LElbow * 0.42, 0, 0)
				pOff = pOff + Vector3.new(0, 0.12 * math.abs(r6Virtual.LElbow), -0.18 * math.sin(r6Virtual.LElbow))
			elseif alias == "RShoulder" and math.abs(r6Virtual.RElbow) > 0.01 then
				rOff = rOff * CFrame.Angles(r6Virtual.RElbow * 0.42, 0, 0)
				pOff = pOff + Vector3.new(0, 0.12 * math.abs(r6Virtual.RElbow), -0.18 * math.sin(r6Virtual.RElbow))
			elseif alias == "LHip" and math.abs(r6Virtual.LKnee) > 0.01 then
				rOff = rOff * CFrame.Angles(r6Virtual.LKnee * 0.35, 0, 0)
				pOff = pOff + Vector3.new(0, 0.22 * math.abs(r6Virtual.LKnee), -0.20 * math.sin(r6Virtual.LKnee))
			elseif alias == "RHip" and math.abs(r6Virtual.RKnee) > 0.01 then
				rOff = rOff * CFrame.Angles(r6Virtual.RKnee * 0.35, 0, 0)
				pOff = pOff + Vector3.new(0, 0.22 * math.abs(r6Virtual.RKnee), -0.20 * math.sin(r6Virtual.RKnee))
			end
		end

		applyMotorTransform(alias, pOff, rOff, responsiveness)
	end

	function ctrl:ImpulseJoint(alias, rotImpulseVec, posImpulseVec)
		local js = jointSprings[alias]
		if not js and S.r6 and alias == "Waist" then
			js = jointSprings["Root"]
		end
		if js then
			if rotImpulseVec then js.rotSpring:Impulse(rotImpulseVec) end
			if posImpulseVec then js.posSpring:Impulse(posImpulseVec) end
		end
	end

	function ctrl:Reset(blendTime)
		r6Virtual.LElbow, r6Virtual.RElbow, r6Virtual.LKnee, r6Virtual.RKnee = 0, 0, 0, 0
		if not blendTime or blendTime <= 0 then
			for m, c0 in pairs(origC0) do
				if m and m.Parent then
					m.C0 = c0
				end
			end
			for _, js in pairs(jointSprings) do
				js.posSpring:Reset(Vector3.zero)
				js.rotSpring:Reset(Vector3.zero)
			end
			return
		end
		local snapshot = {}
		for m, _ in pairs(origC0) do
			if m and m.Parent then
				snapshot[m] = m.C0
			end
		end
		local t0 = os.clock()
		while os.clock() - t0 < blendTime and alive(ctx.gen) do
			local a = smoother(0, 1, (os.clock() - t0) / blendTime)
			for m, startCF in pairs(snapshot) do
				if m and m.Parent and origC0[m] then
					m.C0 = startCF:Lerp(origC0[m], a)
				end
			end
			RunService.RenderStepped:Wait()
		end
		for m, c0 in pairs(origC0) do
			if m and m.Parent then
				m.C0 = c0
			end
		end
		for _, js in pairs(jointSprings) do
			js.posSpring:Reset(Vector3.zero)
			js.rotSpring:Reset(Vector3.zero)
		end
	end

	ctx.maid:Add(function()
		for m, c0 in pairs(origC0) do
			if m and m.Parent then
				m.C0 = c0
			end
		end
		if wasAnimateEnabled and animateScript and animateScript.Parent then
			animateScript.Disabled = false
		end
	end)

	return ctrl
end

-- Captura e controla visibilidade de partes e acessórios acoplados
local function CaptureVisibility(parts, includeAccessories)
	local orig = {}
	local partSet = {}

	local function record(inst)
		if inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture") then
			if orig[inst] == nil then
				orig[inst] = inst.Transparency
			end
		end
	end

	local function recordTree(rootInst)
		record(rootInst)
		for _, d in ipairs(rootInst:GetDescendants()) do
			record(d)
		end
	end

	for _, p in ipairs(parts) do
		partSet[p] = true
		recordTree(p)
	end

	if includeAccessories and S.char then
		for _, acc in ipairs(S.char:GetChildren()) do
			if acc:IsA("Accessory") then
				local handle = acc:FindFirstChild("Handle")
				if handle then
					local matched = (includeAccessories == true)
					if not matched then
						local weld = handle:FindFirstChildWhichIsA("JointInstance")
						local attachedTo = weld and (weld.Part0 == handle and weld.Part1 or weld.Part0)
						if attachedTo and partSet[attachedTo] then
							matched = true
						end
						if not matched and partSet[S.char:FindFirstChild("Head")] then
							local att = handle:FindFirstChildOfClass("Attachment")
							if att and (att.Name:find("Hat") or att.Name:find("Hair") or att.Name:find("Face") or att.Name:find("Head")) then
								matched = true
							end
						end
					end
					if matched then
						recordTree(handle)
					end
				end
			end
		end
	end

	return orig
end

local function SetVisibility(orig, hiddenFraction, filterFn)
	hiddenFraction = clamp01(hiddenFraction)
	for inst, baseTrans in pairs(orig) do
		if inst and inst.Parent and (not filterFn or filterFn(inst)) then
			local target = baseTrans + (1 - baseTrans) * hiddenFraction
			if math.abs(inst.Transparency - target) > 0.002 then
				inst.Transparency = target
			end
		end
	end
end

--------------------------------------------------------------------------------
-- 6. FÍSICA E EFEITOS NATURAIS (ZERO NEON / ZERO BRILHO ARTIFICIAL)
--------------------------------------------------------------------------------
local function NewCtx(gen)
	local ctx = {
		gen   = gen,
		maid  = Maid.new(),
		drops = 0,
	}

	ctx.maid:Add(function()
		CamDirector:ClearStage()
	end)

	local folder = Instance.new("Folder")
	folder.Name = "RegenV4_LocalFX"
	folder.Parent = Workspace
	ctx.folder = ctx.maid:Add(folder)

	local carrier = Instance.new("Part")
	carrier.Name = "ParticleCarrier"
	carrier.Anchored = true
	carrier.CanCollide = false
	carrier.CanQuery = false
	carrier.CanTouch = false
	carrier.CastShadow = false
	carrier.Transparency = 1
	carrier.Size = Vector3.new(0.2, 0.2, 0.2)
	carrier.Parent = folder
	ctx.carrier = carrier

	-- Poeira física discreta (100% iluminação ambiente natural, zero emissão própria)
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = TEX_SMOKE
	dust.Color = ColorSequence.new(COL.Dust)
	dust.LightEmission = 0
	dust.LightInfluence = 1
	dust.Rate = 0
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.38),
		NumberSequenceKeypoint.new(0.4, 1.25),
		NumberSequenceKeypoint.new(1, 2.15),
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.50),
		NumberSequenceKeypoint.new(0.6, 0.80),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Lifetime = NumberRange.new(0.48, 0.95)
	dust.Speed = NumberRange.new(2.0, 5.8)
	dust.Drag = 4.6
	dust.SpreadAngle = Vector2.new(80, 18)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-35, 35)
	dust.Parent = carrier
	ctx.dust = dust

	-- Micro-partículas orgânicas opacas (zero brilho)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = TEX_SMOKE
	mist.Color = ColorSequence.new(COL.MuscleDeep, COL.BloodDark)
	mist.LightEmission = 0
	mist.LightInfluence = 1
	mist.Rate = 0
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.7, 0.30),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.42),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Lifetime = NumberRange.new(0.18, 0.38)
	mist.Speed = NumberRange.new(1.8, 4.8)
	mist.Drag = 6.2
	mist.SpreadAngle = Vector2.new(180, 180)
	mist.Rotation = NumberRange.new(0, 360)
	mist.Parent = carrier
	ctx.mist = mist

	return ctx
end

local function FXPart(ctx, color, material, shape, castShadow)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = (castShadow == true)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color or COL.Muscle
	p.Transparency = 1
	p.Size = Vector3.new(0.05, 0.05, 0.05)
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = ctx.folder
	return p
end

local function FXWedge(ctx, color, material)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color or COL.Muscle
	p.Transparency = 1
	p.Size = Vector3.new(0.05, 0.05, 0.05)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = ctx.folder
	return p
end

local function Put(p, cf, size, trans, color)
	if not p or not p.Parent then return end
	if trans >= 0.995 then
		p.Transparency = 1
		return
	end
	p.Transparency = clamp01(trans)
	p.Size = Vector3.new(
		math.max(size.X, 0.02),
		math.max(size.Y, 0.02),
		math.max(size.Z, 0.02)
	)
	p.CFrame = cf
	if color then
		p.Color = color
	end
end

local function EmitDust(ctx, pos, count, groundColor)
	if not ctx.carrier or not ctx.carrier.Parent then return end
	if groundColor then
		ctx.dust.Color = ColorSequence.new(groundColor:Lerp(COL.Dust, 0.55))
	else
		ctx.dust.Color = ColorSequence.new(COL.Dust)
	end
	ctx.carrier.CFrame = CFrame.new(pos)
	ctx.dust:Emit(IS_MOBILE and math.ceil(count * 0.6) or count)
end

local function EmitTissueMist(ctx, pos, count)
	if not ctx.carrier or not ctx.carrier.Parent then return end
	ctx.carrier.CFrame = CFrame.new(pos)
	ctx.mist:Emit(IS_MOBILE and math.ceil(count * 0.6) or count)
end

local function SpawnPhysicalDrop(ctx, pos, vel, radius, mat, col)
	if ctx.drops >= CFG.MaxDrops then return end
	ctx.drops += 1
	local d = Instance.new("Part")
	d.Shape = Enum.PartType.Ball
	local sz = radius or rand(0.09, 0.20)
	d.Size = Vector3.new(sz, sz, sz)
	d.Color = col or (math.random() < 0.55 and COL.Blood or COL.MuscleDeep)
	d.Material = mat or Enum.Material.SmoothPlastic
	d.CanCollide = true
	d.CanQuery = false
	d.CanTouch = false
	d.CastShadow = false
	d.Massless = true
	d.CFrame = CFrame.new(pos)
	d.Parent = ctx.folder
	d.AssemblyLinearVelocity = vel or Vector3.new(rand(-5, 5), rand(2, 8), rand(-5, 5))
	TweenService:Create(d, TweenInfo.new(0.90, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(0.03, 0.03, 0.03),
		Transparency = 1,
	}):Play()
	Debris:AddItem(d, 0.95)
	task.delay(0.95, function()
		ctx.drops = math.max(0, ctx.drops - 1)
	end)
end

local function RayParams(ctx, extraIgnore)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local list = { S.char, ctx.folder }
	if extraIgnore then
		for _, item in ipairs(extraIgnore) do
			table.insert(list, item)
		end
	end
	rp.FilterDescendantsInstances = list
	return rp
end

local function GroundBelow(ctx, pos, maxDepth)
	local r = Workspace:Raycast(pos + Vector3.new(0, 2.3, 0), Vector3.new(0, -(maxDepth or 85), 0), RayParams(ctx))
	if r then
		return r.Position, r.Normal, r.Material, r.Instance and r.Instance.Color or COL.Dust
	end
	return pos - Vector3.new(0, 3.0, 0), Vector3.yAxis, Enum.Material.Concrete, COL.Dust
end

--------------------------------------------------------------------------------
-- 7. SISTEMA DE TENDÕES, ARTÉRIAS E FIBRAS NERVOSAS COM CATENÁRIA E TORÇÃO
--------------------------------------------------------------------------------
local function NewTendonBundle(ctx, customCount, includeNerves)
	local B = { strands = {}, nodes = {} }
	local nStrands = customCount or QUALITY.strands
	for k = 1, nStrands do
		local isNerve  = includeNerves and (k == nStrands)
		local isTendon = (not isNerve) and (k == nStrands or k % 3 == 0)
		local segs = {}
		local knots = {}
		local col = isNerve and COL.Nerve
			or (isTendon and COL.Tendon or (k % 2 == 0 and COL.Muscle or COL.MuscleDeep))
		local mat = (isTendon or isNerve) and Enum.Material.Granite or Enum.Material.SmoothPlastic
		for i = 1, QUALITY.segs do
			segs[i] = FXPart(ctx, col, mat)
			if i % 3 == 0 then
				knots[i] = FXPart(ctx, COL.MuscleFascia, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			end
		end
		B.strands[k] = {
			segs         = segs,
			knots        = knots,
			isTendon     = isTendon,
			isNerve      = isNerve,
			phase        = k * (TAU / nStrands),
			radialOffset = (k - (nStrands + 1) * 0.5) * 0.115,
		}
	end
	return B
end

-- Desenha feixes fibrosos entrelaçados com ondas de tensão transversal e nós fasciais
local function DrawTendonBundle(B, pointA, pointB, sag, waveAmp, thickness, trans, tensionFactor)
	local diff = pointB - pointA
	local dist = diff.Magnitude
	if dist < 0.04 or trans >= 0.99 then
		for _, s in ipairs(B.strands) do
			for _, seg in ipairs(s.segs) do
				seg.Transparency = 1
			end
			for _, kn in pairs(s.knots) do
				kn.Transparency = 1
			end
		end
		return {}
	end

	tensionFactor = clamp01(tensionFactor or 0)
	local dir = diff / dist
	local right = dir:Cross(Vector3.yAxis)
	right = right.Magnitude > 1e-3 and right.Unit or Vector3.xAxis
	local up = right:Cross(dir).Unit
	local clock = os.clock()
	local samplePts = {}

	-- Sob alta tensão: catenária zera, feixes se contraem em espiral cerrada e vibram em alta frequência
	local vibFreq = lerp(7.5, 32.0, tensionFactor)
	local effectiveSag = sag * (1 - 0.92 * tensionFactor)
	local radialTighten = 1 - 0.68 * tensionFactor
	local pulseTravel = (clock * 3.8) % 1.0

	for _, s in ipairs(B.strands) do
		local n = #s.segs
		local prev = pointA
		for i = 1, n do
			local f = i / n
			local env = bell(f)
			local twistTurns = lerp(2.2, 5.0, tensionFactor)
			local helixAngle = f * PI * twistTurns + s.phase + clock * lerp(1.5, 6.0, tensionFactor)

			local w1 = math.sin(helixAngle + clock * vibFreq) * waveAmp * env
			local w2 = math.cos(helixAngle + clock * (vibFreq * 0.84)) * waveAmp * 0.78 * env
			local rad = s.radialOffset * radialTighten * env

			-- Catenária parabólica real + torção helicoidal
			local catenary = 4 * f * (1 - f) * effectiveSag
			local pt = pointA
				+ diff * f
				- Vector3.new(0, catenary, 0)
				+ right * (w1 + math.cos(helixAngle) * rad)
				+ up * (w2 + math.sin(helixAngle) * rad)

			local mid = (prev + pt) * 0.5
			local segLen = (pt - prev).Magnitude
			local baseTh = s.isNerve and (thickness * 0.46)
				or (s.isTendon and (thickness * 0.72) or thickness)

			-- Onda peristáltica viajando ao longo do feixe
			local peristalsis = 1 + 0.28 * math.exp(-((f - pulseTravel) ^ 2) / 0.025) * (1 - tensionFactor * 0.5)
			local th = baseTh * (1 - 0.22 * env) * (1 - 0.16 * tensionFactor) * peristalsis

			Put(s.segs[i], CFrame.lookAt(mid, pt), Vector3.new(th, th, segLen + th * 0.48), trans)

			local kn = s.knots[i]
			if kn then
				local knSize = th * 1.45
				Put(kn, CFrame.new(pt), Vector3.new(knSize, knSize, knSize), trans)
			end

			samplePts[i] = pt
			prev = pt
		end
	end
	return samplePts
end

--------------------------------------------------------------------------------
-- 8. MOTOR DE RECONSTRUÇÃO CORPORAL DE 10 ESTÁGIOS (ZERO TRANSPARENCY POPPING)
--------------------------------------------------------------------------------
--[[
	ARQUITETURA DE RECONSTRUÇÃO VISUALMENTE CONTÍNUA (10 CAMADAS GEOMÉTRICAS REAIS):
	1. Anel Vascular & Colar Proximal (brota diretamente da junta pai — nenhuma peça nasce flutuando)
	2. Medula Óssea Exposta (frente de calcificação vermelha/escura avançando na ponta do osso)
	3. Diáfises Ósseas Duplas/Segmentadas (vértebras, costelas, rádio/ulna, tíbia/fíbula, crânio + mandíbula)
	4. Epífises Condilares & Cápsulas de Cartilagem Articular (encaixe mecânico nas extremidades)
	5. Ligamentos Cruzados & Feixes Nervosos Internos (conectam epífises com tensão elástica)
	6. Feixes Musculares Profundos (envolvem o esqueleto com orientação oblíqua/penada)
	7. Ventres Musculares Superficiais & Fáscia (contraem com ondas peristálticas e espasmos)
	8. Matriz Subdérmica (preenche o volume anatômico com pulsação vascular)
	9. Placas Epidérmicas Multi-Facetadas (4 placas externas que crescem da raiz e se fecham como um zíper)
	10. Travamento Articular Mecânico (a peça real só aparece em 100% de opacidade quando as 4 placas dérmicas já fecharam 100% da superfície — ZERO fade de transparência!)
]]
local function BuildAnatomicalRigForPart(ctx, part, anatomyType)
	local rig = {
		part         = part,
		anatomyType  = anatomyType,
		collar       = nil,
		marrowTip    = nil,
		bones        = {},
		joints       = {},
		ligaments    = {},
		deepMuscles  = {},
		superMuscles = {},
		tendons      = {},
		subdermis    = nil,
		dermalPlates = {},
	}

	-- 1. Colar vascular proximal + Ponta de calcificação medular
	rig.collar    = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	rig.marrowTip = FXPart(ctx, COL.Marrow, Enum.Material.Slate, Enum.PartType.Ball)

	-- 2. Esqueleto Anatômico Específico por Membro
	if anatomyType == "Torso" then
		local vCount = QUALITY.vertebrae
		for i = 1, vCount do
			table.insert(rig.bones, FXPart(ctx, i % 2 == 0 and COL.Bone or COL.BoneDark, Enum.Material.Slate))
		end
		-- Costelas arqueadas (pares esquerdo/direito + esterno central + clavículas)
		for i = 1, 6 do
			table.insert(rig.joints, FXPart(ctx, i <= 4 and COL.Bone or COL.Cartilage, Enum.Material.Slate))
		end
	elseif anatomyType == "Head" then
		table.insert(rig.bones, FXPart(ctx, COL.BoneDark, Enum.Material.Slate))   -- Coluna cervical C1-C7
		table.insert(rig.bones, FXPart(ctx, COL.Bone, Enum.Material.Slate))       -- Abóbada craniana
		table.insert(rig.bones, FXPart(ctx, COL.Periosteum, Enum.Material.Slate)) -- Osso frontal / zigomático
		table.insert(rig.bones, FXPart(ctx, COL.BoneDark, Enum.Material.Slate))   -- Mandíbula articulada
		table.insert(rig.joints, FXPart(ctx, COL.Cartilage, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder))
	else
		-- Membros (Braços/Pernas): Diáfise principal + osso paralelo + côndilos proximal/distal + patela/olécrano
		table.insert(rig.bones, FXPart(ctx, COL.Bone, Enum.Material.Slate))
		table.insert(rig.bones, FXPart(ctx, COL.BoneDark, Enum.Material.Slate))
		table.insert(rig.joints, FXPart(ctx, COL.Cartilage, Enum.Material.Slate))
		table.insert(rig.joints, FXPart(ctx, COL.Cartilage, Enum.Material.Slate))
		table.insert(rig.joints, FXPart(ctx, COL.Periosteum, Enum.Material.Slate, Enum.PartType.Ball))
	end

	-- 3. Ligamentos cruzados e feixes nervosos
	for i = 1, 3 do
		local col = (i == 3) and COL.Nerve or COL.Tendon
		table.insert(rig.ligaments, FXPart(ctx, col, Enum.Material.Granite))
	end

	-- 4. Feixes Musculares Profundos (oblíquos/espiralados ao redor do osso) e Superficiais (quadrantes anatômicos)
	local quadDirs = {
		Vector3.new( 0, 0, -1), -- Anterior (Bíceps / Quadríceps / Peitoral)
		Vector3.new( 0, 0,  1), -- Posterior (Tríceps / Isquiotibiais / Dorsal)
		Vector3.new(-1, 0,  0), -- Lateral Esquerdo
		Vector3.new( 1, 0,  0), -- Lateral Direito
	}
	for i = 1, 4 do
		table.insert(rig.deepMuscles, {
			part  = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic),
			dir   = quadDirs[i],
			tilt  = (i % 2 == 0 and 1 or -1) * 0.22,
			phase = i * 1.15,
		})
	end

	local mCount = QUALITY.muscleBands
	for i = 1, mCount do
		local col = (i % 2 == 1) and COL.Muscle or COL.MuscleMid
		table.insert(rig.superMuscles, {
			part    = FXPart(ctx, col, Enum.Material.SmoothPlastic),
			dir     = quadDirs[((i - 1) % #quadDirs) + 1],
			tier    = (i <= 4) and 1 or 2,
			phase   = i * 1.57,
			baseCol = col,
		})
	end

	-- 5. Tendões de inserção proximal e distal
	for i = 1, 2 do
		table.insert(rig.tendons, FXPart(ctx, COL.Tendon, Enum.Material.Granite))
	end

	-- 6. Matriz Subdérmica + 4 Placas Epidérmicas que envolvem e selam a superfície sem transparência
	rig.subdermis = FXPart(ctx, COL.Subdermis, Enum.Material.SmoothPlastic)
	for i = 1, QUALITY.dermalPlates do
		table.insert(rig.dermalPlates, {
			part = FXPart(ctx, part.Color, part.Material),
			dir  = quadDirs[i],
		})
	end

	return rig
end

local function DestroyAnatomicalRig(rig)
	if rig.collar then rig.collar:Destroy() end
	if rig.marrowTip then rig.marrowTip:Destroy() end
	for _, p in ipairs(rig.bones) do p:Destroy() end
	for _, p in ipairs(rig.joints) do p:Destroy() end
	for _, p in ipairs(rig.ligaments) do p:Destroy() end
	for _, m in ipairs(rig.deepMuscles) do m.part:Destroy() end
	for _, m in ipairs(rig.superMuscles) do m.part:Destroy() end
	for _, t in ipairs(rig.tendons) do t:Destroy() end
	if rig.subdermis then rig.subdermis:Destroy() end
	for _, dp in ipairs(rig.dermalPlates) do dp.part:Destroy() end
end

local function HideAllRigParts(rig)
	if rig.collar then rig.collar.Transparency = 1 end
	if rig.marrowTip then rig.marrowTip.Transparency = 1 end
	for _, p in ipairs(rig.bones) do p.Transparency = 1 end
	for _, p in ipairs(rig.joints) do p.Transparency = 1 end
	for _, p in ipairs(rig.ligaments) do p.Transparency = 1 end
	for _, m in ipairs(rig.deepMuscles) do m.part.Transparency = 1 end
	for _, m in ipairs(rig.superMuscles) do m.part.Transparency = 1 end
	for _, t in ipairs(rig.tendons) do t.Transparency = 1 end
	if rig.subdermis then rig.subdermis.Transparency = 1 end
	for _, dp in ipairs(rig.dermalPlates) do dp.part.Transparency = 1 end
end

local function UpdateAnatomicalRig(ctx, rig, g, origTrans, seed)
	local part = rig.part
	if g <= 0 or not part or not part.Parent then
		HideAllRigParts(rig)
		if part and part.Parent and g <= 0 then
			part.Transparency = 1
		end
		return
	end

	-- Se já concluiu 100% da reconstrução e travamento, exibe apenas a peça real e recolhe o rig interno
	if g >= 0.985 then
		HideAllRigParts(rig)
		part.Transparency = origTrans
		return
	end

	-- Enquanto o membro está sendo reconstruído (0 < g < 0.985), a peça original fica 100% oculta;
	-- toda a geometria visível vem exclusivamente das 10 camadas físicas em construção (ZERO fade de transparência!)
	part.Transparency = 1

	local clock  = os.clock()
	local sz     = part.Size
	local baseCF = part.CFrame
	local aType  = rig.anatomyType

	-- Direção de crescimento biológico: Torso e Head brotam de baixo para cima (+Y); Membros brotam da raiz para a ponta (-Y)
	local growsUp  = (aType == "Torso" or aType == "Head")
	local anchorY  = growsUp and (-sz.Y * 0.5) or (sz.Y * 0.5)
	local growSign = growsUp and 1 or -1

	-- Curvas de progressão das 10 fases sobrepostas
	local collarProg    = smoother(0.00, 0.18, g)
	local boneProg      = outCubic(inv(0.02, 0.44, g))
	local cartilageProg = smoother(0.12, 0.52, g)
	local ligProg       = smoother(0.18, 0.58, g)
	local deepMusProg   = outCubic(inv(0.22, 0.66, g))
	local superMusProg  = outCubic(inv(0.34, 0.78, g))
	local swellProg     = inv(0.46, 0.88, g)
	local subdermProg   = smoother(0.56, 0.88, g)
	local dermalZipProg = smoother(0.64, 0.95, g)
	local dermalSeal    = smoother(0.76, 0.97, g)
	local finalLock     = smoother(0.90, 0.985, g)

	-- Encolhimento radial das estruturas internas apenas depois que as placas dérmicas já as cobriram por fora
	local internalRetract = 1 - 0.18 * smooth(0.86, 0.98, g)

	-- Movimentos secundários involuntários: espasmos neuromusculares, tremores de tensão e encaixe articular mecânico
	local spasmEnv   = bell(clamp01(g * 1.12)) * (1 - finalLock)
	local microSpasm = math.sin(clock * 24.0 + seed * 3.1) * 0.018 * bell(inv(0.35, 0.82, g))
	local noisePitch = math.noise(clock * 5.2, seed) * 0.065 * spasmEnv + microSpasm
	local noiseRoll  = math.noise(clock * 5.2, seed + 23.7) * 0.065 * spasmEnv
	local noiseYaw   = math.noise(clock * 4.0, seed + 51.2) * 0.045 * spasmEnv

	-- Impulso físico de encaixe articular ("snap-lock") em g = 0.88..0.96
	local snapWave = math.sin(inv(0.84, 0.96, g) * PI * 2) * math.exp(-3.5 * inv(0.84, 0.96, g)) * 0.055

	-- Emergência progressiva a partir da articulação pai (impede que peças pareçam surgir soltas no ar)
	local rootEmerge = (1 - outQuart(inv(0.0, 0.36, g))) * (sz.Y * 0.18) * (-growSign)
	local workCF = baseCF
		* CFrame.new(0, rootEmerge + snapWave * growSign, 0)
		* CFrame.Angles(noisePitch, noiseYaw, noiseRoll)

	-- 1. COLAR VASCULAR PROXIMAL & FRENTE DE CALCIFICAÇÃO MEDULAR
	if rig.collar then
		local cScale = spring(collarProg, 5.2, 11.0) * (1 - 0.12 * dermalSeal)
		local cCF = workCF * CFrame.new(0, anchorY + growSign * 0.045, 0) * CFrame.Angles(0, 0, PI * 0.5)
		Put(rig.collar, cCF, Vector3.new(0.12, sz.X * 0.78 * cScale, sz.Z * 0.78 * cScale), 0)
	end

	if rig.marrowTip then
		if boneProg > 0.01 and boneProg < 0.98 then
			local tipY = anchorY + growSign * (sz.Y * boneProg)
			local mScale = bell(boneProg) * 0.42
			Put(rig.marrowTip, workCF * CFrame.new(0, tipY, 0), Vector3.new(sz.X * mScale, sz.X * mScale, sz.Z * mScale), 0)
		else
			rig.marrowTip.Transparency = 1
		end
	end

	-- 2. ESTRUTURA ÓSSEA E CARTILAGINOSA DETALHADA (100% OPACA — CRESCIMENTO GEOMÉTRICO REAL)
	if aType == "Torso" then
		local vCount = #rig.bones
		for i, vPart in ipairs(rig.bones) do
			local vStart = (i - 1) / vCount * 0.34
			local vp = spring(inv(vStart, vStart + 0.24, g), 5.8, 10.5)
			if vp > 0.01 then
				local fracY = (i - 0.5) / vCount
				local yPos = -sz.Y * 0.5 + sz.Y * fracY * boneProg
				local spineCurveZ = math.sin(fracY * PI) * 0.075 * sz.Z
				local vSize = Vector3.new(
					sz.X * 0.26 * vp * internalRetract,
					(sz.Y / vCount) * 0.88 * vp,
					sz.Z * 0.36 * vp * internalRetract
				)
				Put(vPart, workCF * CFrame.new(0, yPos, sz.Z * 0.09 + spineCurveZ), vSize, 0)
			else
				vPart.Transparency = 1
			end
		end

		-- Costelas se expandindo lateralmente a partir da coluna + esterno fechando à frente
		for i, rib in ipairs(rig.joints) do
			local rp = spring(inv(0.08 + i * 0.045, 0.48 + i * 0.035, g), 5.4, 11.0)
			if rp > 0.01 then
				if i <= 4 then
					local yPos = (-0.26 + (i - 1) * 0.19) * sz.Y
					local ribW = sz.X * (0.64 + 0.09 * (4 - i)) * rp * internalRetract
					local ribD = sz.Z * 0.76 * rp * internalRetract
					local breatheRib = 1 + 0.035 * math.sin(clock * 10 + i) * (1 - finalLock)
					Put(rib, workCF * CFrame.new(0, yPos, 0), Vector3.new(ribW * breatheRib, sz.Y * 0.115, ribD), 0)
				elseif i == 5 then
					-- Esterno anterior
					Put(rib, workCF * CFrame.new(0, 0.05 * sz.Y, -sz.Z * 0.34 * internalRetract),
						Vector3.new(sz.X * 0.22 * rp, sz.Y * 0.62 * rp, sz.Z * 0.12), 0)
				else
					-- Cintura escapular / clavículas
					Put(rib, workCF * CFrame.new(0, sz.Y * 0.38 * rp, -sz.Z * 0.05),
						Vector3.new(sz.X * 0.88 * rp * internalRetract, sz.Y * 0.10, sz.Z * 0.28 * rp), 0)
				end
			else
				rib.Transparency = 1
			end
		end

	elseif aType == "Head" then
		local cerv     = rig.bones[1]
		local skull    = rig.bones[2]
		local frontal  = rig.bones[3]
		local jaw      = rig.bones[4]
		local neckRing = rig.joints[1]

		-- Eixo cervical subindo vértebra por vértebra
		local cLen = sz.Y * 0.62 * boneProg
		if cLen > 0.02 then
			Put(cerv, workCF * CFrame.new(0, -sz.Y * 0.5 + cLen * 0.5, 0.06),
				Vector3.new(sz.X * 0.30 * internalRetract, cLen, sz.Z * 0.30 * internalRetract), 0)
		end

		-- Abóbada craniana e bloco zigomático/frontal se expandindo
		local skScale = spring(inv(0.10, 0.50, g), 5.5, 11.0) * internalRetract
		if skScale > 0.02 then
			Put(skull, workCF * CFrame.new(0, sz.Y * 0.12 * skScale, 0.02),
				Vector3.new(sz.X * 0.76 * skScale, sz.Y * 0.64 * skScale, sz.Z * 0.78 * skScale), 0)
		end

		local frScale = spring(inv(0.16, 0.54, g), 5.5, 11.0) * internalRetract
		if frScale > 0.02 then
			Put(frontal, workCF * CFrame.new(0, sz.Y * 0.04, -sz.Z * 0.14 * frScale),
				Vector3.new(sz.X * 0.68 * frScale, sz.Y * 0.44 * frScale, sz.Z * 0.54 * frScale), 0)
		end

		-- Mandíbula articulada: nasce aberta com espasmos e trava fechando contra o maxilar
		local jawGrow  = smoother(0.16, 0.52, g) * internalRetract
		local jawClose = outBack(inv(0.40, 0.78, g), 1.35)
		local jawTremor = math.sin(clock * 28 + seed) * 0.08 * (1 - clamp01(jawClose))
		local jawAngle = lerp(0.62, 0, clamp01(jawClose)) + jawTremor
		if jawGrow > 0.02 then
			local jawCF = workCF * CFrame.new(0, -sz.Y * 0.22, -sz.Z * 0.06) * CFrame.Angles(jawAngle, 0, 0)
			Put(jaw, jawCF, Vector3.new(sz.X * 0.62 * jawGrow, sz.Y * 0.28 * jawGrow, sz.Z * 0.66 * jawGrow), 0)
		end

		if neckRing and cartilageProg > 0.02 then
			Put(neckRing, workCF * CFrame.new(0, -sz.Y * 0.46, 0) * CFrame.Angles(0, 0, PI * 0.5),
				Vector3.new(0.10, sz.X * 0.62 * cartilageProg * internalRetract, sz.Z * 0.62 * cartilageProg * internalRetract), 0)
		end

	else
		-- Braços e Pernas: Hastes ósseas duplas (ex: rádio/ulna ou tíbia/fíbula) + côndilos articulares
		local bLen = sz.Y * boneProg
		local centerOffset = anchorY + growSign * (bLen * 0.5)
		local b1 = rig.bones[1]
		local b2 = rig.bones[2]
		if b1 and bLen > 0.02 then
			Put(b1, workCF * CFrame.new(-sz.X * 0.115 * internalRetract, centerOffset, 0),
				Vector3.new(sz.X * 0.25 * internalRetract, bLen, sz.Z * 0.29 * internalRetract), 0)
		end
		if b2 then
			local b2Prog = outCubic(inv(0.06, 0.48, g))
			local b2Len = sz.Y * b2Prog
			if b2Len > 0.02 then
				local center2 = anchorY + growSign * (b2Len * 0.5)
				Put(b2, workCF * CFrame.new(sz.X * 0.125 * internalRetract, center2, sz.Z * 0.04),
					Vector3.new(sz.X * 0.19 * internalRetract, b2Len, sz.Z * 0.23 * internalRetract), 0)
			else
				b2.Transparency = 1
			end
		end

		local jProx   = rig.joints[1]
		local jDist   = rig.joints[2]
		local patella = rig.joints[3]
		if jProx and cartilageProg > 0.02 then
			local jp = spring(cartilageProg, 5.5, 11.0) * internalRetract
			Put(jProx, workCF * CFrame.new(0, anchorY + growSign * (sz.Y * 0.07), 0),
				Vector3.new(sz.X * 0.62 * jp, sz.Y * 0.13, sz.Z * 0.62 * jp), 0)
		end
		if jDist then
			local jd = smoother(0.28, 0.62, g) * internalRetract
			if jd > 0.02 then
				local tipY = anchorY + growSign * bLen
				Put(jDist, workCF * CFrame.new(0, tipY, 0),
					Vector3.new(sz.X * 0.54 * jd, sz.Y * 0.12 * jd, sz.Z * 0.54 * jd), 0)
			else
				jDist.Transparency = 1
			end
		end
		if patella then
			local kp = spring(inv(0.22, 0.58, g), 5.5, 12.0) * internalRetract
			if kp > 0.02 then
				Put(patella, workCF * CFrame.new(0, anchorY + growSign * (sz.Y * 0.14), -sz.Z * 0.28 * internalRetract),
					Vector3.new(sz.X * 0.34 * kp, sz.X * 0.34 * kp, sz.Z * 0.26 * kp), 0)
			else
				patella.Transparency = 1
			end
		end
	end

	-- 3. LIGAMENTOS CRUZADOS E FEIXES NERVOSOS INTERNOS
	for i, lig in ipairs(rig.ligaments) do
		local lp = smoother(0.10 + (i - 1) * 0.05, 0.62, g)
		if lp > 0.02 then
			local sign = (i == 1) and -1 or (i == 2 and 1 or 0)
			local lLen = sz.Y * 0.72 * lp
			local lY = anchorY + growSign * (lLen * 0.48)
			local crossTilt = sign * 0.26 * (1 - 0.45 * finalLock)
			Put(lig,
				workCF * CFrame.new(sign * sz.X * 0.15 * internalRetract, lY, (i == 3 and -1 or 1) * sz.Z * 0.12 * internalRetract)
					* CFrame.Angles(crossTilt, 0, -crossTilt),
				Vector3.new(sz.X * 0.10 * internalRetract, lLen, sz.Z * 0.10 * internalRetract),
				0
			)
		else
			lig.Transparency = 1
		end
	end

	-- 4. TENDÕES DE INSERÇÃO PROXIMAL E DISTAL
	for i, tPart in ipairs(rig.tendons) do
		local tp = smoother(0.04, 0.66, g)
		if tp > 0.02 then
			local sideSign = (i == 1) and -1 or 1
			local tLen = sz.Y * 0.48 * tp
			local tY = anchorY + growSign * (tLen * 0.36)
			local tilt = sideSign * 0.16 * (1 - finalLock)
			Put(tPart,
				workCF * CFrame.new(sideSign * sz.X * 0.27 * internalRetract, tY, 0) * CFrame.Angles(0, 0, tilt),
				Vector3.new(sz.X * 0.14 * internalRetract, tLen, sz.Z * 0.14 * internalRetract),
				0
			)
		else
			tPart.Transparency = 1
		end
	end

	-- 5. CAMADA MUSCULAR PROFUNDA (FEIXES PENADOS / OBLÍQUOS)
	if deepMusProg > 0.01 then
		local dmLen = sz.Y * deepMusProg
		local dmCenterY = anchorY + growSign * (dmLen * 0.5)
		for idx, dm in ipairs(rig.deepMuscles) do
			local stagger = (idx - 1) * 0.05
			local localP = clamp01((deepMusProg - stagger) / (1 - stagger))
			if localP > 0.01 then
				local rad = 0.16 * internalRetract
				local off = Vector3.new(dm.dir.X * sz.X * rad, dmCenterY, dm.dir.Z * sz.Z * rad)
				local w = (math.abs(dm.dir.X) > 0 and sz.X * 0.42 or sz.X * 0.64) * localP * internalRetract
				local d = (math.abs(dm.dir.Z) > 0 and sz.Z * 0.42 or sz.Z * 0.64) * localP * internalRetract
				Put(dm.part,
					workCF * CFrame.new(off) * CFrame.Angles(dm.tilt * (1 - finalLock * 0.5), 0, dm.tilt * (1 - finalLock * 0.5)),
					Vector3.new(w, dmLen * localP * 0.92, d),
					0
				)
			else
				dm.part.Transparency = 1
			end
		end
	else
		for _, dm in ipairs(rig.deepMuscles) do dm.part.Transparency = 1 end
	end

	-- 6. VENTRES MUSCULARES SUPERFICIAIS & EXPANSÃO PERISTÁLTICA
	if superMusProg > 0.01 then
		local mLen = sz.Y * superMusProg
		local mCenterY = anchorY + growSign * (mLen * 0.5)
		local swell = spring(swellProg, 4.8, 11.5) * internalRetract
		local peristalticWave = 1 + 0.068 * math.sin(clock * 14.5 + seed) * (1 - finalLock)

		for idx, m in ipairs(rig.superMuscles) do
			local stagger = (idx - 1) * 0.055
			local localM = clamp01((superMusProg - stagger) / (1 - stagger))
			if localM <= 0.01 then
				m.part.Transparency = 1
			else
				local radialDist = lerp(0.12, 0.25, swell) * peristalticWave
				local tierShiftY = (m.tier == 2) and (growSign * sz.Y * 0.12 * (1 - finalLock)) or 0
				local offset = Vector3.new(
					m.dir.X * sz.X * radialDist,
					mCenterY + tierShiftY,
					m.dir.Z * sz.Z * radialDist
				)
				local bundleW = (math.abs(m.dir.X) > 0 and sz.X * 0.52 or sz.X * 0.78) * swell * peristalticWave
				local bundleD = (math.abs(m.dir.Z) > 0 and sz.Z * 0.52 or sz.Z * 0.78) * swell * peristalticWave
				local bundleH = mLen * localM * (1 - 0.05 * bell(swellProg))
				local col = COL.Marrow:Lerp(m.baseCol, smooth(0, 0.45, localM)):Lerp(COL.MuscleMid, 0.40 * bell(swellProg))
				Put(m.part, workCF * CFrame.new(offset), Vector3.new(bundleW, bundleH, bundleD), 0, col)
			end
		end
	else
		for _, m in ipairs(rig.superMuscles) do
			m.part.Transparency = 1
		end
	end

	-- 7. MATRIZ SUBDÉRMICA (ENVELOPE VASCULAR ANTES DO FECHAMENTO EPIDÉRMICO)
	if rig.subdermis then
		if subdermProg > 0.01 then
			local subLen = sz.Y * outCubic(subdermProg)
			local subY = anchorY + growSign * (subLen * 0.5)
			local subW = lerp(0.76, 0.94, subdermProg) * internalRetract
			local subCol = COL.MuscleMid:Lerp(COL.Subdermis, subdermProg)
			Put(rig.subdermis, workCF * CFrame.new(0, subY, 0), Vector3.new(sz.X * subW, subLen * 0.96, sz.Z * subW), 0, subCol)
		else
			rig.subdermis.Transparency = 1
		end
	end

	-- 8. PLACAS EPIDÉRMICAS MULTI-FACETADAS (FECHAMENTO TIPO ZÍPER BIOLÓGICO COM OPACIDADE REAL)
	-- As 4 placas crescem da raiz até a ponta (dermalZipProg) e simultaneamente expandem a largura
	-- até selarem as 4 faces do membro (dermalSeal -> 1.0), eliminando qualquer truque de fade de transparência!
	if dermalZipProg > 0.01 then
		local plateLen = sz.Y * outCubic(dermalZipProg)
		local plateCenterY = anchorY + growSign * (plateLen * 0.5)
		local closeFrac = spring(dermalSeal, 5.6, 10.5)
		local plateColor = COL.Subdermis:Lerp(part.Color, smoother(0.0, 0.68, dermalZipProg))

		for idx, dp in ipairs(rig.dermalPlates) do
			local d = dp.dir
			-- Enquanto closeFrac < 1, há uma fresta longitudinal entre as placas mostrando o músculo vivo por dentro;
			-- quando closeFrac atinge 1, as 4 placas formam exatamente o bloco externo completo do membro!
			local radialSpread = lerp(0.32, 0.25, clamp01(closeFrac))
			local tangentialCover = lerp(0.36, 1.00, clamp01(closeFrac))
			local normalThick = lerp(0.18, 0.50, clamp01(closeFrac))

			local pW = (math.abs(d.X) > 0) and (sz.X * normalThick) or (sz.X * tangentialCover)
			local pD = (math.abs(d.Z) > 0) and (sz.Z * normalThick) or (sz.Z * tangentialCover)
			local pOff = Vector3.new(d.X * sz.X * radialSpread, plateCenterY, d.Z * sz.Z * radialSpread)

			-- Leve inclinação das bordas da placa enquanto ela avança fechando sobre o músculo
			local flareAngle = (1 - clamp01(dermalSeal)) * 0.14
			local flareCF = CFrame.Angles(-d.Z * flareAngle * growSign, 0, d.X * flareAngle * growSign)

			Put(dp.part, workCF * CFrame.new(pOff) * flareCF, Vector3.new(pW, plateLen, pD), origTrans, plateColor)
		end
	else
		for _, dp in ipairs(rig.dermalPlates) do
			dp.part.Transparency = 1
		end
	end
end

-- Coordena a reconstrução progressiva de múltiplos membros com pontes tendíneas inter-segmentares e reações articulares
local function RebuildAnatomy(ctx, origVis, entries, onFrame)
	local jobs = {}
	local totalDuration = 0

	for eIdx, entry in ipairs(entries) do
		local stagger = entry.stagger or 0.24
		for pIdx, part in ipairs(entry.parts) do
			local startT = entry.t0 + (pIdx - 1) * stagger
			local dur = entry.dur
			local rig = BuildAnatomicalRigForPart(ctx, part, entry.anatomy or "Limb")
			local parentPart = (pIdx > 1) and entry.parts[pIdx - 1] or entry.anchorPart
			local bridge = parentPart and NewTendonBundle(ctx, 2, true) or nil

			table.insert(jobs, {
				part       = part,
				parentPart = parentPart,
				bridge     = bridge,
				rig        = rig,
				t0         = startT,
				dur        = dur,
				orig       = origVis[part] or 0,
				seed       = eIdx * 13.7 + pIdx * 5.3,
				boneFired  = false,
				mistFired  = false,
				lockFired  = false,
			})
			totalDuration = math.max(totalDuration, startT + dur)
		end
	end

	ctx.maid:Add(function()
		for _, j in ipairs(jobs) do
			DestroyAnatomicalRig(j.rig)
		end
	end)

	Animate(ctx, totalDuration, function(_, elapsed, dt)
		for _, j in ipairs(jobs) do
			local g = (elapsed - j.t0) / j.dur
			UpdateAnatomicalRig(ctx, j.rig, g, j.orig, j.seed)

			-- Feixe fibroso inter-segmentar conectando a peça em crescimento ao segmento pai
			if j.bridge and j.parentPart and j.parentPart.Parent and j.part and j.part.Parent then
				if g > 0.01 and g < 0.90 then
					local pA = j.parentPart.Position
					local pB = j.part.Position
					local dist = (pB - pA).Magnitude
					if dist > 0.05 and dist < 6.5 then
						local tension = smooth(0.3, 0.85, g)
						local hideBridge = smooth(0.76, 0.90, g)
						DrawTendonBundle(j.bridge, pA, pB, 0.08, 0.07, 0.11, hideBridge, tension)
					else
						DrawTendonBundle(j.bridge, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
					end
				else
					DrawTendonBundle(j.bridge, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
				end
			end

			if not j.boneFired and g >= 0.06 and j.part.Parent then
				j.boneFired = true
				SpawnPhysicalDrop(ctx, j.part.Position, Vector3.new(rand(-2.5, 2.5), rand(1, 3.5), rand(-2.5, 2.5)), 0.09, Enum.Material.SmoothPlastic, COL.Marrow)
			end
			if not j.mistFired and g >= 0.32 and j.part.Parent then
				j.mistFired = true
				EmitTissueMist(ctx, j.part.Position, 4)
			end
			if not j.lockFired and g >= 0.90 and j.part.Parent then
				j.lockFired = true
				SpawnPhysicalDrop(ctx, j.part.Position, Vector3.new(rand(-3.5, 3.5), rand(1.5, 4.5), rand(-3.5, 3.5)), 0.10)
				CamDirector:AddTrauma(0.08, 3.5)
			end
		end
		if onFrame then
			onFrame(elapsed, totalDuration, dt)
		end
	end)

	for _, j in ipairs(jobs) do
		DestroyAnatomicalRig(j.rig)
		if j.part and j.part.Parent then
			j.part.Transparency = j.orig
		end
	end
end

--------------------------------------------------------------------------------
-- 9. HABILIDADE 1: JUMP (IMPULSO MASSIVO, RUPTURA AÉREA, IMPACTO E RASTEJAMENTO)
--------------------------------------------------------------------------------
local function AbilityJump(ctx)
	local hum, root = S.hum, S.root
	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local lLeg = Group("LLeg")
	local rLeg = Group("RLeg")
	local legs = Concat(lLeg, rLeg)
	local origLegs = CaptureVisibility(legs, "attached")

	ctx.maid:Add(function()
		SetVisibility(origLegs, 0)
		if root and root.Parent then
			root.Anchored = false
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			hum.AutoRotate = true
		end
	end)

	local standOffset = S.r6 and 3.0 or (hum.HipHeight + root.Size.Y * 0.5)
	local look = flat(root.CFrame.LookVector)
	local ground0, _, _, groundCol0 = GroundBelow(ctx, root.Position)

	-- 1. ANTECIPAÇÃO PROFUNDA DE SALTO (Inspiração -> Compressão Muscular -> Sobrecarga nos Tendões)
	root.Anchored = true
	local startCF = root.CFrame
	CamDirector:SetStage(Vector3.new(0.45, -0.65, 1.2), -5, 0, 14)

	Animate(ctx, 0.38, function(p)
		-- Fase 1 (0..0.22): Leve elevação de tomada de fôlego
		-- Fase 2 (0.22..0.82): Agachamento profundo acumulando energia elástica
		-- Fase 3 (0.82..1.00): Chicote pré-impulso do tronco
		local inhale   = bell(inv(0.0, 0.25, p))
		local coil     = smoother(0.15, 0.85, p)
		local snapPrep = smooth(0.80, 1.0, p)
		local crouchDepth = -0.12 * inhale + 1.28 * coil - 0.14 * snapPrep
		local tremor = coil * coil * 0.032

		root.CFrame = startCF
			* CFrame.new(rand(-tremor, tremor), -crouchDepth, -0.26 * coil + 0.08 * inhale)
			* CFrame.Angles(-0.48 * coil + 0.12 * inhale + 0.14 * snapPrep, 0, 0)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.26 * coil + 0.08 * inhale, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(-1.18 * coil + 0.35 * inhale, 0, 0.28 * coil), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-1.18 * coil + 0.35 * inhale, 0, -0.28 * coil), 1, 0.45)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.65 * coil, 0, 0), 1, 0.45)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.65 * coil, 0, 0), 1, 0.45)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.92 * coil, 0, 0.08 * coil), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.92 * coil, 0, -0.08 * coil), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.38 * coil, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-1.38 * coil, 0, 0), 1, 0.45)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(0.38 * coil - 0.15 * inhale, 0, 0), 1, 0.45)
	end)

	-- Disparo propulsivo de alta potência
	EmitDust(ctx, ground0, 26, groundCol0)
	ShakeCamera(hum, 0.48, 0.32)
	CamDirector:SetStage(Vector3.new(0, 0.8, 3.2), 10, 0, 10)

	root.Anchored = false
	hum.PlatformStand = true
	hum.AutoRotate = false

	local moveDir = hum.MoveDirection.Magnitude > 0.05 and flat(hum.MoveDirection) or look
	local launchVel = moveDir * CFG.Jump.ForwardSpeed + Vector3.new(0, CFG.Jump.UpVelocity, 0)
	root.AssemblyLinearVelocity = launchVel

	-- Extensão explosiva na saída do solo (0.12s) — as pernas começam a rasgar nos quadris sob a força extrema
	local tearTendonL = NewTendonBundle(ctx, 3, true)
	local tearTendonR = NewTendonBundle(ctx, 3, true)
	local lowerTorso  = GetLowerTorso()

	Animate(ctx, 0.13, function(p)
		local k = outQuart(p)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(lerp(-0.26, 0.24, k), 0, 0), 1, 0.8)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(-1.18, 2.65, k), 0, 0.18), 1, 0.8)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(-1.18, 2.65, k), 0, -0.18), 1, 0.8)
		pose:SetJoint("RHip",      Vector3.new(0, -0.45 * k, 0), CFrame.Angles(lerp(0.92, -0.62, k), 0, 0), 1, 0.8)
		pose:SetJoint("LHip",      Vector3.new(0, -0.45 * k, 0), CFrame.Angles(lerp(0.92, -0.62, k), 0, 0), 1, 0.8)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(lerp(-1.38, -0.10, k), 0, 0), 1, 0.8)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(lerp(-1.38, -0.10, k), 0, 0), 1, 0.8)
	end)

	-- 2. RUPTURA ANATÔMICA COMPLETA: PERNAS ARTICULADAS FICAM PARA TRÁS DURANTE A SUBIDA
	SetVisibility(origLegs, 1)
	local detachedLimbs = {}

	local function SpawnDetachedLegAssembly(legParts, sideSign)
		local assemblyParts = {}
		for idx, p in ipairs(legParts) do
			local clone = p:Clone()
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Motor6D") or d:IsA("Weld") then
					d:Destroy()
				end
			end
			clone.Transparency = origLegs[p] or 0
			clone.Anchored = false
			clone.CanCollide = true
			clone.CanQuery = false
			clone.CanTouch = false
			clone.Massless = false
			clone.CFrame = p.CFrame
			clone.Parent = ctx.folder
			table.insert(assemblyParts, clone)
			table.insert(detachedLimbs, clone)

			-- Conecta os segmentos da mesma perna com BallSocketConstraint para cair como um membro articulado real
			if idx > 1 then
				local prevClone = assemblyParts[idx - 1]
				local att0 = Instance.new("Attachment")
				att0.Position = Vector3.new(0, -prevClone.Size.Y * 0.48, 0)
				att0.Parent = prevClone
				local att1 = Instance.new("Attachment")
				att1.Position = Vector3.new(0, clone.Size.Y * 0.48, 0)
				att1.Parent = clone
				local bs = Instance.new("BallSocketConstraint")
				bs.Attachment0 = att0
				bs.Attachment1 = att1
				bs.LimitsEnabled = true
				bs.UpperAngle = 45
				bs.Parent = clone
			end

			if idx == 1 then
				-- Topo anatômico da coxa arrancada (músculo + cabeça do fêmur exposta)
				local cap = Instance.new("Part")
				cap.Size = Vector3.new(p.Size.X * 0.82, 0.16, p.Size.Z * 0.82)
				cap.Color = COL.MuscleDeep
				cap.Material = Enum.Material.SmoothPlastic
				cap.CanCollide = false
				cap.Massless = true
				cap.CFrame = clone.CFrame * CFrame.new(0, p.Size.Y * 0.5, 0)
				cap.Parent = clone
				local w1 = Instance.new("WeldConstraint")
				w1.Part0 = clone
				w1.Part1 = cap
				w1.Parent = cap

				local fem = Instance.new("Part")
				fem.Size = Vector3.new(0.24, 0.34, 0.24)
				fem.Color = COL.Bone
				fem.Material = Enum.Material.Slate
				fem.CanCollide = false
				fem.Massless = true
				fem.CFrame = clone.CFrame * CFrame.new(0, p.Size.Y * 0.5 + 0.16, 0)
				fem.Parent = clone
				local w2 = Instance.new("WeldConstraint")
				w2.Part0 = clone
				w2.Part1 = fem
				w2.Parent = fem

				local hipPos = cap.Position
				EmitTissueMist(ctx, hipPos, 8)
				for _ = 1, 5 do
					SpawnPhysicalDrop(ctx, hipPos, Vector3.new(rand(-9, 9), rand(-3, 10), rand(-9, 9)))
				end
			end

			clone.AssemblyLinearVelocity = Vector3.new(
				launchVel.X * 0.15 + sideSign * rand(2, 5),
				-16 + rand(-6, 2),
				launchVel.Z * 0.15 + rand(-4, 4)
			)
			clone.AssemblyAngularVelocity = Vector3.new(rand(-9, 9), rand(-5, 5), rand(-9, 9))
		end
		return assemblyParts[1]
	end

	local topLegL = SpawnDetachedLegAssembly(lLeg, -1)
	local topLegR = SpawnDetachedLegAssembly(rLeg, 1)

	-- Tocos anatômicos e fêmures quebrados expostos no quadril do personagem
	local hipStumpL = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic)
	local hipStumpR = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic)
	local hipBoneL  = FXPart(ctx, COL.Bone, Enum.Material.Slate)
	local hipBoneR  = FXPart(ctx, COL.Bone, Enum.Material.Slate)

	local function UpdateHipStumps(alpha)
		if not lowerTorso or not lowerTorso.Parent then return end
		local cf = lowerTorso.CFrame
		local sx, sy, sz = lowerTorso.Size.X, lowerTorso.Size.Y, lowerTorso.Size.Z
		Put(hipStumpL, cf * CFrame.new(-sx * 0.25, -sy * 0.52, 0), Vector3.new(sx * 0.45, 0.20, sz * 0.82), alpha)
		Put(hipStumpR, cf * CFrame.new( sx * 0.25, -sy * 0.52, 0), Vector3.new(sx * 0.45, 0.20, sz * 0.82), alpha)
		Put(hipBoneL,  cf * CFrame.new(-sx * 0.25, -sy * 0.65, 0), Vector3.new(0.24, 0.32, 0.24), alpha)
		Put(hipBoneR,  cf * CFrame.new( sx * 0.25, -sy * 0.65, 0), Vector3.new(0.24, 0.32, 0.24), alpha)
	end

	-- 3. VOO BALÍSTICO DE GRANDE ALTURA E QUEDA COM FÍSICA CONVINCENTE
	local rp = RayParams(ctx, detachedLimbs)
	local landedHit = nil
	local currentYaw = math.atan2(-moveDir.X, -moveDir.Z)
	local pitchAngle = -0.15
	local rollAngle  = 0

	local flightAtt = ctx.maid:Add(Instance.new("Attachment"))
	flightAtt.Parent = root
	local flightAO = ctx.maid:Add(Instance.new("AlignOrientation"))
	flightAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flightAO.Attachment0 = flightAtt
	flightAO.Responsiveness = 20
	flightAO.MaxTorque = 1e6
	flightAO.CFrame = root.CFrame.Rotation
	flightAO.Parent = root

	Animate(ctx, 5.5, function(_, elapsed, dt)
		UpdateHipStumps(0)

		-- Tendões esticando sob tensão extrema até estourarem quando o tronco dispara para o alto
		if elapsed < 0.46 and topLegL and topLegR and lowerTorso then
			local snapAlpha = smooth(0.26, 0.46, elapsed)
			local tension   = smooth(0.0, 0.30, elapsed)
			local hL = (lowerTorso.CFrame * CFrame.new(-0.5, -lowerTorso.Size.Y * 0.5, 0)).Position
			local hR = (lowerTorso.CFrame * CFrame.new( 0.5, -lowerTorso.Size.Y * 0.5, 0)).Position
			DrawTendonBundle(tearTendonL, hL, topLegL.Position, 0.12, 0.26, 0.13, snapAlpha, tension)
			DrawTendonBundle(tearTendonR, hR, topLegR.Position, 0.12, 0.26, 0.13, snapAlpha, tension)
		else
			DrawTendonBundle(tearTendonL, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
			DrawTendonBundle(tearTendonR, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
		end

		local airSteer = hum.MoveDirection
		if airSteer.Magnitude > 0.05 then
			root.AssemblyLinearVelocity += Vector3.new(airSteer.X, 0, airSteer.Z) * (15 * dt)
			local desiredYaw = math.atan2(-airSteer.X, -airSteer.Z)
			local diffYaw = math.atan2(math.sin(desiredYaw - currentYaw), math.cos(desiredYaw - currentYaw))
			currentYaw += diffYaw * math.min(1, dt * 3.8)
		end

		local vel = root.AssemblyLinearVelocity
		local vy  = vel.Y

		-- Na subida o peito aponta para o alto; no ápice faz transição de gravidade zero; na queda mergulha preparando as mãos
		local targetPitch = clamp(lerp(-1.44, 0.42, inv(-135, 145, vy)), -1.50, 0.48)
		pitchAngle = lerp(pitchAngle, targetPitch, 1 - math.exp(-dt * 7.2))
		rollAngle  = math.sin(elapsed * 5.4) * 0.18 * clamp01(math.abs(vy) / 90)

		flightAO.CFrame = CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(pitchAngle, 0, rollAngle)

		local fallFactor  = clamp01(-vy / 100)
		local windFlutter = math.sin(elapsed * 16) * 0.18 * fallFactor
		CamDirector:SetStage(Vector3.new(0, lerp(0.8, -0.4, fallFactor), lerp(2.8, 1.5, fallFactor)), lerp(9, 4, fallFactor), rollAngle * 0.25, 10)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(lerp(0.18, -0.32, fallFactor), 0, rollAngle * 0.5), 1, 0.35)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(2.25, 1.55, fallFactor) + windFlutter, 0, lerp(0.24, 0.52, fallFactor)), 1, 0.35)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(2.25, 1.55, fallFactor) - windFlutter, 0, lerp(-0.24, -0.52, fallFactor)), 1, 0.35)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(lerp(0.22, 0.58, fallFactor), 0, 0), 1, 0.35)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(lerp(0.22, 0.58, fallFactor), 0, 0), 1, 0.35)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(lerp(-0.20, -0.62, fallFactor), 0, 0), 1, 0.35)

		if math.random() < 0.26 then
			SpawnPhysicalDrop(ctx, hipBoneL.Position, Vector3.new(rand(-2, 2), rand(0, 3), rand(-2, 2)), 0.10)
		end

		if elapsed > 0.26 and vy <= 2 then
			local castDist = math.max(3.0, math.abs(vy) * dt * 1.6 + 2.2)
			local hit = Workspace:Raycast(root.Position, Vector3.new(0, -castDist, 0), rp)
			if hit then
				landedHit = hit
				return true
			end
		end
	end)

	flightAO:Destroy()
	flightAtt:Destroy()

	-- 4. IMPACTO PESADO COM O CHÃO, AMORTECIMENTO DE BRAÇOS, QUIQUE E DERRAPAGEM POR INÉRCIA
	local groundPos, _, _, landCol = GroundBelow(ctx, root.Position)
	if landedHit then
		groundPos = landedHit.Position
		landCol = landedHit.Instance and landedHit.Instance.Color or COL.Dust
	end

	local horizVel  = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
	local fallSpeed = math.abs(math.min(0, root.AssemblyLinearVelocity.Y))
	local crawlDir  = horizVel.Magnitude > 2.5 and horizVel.Unit or moveDir

	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local function ProneCF(pos, dir, torsoRoll, torsoPitch, torsoYaw)
		local fDir = flat(dir)
		local base = CFrame.lookAt(pos, pos + Vector3.yAxis, -fDir)
		return base * CFrame.Angles(torsoPitch or 0, torsoYaw or 0, torsoRoll or 0)
	end

	local impactPos = Vector3.new(root.Position.X, groundPos.Y + 0.64, root.Position.Z)
	EmitDust(ctx, groundPos, 34, landCol)
	EmitTissueMist(ctx, impactPos, 14)
	ShakeCamera(hum, clamp(fallSpeed / 175, 0.52, 0.88), 0.46)
	CamDirector:SetStage(Vector3.new(0.55, -1.35, -0.8), -4, 0, 14)

	for _ = 1, 10 do
		SpawnPhysicalDrop(ctx, impactPos, Vector3.new(rand(-12, 12), rand(3, 13), rand(-12, 12)))
	end

	local skidDist = clamp(horizVel.Magnitude * 0.12 + fallSpeed * 0.014, 1.3, 4.6)
	local impactStartCF = root.CFrame
	Animate(ctx, 0.44, function(p)
		UpdateHipStumps(0)
		local skid     = outQuart(p) * skidDist
		local slapDown = smooth(0.0, 0.24, p)
		local rebound  = math.sin(smooth(0.20, 0.78, p) * PI) * 0.48 * (1 - p)
		local curG, _, _, curCol = GroundBelow(ctx, impactPos + crawlDir * skid, 14)
		local heightOff = lerp(0.76, 0.40, slapDown) + rebound + 0.19 * smooth(0.65, 1.0, p)
		local pPos = Vector3.new(impactPos.X + crawlDir.X * skid, curG.Y + heightOff, impactPos.Z + crawlDir.Z * skid)

		local impactRoll  = math.sin(p * PI * 3) * 0.16 * (1 - p)
		local impactPitch = -0.20 * bell(smooth(0.0, 0.45, p))
		local targetProne = ProneCF(pPos, crawlDir, impactRoll, impactPitch, 0)
		root.CFrame = impactStartCF:Lerp(targetProne, outCubic(clamp01(p * 1.85)))

		local elbowBuckle = bell(smooth(0.0, 0.55, p))
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(1.45 - 0.38 * elbowBuckle, 0, 0.44 + 0.26 * elbowBuckle), 1, 0.5)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(1.45 - 0.38 * elbowBuckle, 0, -0.44 - 0.26 * elbowBuckle), 1, 0.5)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.48 + 0.80 * elbowBuckle, 0, 0), 1, 0.5)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.48 + 0.80 * elbowBuckle, 0, 0), 1, 0.5)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.58 + 0.38 * elbowBuckle, 0, 0), 1, 0.5)

		if math.random() < 0.38 and p < 0.68 then
			EmitDust(ctx, Vector3.new(pPos.X, curG.Y, pPos.Z), 2, curCol)
		end
	end)

	-- 5. RASTEJAMENTO BIOMECÂNICO SINCRONIZADO (TRAÇÃO ASSIMÉTRICA DOS BRAÇOS, ESCÁPULAS E TORSO)
	local crawlPos = Vector3.new(root.Position.X, groundPos.Y + 0.58, root.Position.Z)
	local crawlVel = Vector3.zero
	local crawlPhase = 0
	local lastPlantedSide = 0
	local torsoTwistSpring = SpringVec3.new(Vector3.zero, 16, 0.74)

	local earlyTendonL = NewTendonBundle(ctx, 2, true)
	local earlyTendonR = NewTendonBundle(ctx, 2, true)

	Animate(ctx, CFG.Jump.CrawlDuration, function(p, elapsed, dt)
		UpdateHipStumps(0)

		for _, c in ipairs(detachedLimbs) do
			if c and c.Parent then
				local fade = smooth(0.35, 0.90, p)
				c.Transparency = lerp(0, 1, fade)
				if fade >= 1 then c:Destroy() end
			end
		end

		local moveInput = hum.MoveDirection
		local inputMag  = clamp01(moveInput.Magnitude)

		if inputMag > 0.04 then
			local desiredDir = flat(moveInput)
			crawlDir = safeUnit(crawlDir:Lerp(desiredDir, 1 - math.exp(-dt * 7.0)), crawlDir)
		end

		local velMag    = crawlVel.Magnitude
		local speedFrac = clamp01(velMag / CFG.Jump.CrawlSpeed)
		local cycleRate = inputMag > 0.04 and lerp(1.8, 7.8, inputMag) or (speedFrac * 3.4)
		crawlPhase += dt * cycleRate

		local lSin, lCos = math.sin(crawlPhase), math.cos(crawlPhase)
		local rSin, rCos = math.sin(crawlPhase + PI), math.cos(crawlPhase + PI)

		-- Fase de cravamento e tração pesada no chão (quando o braço puxa o peso do tronco)
		local lPullPower = math.max(0, -lCos) * smooth(0, 0.22, inputMag)
		local rPullPower = math.max(0, -rCos) * smooth(0, 0.22, inputMag)
		local activePull = math.max(lPullPower, rPullPower)

		local currentSide = lSin >= 0 and 1 or -1
		if inputMag > 0.12 and currentSide ~= lastPlantedSide then
			lastPlantedSide = currentSide
			local rightVec = crawlDir:Cross(Vector3.yAxis)
			local handGroundPos = crawlPos + crawlDir * 1.48 + rightVec * (currentSide * 0.80) - Vector3.new(0, 0.54, 0)
			EmitDust(ctx, handGroundPos, 5)
			crawlVel += crawlDir * (4.0 * inputMag)
			CamDirector:AddTrauma(0.06 * inputMag, 4.0)
		end

		local targetSpeed = CFG.Jump.CrawlSpeed * inputMag * (0.38 + 0.88 * activePull)
		local targetVel   = crawlDir * targetSpeed
		local accelRate   = inputMag > 0.05 and 7.5 or 4.4
		crawlVel = crawlVel:Lerp(targetVel, 1 - math.exp(-dt * accelRate))

		local stepVec = Vector3.new(crawlVel.X, 0, crawlVel.Z) * dt
		if stepVec.Magnitude > 1e-4 then
			local wallHit = Workspace:Raycast(crawlPos + Vector3.new(0, 0.3, 0), stepVec.Unit * (stepVec.Magnitude + 1.45), rp)
			if not wallHit then
				crawlPos += stepVec
			else
				crawlVel = crawlVel * 0.2
			end
		end

		local curGPos = GroundBelow(ctx, crawlPos, 15)
		crawlPos = Vector3.new(crawlPos.X, lerp(crawlPos.Y, curGPos.Y + 0.58, 1 - math.exp(-dt * 15)), crawlPos.Z)

		-- Rotação biomecânica sincronizada entre torso, escápulas e quadris
		local rawRoll  = lSin * 0.28 * speedFrac
		local rawYaw   = -lSin * 0.22 * speedFrac
		local rawPitch = -0.07 + activePull * 0.16 * speedFrac + math.sin(elapsed * 4.4) * 0.025
		local twist    = torsoTwistSpring:Step(dt, Vector3.new(rawPitch, rawYaw, rawRoll))
		local verticalHeave = activePull * 0.18 * speedFrac

		CamDirector:SetStage(Vector3.new(twist.Z * 1.2, -1.45 + verticalHeave * 0.5, -0.9), -3, twist.Z * 0.18, 12)

		root.CFrame = ProneCF(crawlPos + Vector3.new(0, verticalHeave, 0), crawlDir, twist.Z, twist.X, twist.Y)
		pose:SetJoint("Waist", Vector3.zero, CFrame.Angles(twist.X * 0.45, twist.Y * 0.70, twist.Z * 0.55), 1, 0.45)

		local lLift = math.max(0, lCos)
		local rLift = math.max(0, rCos)

		pose:SetJoint("LShoulder",
			Vector3.new(0, 0.22 * lSin * speedFrac, -0.20 * lLift * speedFrac),
			CFrame.Angles(1.50 + 0.76 * lSin * speedFrac, 0.24 * lSin * speedFrac, -0.35 - 0.24 * lLift * speedFrac),
			1, 0.45
		)
		pose:SetJoint("RShoulder",
			Vector3.new(0, 0.22 * rSin * speedFrac, -0.20 * rLift * speedFrac),
			CFrame.Angles(1.50 + 0.76 * rSin * speedFrac, -0.24 * rSin * speedFrac, 0.35 + 0.24 * rLift * speedFrac),
			1, 0.45
		)
		pose:SetJoint("LElbow", Vector3.zero, CFrame.Angles(0.50 + 0.62 * (1 - lSin * 0.7) * speedFrac, 0, 0), 1, 0.45)
		pose:SetJoint("RElbow", Vector3.zero, CFrame.Angles(0.50 + 0.62 * (1 - rSin * 0.7) * speedFrac, 0, 0), 1, 0.45)
		pose:SetJoint("LWrist", Vector3.zero, CFrame.Angles(-0.35 * lPullPower, 0, 0), 1, 0.45)
		pose:SetJoint("RWrist", Vector3.zero, CFrame.Angles(-0.35 * rPullPower, 0, 0), 1, 0.45)
		pose:SetJoint("Neck",   Vector3.zero, CFrame.Angles(-0.64 - 0.12 * activePull, -twist.Y * 0.85, -twist.Z * 0.45), 1, 0.40)

		-- Primeiros brotos ósseos e feixes nervosos emergindo dos tocos do quadril antes da parada
		if p > 0.48 and lowerTorso then
			local sprout = smooth(0.48, 1.0, p)
			local hL = hipBoneL.Position
			local hR = hipBoneR.Position
			local backDir = -crawlDir
			DrawTendonBundle(earlyTendonL, hL, hL + backDir * (1.45 * sprout) - Vector3.new(0, 0.12, 0), 0.05, 0.09, 0.11, 0.0, 0.35)
			DrawTendonBundle(earlyTendonR, hR, hR + backDir * (1.30 * sprout) - Vector3.new(0, 0.12, 0), 0.05, 0.09, 0.11, 0.0, 0.35)
		end
	end)

	DrawTendonBundle(earlyTendonL, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
	DrawTendonBundle(earlyTendonR, Vector3.zero, Vector3.zero, 0, 0, 0, 1)

	-- 6. REGENERAÇÃO COMPLETA DAS PERNAS ENQUANTO DEITADO + LEVANTAMENTO COM APOIO
	local finalGround, _, _, finalCol = GroundBelow(ctx, crawlPos, 14)
	local baseProne = ProneCF(Vector3.new(crawlPos.X, finalGround.Y + 0.58, crawlPos.Z), crawlDir, 0, -0.05, 0)

	-- Câmera enquadra lateralmente para destacar a reconstrução das pernas em tempo real
	CamDirector:SetStage(Vector3.new(1.35, -1.25, -1.15), -6, 0.02, 10)

	RebuildAnatomy(ctx, origLegs, {
		{ parts = lLeg, anchorPart = lowerTorso, t0 = 0.00, dur = 1.95, anatomy = "Leg", stagger = 0.36 },
		{ parts = rLeg, anchorPart = lowerTorso, t0 = 0.24, dur = 1.95, anatomy = "Leg", stagger = 0.36 },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		UpdateHipStumps(smooth(0.55, 0.90, k))

		-- O personagem apoia as palmas no chão, ergue o peito e olha para trás acompanhando a formação das próprias pernas
		local pushUp   = smooth(0.32, 0.96, k)
		local lookBack = bell(inv(0.10, 0.78, k))
		local spasm    = math.sin(t * 14.0) * 0.032 * bell(k)
		root.CFrame = baseProne
			* CFrame.new(0, 0, -0.24 * pushUp - spasm * 0.3)
			* CFrame.Angles(-0.28 * pushUp + spasm, 0.18 * lookBack, -0.08 * lookBack)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.18 * pushUp, 0.25 * lookBack, 0), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(1.42, 0.62, pushUp), 0, -0.26), 1, 0.4)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(1.42, 0.62, pushUp), 0,  0.26), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(lerp(0.65, 0.15, pushUp), 0, 0), 1, 0.4)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(lerp(0.65, 0.15, pushUp), 0, 0), 1, 0.4)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(lerp(-0.58, -0.15, pushUp), 0.55 * lookBack, 0), 1, 0.4)
	end)

	SetVisibility(origLegs, 0)
	UpdateHipStumps(1)

	-- 7. SEQUÊNCIA DE RECUPERAÇÃO FÍSICA (Recolhe um joelho -> Apoia mão na coxa -> Ergue com peso)
	CamDirector:SetStage(Vector3.new(0.4, -0.4, 0), -2, 0, 12)
	local standPos = Vector3.new(crawlPos.X, finalGround.Y + standOffset, crawlPos.Z)
	local standCF  = CFrame.lookAt(standPos, standPos + crawlDir)
	local kneelCF  = CFrame.lookAt(
		Vector3.new(crawlPos.X, finalGround.Y + standOffset * 0.56, crawlPos.Z),
		Vector3.new(crawlPos.X, finalGround.Y + standOffset * 0.56, crawlPos.Z) + crawlDir
	) * CFrame.Angles(-0.34, 0, 0)

	local fromCF = root.CFrame
	Animate(ctx, 0.36, function(p)
		local k = inOutCubic(p)
		root.CFrame = fromCF:Lerp(kneelCF, k)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.22 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.95 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.15 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.35 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.85 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.55 * k, 0, 0.15), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.35 * k, 0, -0.15), 1, 0.45)
	end)

	EmitDust(ctx, finalGround, 8, finalCol)
	CamDirector:ClearStage()

	Animate(ctx, 0.42, function(p)
		local k = outBack(p, 1.25)
		root.CFrame = kneelCF:Lerp(standCF, k)
		local rem = 1 - clamp01(p)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.22 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.95 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.15 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.35 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.85 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.55 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.35 * rem, 0, 0), 1, 0.45)
	end)

	pose:Reset(0.14)
	pose:SuppressDefaultAnimations(false)
	root.Anchored = false
	hum.PlatformStand = false
	hum.AutoRotate = true
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end

--------------------------------------------------------------------------------
-- 10. HABILIDADE 2: NOCLIP (DESINTEGRAÇÃO, POÇA IRREGULAR, GOTA VISCOSA E RECONSTRUÇÃO)
--------------------------------------------------------------------------------
local function IsBoxBlocked(ctx, cf, size)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = { S.char, ctx.folder }
	for _, p in ipairs(Workspace:GetPartBoundsInBox(cf, size, op)) do
		if p.CanCollide then
			return true
		end
	end
	return false
end

local function AbilityNoclip(ctx)
	local hum, root = S.hum, S.root
	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local body = Concat(Group("LLeg"), Group("RLeg"), Group("Torso"), Group("LArm"), Group("RArm"), Group("Head"))
	local origBody = CaptureVisibility(body, true)
	local standOffset = S.r6 and 3.0 or (hum.HipHeight + root.Size.Y * 0.5)
	local charBoxSize = Vector3.new(2.0, standOffset * 2 - 0.4, 1.2)

	local allCharParts = {}
	for _, d in ipairs(S.char:GetDescendants()) do
		if d:IsA("BasePart") then
			allCharParts[d] = d.CanCollide
		end
	end
	local noclipActive = true
	ctx.maid:Add(RunService.Stepped:Connect(function()
		if not noclipActive then return end
		for part, _ in pairs(allCharParts) do
			if part and part.Parent then
				part.CanCollide = false
			end
		end
	end))

	local function RestoreCollisions()
		noclipActive = false
		for part, origCollide in pairs(allCharParts) do
			if part and part.Parent then
				part.CanCollide = origCollide
			end
		end
	end

	ctx.maid:Add(RestoreCollisions)
	ctx.maid:Add(function()
		SetVisibility(origBody, 0)
		if root and root.Parent then
			root.Anchored = false
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			hum.AutoRotate = true
		end
	end)

	-- 1. COLAPSO ESTRUTURAL INTERNO ANTES DA LIQUEFAÇÃO
	root.Anchored = true
	local baseCF = root.CFrame
	CamDirector:SetStage(Vector3.new(0, -0.85, -1.2), -5, 0, 12)

	Animate(ctx, 0.36, function(p)
		local k = inOutCubic(p)
		local tremor = 0.055 * p * p
		root.CFrame = baseCF
			* CFrame.new(rand(-tremor, tremor), -0.78 * k, rand(-tremor, tremor))
			* CFrame.Angles(-0.34 * k, 0, 0)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.35 * k, 0, 0), 1, 0.5)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.95 * k, 0, -0.45 * k), 1, 0.5)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.95 * k, 0,  0.45 * k), 1, 0.5)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.85 * k, 0, 0), 1, 0.5)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.85 * k, 0, 0), 1, 0.5)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.65 * k, 0, 0), 1, 0.5)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.65 * k, 0, 0), 1, 0.5)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.10 * k, 0, 0), 1, 0.5)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-1.10 * k, 0, 0), 1, 0.5)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.50 * k, 0, 0), 1, 0.5)
	end)

	ShakeCamera(hum, 0.38, 0.28)
	EmitTissueMist(ctx, root.Position, 16)

	-- 2. DESINTEGRAÇÃO PROGRESSIVA E FORMAÇÃO DA POÇA VERMELHA IRREGULAR (MULTI-LÓBULOS)
	local groundPos = GroundBelow(ctx, root.Position)
	local puddleOuter = FXPart(ctx, COL.BloodDark, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local puddleMid   = FXPart(ctx, COL.Blood, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local puddleInner = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)

	-- Lóbulos orgânicos assimétricos para criar uma poça verdadeiramente irregular (não apenas um círculo perfeito)
	local puddleLobes = {}
	for i = 1, QUALITY.puddleLobes do
		local ang = (i / QUALITY.puddleLobes) * TAU + rand(-0.25, 0.25)
		table.insert(puddleLobes, {
			part   = FXPart(ctx, i % 2 == 0 and COL.Blood or COL.BloodDark, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder),
			dir    = Vector3.new(math.cos(ang), 0, math.sin(ang)),
			dist   = rand(1.1, 2.1),
			scaleX = rand(0.9, 1.8),
			scaleZ = rand(0.8, 1.5),
			phase  = rand(0, TAU),
		})
	end

	local function CylinderFloorCF(pos, yaw)
		return CFrame.new(pos) * CFrame.Angles(0, yaw or 0, PI * 0.5)
	end

	-- Ordena partes de baixo para cima para derreter em direção ao solo
	table.sort(body, function(a, b)
		return a.Position.Y < b.Position.Y
	end)

	local totalParts = #body
	for idx, p in ipairs(body) do
		p.Transparency = 1
		local prog = idx / totalParts
		local d = lerp(0.8, 5.0, outBack(prog, 1.18))
		Put(puddleOuter, CylinderFloorCF(groundPos + Vector3.new(0, 0.025, 0)), Vector3.new(0.05, d, d), 0.02)
		Put(puddleMid,   CylinderFloorCF(groundPos + Vector3.new(0, 0.038, 0)), Vector3.new(0.06, d * 0.78, d * 0.78), 0.0)
		Put(puddleInner, CylinderFloorCF(groundPos + Vector3.new(0, 0.052, 0)), Vector3.new(0.07, d * 0.52, d * 0.52), 0.0)

		for _, lb in ipairs(puddleLobes) do
			local lp = outBack(clamp01(prog * 1.15), 1.3)
			local lPos = groundPos + lb.dir * (lb.dist * lp) + Vector3.new(0, 0.03, 0)
			Put(lb.part, CylinderFloorCF(lPos, lb.phase), Vector3.new(0.055, d * 0.42 * lb.scaleX, d * 0.42 * lb.scaleZ), 0.0)
		end

		-- Colunas e fragmentos orgânicos caindo diretamente na poça
		for i = 1, QUALITY.frags do
			local f = Instance.new("Part")
			f.Shape = Enum.PartType.Ball
			local fSz = p.Size * rand(0.24, 0.40)
			f.Size = fSz
			f.Color = (i == 1) and COL.Bone or (i % 2 == 0 and COL.Muscle or COL.Blood)
			f.Material = (i == 1) and Enum.Material.Slate or Enum.Material.SmoothPlastic
			f.CanCollide = false
			f.CanQuery = false
			f.CanTouch = false
			f.CastShadow = false
			f.Massless = true
			local startPos = p.Position + Vector3.new(rand(-0.4, 0.4), rand(-0.3, 0.3), rand(-0.4, 0.4))
			local targetPuddlePos = Vector3.new(startPos.X + rand(-1.2, 1.2), groundPos.Y + 0.06, startPos.Z + rand(-1.2, 1.2))
			f.CFrame = CFrame.new(startPos)
			f.Parent = ctx.folder
			TweenService:Create(f, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(targetPuddlePos),
				Size   = Vector3.new(fSz.X * 1.7, 0.05, fSz.Z * 1.7),
				Transparency = 0.25,
			}):Play()
			Debris:AddItem(f, 0.35)
		end
		Wait(ctx, 0.025)
	end
	SetVisibility(origBody, 1)

	-- 3. POÇA SE CONTRAINDO POR TENSÃO SUPERFICIAL E FORMANDO A GOTA VISCOSA
	local dropShell  = FXPart(ctx, COL.Blood, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local dropMid    = FXPart(ctx, COL.Muscle, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local dropCore   = FXPart(ctx, COL.ViscousCore, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local surfaceCap = FXPart(ctx, COL.BloodDark, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)

	local subDrops = {}
	for i = 1, QUALITY.subDrops do
		subDrops[i] = {
			part  = FXPart(ctx, i % 2 == 0 and COL.Blood or COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Ball),
			pos   = groundPos + Vector3.new(0, 0.35, 0),
			vel   = Vector3.zero,
			phase = i * 1.35,
		}
	end

	local R = 1.32
	CamDirector:SetStage(Vector3.new(0, -1.55, -0.6), -4, 0, 12)

	Animate(ctx, 0.44, function(p)
		local k = inOutCubic(p)
		local d = lerp(5.0, 0.9, k)
		local fadePuddle = smooth(0.65, 1.0, p)
		Put(puddleOuter, CylinderFloorCF(groundPos + Vector3.new(0, 0.025, 0)), Vector3.new(0.05, d, d), fadePuddle)
		Put(puddleMid,   CylinderFloorCF(groundPos + Vector3.new(0, 0.038, 0)), Vector3.new(0.06, d * 0.75, d * 0.75), fadePuddle)
		Put(puddleInner, CylinderFloorCF(groundPos + Vector3.new(0, 0.052, 0)), Vector3.new(0.07, d * 0.50, d * 0.50), fadePuddle)

		for _, lb in ipairs(puddleLobes) do
			local shrink = 1 - k
			local lPos = groundPos + lb.dir * (lb.dist * shrink) + Vector3.new(0, 0.03, 0)
			Put(lb.part, CylinderFloorCF(lPos, lb.phase), Vector3.new(0.055, d * 0.40 * lb.scaleX * shrink, d * 0.40 * lb.scaleZ * shrink), fadePuddle)
		end

		local r   = R * spring(p, 5.0, 11.5)
		local wob = 0.26 * bell(p)
		local cPos = groundPos + Vector3.new(0, r * 0.44, 0)
		Put(dropShell,  CFrame.new(cPos), Vector3.new(r * (1 + wob), r * (0.82 - wob * 0.45), r * (1 + wob)), 0.08)
		Put(dropMid,    CFrame.new(cPos), Vector3.new(r * 0.84, r * 0.70, r * 0.84), 0.0)
		Put(dropCore,   CFrame.new(cPos), Vector3.new(r * 0.58, r * 0.48, r * 0.58), 0.0)
		Put(surfaceCap, CylinderFloorCF(groundPos + Vector3.new(0, 0.02, 0)), Vector3.new(0.05, r * 1.15, r * 1.15), 0.05)
	end)

	puddleOuter.Transparency = 1
	puddleMid.Transparency   = 1
	puddleInner.Transparency = 1
	for _, lb in ipairs(puddleLobes) do lb.part.Transparency = 1 end

	-- 4. LOCOMOÇÃO VISCOSA COM ACELERAÇÃO, DESACELERAÇÃO, INÉRCIA E CONSERVAÇÃO DE VOLUME
	root.Anchored = false
	hum.PlatformStand = true
	hum.AutoRotate = false

	local att = ctx.maid:Add(Instance.new("Attachment"))
	att.Parent = root
	local lv = ctx.maid:Add(Instance.new("LinearVelocity"))
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = 1e7
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root

	local ao = ctx.maid:Add(Instance.new("AlignOrientation"))
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = true
	ao.CFrame = CFrame.lookAt(Vector3.zero, flat(baseCF.LookVector))
	ao.Parent = root

	local lockY      = root.Position.Y
	local vel        = Vector3.zero
	local prevVel    = Vector3.zero
	local dropPos    = dropShell.Position
	local dropVel    = Vector3.zero
	local lastDir    = flat(baseCF.LookVector)
	local trailTimer = 0

	local function StepDropletVisual(dt, targetPos, accelVec, wallSqueeze)
		local acc = (targetPos - dropPos) * 145 - dropVel * 17
		dropVel += acc * dt
		dropPos += dropVel * dt

		local horizVel = Vector3.new(dropVel.X, 0, dropVel.Z)
		local horizSpd = horizVel.Magnitude
		local spdFrac  = clamp01(horizSpd / CFG.Noclip.Speed)
		if spdFrac > 0.03 then
			lastDir = safeUnit(lastDir:Lerp(horizVel.Unit, 1 - math.exp(-dt * 14)), lastDir)
		end

		local clock = os.clock()
		local accelForward = accelVec:Dot(lastDir)
		local accelStretch = clamp(accelForward * 0.0085, -0.32, 0.38)

		-- Deformação elipsoidal com conservação de volume (sX * sY * sZ = 1)
		local squeeze = wallSqueeze and 0.34 or 0
		local wob     = 0.055 * math.sin(clock * 11.0)
		local stretchZ = clamp(1 + 0.56 * spdFrac + accelStretch + squeeze * 0.45 + wob, 0.65, 1.95)
		local flattenY = clamp(0.80 - 0.18 * spdFrac - accelStretch * 0.28 + 0.14 * squeeze - wob * 0.5, 0.45, 1.15)
		local narrowX  = clamp(1 / (stretchZ * flattenY), 0.45, 1.35) * (1 - squeeze * 0.48)

		-- Inclinação hidrodinâmica proporcional à derivada da velocidade
		local pitchTilt = clamp(-accelForward * 0.0045 - spdFrac * 0.12, -0.34, 0.28)
		local orient    = CFrame.lookAt(dropPos, dropPos + lastDir) * CFrame.Angles(pitchTilt, 0, 0)

		Put(dropShell, orient, Vector3.new(R * narrowX, R * flattenY, R * stretchZ), 0.08)
		Put(dropMid,   orient * CFrame.new(0, -0.03, -0.05 * spdFrac), Vector3.new(R * narrowX * 0.84, R * flattenY * 0.84, R * stretchZ * 0.86), 0.0)

		local corePulse = 1 + 0.12 * math.sin(clock * 15.0)
		Put(dropCore, orient * CFrame.new(0, 0, 0.08 * spdFrac), Vector3.new(R * 0.54 * corePulse, R * 0.46 * corePulse, R * 0.64 * stretchZ), 0.0)

		-- Menisco de tensão superficial deslizando colado ao chão
		Put(surfaceCap, CylinderFloorCF(Vector3.new(dropPos.X, targetPos.Y - R * 0.38, dropPos.Z)),
			Vector3.new(0.05, R * narrowX * 1.12, R * stretchZ * 1.18), 0.04)

		-- Sub-gotas satélites com atraso elástico formando cauda viscosa
		for i, sd in ipairs(subDrops) do
			local lagDist   = (0.40 + i * 0.22) * (0.35 + 0.85 * spdFrac)
			local sideWob   = math.sin(clock * 12.0 + sd.phase) * 0.22 * (1 - 0.4 * spdFrac)
			local rightVec  = lastDir:Cross(Vector3.yAxis)
			local goal      = dropPos - lastDir * lagDist + rightVec * sideWob + Vector3.new(0, -0.08 * i, 0)
			local sAcc      = (goal - sd.pos) * (95 - i * 9) - sd.vel * 14
			sd.vel += sAcc * dt
			sd.pos += sd.vel * dt
			local sR = R * (0.44 - i * 0.055)
			Put(sd.part, CFrame.lookAt(sd.pos, dropPos), Vector3.new(sR * 0.9, sR * 0.78, sR * (1 + 0.40 * spdFrac)), 0.04)
		end

		trailTimer += dt * (0.45 + spdFrac * 1.8)
		if trailTimer >= 0.085 then
			trailTimer = 0
			local tr = Instance.new("Part")
			tr.Shape = Enum.PartType.Cylinder
			tr.Anchored = true
			tr.CanCollide = false
			tr.CanQuery = false
			tr.CanTouch = false
			tr.CastShadow = false
			tr.Material = Enum.Material.SmoothPlastic
			tr.Color = math.random() < 0.5 and COL.BloodDark or COL.Blood
			local w = rand(0.50, 1.00) * (0.65 + 0.55 * spdFrac)
			tr.Size = Vector3.new(0.04, w, w)
			tr.CFrame = CylinderFloorCF(Vector3.new(dropPos.X, targetPos.Y - R * 0.39, dropPos.Z))
			tr.Transparency = 0.14
			tr.Parent = ctx.folder
			TweenService:Create(tr, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.02, 0.08, 0.08),
				Transparency = 1,
			}):Play()
			Debris:AddItem(tr, 0.60)
		end
	end

	Animate(ctx, CFG.Noclip.Duration, function(_, _, dt)
		local moveInput = hum.MoveDirection
		local desiredVel = Vector3.new(moveInput.X, 0, moveInput.Z) * CFG.Noclip.Speed
		local accelRate = moveInput.Magnitude > 0.05 and 9.5 or 6.0
		prevVel = vel
		vel = vel:Lerp(desiredVel, 1 - math.exp(-dt * accelRate))
		local accelVec = (vel - prevVel) / math.max(dt, 1e-3)

		local gHit = Workspace:Raycast(root.Position + Vector3.new(0, 1.5, 0), Vector3.new(0, -14, 0), RayParams(ctx))
		if gHit then
			lockY = lerp(lockY, gHit.Position.Y + standOffset, 1 - math.exp(-dt * 12))
		end

		local yCorrection = (lockY - root.Position.Y) * 14
		lv.VectorVelocity = Vector3.new(vel.X, yCorrection, vel.Z)

		if vel.Magnitude > 0.4 then
			ao.CFrame = CFrame.lookAt(Vector3.zero, flat(vel))
		end

		local gPos = gHit and gHit.Position or (root.Position - Vector3.new(0, standOffset, 0))
		local targetDropPos = Vector3.new(root.Position.X, gPos.Y + R * 0.42, root.Position.Z)
		local insideWall = IsBoxBlocked(ctx, CFrame.new(root.Position), Vector3.new(1.4, 2.5, 1.4))
		StepDropletVisual(dt, targetDropPos, accelVec, insideWall)

		local spdFrac = clamp01(vel.Magnitude / CFG.Noclip.Speed)
		CamDirector:SetStage(Vector3.new(0, -1.65, 0.4 * spdFrac), 4 * spdFrac, 0, 11)
	end)

	-- 5. BUSCA DE PONTO SEGURO FORA DE PAREDES ANTES DE RECONSTRUIR
	local function StandCFAt(pos2D, dir)
		local g = GroundBelow(ctx, Vector3.new(pos2D.X, root.Position.Y + 2, pos2D.Z))
		local p = Vector3.new(pos2D.X, g.Y + standOffset, pos2D.Z)
		return CFrame.lookAt(p, p + flat(dir)), g
	end

	local exitCF, exitGround = StandCFAt(root.Position, lastDir)
	if IsBoxBlocked(ctx, exitCF, charBoxSize) then
		local found = false
		for radius = 2, 20, 2 do
			for a = 1, 12 do
				local ang = (a / 12) * TAU
				local testPos = root.Position + Vector3.new(math.cos(ang) * radius, 0, math.sin(ang) * radius)
				local candCF, candG = StandCFAt(testPos, lastDir)
				if not IsBoxBlocked(ctx, candCF, charBoxSize) then
					exitCF, exitGround = candCF, candG
					found = true
					break
				end
			end
			if found then break end
		end
		local slideStart = dropPos
		local slideEnd   = exitGround + Vector3.new(0, R * 0.42, 0)
		Animate(ctx, 0.24, function(p, _, dt)
			local cur = slideStart:Lerp(slideEnd, outCubic(p))
			root.CFrame = CFrame.new(cur.X, exitCF.Position.Y, cur.Z) * exitCF.Rotation
			StepDropletVisual(dt, cur, Vector3.zero, false)
		end)
	end

	lv:Destroy()
	ao:Destroy()
	att:Destroy()
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = exitCF

	-- 6. EXPANSÃO DA GOTA EM BASE BIOMECÂNICA E RECONSTRUÇÃO ASCENDENTE COMPLETA
	for _, sd in ipairs(subDrops) do sd.part.Transparency = 1 end
	surfaceCap.Transparency = 1

	Animate(ctx, 0.28, function(p)
		local k = outCubic(p)
		Put(dropShell, CFrame.new(exitGround + Vector3.new(0, lerp(R * 0.42, 0.14, k), 0)),
			Vector3.new(lerp(R, 3.8, k), lerp(R * 0.8, 0.20, k), lerp(R, 3.8, k)), 0.08)
		Put(dropMid, CFrame.new(exitGround + Vector3.new(0, lerp(R * 0.36, 0.10, k), 0)),
			Vector3.new(lerp(R * 0.8, 3.0, k), lerp(R * 0.65, 0.16, k), lerp(R * 0.8, 3.0, k)), 0.0)
		Put(dropCore, CFrame.new(exitGround + Vector3.new(0, lerp(R * 0.30, 0.08, k), 0)),
			Vector3.new(lerp(R * 0.55, 2.0, k), lerp(R * 0.45, 0.14, k), lerp(R * 0.55, 2.0, k)), 0.0)
	end)

	local anchorTendons = {
		NewTendonBundle(ctx, 2, true),
		NewTendonBundle(ctx, 2, true),
		NewTendonBundle(ctx, 2, true),
	}

	CamDirector:SetStage(Vector3.new(0.85, -0.45, -1.35), -5, 0.015, 10)
	local lowerT = GetLowerTorso()
	local upperT = GetUpperTorso()

	RebuildAnatomy(ctx, origBody, {
		{ parts = Group("LLeg"),  t0 = 0.00, dur = 1.38, anatomy = "Leg",   stagger = 0.20 },
		{ parts = Group("RLeg"),  t0 = 0.06, dur = 1.38, anatomy = "Leg",   stagger = 0.20 },
		{ parts = Group("Torso"), t0 = 0.28, dur = 1.32, anatomy = "Torso", stagger = 0.22 },
		{ parts = Group("LArm"),  anchorPart = upperT, t0 = 0.52, dur = 1.25, anatomy = "Arm", stagger = 0.18 },
		{ parts = Group("RArm"),  anchorPart = upperT, t0 = 0.58, dur = 1.25, anatomy = "Arm", stagger = 0.18 },
		{ parts = Group("Head"),  anchorPart = upperT, t0 = 0.78, dur = 1.15, anatomy = "Head", stagger = 0.15 },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		local poolFade = smooth(0.55, 0.96, k)
		local d = lerp(3.8, 0.5, k)
		Put(dropShell, CFrame.new(exitGround + Vector3.new(0, 0.08, 0)), Vector3.new(d, 0.14 * (1 - k), d), 0.08 + 0.92 * poolFade)
		Put(dropMid,   CFrame.new(exitGround + Vector3.new(0, 0.06, 0)), Vector3.new(d * 0.76, 0.10 * (1 - k), d * 0.76), poolFade)
		Put(dropCore,  CFrame.new(exitGround + Vector3.new(0, 0.04, 0)), Vector3.new(d * 0.50, 0.08 * (1 - k), d * 0.50), poolFade)

		-- Elevação progressiva do esqueleto emergindo da poça com postura de despertar orgânico
		local rise = smoother(0.0, 0.88, k)
		local arch = bell(inv(0.18, 0.86, k))
		root.CFrame = exitCF * CFrame.new(0, -0.58 * (1 - rise), 0) * CFrame.Angles(0.20 * arch, 0, 0)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0.24 * arch, 0, 0), 1, 0.4)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(-0.42 * arch, 0, 0.45 * arch), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-0.42 * arch, 0, -0.45 * arch), 1, 0.4)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.55 * arch, 0, 0), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.55 * arch, 0, 0), 1, 0.4)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(0.42 * arch, 0, 0), 1, 0.4)

		-- Filamentos de ancoragem puxando da poça até os quadris e tronco
		if k < 0.76 and lowerT then
			local fAlpha = smooth(0.52, 0.76, k)
			for idx, tb in ipairs(anchorTendons) do
				local ang = (idx / #anchorTendons) * TAU + t * 1.6
				local pA  = exitGround + Vector3.new(math.cos(ang) * d * 0.38, 0.05, math.sin(ang) * d * 0.38)
				local pB  = lowerT.Position + Vector3.new(math.cos(ang) * 0.45, -0.4, math.sin(ang) * 0.35)
				DrawTendonBundle(tb, pA, pB, 0.08, 0.08, 0.11, fAlpha, 0.45)
			end
		else
			for _, tb in ipairs(anchorTendons) do
				DrawTendonBundle(tb, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
			end
		end
	end)

	CamDirector:ClearStage()
	SetVisibility(origBody, 0)
	RestoreCollisions()
	pose:Reset(0.16)
	pose:SuppressDefaultAnimations(false)
	root.Anchored = false
	hum.PlatformStand = false
	hum.AutoRotate = true
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end

--------------------------------------------------------------------------------
-- 11. HABILIDADE 3: GRAPPLE / GANCHO (PREPARAÇÃO, TENSÃO, PÊNDULO FÍSICO E RETRAÇÃO)
--------------------------------------------------------------------------------
local aimCallback = nil
local SetBanner   = function(_) end

local function AbilityGrapple(ctx)
	local hum, root = S.hum, S.root
	local cam = Workspace.CurrentCamera

	S.cancelAim = false
	local chosenScreenPos = nil
	SetBanner("SELECIONE UM PONTO PARA O GANCHO (CLIQUE / TOQUE) — [R] CANCELAR")
	aimCallback = function(screenPos)
		chosenScreenPos = screenPos
	end
	ctx.maid:Add(function()
		aimCallback = nil
		SetBanner(nil)
	end)

	Animate(ctx, 5.5, function()
		return chosenScreenPos ~= nil or S.cancelAim
	end)
	aimCallback = nil
	SetBanner(nil)

	if S.cancelAim or not chosenScreenPos then
		return false
	end

	local ray = cam:ScreenPointToRay(chosenScreenPos.X, chosenScreenPos.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 580, RayParams(ctx))
	if not hit then
		return false
	end

	local targetPos  = hit.Position
	local targetNorm = hit.Normal
	if (targetPos - root.Position).Magnitude > CFG.Grapple.Range then
		SetBanner("ALVO FORA DE ALCANCE")
		task.delay(1.1, function()
			if S.busy == nil then SetBanner(nil) end
		end)
		return false
	end

	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local rArm = Group("RArm")
	local origArm = CaptureVisibility(rArm, "attached")
	ctx.maid:Add(function()
		SetVisibility(origArm, 0)
		if root and root.Parent then
			root.Anchored = false
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			hum.AutoRotate = true
		end
	end)

	local armLen, armW, armD = 0, 1.0, 1.0
	for _, p in ipairs(rArm) do
		armLen += p.Size.Y
		armW = p.Size.X
		armD = p.Size.Z
	end
	if armLen < 0.5 then armLen = 2.0 end

	local upperTorso = GetUpperTorso()
	local function GetShoulderWorldPos()
		if upperTorso and upperTorso.Parent then
			return (upperTorso.CFrame * CFrame.new(upperTorso.Size.X * 0.5 + armW * 0.35, upperTorso.Size.Y * 0.28, 0)).Position
		end
		return (root.CFrame * CFrame.new(1.35, 0.5, 0)).Position
	end

	-- Modelo articulado do braço projetado + garras de ancoragem + feixes tendíneos
	local samplePart = rArm[1]
	local armColor   = samplePart and samplePart.Color or COL.Bone
	local armMat     = samplePart and samplePart.Material or Enum.Material.SmoothPlastic

	local projUpper = FXPart(ctx, armColor, armMat)
	local projLower = FXPart(ctx, armColor, armMat)
	local projHand  = FXPart(ctx, armColor, armMat)
	local projBone  = FXPart(ctx, COL.Bone, Enum.Material.Slate)
	local woundRing = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local gripPad   = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)

	local gripFingers = {}
	for i = 1, 5 do
		gripFingers[i] = FXPart(ctx, i % 2 == 0 and COL.Bone or armColor, Enum.Material.Slate)
	end

	local tendon      = NewTendonBundle(ctx, QUALITY.strands + 1, true)
	local outerTendon = NewTendonBundle(ctx, 2, false)

	local function DrawProjectedArm(basePos, tipPos, spreadFingers)
		local segVec = tipPos - basePos
		local segLen = segVec.Magnitude
		if segLen < 0.05 then return end
		local dir = segVec / segLen
		local mid = basePos + dir * (segLen * 0.46)
		local handCenter = basePos + dir * (segLen * 0.88)

		local uCF = CFrame.lookAt((basePos + mid) * 0.5, mid) * CFrame.Angles(PI * 0.5, 0, 0)
		local lCF = CFrame.lookAt((mid + handCenter) * 0.5, handCenter) * CFrame.Angles(PI * 0.5, 0, 0)
		local hCF = CFrame.lookAt(handCenter, tipPos) * CFrame.Angles(PI * 0.5, 0, 0)

		Put(projUpper, uCF, Vector3.new(armW, segLen * 0.48, armD), 0)
		Put(projLower, lCF, Vector3.new(armW * 0.94, segLen * 0.44, armD * 0.94), 0)
		Put(projHand,  hCF, Vector3.new(armW * 1.06 + 0.14 * spreadFingers, segLen * 0.22, armD * 1.06 + 0.14 * spreadFingers), 0)
		Put(projBone,  uCF * CFrame.new(0, -segLen * 0.26, 0), Vector3.new(armW * 0.36, 0.34, armD * 0.36), 0)
	end

	-- 1. PREPARAÇÃO BIOMECÂNICA DO BRAÇO (Torção de tronco, recuo de ombro e mira)
	local initDir = flat(targetPos - root.Position)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + initDir)
	CamDirector:SetStage(Vector3.new(0.75, 0.15, 0.8), -4, -0.02, 14)

	Animate(ctx, 0.22, function(p)
		local k = inOutCubic(p)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.10 * k, -0.58 * k, 0), 1, 0.5)
		pose:SetJoint("RShoulder", Vector3.new(0, 0, 0.28 * k), CFrame.Angles(-0.78 * k, -0.45 * k, 0.42 * k), 1, 0.5)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(1.15 * k, 0, 0), 1, 0.5)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.55 * k, 0, -0.38 * k), 1, 0.5)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(0.12 * k, 0.48 * k, 0), 1, 0.5)
	end)

	-- Chicote explosivo de disparo
	SetVisibility(origArm, 1)
	EmitTissueMist(ctx, GetShoulderWorldPos(), 9)
	ShakeCamera(hum, 0.28, 0.18)
	CamDirector:SetStage(Vector3.new(0.65, 0.1, -0.9), 5, 0.02, 16)

	Animate(ctx, 0.08, function(p)
		local k = outQuart(p)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0.18 * k, 0.48 * k, 0), 1, 0.85)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-0.55 * k, 0, -0.35), 1, 0.85)
		local sh = GetShoulderWorldPos()
		local aimUnit = safeUnit(targetPos - sh, initDir)
		DrawProjectedArm(sh, sh + aimUnit * (armLen * (1 + 0.35 * k)), 0)
		Put(woundRing, CFrame.lookAt(sh, targetPos) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.18, armW * 0.92, armD * 0.92), 0)
	end)

	-- 2. LANÇAMENTO COM ACELERAÇÃO BALÍSTICA E EXTENSÃO PROGRESSIVA DE TENDÕES
	local dist0     = (targetPos - GetShoulderWorldPos()).Magnitude
	local flightDur = clamp(dist0 / 105, 0.18, 0.42)

	Animate(ctx, flightDur, function(p)
		local sh  = GetShoulderWorldPos()
		local dir = safeUnit(targetPos - sh, initDir)
		-- Curva com aceleração inicial intensa seguida de cravamento veloz
		local eased = outQuart(p)
		local arcLift = Vector3.new(0, bell(p) * math.min(dist0 * 0.065, 2.4), 0)
		local armBase = sh:Lerp(targetPos - dir * armLen, eased) + arcLift
		local armTip  = armBase + dir * armLen

		DrawProjectedArm(armBase, armTip, smooth(0.65, 1.0, p))
		Put(woundRing, CFrame.lookAt(sh, armBase) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.18, armW * 0.92, armD * 0.92), 0)

		DrawTendonBundle(tendon, sh, armBase, 0.42 * (1 - p * 0.6), 0.22, 0.17, 0, 0.18)
		DrawTendonBundle(outerTendon, sh, armBase, 0.55 * (1 - p * 0.5), 0.28, 0.11, 0, 0.10)

		if math.random() < 0.38 then
			SpawnPhysicalDrop(ctx, armBase, Vector3.new(rand(-4, 4), rand(0, 4), rand(-4, 4)), 0.10)
		end
	end)

	-- 3. CONEXÃO CONVINCENTE COM A SUPERFÍCIE (GARRAS DE ANCORAGEM + POEIRA)
	EmitDust(ctx, targetPos, 16, hit.Instance and hit.Instance.Color or COL.Dust)
	EmitTissueMist(ctx, targetPos, 8)
	ShakeCamera(hum, 0.30, 0.22)

	for _ = 1, 5 do
		SpawnPhysicalDrop(ctx, targetPos + targetNorm * 0.2, targetNorm * rand(4, 10) + Vector3.new(rand(-5, 5), rand(2, 7), rand(-5, 5)))
	end

	local surfRight = targetNorm:Cross(Vector3.yAxis)
	surfRight = surfRight.Magnitude > 1e-3 and surfRight.Unit or Vector3.xAxis
	local surfUp = surfRight:Cross(targetNorm).Unit
	local surfCF = CFrame.fromMatrix(targetPos + targetNorm * 0.05, surfRight, surfUp, -targetNorm)

	-- 4. TENSÃO ANTES DA PUXADA (Fibras esticam retas, vibram e puxam o ombro para frente)
	local preRootCF = root.CFrame
	CamDirector:SetStage(Vector3.new(0.5, 0.0, 1.1), -6, 0, 15)

	Animate(ctx, CFG.Grapple.PreTensionTime, function(p)
		local tension = outCubic(p)
		local sh  = GetShoulderWorldPos()
		local dir = safeUnit(targetPos - sh, initDir)

		local contractedLen = armLen * (1 - 0.16 * tension)
		local armBase = targetPos - dir * contractedLen
		DrawProjectedArm(armBase, targetPos, 1)
		Put(woundRing, CFrame.lookAt(sh, targetPos) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.18, armW * 0.92, armD * 0.92), 0)

		-- Placa muscular de aderência e 5 garras ósseas cravando na superfície
		local padScale = outBack(p, 1.45)
		Put(gripPad, surfCF * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.12, 1.35 * padScale, 1.35 * padScale), 0.04)
		for i, fg in ipairs(gripFingers) do
			local ang = (i / #gripFingers) * TAU + 0.35
			local fDir = (surfRight * math.cos(ang) + surfUp * math.sin(ang)).Unit
			local fPos = targetPos + targetNorm * 0.06 + fDir * (0.48 * padScale)
			Put(fg, CFrame.lookAt(fPos, targetPos - targetNorm * 0.18), Vector3.new(0.15, 0.15, 0.62 * padScale), 0)
		end

		-- Os tendões perdem toda a barriga (sag -> 0) e entram em vibração de alta frequência
		DrawTendonBundle(tendon, sh, armBase, 0.38, lerp(0.18, 0.04, tension), 0.19, 0, tension)
		DrawTendonBundle(outerTendon, sh, armBase, 0.45, lerp(0.22, 0.05, tension), 0.12, 0, tension)

		-- O corpo sofre um tranco inicial sendo puxado pela linha de força
		local jerk = inCubic(p) * 0.78
		root.CFrame = preRootCF + dir * jerk
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0.32 * tension, 0.42 * tension, 0), 1, 0.5)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-0.75 * tension, 0, -0.42), 1, 0.5)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(-0.28 * tension, 0, 0), 1, 0.5)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(-0.28 * tension, 0, 0), 1, 0.5)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.26 * tension, 0, 0), 1, 0.5)
	end)

	-- 5. TRAÇÃO FÍSICA COM BALANÇO PENDULAR, INÉRCIA E CONTROLE AERODINÂMICO
	ShakeCamera(hum, 0.38, 0.26)
	EmitDust(ctx, GroundBelow(ctx, root.Position), 14)

	hum.PlatformStand = true
	hum.AutoRotate = false

	local att = ctx.maid:Add(Instance.new("Attachment"))
	att.Parent = root
	local lv = ctx.maid:Add(Instance.new("LinearVelocity"))
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = 1e6
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root

	local ao = ctx.maid:Add(Instance.new("AlignOrientation"))
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.Responsiveness = 24
	ao.MaxTorque = 1e6
	ao.CFrame = root.CFrame.Rotation
	ao.Parent = root

	local stopOffset = targetNorm * 2.8 + Vector3.new(0, 1.0, 0)
	local pullDest   = targetPos + stopOffset
	local totalPullDist = math.max((pullDest - root.Position).Magnitude, 1)
	local curVel     = Vector3.zero

	Animate(ctx, 2.5, function(_, elapsed, dt)
		local toDest = pullDest - root.Position
		local rem    = toDest.Magnitude
		if rem < 3.4 or elapsed > 2.35 then
			return true
		end

		local dir = toDest / rem
		local q   = clamp01(1 - rem / totalPullDist)

		-- Curva de força de tração + arco pendular gravitacional + oscilação aerodinâmica
		local accelCurve  = smooth(0.0, 0.16, q) * (1 - 0.35 * smooth(0.76, 1.0, q))
		local speed       = CFG.Grapple.PullSpeed * (0.48 + 0.68 * accelCurve)
		local pendulumDip = Vector3.new(0, -20 * bell(clamp01(q * 1.4)) * (1 - q), 0)
		local swingRight  = dir:Cross(Vector3.yAxis)
		swingRight = swingRight.Magnitude > 1e-3 and swingRight.Unit or Vector3.xAxis
		local naturalSwing = swingRight * (math.sin(elapsed * 7.5) * 6.0 * bell(q))
		local steer        = hum.MoveDirection * 20

		local desiredVel = dir * speed + pendulumDip + naturalSwing + steer
		curVel = curVel:Lerp(desiredVel, 1 - math.exp(-dt * 11.5))
		lv.VectorVelocity = curVel

		local velDir    = safeUnit(curVel, dir)
		local swingRoll = clamp(-curVel:Dot(swingRight) * 0.020, -0.45, 0.45)
		local pullPitch = clamp(-0.55 * bell(q) - 0.18, -0.78, 0.25)
		ao.CFrame = CFrame.lookAt(Vector3.zero, flat(velDir)) * CFrame.Angles(pullPitch, 0, swingRoll)

		CamDirector:SetStage(Vector3.new(swingRoll * 1.6, 0.35, 2.4 * bell(q)), 11 * bell(q), swingRoll * 0.35, 12)

		-- Pose corporal reagindo ao vento e à força do cabo no ombro direito
		local legTrail = clamp01(curVel.Magnitude / CFG.Grapple.PullSpeed)
		local kneeWave = math.sin(elapsed * 15) * 0.16 * legTrail
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0.28 * legTrail, 0.38, -swingRoll * 0.5), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-0.95 * legTrail, 0, -0.48), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.55 * legTrail, 0, 0), 1, 0.4)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(-0.52 * legTrail + kneeWave, 0, 0.10), 1, 0.4)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(-0.68 * legTrail - kneeWave, 0, -0.10), 1, 0.4)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-0.58 * legTrail, 0, 0), 1, 0.4)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.78 * legTrail, 0, 0), 1, 0.4)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.35 * legTrail, -0.25, 0), 1, 0.4)

		local sh      = GetShoulderWorldPos()
		local armDir  = safeUnit(targetPos - sh, dir)
		local armBase = targetPos - armDir * (armLen * 0.90)
		DrawProjectedArm(armBase, targetPos, 1)
		Put(woundRing, CFrame.lookAt(sh, targetPos) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.18, armW * 0.92, armD * 0.92), 0)
		DrawTendonBundle(tendon, sh, armBase, 0.04, 0.05, 0.18, 0, 0.95)
		DrawTendonBundle(outerTendon, sh, armBase, 0.08, 0.09, 0.11, 0, 0.85)
	end)

	-- Liberação com preservação de inércia
	lv:Destroy()
	ao:Destroy()
	att:Destroy()
	hum.PlatformStand = false
	hum.AutoRotate = true
	root.AssemblyLinearVelocity = curVel * 0.30 + Vector3.new(0, 25, 0)

	-- 6. RECOLHIMENTO ELÁSTICO DO BRAÇO E RECONSTRUÇÃO ARTICULAR NO OMBRO
	gripPad.Transparency = 1
	for _, fg in ipairs(gripFingers) do fg.Transparency = 1 end
	CamDirector:SetStage(Vector3.new(0.85, 0.15, -0.85), -3, 0, 12)

	Animate(ctx, 0.24, function(p)
		local k = inOutQuad(p)
		local sh = GetShoulderWorldPos()
		local retractBase = targetPos:Lerp(sh, k)
		local dir = safeUnit(targetPos - sh, initDir)
		DrawProjectedArm(retractBase, retractBase + dir * (armLen * (1 - 0.55 * k)), 1 - k)
		Put(woundRing, CFrame.lookAt(sh, targetPos) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.18, armW * 0.92, armD * 0.92), 0)
		DrawTendonBundle(tendon, sh, retractBase, 0.28 * (1 - k), 0.18 * (1 - k), 0.16, k * 0.4, 0.3)
		DrawTendonBundle(outerTendon, sh, retractBase, 0.35 * (1 - k), 0.22 * (1 - k), 0.10, k * 0.6, 0.2)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.18 * bell(p), -0.32 * bell(p), 0), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.45 * bell(p), 0, -0.25), 1, 0.45)
	end)

	projUpper.Transparency = 1
	projLower.Transparency = 1
	projHand.Transparency  = 1
	projBone.Transparency  = 1
	DrawTendonBundle(tendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
	DrawTendonBundle(outerTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)

	-- Reconstrução e encaixe final do braço direito com reação de impacto no ombro
	EmitTissueMist(ctx, GetShoulderWorldPos(), 7)
	RebuildAnatomy(ctx, origArm, {
		{ parts = rArm, anchorPart = upperTorso, t0 = 0.0, dur = 0.78, anatomy = "Arm", stagger = 0.14 },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		local sh = GetShoulderWorldPos()
		Put(woundRing, CFrame.new(sh) * CFrame.Angles(0, 0, PI * 0.5), Vector3.new(0.18, armW * 0.92, armD * 0.92), smooth(0.45, 0.92, k))

		local snapImpact = bell(inv(0.60, 0.98, k))
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0, -0.22 * snapImpact, 0.10 * snapImpact), 1, 0.5)
		pose:SetJoint("RShoulder", Vector3.new(-0.10 * snapImpact, 0, 0), CFrame.Angles(0.55 * (1 - k) + 0.28 * snapImpact, 0, 0.25 * (1 - k)), 1, 0.5)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.75 * snapImpact, 0, 0), 1, 0.5)
		-- Mão esquerda segura o ombro direito enquanto ele se reconecta
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(1.15 * (1 - k * 0.5), 0.45 * (1 - k * 0.5), 0.55 * (1 - k * 0.5)), 1, 0.45)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(1.10 * (1 - k * 0.5), 0, 0), 1, 0.45)
	end)

	woundRing.Transparency = 1
	CamDirector:ClearStage()
	SetVisibility(origArm, 0)
	pose:Reset(0.14)
	pose:SuppressDefaultAnimations(false)
end

--------------------------------------------------------------------------------
-- 12. HABILIDADE 4: HEAD THROW (ARRANCAMENTO, VOO FÍSICO, QUIQUE E RECONSTRUÇÃO)
--------------------------------------------------------------------------------
local function AbilityHeadThrow(ctx)
	local hum, root = S.hum, S.root
	local cam = Workspace.CurrentCamera
	local headGroup = Group("Head")
	local realHead  = headGroup[1]
	if not realHead then return end

	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local origHead = CaptureVisibility(headGroup, "attached")
	local origCamSubject = cam.CameraSubject
	local origCamType    = cam.CameraType

	ctx.maid:Add(function()
		SetVisibility(origHead, 0)
		if cam then
			cam.CameraType = origCamType
			if S.hum and S.hum.Parent then
				cam.CameraSubject = S.hum
			elseif origCamSubject then
				cam.CameraSubject = origCamSubject
			end
		end
	end)

	local upperTorso = GetUpperTorso()
	local neckWound   = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local neckBone    = FXPart(ctx, COL.Bone, Enum.Material.Slate)
	local neckTrachea = FXPart(ctx, COL.Cartilage, Enum.Material.Slate)

	local function GetNeckWorldCF()
		if upperTorso and upperTorso.Parent then
			return upperTorso.CFrame * CFrame.new(0, upperTorso.Size.Y * 0.5, 0)
		end
		return root.CFrame * CFrame.new(0, 1.5, 0)
	end

	local function UpdateNeckStump(alpha)
		local nCF = GetNeckWorldCF()
		Put(neckWound,   nCF * CFrame.Angles(0, 0, PI * 0.5), Vector3.new(0.16, 0.92, 0.92), alpha)
		Put(neckBone,    nCF * CFrame.new(0, 0.15, 0.11), Vector3.new(0.24, 0.34, 0.24), alpha)
		Put(neckTrachea, nCF * CFrame.new(0, 0.11, -0.11), Vector3.new(0.20, 0.26, 0.20), alpha)
	end

	-- 1. PREPARAÇÃO E SEPARAÇÃO VISCERAL DA CABEÇA (Mãos agarram, torcem e tracionam o pescoço)
	local neckTendon = NewTendonBundle(ctx, 4, true)
	CamDirector:SetStage(Vector3.new(0.55, 0.45, -1.35), -6, 0.02, 14)

	Animate(ctx, 0.52, function(p)
		local grab = smooth(0.0, 0.35, p)
		local pull = inCubic(inv(0.28, 1.0, p))
		local strainTremor = math.sin(p * 52) * 0.075 * pull

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.22 * grab + 0.30 * pull, strainTremor * 0.5, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(2.62 * grab, -0.22 * grab, -0.40 * grab), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(2.62 * grab,  0.22 * grab,  0.40 * grab), 1, 0.45)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.92 * grab - 0.38 * pull, 0, 0), 1, 0.45)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.92 * grab - 0.38 * pull, 0, 0), 1, 0.45)

		-- A cabeça sobe descolando das vértebras cervicais enquanto os tendões esticam
		pose:SetJoint("Neck",
			Vector3.new(strainTremor * 0.3, 0.64 * pull, 0),
			CFrame.Angles(0.28 * pull, strainTremor * 1.6, 0.22 * pull),
			1, 0.65
		)

		if pull > 0.06 then
			UpdateNeckStump(0)
			local nPos = GetNeckWorldCF().Position
			local hBot = (realHead.CFrame * CFrame.new(0, -realHead.Size.Y * 0.46, 0)).Position
			DrawTendonBundle(neckTendon, nPos, hBot, 0.02, 0.07, 0.15, 0, pull)
		end
	end)

	-- Ruptura completa + Chicote de Arremesso Bimanual
	local aimDir = safeUnit(cam.CFrame.LookVector + Vector3.new(0, 0.12, 0), root.CFrame.LookVector)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + flat(aimDir))

	SetVisibility(origHead, 1)
	UpdateNeckStump(0)
	EmitTissueMist(ctx, GetNeckWorldCF().Position, 14)
	ShakeCamera(hum, 0.42, 0.28)
	for _ = 1, 8 do
		SpawnPhysicalDrop(ctx, GetNeckWorldCF().Position, Vector3.new(rand(-8, 8), rand(3, 11), rand(-8, 8)))
	end

	-- Constrói o modelo físico da cabeça lançada com todos os acessórios/cabelos/chapéus preservados
	local thrownModel = Instance.new("Model")
	thrownModel.Name = "ThrownHeadModel"
	thrownModel.Parent = ctx.folder

	local hClone = realHead:Clone()
	for _, d in ipairs(hClone:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Motor6D") or d:IsA("Weld") then
			d:Destroy()
		end
	end
	hClone.Transparency = origHead[realHead] or 0
	hClone.Anchored = true
	hClone.CanCollide = false
	hClone.CanQuery = false
	hClone.CanTouch = false
	hClone.Parent = thrownModel

	local neckCap = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	neckCap.Transparency = 0
	neckCap.Parent = thrownModel
	local cervicalStub = FXPart(ctx, COL.Bone, Enum.Material.Slate)
	cervicalStub.Transparency = 0
	cervicalStub.Parent = thrownModel

	local accAttachments = {}
	for _, acc in ipairs(S.char:GetChildren()) do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle")
			if handle and origHead[handle] ~= nil then
				local ac = handle:Clone()
				ac:ClearAllChildren()
				for _, child in ipairs(handle:GetChildren()) do
					if child:IsA("SpecialMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
						child:Clone().Parent = ac
					end
				end
				ac.Transparency = origHead[handle] or 0
				ac.Anchored = true
				ac.CanCollide = false
				ac.CanQuery = false
				ac.CanTouch = false
				ac.Parent = thrownModel
				table.insert(accAttachments, {
					part  = ac,
					relCF = realHead.CFrame:ToObjectSpace(handle.CFrame),
					origSize = handle.Size,
				})
			end
		end
	end

	local baseHeadSize = hClone.Size
	local headRadius   = math.max(baseHeadSize.X, baseHeadSize.Y, baseHeadSize.Z) * 0.52

	local function SetThrownHeadTransform(cf, squashVec)
		squashVec = squashVec or Vector3.one
		hClone.Size = Vector3.new(baseHeadSize.X * squashVec.X, baseHeadSize.Y * squashVec.Y, baseHeadSize.Z * squashVec.Z)
		hClone.CFrame = cf
		Put(neckCap, cf * CFrame.new(0, -hClone.Size.Y * 0.48, 0) * CFrame.Angles(0, 0, PI * 0.5),
			Vector3.new(0.14, hClone.Size.X * 0.72, hClone.Size.Z * 0.72), 0)
		Put(cervicalStub, cf * CFrame.new(0, -hClone.Size.Y * 0.58, 0.05),
			Vector3.new(0.22, 0.26, 0.22), 0)
		for _, item in ipairs(accAttachments) do
			local rPos = item.relCF.Position
			local scaledRel = CFrame.new(rPos.X * squashVec.X, rPos.Y * squashVec.Y, rPos.Z * squashVec.Z) * item.relCF.Rotation
			item.part.Size = Vector3.new(item.origSize.X * squashVec.X, item.origSize.Y * squashVec.Y, item.origSize.Z * squashVec.Z)
			item.part.CFrame = cf * scaledRel
		end
	end

	-- Chicote de lançamento (0.12s)
	local startThrowPos = GetNeckWorldCF().Position + Vector3.new(0, 0.75, 0)
	Animate(ctx, 0.12, function(p)
		local k = outQuart(p)
		UpdateNeckStump(0)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(lerp(0.28, -0.38, k), 0, 0), 1, 0.8)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(2.62, 1.05, k), 0, 0.28), 1, 0.8)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(2.62, 1.05, k), 0, -0.28), 1, 0.8)
		local hPos = startThrowPos + aimDir * (1.75 * k)
		SetThrownHeadTransform(CFrame.lookAt(hPos, hPos + aimDir))
		DrawTendonBundle(neckTendon, GetNeckWorldCF().Position, hPos, 0.05, 0.16, 0.13, k, 0.9)
	end)
	DrawTendonBundle(neckTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)

	-- 2. TRAJETÓRIA BALÍSTICA FÍSICA, ROTAÇÃO NATURAL, IMPACTO, QUIQUE E ROLAGEM
	local headPos = startThrowPos + aimDir * 1.75
	local headVel = aimDir * CFG.HeadThrow.Speed + Vector3.new(0, CFG.HeadThrow.UpwardBias, 0)
	local headRot = CFrame.lookAt(Vector3.zero, aimDir)
	local angVel  = Vector3.new(-12.5, rand(-3.5, 3.5), rand(-2.5, 2.5))

	local rp          = RayParams(ctx, { thrownModel })
	local bounces     = 0
	local bounceSquashTimer = 0
	local settledTime = nil
	local camFocus    = headPos
	local camLookDir  = flat(aimDir)

	cam.CameraType = Enum.CameraType.Scriptable

	Animate(ctx, CFG.HeadThrow.MaxFlightTime, function(_, elapsed, dt)
		UpdateNeckStump(0)

		-- Corpo sem cabeça mantém postura reativa e recupera do arremesso
		local bodyRecover = smooth(0.0, 0.55, elapsed)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(lerp(-0.38, -0.06, bodyRecover), 0, 0), 1, 0.35)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(1.05, 0.22, bodyRecover), 0, 0.18), 1, 0.35)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(1.05, 0.22, bodyRecover), 0, -0.18), 1, 0.35)

		headVel -= Vector3.new(0, CFG.HeadThrow.Gravity * dt, 0)
		headVel *= (1 - 0.15 * dt)

		local step = headVel * dt
		if step.Magnitude > 1e-4 then
			local hit = Workspace:Raycast(headPos, step.Unit * (step.Magnitude + headRadius), rp)
			if hit then
				bounces += 1
				local n = hit.Normal
				headPos = hit.Position + n * headRadius

				local vDotN = headVel:Dot(n)
				local vNorm = n * vDotN
				local vTang = headVel - vNorm

				if math.abs(vDotN) > 10 then
					bounceSquashTimer = 0.18
					local hitCol = hit.Instance and hit.Instance.Color or COL.Dust
					EmitDust(ctx, hit.Position, math.clamp(math.floor(math.abs(vDotN) * 0.16), 4, 16), hitCol)
					EmitTissueMist(ctx, hit.Position, 5)
					for _ = 1, 3 do
						SpawnPhysicalDrop(ctx, hit.Position + n * 0.15, n * rand(3, 8) + Vector3.new(rand(-5, 5), rand(2, 6), rand(-5, 5)), 0.10)
					end
					if bounces == 1 then
						ShakeCamera(hum, 0.32, 0.22)
					end
				end

				-- Coeficiente de restituição e atrito com rolagem física real sobre o solo
				local restitution = bounces == 1 and 0.48 or (bounces == 2 and 0.35 or 0.22)
				local friction    = bounces == 1 and 0.75 or 0.62
				headVel = vTang * friction - vNorm * restitution

				if vTang.Magnitude > 0.5 then
					local rollAxis = n:Cross(vTang.Unit)
					angVel = rollAxis * (vTang.Magnitude / math.max(headRadius, 0.4))
				else
					angVel *= 0.45
				end

				if headVel.Magnitude < 5.5 and n.Y > 0.5 then
					headVel = Vector3.new(headVel.X * 0.65, 0, headVel.Z * 0.65)
					if not settledTime then
						settledTime = elapsed
					end
				end
			else
				headPos += step
			end
		end

		local angMag = angVel.Magnitude
		if angMag > 1e-3 then
			headRot = CFrame.fromAxisAngle(angVel.Unit, angMag * dt) * headRot
		end

		local squashVec = Vector3.one
		if bounceSquashTimer > 0 then
			bounceSquashTimer = math.max(0, bounceSquashTimer - dt)
			local s = math.sin((bounceSquashTimer / 0.18) * PI) * 0.30
			squashVec = Vector3.new(1 + s * 0.65, 1 - s, 1 + s * 0.65)
		end

		SetThrownHeadTransform(CFrame.new(headPos) * headRot, squashVec)

		if math.random() < 0.28 and headVel.Magnitude > 14 then
			SpawnPhysicalDrop(ctx, headPos, Vector3.new(rand(-3, 3), rand(0, 3), rand(-3, 3)), 0.09)
		end

		-- Câmera acompanha a trajetória da cabeça com suavização exponencial e prevenção de colisão
		camFocus = camFocus:Lerp(headPos, 1 - math.exp(-dt * 18))
		local horizVel = Vector3.new(headVel.X, 0, headVel.Z)
		if horizVel.Magnitude > 3.5 then
			camLookDir = safeUnit(camLookDir:Lerp(horizVel.Unit, 1 - math.exp(-dt * 6)), camLookDir)
		end
		local desiredCamPos = camFocus - flat(camLookDir) * 8.2 + Vector3.new(0, 3.2, 0)
		local camHit = Workspace:Raycast(camFocus, desiredCamPos - camFocus, rp)
		local finalCamPos = camHit and (camHit.Position + camHit.Normal * 0.6) or desiredCamPos
		cam.CFrame = CFrame.lookAt(finalCamPos, camFocus)

		if settledTime and (elapsed - settledTime) >= CFG.HeadThrow.PostImpactWait then
			return true
		end
	end)

	if not settledTime then
		Wait(ctx, CFG.HeadThrow.PostImpactWait * 0.5)
	end

	-- 3. TRANSIÇÃO DE CÂMERA DE VOLTA AO PESCOÇO + DESINTEGRAÇÃO ORGÂNICA DA CABEÇA DESCARTADA
	local returnStartCam = cam.CFrame
	local charCamLook    = flat(root.CFrame.LookVector)
	Animate(ctx, 0.36, function(p)
		UpdateNeckStump(0)
		local k = smoother(0, 1, p)
		local neckFocus  = GetNeckWorldCF().Position + Vector3.new(0, 0.55, 0)
		local charCamGoal = CFrame.lookAt(neckFocus - charCamLook * 6.8 + Vector3.new(0, 1.8, 0), neckFocus)
		cam.CFrame = returnStartCam:Lerp(charCamGoal, k)

		for _, d in ipairs(thrownModel:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = lerp(0, 1, p)
			end
		end
	end)
	thrownModel:Destroy()

	cam.CameraType = origCamType
	if S.hum and S.hum.Parent then
		cam.CameraSubject = S.hum
	end

	-- 4. RECONSTRUÇÃO DETALHADA DO PESCOÇO E CABEÇA + ENCAIXE CERVICAL FINAL
	CamDirector:SetStage(Vector3.new(0.45, 0.55, -1.55), -7, 0, 12)
	local neckBridge = NewTendonBundle(ctx, 3, true)

	RebuildAnatomy(ctx, origHead, {
		{ parts = headGroup, anchorPart = upperTorso, t0 = 0.0, dur = 1.55, anatomy = "Head" },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		UpdateNeckStump(smooth(0.62, 0.94, k))

		local nPos = GetNeckWorldCF().Position
		local hPos = realHead.Position
		if k < 0.80 then
			DrawTendonBundle(neckBridge, nPos, hPos, 0.02, 0.06, 0.13, smooth(0.58, 0.80, k), 0.55)
		else
			DrawTendonBundle(neckBridge, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
		end

		-- As mãos sobem até a base da mandíbula acompanhando e estabilizando o crânio em formação
		local cradle = bell(inv(0.12, 0.90, k))
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(0.12 * cradle, 0, 0), 1, 0.4)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(1.75 * cradle, -0.22 * cradle, -0.32 * cradle), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(1.75 * cradle,  0.22 * cradle,  0.32 * cradle), 1, 0.4)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(1.18 * cradle, 0, 0), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(1.18 * cradle, 0, 0), 1, 0.4)
	end)

	UpdateNeckStump(1)
	SetVisibility(origHead, 0)

	-- Estalo e estabilização mecânica das vértebras cervicais
	ShakeCamera(hum, 0.22, 0.20)
	Animate(ctx, 0.28, function(p)
		local snap = outBack(p, 1.65)
		local rem  = 1 - clamp01(p)
		local rollSnap  = math.sin(p * PI * 2) * 0.24 * rem
		local pitchSnap = (1 - snap) * 0.34
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(pitchSnap, rollSnap * 0.6, rollSnap), 1, 0.6)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.55 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.55 * rem, 0, 0), 1, 0.45)
	end)

	CamDirector:ClearStage()
	pose:Reset(0.12)
	pose:SuppressDefaultAnimations(false)
end

--------------------------------------------------------------------------------
-- 13. HABILIDADE 5: ARM CONTROL (ARRANCAMENTO E CONTROLE DO BRAÇO COMO CRIATURA)
--------------------------------------------------------------------------------
local function AbilityArmControl(ctx)
	local hum, root = S.hum, S.root
	local cam = Workspace.CurrentCamera
	local lArm = Group("LArm")
	if #lArm == 0 then return end

	S.endEarly = false
	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local origArm = CaptureVisibility(lArm, "attached")
	local origCamSubject = cam.CameraSubject
	local origCamType    = cam.CameraType

	ctx.maid:Add(function()
		SetVisibility(origArm, 0)
		SetBanner(nil)
		if root and root.Parent then
			root.Anchored = false
		end
		if cam then
			cam.CameraType = origCamType
			if S.hum and S.hum.Parent then
				cam.CameraSubject = S.hum
			elseif origCamSubject then
				cam.CameraSubject = origCamSubject
			end
		end
	end)

	local upperTorso = GetUpperTorso()
	local armW = lArm[1].Size.X
	local armD = lArm[1].Size.Z
	local armLen = 0
	for _, p in ipairs(lArm) do armLen += p.Size.Y end
	if armLen < 0.5 then armLen = 2.0 end

	local function GetLeftShoulderWorldCF()
		if upperTorso and upperTorso.Parent then
			return upperTorso.CFrame * CFrame.new(-(upperTorso.Size.X * 0.5 + armW * 0.35), upperTorso.Size.Y * 0.25, 0)
		end
		return root.CFrame * CFrame.new(-1.35, 0.45, 0)
	end

	local shoulderWound = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local shoulderBone  = FXPart(ctx, COL.Bone, Enum.Material.Slate)

	local function UpdateShoulderStump(alpha)
		local sCF = GetLeftShoulderWorldCF()
		Put(shoulderWound, sCF, Vector3.new(0.18, armW * 0.88, armD * 0.88), alpha)
		Put(shoulderBone,  sCF * CFrame.new(-0.14, 0, 0), Vector3.new(0.28, 0.24, 0.24), alpha)
	end

	-- 1. MÃO DIREITA AGARRA E ARRANCA O BRAÇO ESQUERDO COM RESISTÊNCIA
	local ripTendon = NewTendonBundle(ctx, 3, true)
	CamDirector:SetStage(Vector3.new(-0.65, 0.25, -1.2), -5, -0.02, 14)

	Animate(ctx, 0.48, function(p)
		local grab = smooth(0.0, 0.35, p)
		local pull = inCubic(inv(0.30, 1.0, p))
		local shake = math.sin(p * 48) * 0.065 * pull

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.15 * grab, 0.44 * grab - 0.58 * pull, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(1.38 * grab, 0.58 * grab, -0.78 * grab + 0.52 * pull), 1, 0.45)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(0.95 * grab - 0.32 * pull, 0, 0), 1, 0.45)
		pose:SetJoint("LShoulder",
			Vector3.new(-0.68 * pull, -0.15 * pull, -0.28 * pull),
			CFrame.Angles(0.48 * pull + shake, 0, -0.68 * pull),
			1, 0.55
		)
		pose:SetJoint("Neck", Vector3.zero, CFrame.Angles(-0.22, 0.48 * grab, 0), 1, 0.45)

		if pull > 0.08 then
			UpdateShoulderStump(0)
			local sPos = GetLeftShoulderWorldCF().Position
			local aPos = lArm[1].Position
			DrawTendonBundle(ripTendon, sPos, aPos, 0.05, 0.09, 0.14, 0, pull)
		end
	end)

	DrawTendonBundle(ripTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
	SetVisibility(origArm, 1)
	UpdateShoulderStump(0)
	EmitTissueMist(ctx, GetLeftShoulderWorldCF().Position, 11)
	ShakeCamera(hum, 0.36, 0.24)
	CamDirector:ClearStage()

	for _ = 1, 6 do
		SpawnPhysicalDrop(ctx, GetLeftShoulderWorldCF().Position, Vector3.new(rand(-7, 7), rand(2, 8), rand(-7, 7)))
	end

	-- 2. CONSTRUÇÃO DO RIG ARTICULADO DO BRAÇO CONTROLÁVEL (ÚMERO, ANTEBRAÇO, MÃO E DEDOS)
	local armColor = lArm[1].Color
	local armMat   = lArm[1].Material
	local segUpper = FXPart(ctx, armColor, armMat)
	local segLower = FXPart(ctx, armColor, armMat)
	local segHand  = FXPart(ctx, armColor, armMat)
	local segBone  = FXPart(ctx, COL.Bone, Enum.Material.Slate)
	local segWound = FXPart(ctx, COL.MuscleDeep, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local tailTendon = NewTendonBundle(ctx, 2, true)

	local armDir      = flat(root.CFrame.LookVector)
	local startG      = GroundBelow(ctx, GetLeftShoulderWorldCF().Position + armDir * 2.0)
	local armPos      = Vector3.new(GetLeftShoulderWorldCF().Position.X + armDir.X * 1.6, startG.Y + 0.38, GetLeftShoulderWorldCF().Position.Z + armDir.Z * 1.6)
	local armVel      = armDir * 14 + Vector3.new(0, 6, 0)
	local crawlCycle  = 0
	local grounded    = false
	local hopRequested = false

	ctx.maid:Add(UIS.JumpRequest:Connect(function()
		hopRequested = true
	end))

	SetBanner("CONTROLANDO O BRAÇO (WASD / ESPAÇO PARA SALTAR) — [G] RECONECTAR")

	local function RenderCrawlingArm(pos, dir, archAngle, clawGrab, rollTilt)
		local fDir = flat(dir)
		local right = fDir:Cross(Vector3.yAxis)
		right = right.Magnitude > 1e-3 and right.Unit or Vector3.xAxis

		local uLen = armLen * 0.44
		local lLen = armLen * 0.40
		local hLen = armLen * 0.22

		local elbowHeight = 0.24 + math.sin(archAngle) * 0.46
		local backPos  = pos - fDir * (uLen * 0.72) + Vector3.new(0, 0.20, 0)
		local elbowPos = pos + Vector3.new(0, elbowHeight, 0) + right * (rollTilt * 0.16)
		local wristPos = pos + fDir * (lLen * 0.78) + Vector3.new(0, 0.14 + math.max(0, -math.sin(archAngle)) * 0.22, 0)
		local tipPos   = wristPos + fDir * hLen - Vector3.new(0, 0.08 * clawGrab, 0)

		local uCF = CFrame.lookAt((backPos + elbowPos) * 0.5, elbowPos) * CFrame.Angles(PI * 0.5, 0, 0)
		local lCF = CFrame.lookAt((elbowPos + wristPos) * 0.5, wristPos) * CFrame.Angles(PI * 0.5, 0, 0)
		local hCF = CFrame.lookAt((wristPos + tipPos) * 0.5, tipPos) * CFrame.Angles(PI * 0.5 + 0.32 * clawGrab, 0, 0)

		Put(segUpper, uCF, Vector3.new(armW * 0.92, (elbowPos - backPos).Magnitude + 0.12, armD * 0.92), 0)
		Put(segLower, lCF, Vector3.new(armW * 0.86, (wristPos - elbowPos).Magnitude + 0.12, armD * 0.86), 0)
		Put(segHand,  hCF, Vector3.new(armW * 0.96, hLen + 0.10, armD * 0.84), 0)
		Put(segWound, CFrame.lookAt(backPos, elbowPos) * CFrame.Angles(0, PI * 0.5, 0), Vector3.new(0.14, armW * 0.84, armD * 0.84), 0)
		Put(segBone,  CFrame.lookAt(backPos - fDir * 0.15, backPos), Vector3.new(0.20, 0.20, 0.34), 0)

		local tailEnd = backPos - fDir * 0.80 - Vector3.new(0, 0.08, 0)
		DrawTendonBundle(tailTendon, backPos, tailEnd, 0.06, 0.09, 0.09, 0.08, 0.25)
	end

	-- 3. LOOP DE LOCOMOÇÃO INTERATIVA DO BRAÇO
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	cam.CameraType = Enum.CameraType.Scriptable
	local camFocus = armPos
	local camLook  = armDir
	local rp       = RayParams(ctx)
	local lastDustStep = 0

	Animate(ctx, CFG.ArmControl.Duration, function(_, elapsed, dt)
		if S.endEarly then return true end
		UpdateShoulderStump(0)

		local breath = math.sin(elapsed * 3.5) * 0.04
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.12 + breath, 0.15, -0.08), 1, 0.3)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.95, 0.42, -0.58), 1, 0.3)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(1.12, 0, 0), 1, 0.3)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.26, 0.22, 0), 1, 0.3)

		local moveInput = hum.MoveDirection
		local inputMag  = clamp01(moveInput.Magnitude)
		if inputMag > 0.04 then
			armDir = safeUnit(armDir:Lerp(flat(moveInput), 1 - math.exp(-dt * 9.5)), armDir)
		end

		local gPos, _, _, gCol = GroundBelow(ctx, armPos, 18)
		local floorY = gPos.Y + 0.28

		if armPos.Y <= floorY + 0.08 and armVel.Y <= 0.5 then
			armPos = Vector3.new(armPos.X, floorY, armPos.Z)
			grounded = true
			if hopRequested then
				hopRequested = false
				grounded = false
				armVel = armDir * (CFG.ArmControl.CrawlSpeed * 1.18) + Vector3.new(0, CFG.ArmControl.HopImpulse, 0)
				EmitDust(ctx, gPos, 8, gCol)
			else
				crawlCycle += dt * (inputMag > 0.05 and lerp(3.2, 11.8, inputMag) or 1.6)
				local pullPhase = math.max(0, math.sin(crawlCycle))
				local targetSpd = CFG.ArmControl.CrawlSpeed * inputMag * (0.38 + 0.90 * pullPhase)
				local targetHVel = armDir * targetSpd
				armVel = Vector3.new(
					lerp(armVel.X, targetHVel.X, 1 - math.exp(-dt * 10)),
					0,
					lerp(armVel.Z, targetHVel.Z, 1 - math.exp(-dt * 10))
				)

				local stepSign = math.sin(crawlCycle) >= 0 and 1 or -1
				if inputMag > 0.15 and stepSign ~= lastDustStep and stepSign == 1 then
					lastDustStep = stepSign
					EmitDust(ctx, gPos, 4, gCol)
				end
			end
		else
			hopRequested = false
			grounded = false
			armVel -= Vector3.new(0, 98 * dt, 0)
			if inputMag > 0.05 then
				armVel += Vector3.new(armDir.X, 0, armDir.Z) * (25 * dt)
			end
		end

		local step = armVel * dt
		if step.Magnitude > 1e-4 then
			local wallHit = Workspace:Raycast(armPos + Vector3.new(0, 0.2, 0), step.Unit * (step.Magnitude + 0.75), rp)
			if wallHit and wallHit.Normal.Y < 0.5 then
				if grounded and inputMag > 0.1 then
					armPos += Vector3.new(0, 10 * dt, 0)
				else
					armVel = armVel - 1.5 * armVel:Dot(wallHit.Normal) * wallHit.Normal
				end
			else
				armPos += step
			end
		end

		local arch     = grounded and (math.sin(crawlCycle) * 0.85 * inputMag + 0.25) or -0.35
		local claw     = grounded and math.max(0, math.cos(crawlCycle)) or 0.8
		local rollTilt = math.sin(crawlCycle) * 0.35 * inputMag
		RenderCrawlingArm(armPos, armDir, arch, claw, rollTilt)

		camFocus = camFocus:Lerp(armPos + Vector3.new(0, 0.4, 0), 1 - math.exp(-dt * 16))
		camLook  = safeUnit(camLook:Lerp(armDir, 1 - math.exp(-dt * 7)), armDir)
		local desiredCam = camFocus - flat(camLook) * 6.2 + Vector3.new(0, 2.4, 0)
		local cHit = Workspace:Raycast(camFocus, desiredCam - camFocus, rp)
		local finalCam = cHit and (cHit.Position + cHit.Normal * 0.5) or desiredCam
		cam.CFrame = CFrame.lookAt(finalCam, camFocus)
	end)

	SetBanner(nil)

	-- 4. RETORNO COM TENDÕES OU RECONSTRUÇÃO COMPLETA NO OMBRO
	local sPos = GetLeftShoulderWorldCF().Position
	local distToBody = (armPos - sPos).Magnitude
	local reconnectTendon = NewTendonBundle(ctx, 3, true)
	local startCam = cam.CFrame
	local charLook = flat(root.CFrame.LookVector)

	Animate(ctx, 0.36, function(p)
		local k = inOutQuad(p)
		UpdateShoulderStump(0)
		local goalCam = CFrame.lookAt(root.Position - charLook * 8.5 + Vector3.new(0, 2.4, 0), root.Position + Vector3.new(0, 1.2, 0))
		cam.CFrame = startCam:Lerp(goalCam, k)

		if distToBody < 30 then
			local cur = armPos:Lerp(sPos, k) + Vector3.new(0, bell(p) * 2.2, 0)
			RenderCrawlingArm(cur, safeUnit(sPos - armPos, armDir), 0.2, 0, 0)
			DrawTendonBundle(reconnectTendon, sPos, cur, 0.12 * (1 - k), 0.10, 0.14, 0, k)
		else
			segUpper.Transparency = p
			segLower.Transparency = p
			segHand.Transparency  = p
			segBone.Transparency  = p
			segWound.Transparency = p
			DrawTendonBundle(tailTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
		end
	end)

	segUpper.Transparency = 1
	segLower.Transparency = 1
	segHand.Transparency  = 1
	segBone.Transparency  = 1
	segWound.Transparency = 1
	DrawTendonBundle(tailTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
	DrawTendonBundle(reconnectTendon, Vector3.zero, Vector3.zero, 0, 0, 0, 1)

	cam.CameraType = origCamType
	if S.hum and S.hum.Parent then
		cam.CameraSubject = S.hum
	end

	CamDirector:SetStage(Vector3.new(-0.75, 0.2, -1.1), -5, 0, 12)
	RebuildAnatomy(ctx, origArm, {
		{ parts = lArm, anchorPart = upperTorso, t0 = 0.0, dur = 1.22, anatomy = "Arm", stagger = 0.18 },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		UpdateShoulderStump(smooth(0.55, 0.90, k))
		local flex = bell(inv(0.50, 0.96, k))
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.68 * flex, 0, -0.38 * flex), 1, 0.45)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(0.90 * flex, 0, 0), 1, 0.45)
	end)

	UpdateShoulderStump(1)
	CamDirector:ClearStage()
	SetVisibility(origArm, 0)
	pose:Reset(0.14)
	pose:SuppressDefaultAnimations(false)
	root.Anchored = false
end

--------------------------------------------------------------------------------
-- 14. HABILIDADE 6: ACCELERATED REGEN (HIPER-REGENERAÇÃO CORPORAL EM PÉ)
--------------------------------------------------------------------------------
local function AbilityAcceleratedRegen(ctx)
	local hum, root = S.hum, S.root
	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local limbs = Concat(Group("LArm"), Group("RArm"), Group("LLeg"), Group("RLeg"))
	local allBody = Concat(Group("Torso"), Group("Head"), limbs)
	local origBody = CaptureVisibility(allBody, true)

	ctx.maid:Add(function()
		SetVisibility(origBody, 0)
		if root and root.Parent then
			root.Anchored = false
		end
	end)

	root.Anchored = true
	local baseCF = root.CFrame
	CamDirector:SetStage(Vector3.new(0, -0.35, -1.5), -7, 0, 12)

	-- 1. CONTRAÇÃO MUSCULAR DE ALTA TENSÃO E EXPULSÃO DE TECIDO DANIFICADO
	Animate(ctx, 0.40, function(p)
		local k = outCubic(p)
		local tr = 0.042 * p * p
		root.CFrame = baseCF * CFrame.new(rand(-tr, tr), -0.46 * k, rand(-tr, tr)) * CFrame.Angles(-0.28 * k, 0, 0)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.34 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(1.15 * k, 0, -0.52 * k), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(1.15 * k, 0,  0.52 * k), 1, 0.45)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(1.28 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(1.28 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.55 * k, 0, 0.10 * k), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.55 * k, 0, -0.10 * k), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-0.85 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.85 * k, 0, 0), 1, 0.45)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(-0.48 * k, 0, 0), 1, 0.45)
	end)

	-- Pulso mecânico de renovação celular (Zero Neon / Zero Luzes)
	EmitDust(ctx, GroundBelow(ctx, root.Position), 20)
	EmitTissueMist(ctx, root.Position, 18)
	ShakeCamera(hum, 0.46, 0.34)
	CamDirector:SetStage(Vector3.new(0.95, 0.15, -1.2), -4, 0.02, 10)

	for _, p in ipairs(limbs) do
		for _ = 1, 2 do
			local outDir = safeUnit(p.Position - root.Position, Vector3.yAxis)
			SpawnPhysicalDrop(ctx, p.Position, outDir * rand(5, 12) + Vector3.new(0, rand(2, 7), 0), rand(0.11, 0.19))
		end
	end

	-- 2. RECONSTRUÇÃO SIMULTÂNEA ACELERADA DE TODAS AS CAMADAS ANATÔMICAS
	local upperT = GetUpperTorso()
	local lowerT = GetLowerTorso()
	local crossTendonL = NewTendonBundle(ctx, 2, true)
	local crossTendonR = NewTendonBundle(ctx, 2, true)

	local startHealth = hum.Health
	local maxHealth   = hum.MaxHealth

	RebuildAnatomy(ctx, origBody, {
		{ parts = Group("Torso"), t0 = 0.00, dur = 1.28, anatomy = "Torso", stagger = 0.14 },
		{ parts = Group("LArm"),  anchorPart = upperT, t0 = 0.12, dur = 1.38, anatomy = "Arm", stagger = 0.16 },
		{ parts = Group("RArm"),  anchorPart = upperT, t0 = 0.14, dur = 1.38, anatomy = "Arm", stagger = 0.16 },
		{ parts = Group("LLeg"),  anchorPart = lowerT, t0 = 0.18, dur = 1.38, anatomy = "Leg", stagger = 0.16 },
		{ parts = Group("RLeg"),  anchorPart = lowerT, t0 = 0.20, dur = 1.38, anatomy = "Leg", stagger = 0.16 },
		{ parts = Group("Head"),  anchorPart = upperT, t0 = 0.24, dur = 1.24, anatomy = "Head" },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		pcall(function()
			hum.Health = math.min(maxHealth, lerp(startHealth, maxHealth, k))
		end)
		S.integrity = clamp01(lerp(S.integrity, 1.0, k))

		local surge = smooth(0.18, 0.86, k)
		local vib   = (1 - k) * 0.032
		root.CFrame = baseCF
			* CFrame.new(rand(-vib, vib), lerp(-0.46, 0.0, surge), rand(-vib, vib))
			* CFrame.Angles(lerp(-0.28, 0.20 * bell(surge), surge), 0, 0)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(lerp(-0.34, 0.24 * bell(surge), surge), 0, 0), 1, 0.4)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(1.15, -0.38, surge), 0, lerp(-0.52, 0.58, surge)), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(1.15, -0.38, surge), 0, lerp( 0.52, -0.58, surge)), 1, 0.4)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(lerp(1.28, 0.35, surge), 0, 0), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(lerp(1.28, 0.35, surge), 0, 0), 1, 0.4)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(lerp(0.55, -0.10, surge), 0, 0.08), 1, 0.4)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(lerp(0.55, -0.10, surge), 0, -0.08), 1, 0.4)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(lerp(-0.85, 0, surge), 0, 0), 1, 0.4)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(lerp(-0.85, 0, surge), 0, 0), 1, 0.4)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(lerp(-0.48, 0.32 * bell(surge), surge), 0, 0), 1, 0.4)

		if k < 0.78 and upperT then
			local fAlpha = smooth(0.55, 0.78, k)
			DrawTendonBundle(crossTendonL, (upperT.CFrame * CFrame.new(-1.1, 0.3, 0)).Position, root.Position, 0.06, 0.08, 0.12, fAlpha, 0.65)
			DrawTendonBundle(crossTendonR, (upperT.CFrame * CFrame.new( 1.1, 0.3, 0)).Position, root.Position, 0.06, 0.08, 0.12, fAlpha, 0.65)
		else
			DrawTendonBundle(crossTendonL, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
			DrawTendonBundle(crossTendonR, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
		end
	end)

	-- 3. ASSENTAMENTO MUSCULAR E RETORNO AO CONTROLE
	ShakeCamera(hum, 0.22, 0.18)
	CamDirector:ClearStage()

	Animate(ctx, 0.28, function(p)
		local rem = 1 - outCubic(p)
		root.CFrame = baseCF * CFrame.Angles(0.14 * rem, 0, 0)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(-0.32 * rem, 0, 0.48 * rem), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(-0.32 * rem, 0, -0.48 * rem), 1, 0.45)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(0.24 * rem, 0, 0), 1, 0.45)
	end)

	SetVisibility(origBody, 0)
	pose:Reset(0.14)
	pose:SuppressDefaultAnimations(false)
	root.Anchored = false
end

--------------------------------------------------------------------------------
-- 15. HABILIDADE 7: PRONE REBUILD (COLAPSO NO CHÃO E RECONSTRUÇÃO DEITADO)
--------------------------------------------------------------------------------
local function AbilityProneRebuild(ctx)
	local hum, root = S.hum, S.root
	local pose = CreatePoseController(ctx)
	pose:SuppressDefaultAnimations(true)

	local allBody = Concat(Group("Torso"), Group("Head"), Group("LArm"), Group("RArm"), Group("LLeg"), Group("RLeg"))
	local origBody = CaptureVisibility(allBody, true)

	ctx.maid:Add(function()
		SetVisibility(origBody, 0)
		if root and root.Parent then
			root.Anchored = false
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			hum.AutoRotate = true
		end
	end)

	local standOffset = S.r6 and 3.0 or (hum.HipHeight + root.Size.Y * 0.5)
	local look = flat(root.CFrame.LookVector)
	local groundPos, _, _, gCol = GroundBelow(ctx, root.Position)

	local function ProneCF(pos, dir, torsoRoll, torsoPitch, torsoYaw)
		local fDir = flat(dir)
		local base = CFrame.lookAt(pos, pos + Vector3.yAxis, -fDir)
		return base * CFrame.Angles(torsoPitch or 0, torsoYaw or 0, torsoRoll or 0)
	end

	-- 1. COLAPSO PESADO NO CHÃO (Joelhos cedem -> Tronco cai com amortecimento das mãos)
	root.Anchored = true
	hum.PlatformStand = true
	hum.AutoRotate = false
	local startCF = root.CFrame
	local kneeDropCF = CFrame.lookAt(
		Vector3.new(startCF.Position.X, groundPos.Y + standOffset * 0.52, startCF.Position.Z),
		Vector3.new(startCF.Position.X, groundPos.Y + standOffset * 0.52, startCF.Position.Z) + look
	) * CFrame.Angles(-0.48, 0, 0.08)

	CamDirector:SetStage(Vector3.new(0.65, -0.75, -0.8), -4, 0.02, 12)

	Animate(ctx, 0.30, function(p)
		local k = inCubic(p)
		root.CFrame = startCF:Lerp(kneeDropCF, k)
		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.28 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.95 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.82 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.45 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-1.35 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.88 * k, 0, 0.22), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.88 * k, 0, -0.22), 1, 0.45)
	end)

	local pronePos = Vector3.new(startCF.Position.X + look.X * 0.85, groundPos.Y + 0.58, startCF.Position.Z + look.Z * 0.85)
	local targetProneCF = ProneCF(pronePos, look, 0, -0.05, 0)

	Animate(ctx, 0.28, function(p)
		local k = outCubic(p)
		local bounce = math.sin(p * PI) * 0.30 * (1 - p)
		root.CFrame = kneeDropCF:Lerp(targetProneCF, k) + Vector3.new(0, bounce, 0)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.95 * (1 - k), 0, 0), 1, 0.5)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.82 * (1 - k), 0, 0), 1, 0.5)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.45 * (1 - k), 0, 0), 1, 0.5)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-1.35 * (1 - k), 0, 0), 1, 0.5)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(0.88, 1.42, k), 0, 0.38), 1, 0.5)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(0.88, 1.42, k), 0, -0.38), 1, 0.5)
	end)

	EmitDust(ctx, groundPos + look * 0.85, 22, gCol)
	EmitTissueMist(ctx, pronePos, 12)
	ShakeCamera(hum, 0.40, 0.30)

	-- 2. RECONSTRUÇÃO PROFUNDA E DETALHADA ENQUANTO DEITADO NO CHÃO
	CamDirector:SetStage(Vector3.new(1.25, -1.35, -1.05), -6, 0.02, 10)
	local upperT = GetUpperTorso()
	local lowerT = GetLowerTorso()
	local bedTendon1 = NewTendonBundle(ctx, 2, true)
	local bedTendon2 = NewTendonBundle(ctx, 2, true)

	local startHealth = hum.Health
	local maxHealth   = hum.MaxHealth

	RebuildAnatomy(ctx, origBody, {
		{ parts = Group("Torso"), t0 = 0.00, dur = 1.65, anatomy = "Torso", stagger = 0.24 },
		{ parts = Group("Head"),  anchorPart = upperT, t0 = 0.26, dur = 1.48, anatomy = "Head" },
		{ parts = Group("LArm"),  anchorPart = upperT, t0 = 0.44, dur = 1.58, anatomy = "Arm", stagger = 0.24 },
		{ parts = Group("RArm"),  anchorPart = upperT, t0 = 0.52, dur = 1.58, anatomy = "Arm", stagger = 0.24 },
		{ parts = Group("LLeg"),  anchorPart = lowerT, t0 = 0.72, dur = 1.68, anatomy = "Leg", stagger = 0.26 },
		{ parts = Group("RLeg"),  anchorPart = lowerT, t0 = 0.82, dur = 1.68, anatomy = "Leg", stagger = 0.26 },
	}, function(t, tEnd)
		local k = clamp01(t / tEnd)
		pcall(function()
			hum.Health = math.min(maxHealth, lerp(startHealth, maxHealth, k * 0.80))
		end)
		S.integrity = clamp01(lerp(S.integrity, 1.0, k))

		local spasm   = math.sin(t * 10.5) * 0.065 * bell(clamp01(k * 1.25))
		local armPush = smooth(0.46, 0.96, k)
		local curPos  = pronePos + Vector3.new(0, 0.24 * armPush + math.abs(spasm) * 0.4, 0)
		root.CFrame   = ProneCF(curPos, look, spasm * 0.85, -0.06 - 0.24 * armPush + spasm, spasm * 0.45)

		pose:SetJoint("Waist",     Vector3.zero, CFrame.Angles(-0.18 * armPush + spasm * 0.5, 0, spasm * 0.4), 1, 0.4)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(lerp(1.42, 0.68, armPush), 0, -0.32), 1, 0.4)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(lerp(1.42, 0.68, armPush), 0,  0.32), 1, 0.4)
		pose:SetJoint("LElbow",    Vector3.zero, CFrame.Angles(lerp(0.75, 0.22, armPush), 0, 0), 1, 0.4)
		pose:SetJoint("RElbow",    Vector3.zero, CFrame.Angles(lerp(0.75, 0.22, armPush), 0, 0), 1, 0.4)
		pose:SetJoint("Neck",      Vector3.zero, CFrame.Angles(lerp(-0.52, -0.15, armPush) + spasm, 0, 0), 1, 0.4)

		if k < 0.74 then
			local bAlpha = smooth(0.52, 0.74, k)
			DrawTendonBundle(bedTendon1, pronePos - look * 1.3, pronePos + look * 1.1, 0.04, 0.08, 0.13, bAlpha, 0.45)
			DrawTendonBundle(bedTendon2, pronePos - look * 0.8, pronePos + Vector3.new(0, 0.35, 0), 0.04, 0.08, 0.12, bAlpha, 0.45)
		else
			DrawTendonBundle(bedTendon1, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
			DrawTendonBundle(bedTendon2, Vector3.zero, Vector3.zero, 0, 0, 0, 1)
		end
	end)

	SetVisibility(origBody, 0)

	-- 3. IMPULSÃO NATURAL COM OS BRAÇOS E RETORNO À POSIÇÃO ERETA
	CamDirector:SetStage(Vector3.new(0.4, -0.4, 0), -2, 0, 12)
	local standPos = Vector3.new(pronePos.X, groundPos.Y + standOffset, pronePos.Z)
	local standCF  = CFrame.lookAt(standPos, standPos + look)
	local kneelCF  = CFrame.lookAt(
		Vector3.new(pronePos.X, groundPos.Y + standOffset * 0.56, pronePos.Z),
		Vector3.new(pronePos.X, groundPos.Y + standOffset * 0.56, pronePos.Z) + look
	) * CFrame.Angles(-0.34, 0, 0)

	local curProne = root.CFrame
	Animate(ctx, 0.38, function(p)
		local k = outCubic(p)
		root.CFrame = curProne:Lerp(kneelCF, k)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.88 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.45 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.12 * k, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.78 * k, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.55 * (1 - k * 0.4), 0, 0.16), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.55 * (1 - k * 0.4), 0, -0.16), 1, 0.45)
	end)

	EmitDust(ctx, groundPos + look * 0.85, 8, gCol)
	CamDirector:ClearStage()

	Animate(ctx, 0.42, function(p)
		local k = outBack(p, 1.22)
		root.CFrame = kneelCF:Lerp(standCF, k)
		local rem = 1 - clamp01(p)
		pose:SetJoint("RHip",      Vector3.zero, CFrame.Angles(0.88 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LHip",      Vector3.zero, CFrame.Angles(0.45 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("RKnee",     Vector3.zero, CFrame.Angles(-1.12 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LKnee",     Vector3.zero, CFrame.Angles(-0.78 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("RShoulder", Vector3.zero, CFrame.Angles(0.35 * rem, 0, 0), 1, 0.45)
		pose:SetJoint("LShoulder", Vector3.zero, CFrame.Angles(0.35 * rem, 0, 0), 1, 0.45)
	end)

	pose:Reset(0.14)
	pose:SuppressDefaultAnimations(false)
	root.Anchored = false
	hum.PlatformStand = false
	hum.AutoRotate = true
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end

--------------------------------------------------------------------------------
-- 16. REGENERAÇÃO PASSIVA EM TEMPO REAL (COSTURA FIBROSA SUTIL AO SOFRER DANO)
--------------------------------------------------------------------------------
local passiveFolder = nil
local function GetPassiveFolder()
	if not passiveFolder or not passiveFolder.Parent then
		passiveFolder = Instance.new("Folder")
		passiveFolder.Name = "RegenV4_PassiveFX"
		passiveFolder.Parent = Workspace
	end
	return passiveFolder
end

local function SpawnPassiveMendFiber(partA, partB)
	if not partA or not partB or not partA.Parent or not partB.Parent then return end
	local folder = GetPassiveFolder()
	local f = Instance.new("Part")
	f.Anchored = true
	f.CanCollide = false
	f.CanQuery = false
	f.CanTouch = false
	f.CastShadow = false
	f.Material = Enum.Material.Granite
	f.Color = math.random() < 0.5 and COL.Tendon or COL.Muscle
	f.Transparency = 0.15

	local pA = partA.Position + Vector3.new(rand(-0.35, 0.35), rand(-0.35, 0.35), rand(-0.35, 0.35))
	local pB = partB.Position + Vector3.new(rand(-0.35, 0.35), rand(-0.35, 0.35), rand(-0.35, 0.35))
	local dist = clamp((pB - pA).Magnitude, 0.2, 2.2)
	f.Size = Vector3.new(0.08, 0.08, dist)
	f.CFrame = CFrame.lookAt((pA + pB) * 0.5, pB)
	f.Parent = folder

	TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.02, 0.02, dist * 0.4),
		Transparency = 1,
	}):Play()
	Debris:AddItem(f, 0.60)
end

local function StepPassiveRegeneration(dt)
	if not alive(S.gen) then return end
	local hum = S.hum
	local curHealth = hum.Health
	local maxHealth = math.max(hum.MaxHealth, 1)

	if curHealth < S.lastHealth - 0.5 then
		local dmgFrac = (S.lastHealth - curHealth) / maxHealth
		S.integrity = clamp01(S.integrity - dmgFrac * 1.25)
	end
	S.lastHealth = curHealth

	if (curHealth < maxHealth or S.integrity < 1.0) and S.busy == nil then
		pcall(function()
			hum.Health = math.min(maxHealth, curHealth + CFG.PassiveRegen.HealPerSecond * dt)
		end)
		S.integrity = clamp01(S.integrity + 0.08 * dt)
		S.passivePulseTimer += dt
		if S.passivePulseTimer >= CFG.PassiveRegen.PulseInterval then
			S.passivePulseTimer = 0
			local ut = GetUpperTorso()
			local lt = GetLowerTorso()
			if ut and lt then
				SpawnPassiveMendFiber(ut, lt)
			end
		end
	else
		S.integrity = clamp01(S.integrity + 0.04 * dt)
	end
end

--------------------------------------------------------------------------------
-- 17. INTERFACE MINIMALISTA E PROFISSIONAL (DESIGN LIMPO E TÁTIL)
--------------------------------------------------------------------------------
local BUTTON_DEFS = {
	{ id = "Jump",       label = "SALTO",    icon = "▲", key = Enum.KeyCode.Q, keyText = "Q" },
	{ id = "Noclip",     label = "NOCLIP",   icon = "●", key = Enum.KeyCode.E, keyText = "E" },
	{ id = "Grapple",    label = "GANCHO",   icon = "↗", key = Enum.KeyCode.R, keyText = "R" },
	{ id = "HeadThrow",  label = "CABEÇA",   icon = "◉", key = Enum.KeyCode.F, keyText = "F" },
	{ id = "ArmControl", label = "BRAÇO",    icon = "✋", key = Enum.KeyCode.G, keyText = "G" },
	{ id = "AccelRegen", label = "REGEN",    icon = "✚", key = Enum.KeyCode.Z, keyText = "Z" },
	{ id = "ProneRegen", label = "RECONSTR", icon = "▬", key = Enum.KeyCode.X, keyText = "X" },
}

local UI_PALETTE = {
	Bg         = Color3.fromRGB(16, 17, 19),
	BgActive   = Color3.fromRGB(28, 30, 34),
	Border     = Color3.fromRGB(44, 46, 52),
	BorderAct  = Color3.fromRGB(142, 42, 46),
	TextMain   = Color3.fromRGB(224, 224, 228),
	TextMuted  = Color3.fromRGB(130, 132, 138),
	CooldownBg = Color3.fromRGB(10, 10, 12),
	BarBg      = Color3.fromRGB(22, 23, 26),
	BarFill    = Color3.fromRGB(132, 34, 38),
}

local UI = {
	gui         = nil,
	buttons     = {},
	banner      = nil,
	passiveFill = nil,
}

local TryUseAbility

function UI.Build()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("RegenMovesetUI")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "RegenMovesetUI"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	UI.gui = sg

	local banner = Instance.new("TextLabel")
	banner.Name = "AimBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 40)
	banner.Size = UDim2.fromOffset(IS_MOBILE and 300 or 370, 26)
	banner.BackgroundColor3 = UI_PALETTE.Bg
	banner.BackgroundTransparency = 0.16
	banner.Font = Enum.Font.GothamMedium
	banner.TextSize = IS_MOBILE and 11 or 12
	banner.TextColor3 = UI_PALETTE.TextMain
	banner.Text = ""
	banner.Visible = false
	banner.Parent = sg
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 4)
	bCorner.Parent = banner
	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 1
	bStroke.Color = UI_PALETTE.BorderAct
	bStroke.Transparency = 0.35
	bStroke.Parent = banner
	UI.banner = banner

	SetBanner = function(msg)
		if not UI.banner then return end
		if msg and msg ~= "" then
			UI.banner.Text = msg
			UI.banner.Visible = true
		else
			UI.banner.Visible = false
		end
	end

	local btnSize = IS_MOBILE and 46 or 50
	local gap     = IS_MOBILE and 5 or 6
	local totalWidth = #BUTTON_DEFS * btnSize + (#BUTTON_DEFS - 1) * gap

	local container = Instance.new("Frame")
	container.Name = "HUDContainer"
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 1, IS_MOBILE and -12 or -16)
	container.Size = UDim2.fromOffset(totalWidth, btnSize + 9)
	container.BackgroundTransparency = 1
	container.Parent = sg

	local pBarBg = Instance.new("Frame")
	pBarBg.Name = "PassiveIntegrityBar"
	pBarBg.Position = UDim2.fromOffset(0, 0)
	pBarBg.Size = UDim2.fromOffset(totalWidth, 3)
	pBarBg.BackgroundColor3 = UI_PALETTE.BarBg
	pBarBg.BackgroundTransparency = 0.25
	pBarBg.BorderSizePixel = 0
	pBarBg.Parent = container
	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 2)
	pCorner.Parent = pBarBg

	local pFill = Instance.new("Frame")
	pFill.Name = "Fill"
	pFill.Size = UDim2.fromScale(1, 1)
	pFill.BackgroundColor3 = UI_PALETTE.BarFill
	pFill.BorderSizePixel = 0
	pFill.Parent = pBarBg
	local pfCorner = Instance.new("UICorner")
	pfCorner.CornerRadius = UDim.new(0, 2)
	pfCorner.Parent = pFill
	UI.passiveFill = pFill

	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.Position = UDim2.fromOffset(0, 7)
	bar.Size = UDim2.fromOffset(totalWidth, btnSize)
	bar.BackgroundTransparency = 1
	bar.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	for idx, def in ipairs(BUTTON_DEFS) do
		local btn = Instance.new("TextButton")
		btn.Name = def.id
		btn.LayoutOrder = idx
		btn.Size = UDim2.fromOffset(btnSize, btnSize)
		btn.BackgroundColor3 = UI_PALETTE.Bg
		btn.BackgroundTransparency = 0.14
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.ClipsDescendants = true
		btn.Parent = bar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = UI_PALETTE.Border
		stroke.Transparency = 0.25
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn

		if not IS_MOBILE then
			local keyLbl = Instance.new("TextLabel")
			keyLbl.Position = UDim2.fromOffset(4, 2)
			keyLbl.Size = UDim2.fromOffset(14, 11)
			keyLbl.BackgroundTransparency = 1
			keyLbl.Font = Enum.Font.GothamMedium
			keyLbl.TextSize = 9
			keyLbl.TextXAlignment = Enum.TextXAlignment.Left
			keyLbl.TextColor3 = UI_PALETTE.TextMuted
			keyLbl.Text = def.keyText
			keyLbl.Parent = btn
		end

		local icon = Instance.new("TextLabel")
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0.5, 0, 0.40, 0)
		icon.Size = UDim2.fromOffset(22, 18)
		icon.BackgroundTransparency = 1
		icon.Font = Enum.Font.GothamMedium
		icon.TextSize = IS_MOBILE and 13 or 14
		icon.TextColor3 = UI_PALETTE.TextMain
		icon.Text = def.icon
		icon.Parent = btn

		local lbl = Instance.new("TextLabel")
		lbl.AnchorPoint = Vector2.new(0.5, 1)
		lbl.Position = UDim2.new(0.5, 0, 1, -3)
		lbl.Size = UDim2.new(1, -4, 0, 11)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = IS_MOBILE and 7 or 8
		lbl.TextColor3 = UI_PALETTE.TextMuted
		lbl.Text = def.label
		lbl.Parent = btn

		local cdFill = Instance.new("Frame")
		cdFill.AnchorPoint = Vector2.new(0, 1)
		cdFill.Position = UDim2.fromScale(0, 1)
		cdFill.Size = UDim2.fromScale(1, 0)
		cdFill.BackgroundColor3 = UI_PALETTE.CooldownBg
		cdFill.BackgroundTransparency = 0.22
		cdFill.BorderSizePixel = 0
		cdFill.ZIndex = 3
		cdFill.Parent = btn

		local cdText = Instance.new("TextLabel")
		cdText.AnchorPoint = Vector2.new(0.5, 0.5)
		cdText.Position = UDim2.fromScale(0.5, 0.5)
		cdText.Size = UDim2.fromScale(1, 1)
		cdText.BackgroundTransparency = 1
		cdText.Font = Enum.Font.GothamMedium
		cdText.TextSize = 11
		cdText.TextColor3 = UI_PALETTE.TextMain
		cdText.Text = ""
		cdText.ZIndex = 4
		cdText.Parent = btn

		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(scale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play()
			end
		end)
		btn.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(scale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
		end)

		btn.Activated:Connect(function()
			if TryUseAbility then
				TryUseAbility(def.id)
			end
		end)

		UI.buttons[def.id] = {
			btn    = btn,
			stroke = stroke,
			scale  = scale,
			icon   = icon,
			lbl    = lbl,
			cdFill = cdFill,
			cdText = cdText,
		}
	end
end

function UI.DenyFeedback(id)
	local b = UI.buttons[id]
	if not b then return end
	TweenService:Create(b.scale, TweenInfo.new(0.05), { Scale = 0.92 }):Play()
	task.delay(0.06, function()
		if b.scale and b.scale.Parent then
			TweenService:Create(b.scale, TweenInfo.new(0.12), { Scale = 1.0 }):Play()
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	local stepDt = math.min(dt, 0.05)
	StepPassiveRegeneration(stepDt)
	CamDirector:Step(stepDt)

	if UI.passiveFill and S.hum then
		local healthFrac = clamp01(S.hum.Health / math.max(S.hum.MaxHealth, 1))
		local displayFrac = clamp01(math.min(healthFrac, S.integrity))
		UI.passiveFill.Size = UDim2.fromScale(displayFrac, 1)
	end

	local now = os.clock()
	for _, def in ipairs(BUTTON_DEFS) do
		local b = UI.buttons[def.id]
		if b then
			local maxCd = CFG.Cooldown[def.id] or 5
			local rem   = math.max(0, (S.cd[def.id] or 0) - now)
			local frac  = clamp01(rem / maxCd)
			local isActive = (S.busy == def.id)
			local isLocked = (S.busy ~= nil and S.busy ~= def.id)

			b.cdFill.Size = UDim2.fromScale(1, frac)
			b.cdText.Text = rem > 0.05 and string.format("%.1f", rem) or ""
			b.btn.BackgroundColor3 = isActive and UI_PALETTE.BgActive or UI_PALETTE.Bg
			b.btn.BackgroundTransparency = isLocked and 0.46 or 0.14
			b.stroke.Color = isActive and UI_PALETTE.BorderAct or UI_PALETTE.Border
			b.stroke.Thickness = isActive and 1.4 or 1.0
			b.icon.TextTransparency = (isLocked or rem > 0) and 0.45 or 0.0
			b.lbl.TextTransparency  = (isLocked or rem > 0) and 0.50 or 0.0
		end
	end
end)

--------------------------------------------------------------------------------
-- 18. DESPACHANTE DE HABILIDADES, TRANSIÇÕES E CICLO DE VIDA DO PERSONAGEM
--------------------------------------------------------------------------------
local ABILITY_HANDLERS = {
	Jump       = AbilityJump,
	Noclip     = AbilityNoclip,
	Grapple    = AbilityGrapple,
	HeadThrow  = AbilityHeadThrow,
	ArmControl = AbilityArmControl,
	AccelRegen = AbilityAcceleratedRegen,
	ProneRegen = AbilityProneRebuild,
}

TryUseAbility = function(id)
	if S.busy == "Grapple" and id == "Grapple" and aimCallback ~= nil then
		S.cancelAim = true
		return
	end
	if S.busy == "ArmControl" and id == "ArmControl" then
		S.endEarly = true
		return
	end

	if not alive(S.gen) then return end
	if S.busy ~= nil then
		UI.DenyFeedback(id)
		return
	end

	local now = os.clock()
	if (S.cd[id] or 0) > now then
		UI.DenyFeedback(id)
		return
	end

	if id == "Jump" and S.hum.FloorMaterial == Enum.Material.Air then
		UI.DenyFeedback(id)
		return
	end

	local fn = ABILITY_HANDLERS[id]
	if not fn then return end

	S.busy = id
	local myGen = S.gen
	local ctx = NewCtx(myGen)

	task.spawn(function()
		local ok, result = pcall(fn, ctx)
		ctx.maid:Clean()
		if S.gen == myGen then
			S.busy = nil
			if ok and result ~= false then
				S.cd[id] = os.clock() + (CFG.Cooldown[id] or 5)
			end
		end
	end)
end

UIS.InputBegan:Connect(function(input, gameProcessed)
	if aimCallback ~= nil then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local pos = UIS:GetMouseLocation()
			aimCallback(pos)
			return
		end
	end

	if gameProcessed then return end
	if UIS:GetFocusedTextBox() then return end

	for _, def in ipairs(BUTTON_DEFS) do
		if input.KeyCode == def.key then
			TryUseAbility(def.id)
			return
		end
	end
end)

local function OnCharacterAdded(char)
	S.gen += 1
	S.busy      = nil
	S.cancelAim = false
	S.endEarly  = false
	S.char      = char
	S.hum       = char:WaitForChild("Humanoid", 10)
	S.root      = char:WaitForChild("HumanoidRootPart", 10)
	if not S.hum or not S.root then return end

	S.r6         = (S.hum.RigType == Enum.HumanoidRigType.R6)
	S.lastHealth = S.hum.Health
	S.integrity  = 1.0
	table.clear(S.cd)
	SetBanner(nil)
	CamDirector:ClearStage()

	local cam = Workspace.CurrentCamera
	if cam then
		CamDirector.baseFov = cam.FieldOfView
	end

	S.hum.Died:Connect(function()
		S.gen += 1
		S.busy = nil
		SetBanner(nil)
		CamDirector:ClearStage()
	end)
end

UI.Build()
if player.Character then
	task.spawn(OnCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(OnCharacterAdded)
