-- Excuse the very good looking code (Joking, but it works).
return function(ARGS)
	local N = ARGS.N or 32
	local iter = ARGS.iter or 16
	local SCALE = ARGS.SCALE or 1
	local t = ARGS.t or 0
	local dampness = ARGS.dampness or 6

	function lin_solve(b, x, x0, a, c)
		local cRecip = 1 / c
		for k = 1, (iter + 1) do
			for j = 1, (N - 1) - 1 do
				for i = 1, (N - 1) - 1 do
					x[IX(i, j)] =
						(x0[IX(i, j)] +
							a *
							(x[IX(i + 1, j)] +
								x[IX(i - 1, j)] +
								x[IX(i, j + 1)] +
								x[IX(i, j - 1)])) *
						cRecip;
				end
			end
			set_bnd(b, x)
		end
	end

	function set_bnd(b, x)
		for i = 1, (N - 1) - 1 do
			x[IX(i, 0)] = b == 2 and -x[IX(i, 1)] or x[IX(i, 1)];
			x[IX(i, N - 1)] = b == 2 and -x[IX(i, N - 2)] or x[IX(i, N - 2)];
		end

		for j = 1, (N - 1) - 1 do
			x[IX(0, j)] = b == 1 and -x[IX(1, j)] or x[IX(1, j)];
			x[IX(N - 1, j)] = b == 1 and -x[IX(N - 2, j)] or x[IX(N - 2, j)];
		end

		x[IX(0, 0)] = 0.5 * (x[IX(1, 0)] + x[IX(0, 1)]);
		x[IX(0, N - 1)] = 0.5 * (x[IX(1, N - 1)] + x[IX(0, N - 2)]);
		x[IX(N - 1, 0)] = 0.5 * (x[IX(N - 2, 0)] + x[IX(N - 1, 1)]);
		x[IX(N - 1, N - 1)] = 0.5 * (x[IX(N - 2, N - 1)] + x[IX(N - 1, N - 2)]);
	end

	function project(velocX, velocY, p, div)
		for j = 1, (N - 1) - 1  do
			for i = 1, (N - 1) - 1 do
				div[IX(i, j)] =
					(-0.5 *
						(velocX[IX(i + 1, j)] -
							velocX[IX(i - 1, j)] +
							velocY[IX(i, j + 1)] -
							velocY[IX(i, j - 1)])) /
					N;
				p[IX(i, j)] = 0;
			end
		end
		set_bnd(0, div);
		set_bnd(0, p);
		lin_solve(0, p, div, 1, dampness);
		for j = 1, (N - 1) - 1 do
			for i = 1, (N - 1) - 1 do
				velocX[IX(i, j)] -= 0.5 * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) * N;
				velocY[IX(i, j)] -= 0.5 * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) * N;
			end
		end
		set_bnd(1, velocX);
		set_bnd(2, velocY);
	end

	function advect(b, d, d0, velocX, velocY, dt)
		local i0, i1, j0, j1

		local dtx = dt * (N - 2)
		local dty = dt * (N - 2)

		local s0, s1, t0, t1;
		local tmp1, tmp2, tmp3, x, y;

		local Nfloat = N - 2;
		local ifloat, jfloat;

		for j = 1, (N - 1) - 1 do
			jfloat = j
			for i = 1, (N - 1) - 1 do
				ifloat = i
				tmp1 = dtx * velocX[IX(i, j)];
				tmp2 = dty * velocY[IX(i, j)];
				x = ifloat - tmp1;
				y = jfloat - tmp2;
				if (x < 0.5) then x = 0.5 end
				if (x > Nfloat + 0.5) then x = Nfloat + 0.5 end
				i0 = math.floor(x);
				i1 = i0 + 1.0;
				if (y < 0.5) then y = 0.5; end
				if (y > Nfloat + 0.5) then y = Nfloat + 0.5; end
				j0 = math.floor(y);
				j1 = j0 + 1.0;
				s1 = x - i0;
				s0 = 1.0 - s1;
				t1 = y - j0;
				t0 = 1.0 - t1;

				local i0i = tonumber(i0);
				local i1i = tonumber(i1);
				local j0i = tonumber(j0);
				local j1i = tonumber(j1);

				d[IX(i, j)] =
					s0 * (t0 * d0[IX(i0i, j0i)] + t1 * d0[IX(i0i, j1i)]) +
					s1 * (t0 * d0[IX(i1i, j0i)] + t1 * d0[IX(i1i, j1i)]);
			end
		end

		set_bnd(b, d);
	end

	function diffuse(b, x, x0, diff, dt) 
		local a = dt * diff * (N - 2) * (N - 2);
		lin_solve(b, x, x0, a, 1 + dampness * a);
	end

	function IX(x, y)
		return x + (y * N)
	end

	return {
		diffuse = diffuse,
		project = project,
		IX = IX,
		advect = advect,
		set_bnd = set_bnd,
		lin_solve = lin_solve
	}
end