local engine_client = require 'libs.engine_client';

supertoss.type = handle:combo('Supertoss', { 'Off', 'Semi', 'Full' });

local ctx = {};

local function update()
	local me = entitylist.get_local_player();
	if not (me and me:is_alive()) then
		return;
	end;

	if ctx.local_velocity then
		ctx.last_local_velocity = vec3_t.new(
			ctx.local_velocity.x,
			ctx.local_velocity.y,
			ctx.local_velocity.z
		);
	end;

	ctx.local_velocity = me:get_velocity();
end;

local function RayCircleIntersection(ray, center, r)
	if (math.abs(ray.x) > math.abs(ray.y)) then
		local k = ray.y / ray.x;

		local a = 1 + k * k;
		local b = -2 * center.x - 2 * k * center.y;
		local c = center:length2d_sqr() - r * r;

		local d = b * b - 4 * a * c;

		if (d < 0) then
			local nearest_on_ray = ray * center:dot(ray);
			local diff = (nearest_on_ray - center):normalize();

			return center + diff * r;
		elseif (d < 0.001) then
			local x = -b / (2 * a);
			localy = k * x;
			return vec2_t.new(x, y);
		end;

		local d_sqrt = math.sqrt(d);

		local x = (-b + d_sqrt) / (2 * a);
		local y = k * x;

		local dir1 = vec3_t.new(x, y, 0);

		x = (-b - d_sqrt) / (2 * a);
		y = k * x;

		local dir2 = vec3_t.new(x, y, 0);

		if (ray:dot(dir1) > ray:dot(dir2)) then
			return dir1;
		end;

		return dir2;
	else
		local k = ray.x / ray.y;

		local a = 1 + k * k;
		local b = -2 * center.y - 2 * k * center.x;
		local c = center:length2d_sqr() - r * r;

		local d = b * b - 4 * a * c;

		if (d < 0) then
			local nearest_on_ray = ray * center:dot(ray);
			local diff = (nearest_on_ray - center):normalize();

			return center + diff * r;
		elseif (d < 0.001) then
			local y = -b / (2 * a);
			local x = k * y;
			return Vector(x, y);
		end;

		local d_sqrt = math.sqrt(d);

		local y = (-b + d_sqrt) / (2 * a);
		local x = k * y;

		local dir1 = vec3_t.new(x, y, 0);

		y = (-b - d_sqrt) / (2 * a);
		x = k * y;

		local dir2 = vec3_t.new(x, y, 0);

		if (ray:dot(dir1) > ray:dot(dir2)) then
			return dir1;
		end;

		return dir2;
	end;
end;

local function CalculateThrowYaw(wish_dir, vel, throw_velocity, throw_strength)
	local dir_normalized = wish_dir;
	dir_normalized.z = 0;
	dir_normalized:normalize();

	local cos_pitch = dir_normalized:dot(wish_dir) / wish_dir:length();

	local real_dir = RayCircleIntersection(dir_normalized, vel * 1.25, math.clamp(throw_velocity * 0.9, 15, 750) * (math.clamp(throw_strength, 0, 1) * 0.7 + 0.3) * cos_pitch) - vel * 1.25;
	return real_dir:to_angle().yaw;
end;

local function CalculateThrowPitch(wish_dir, wish_z_vel, vel, throw_velocity, throw_strength)
	local speed = math.clamp(throw_velocity * 0.9, 15, 750) * (math.clamp(throw_strength, 0, 1) * 0.7 + 0.3);

	local cur_vel = vel * 1.25 + wish_dir * speed;
	local wish_vel = Vector(vel.x, vel.y, wish_z_vel) * 1.25 + wish_dir * speed;

	local ang1 = cur_vel:to_angle();
	local ang2 = wish_vel:to_angle();

	local ang_diff = ang2.pitch - ang1.pitch;

	return ang_diff * (math.cos(math.rad(ang_diff)) + 1) * 0.5;
end;

local function CompensateThrowable(cmd)
	local type = supertoss.type:get();
	if type == 0 then
		return;
	end;

	local me = entitylist.get_local_player();
	if not (me and me:is_alive()) then
		return;
	end;

	local weapon = me:get_active_weapon();

	if not weapon:is_grenade() then
		return;
	end;

	print('AXYET GRANATA');

	local weaponData = weapon:get_weapon_info();

	if not weaponData then
		return;
	end;

	local vangle = engine.get_view_angles();
	local m_flThrowStrength = ffi.cast('float*', weapon[netvars.m_flThrowStrength])[0];

	if (type == 2) then
		local direction = vangle:forward();
		local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];

		local smoothed_velocity = (ctx.local_velocity + ctx.last_local_velocity) * 0.5;

		local base_vel = direction * (math.clamp(weaponData.flThrowVelocity * 0.9, 15, 750) * (m_flThrowStrength * 0.7 + 0.3));
		local curent_vel = ctx.local_velocity * 1.25 + base_vel;

		local target_vel = (base_vel + smoothed_velocity * 1.25):normalize();
		if (curent_vel:dot(direction) > 0) then
			target_vel = direction;
		end;

		local throw_yaw = CalculateThrowYaw(target_vel, ctx.local_velocity, weaponData.flThrowVelocity, m_flThrowStrength);

		if bit.hasnt(flags, FL.ONGROUND) then
			cmd.viewangles.yaw = throw_yaw;
		end;
	end;

	if (type == 1) then
		cmd.viewangles.pitch = cmd.viewangles.pitch + CalculateThrowPitch(cmd.viewangles:forward(), math.clamp(ctx.local_velocity.z, -120, 120), ctx.local_velocity, weaponData.flThrowVelocity, m_flThrowStrength);
	end;
end;

register_callback('create_move', update);
register_callback('create_move', function(cmd)
	xpcall(CompensateThrowable, print, cmd);
end);
