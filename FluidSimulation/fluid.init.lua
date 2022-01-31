-- This is some old experiment I had for 2D and 3D fluid simulation.
-- For now you probably shouldn't change too much if you don't understand it. I will add more comments later.

local N = 32
local SCALE = 1

local is3D = false

local SIMULATOR = require(script["2d"])({N = N, iter = 16, SCALE = SCALE, t = 0, dampness = 6})

local Fluid = {}
Fluid.__index = Fluid

function Fluid.new(dt, diffusion, viscosity)
	return setmetatable({
		size = N,
		dt = dt,
		diff = diffusion,
		visc = viscosity,

		s = table.create(is3D and N^3 or N^2, 0),
		density = table.create(is3D and N^3 or N^2, 0),

		Vx = table.create(is3D and N^3 or N^2, 0),
		Vy = table.create(is3D and N^3 or N^2, 0),
		Vz = table.create(is3D and N^3 or N^2, 0),

		Vx0 = table.create(is3D and N^3 or N^2, 0),
		Vy0 = table.create(is3D and N^3 or N^2, 0),
		Vz0 = table.create(is3D and N^3 or N^2, 0),
	}, Fluid)
end

function Fluid:step()
	N = self.size;
	local visc = self.visc;
	local diff = self.diff;
	local dt = self.dt;
	local Vx = self.Vx;
	local Vy = self.Vy;
	local Vz = self.Vz;
	local Vx0 = self.Vx0;
	local Vy0 = self.Vy0;
	local Vz0 = self.Vy0;
	local s = self.s;
	local density = self.density;

	if is3D == true then
		SIMULATOR.diffuse(1, Vx0, Vx, visc, dt, 4);
		SIMULATOR.diffuse(2, Vy0, Vy, visc, dt, 4);
		SIMULATOR.diffuse(3, Vz0, Vz, visc, dt, 4);

		SIMULATOR.project(Vx0, Vy0, Vz0, Vx, Vy, 4);

		SIMULATOR.advect(1, Vx, Vx0, Vx0, Vy0, Vz0, dt);
		SIMULATOR.advect(2, Vy, Vy0, Vx0, Vy0, Vz0, dt);
		SIMULATOR.advect(3, Vz, Vz0, Vx0, Vy0, Vz0, dt);

		SIMULATOR.project(Vx, Vy, Vz, Vx0, Vy0, 4);

		SIMULATOR.diffuse(0, s, density, diff, dt, 4);
		SIMULATOR.advect(0, density, s, Vx, Vy, Vz, dt);
	else
		SIMULATOR.diffuse(1, Vx0, Vx, visc, dt);
		SIMULATOR.diffuse(2, Vy0, Vy, visc, dt);

		SIMULATOR.project(Vx0, Vy0, Vx, Vy);

		SIMULATOR.advect(1, Vx, Vx0, Vx0, Vy0, dt);
		SIMULATOR.advect(2, Vy, Vy0, Vx0, Vy0, dt);

		SIMULATOR.project(Vx, Vy, Vx0, Vy0);
		SIMULATOR.diffuse(0, s, density, diff, dt);
		SIMULATOR.advect(0, density, s, Vx, Vy, dt);
	end
end

function Fluid:addDensity(x, y, z, amount)
	--print(SIMULATOR.IX(x, y, z))
	self.density[SIMULATOR.IX(x, y, z)] += amount
end

function Fluid:addVelocity(x, y, z, amountX, amountY, amountZ)
	local index = SIMULATOR.IX(x, y, z);
	self.Vx[index] += amountX;
	self.Vy[index] += amountY;
	if is3D then
		self.Vz[index] += amountZ;
	end
end

function Fluid:renderD()
	for i = 1, (N - 1) do
		for j = 1, (N - 1) do
			--for k = 1, (N - 1) do
			local x = i * SCALE
			local y = j * SCALE
			--local z = k * SCALE
			local d = self.density[SIMULATOR.IX(x, y, 0)]-- + (170/3 + 85/3 + 255/3)
			local pixels = workspace:FindFirstChild("Pixels")
			local pixel = pixels:FindFirstChild(x .. "," .. y)-- .. ",".. z)
			if not pixel then
				pixel = Instance.new("Part")
				pixel.Name = x .. "," .. y --.. ",".. z
				pixel.Size = Vector3.new(SCALE, SCALE, SCALE)
				pixel.Anchored = true
				pixel.Parent = pixels
				pixel.TopSurface = Enum.SurfaceType.Smooth
				--pixel.BorderSizePixel = 0
			end
			--pixel.Transparency = (255-d)/255
			pixel.Color = Color3.fromRGB(0, d, d)
			pixel.Position = Vector3.new(x,0,y)
			--end
		end
	end
end

function Fluid:fadeD()
	for i = 1, #self.density do
		local d = self.density[i]
		self.density[i] = math.clamp(d-0.02, 0, 255)
	end
end

local newFluid = Fluid.new(0.2, 0, 0.0000001)
while true do
	local on = true--script:GetAttribute("on")
	local cx = (0.5 * 32) / SCALE
	local cy = (0.5 * 32) / SCALE
	if on then
		newFluid:addDensity(1, cy, 0, 150)
		newFluid:addDensity(1, cy+1, 0, 150)
		newFluid:addDensity(1, cy-1, 0, 150)
		--newFluid:addDensity(cx, 5, 150)

		--newFluid:addVelocity(cx, 5, 0, 2)
	end
	newFluid:addVelocity(1, cy, 0, 5, 0)

	newFluid:step()
	newFluid:renderD()
	--newFluid:fadeD()

	task.wait(1/60)
end