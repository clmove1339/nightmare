local function AngleVectors(angles)
	local sr, sp, sy = math.sin(math.rad(angles.roll)), math.sin(math.rad(angles.pitch)), math.sin(math.rad(angles.yaw));
	local cr, cp, cy = math.cos(math.rad(angles.roll)), math.cos(math.rad(angles.pitch)), math.cos(math.rad(angles.yaw));

	local forward = {
		x = cp * cy,
		y = cp * sy,
		z = -sp
	};

	local right = {
		x = -sr * sp * cy + cr * -sy,
		y = -sr * sp * sy + cr * cy,
		z = -sr * cp
	};

	local up = {
		x = cr * sp * cy + -sr * -sy,
		y = cr * sp * sy + -sr * cy,
		z = cr * cp
	};

	return forward, right, up;
end;

local function GetYaw(a1, a2)
	if (a1 ~= 0 or a2 ~= 0) then
		return math.atan2(a2, a1) * 57.295776;
	end;
	return 0;
end;

local function AutoStrafe(cmd)
	local m_strafe_flags, m_last_yaw;

	local me = entitylist.get_local_player();
	if not (me and me:is_alive()) then
		return;
	end;

	local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];
	local m_MoveType = me.m_MoveType;                                                                    -- гетните

	if (bit.has(flags, FL.ONGROUND) or m_MoveType == MOVETYPE_NOCLIP or m_MoveType or MOVETYPE_LADDER) then -- пукните
		return;
	end;

	if (bit.has(cmd.buttons, IN.SPEED)) then
		return;
	end;

	local velocity = me:get_velocity();
	local velocity_len = velocity:length2d();

	local strafer_smoothing = config.misc.movement.auto_strafe_smooth:get();
	local ideal_step = math.min(90, 845 / velocity_len);
	local velocity_yaw = GetYaw(velocity.x, velocity.y);

	local angles = cmd.viewangles;

	if (velocity_len < 2 and bit.has(cmd.buttons, IN.JUMP)) then
		cmd.forwardmove = 450;
	end;

	local forward_move = cmd.forwardmove;

	if (forward_move ~= 0 or cmd.sidemove ~= 0) then
		cmd.forwardmove = 0;

		if (velocity_len ~= 0 and math.abs(velocity.z) ~= 0) then
			::DO_IT_AGAIN::
			local forw, right = AngleVectors(angles);

			local v262 = (forw.x * forward_move) + (cmd.sidemove * right.x);
			local v263 = (right.y * cmd.sidemove) + (forw.y * forward_move);
			angles.yaw = GetYaw(v262, v263);
		end;
	end;

	local yaw_to_use = 0;
	m_strafe_flags = bit.band(m_strafe_flags, bit.bnot(4));

	local clamped_angles = angles.yaw;
	if (clamped_angles < -180) then
		clamped_angles = clamped_angles + 360;
	end;
	if (clamped_angles > 180) then
		clamped_angles = clamped_angles - 360;
	end;

	yaw_to_use = cmd.viewangles.yaw;
	m_strafe_flags = bit.bor(m_strafe_flags, 4);
	m_last_yaw = clamped_angles;

	if (m_strafe_flags & 4) then
		local diff = angles.yaw - yaw_to_use;
		if (diff < -180) then diff = diff + 360; end;
		if (diff > 180) then diff = diff - 360; end;

		if (math.abs(diff) > ideal_step and math.abs(diff) <= 30) then
			local move = 450;
			if (diff < 0) then
				move = move * -1;
			end;

			cmd.sidemove = move;
			return;
		end;
	end;

	local diff = angles.yaw - velocity_yaw;
	if (diff < -180) then diff = diff + 360; end;
	if (diff > 180) then diff = diff - 360; end;

	local step = ((100 - 30) * 0.02) * (ideal_step + ideal_step);
	local sidemove = 0;
	if (math.abs(diff) > 170 and velocity_len > 80 or diff > step and velocity_len > 80) then
		angles.yaw = step + velocity_yaw;
		cmd.sidemove = -450;
	elseif (-step <= diff or velocity_len <= 80) then
		if (m_strafe_flags & 1) then
			angles.yaw = angles.yaw - ideal_step;
			cmd.sidemove = -450;
		else
			angles.yaw = angles.yaw + ideal_step;
			cmd.sidemove = 450;
		end;
	else
		angles.yaw = velocity_yaw - step;
		cmd.sidemove = 450;
	end;
	if (not (cmd.buttons & 16) and cmd.sidemove == 0) then
		goto DO_IT_AGAIN;
	end;

	m_strafe_flags = bit.bxor(
		m_strafe_flags,
		bit.band(
			bit.bxor(m_strafe_flags, bit.bnot(m_strafe_flags)),
			1
		)
	);

	local rotation = math.rad(cmd.viewangles.yaw - angles.yaw);

	local cos_rot = math.cos(rotation);
	local sin_rot = math.sin(rotation);

	local new_forwardmove = (cos_rot * cmd.forwardmove) - (sin_rot * cmd.sidemove);
	local new_sidemove = (sin_rot * cmd.forwardmove) + (cos_rot * cmd.sidemove);

	cmd.forwardmove = new_forwardmove;
	cmd.sidemove = new_sidemove;
end;
