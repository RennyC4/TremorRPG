const float lock_on_fov = 0.17;
const float lock_on_dist = 2000;

float lock_on_active;
entity lock_on_target;

float(vector a, vector b) vdot = {return a_x * b_x + a_y * b_y + a_z * b_z;};

void(vector where) CSQC_LockOn_Plaques =
{
	vector plaque_coord = project(where);

	if (plaque_coord_y > g_height / 2) // snap plaque
		plaque_coord_y = g_height / 2;

	plaque_coord_x -= 16; // center it
	plaque_coord_y -= 16;

	// TODO, use players netname if they're not a monster
	if (plaque_coord_z > 0)
	{
		drawstring(plaque_coord+[1,1], lock_on_target.displayname, [10, 10], [0, 0, 0], 1, 0); // shadow
		drawstring(plaque_coord, lock_on_target.displayname, [10, 10], [1, 1, 1], 1, 0);
	}

	// draw bar + level
	plaque_coord_x -= 12;
	plaque_coord_y += 8;

	vector hbar_size = '50 4 0';
	hbar_size_x = (lock_on_target.health / lock_on_target.max_health) * hbar_size_x; // keep bar updated
	if (plaque_coord_z > 0)
	{
		drawfill(plaque_coord + [1 , 3], hbar_size, '0 0 0', 1, 0); // shadow
		drawfill(plaque_coord + [0 , 2], hbar_size, '0.5 0 0', 1, 0);
	}

	plaque_coord_x += 28;
	string lvl = ftos(lock_on_target.level);
	if (plaque_coord_z > 0)
	{
		drawstring(plaque_coord + [25, -1], lvl, [10, 10], [0, 0, 0], 1, 0); // shadow
		drawstring(plaque_coord + [24, -2], lvl, [10, 10], [1, .8, 0], 1, 0);
	}
	//
	//

	// crosshair on target
	vector target_coord = project(where);
	target_coord_x -= 32;
	target_coord_y -= 32;

	if (target_coord_y > g_height / 1.75) // snap target crosshair
		target_coord_y = g_height / 1.75;
	
	if (target_coord_z > 0)
		drawpic(target_coord, "progs/targetdot.spr_0", [64, 64], '1 1 1', 1, 0);
};

void() CSQC_LockOn_Update =
{
	if (lock_on_active && lock_on_target && lock_on_target.health > 0)
	{
		vector lockon_pos = lock_on_target.origin;
		vector player_ang = getproperty(VF_ANGLES);

		vector dir = normalize(lockon_pos - vPlayerOrigin); // don't change vPlayerOrigin, otherwise things break
		vector ang = vectoangles(dir);

		float dt = frametime * 2;   // frame delta time
		float turn_speed = 360; // degrees per second

		// Smoothly approach target yaw/pitch *broken / crap*
		//player_ang[0] = ApproachAngle(player_ang[0], ang_x, turn_speed, dt);
		//player_ang[1] = ApproachAngle(player_ang[1], ang_y, turn_speed, dt);

		player_ang[0] = ang_x;
		player_ang[1] = ang_y;

		// apply
		makevectors(player_ang);
		setproperty(VF_ANGLES, player_ang);

		sendevent("PlayerUpdateAngles_Lockon", "v", player_ang); // update angles on SSQC
		CSQC_LockOn_Plaques(lock_on_target.origin);
	}
	else
	{
		// auto unlock
		if (lock_on_active && (!lock_on_target || lock_on_target.health <= 0 || vlen(lock_on_target.origin - self.origin) > lock_on_dist) || lock_on_target.ai_mode == AI_RUNBACK)
		{
			lock_on_active = FALSE;
			lock_on_target = world;
		}
	}
};

void() CSQC_LockOn_Toggle =
{
	if (lock_on_active) // unlock
	{
		lock_on_active = FALSE;
		lock_on_target = world;
		return;
	}

	entity best = world;
	float best_dist = lock_on_dist;
	vector player_ang = getproperty(VF_ANGLES);
	makevectors(player_ang);

	vector forward = v_forward;

	// search for monsters
	for (entity e = world; (e = find(e, classname, "monster")); )
	{
		// skip dead or invalid
		if (!e || e.health <= 0 || e.ai_mode == AI_RUNBACK)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > lock_on_dist)
			continue;

		dir = normalize(dir);

		float dot = vdot(forward, dir);
		if (dot < lock_on_fov)
			continue;

		// closer target wins
		if (dist < best_dist)
		{
			best_dist = dist;
			best = e;
		}
	}

	// search for players
	for (entity e = world; (e = find(e, classname, "player")); )
	{
		// skip dead or invalid
		if (!e || e.health <= 0)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > lock_on_dist)
			continue;

		dir = normalize(dir);

		float dot = vdot(forward, dir);
		if (dot < lock_on_fov)
			continue;

		// closer target wins
		if (dist < best_dist)
		{
			best_dist = dist;
			best = e;
		}
	}

	if (best)
	{
		lock_on_target = best;
		lock_on_active = TRUE;
	}
	else
	{
		lock_on_target = world;
		lock_on_active = FALSE;
	}
};

void() CSQC_LockOn_Cycle =
{
	if (!lock_on_active)
		return; // no lock to cycle through

	entity best = world;
	float best_dot = -1;

	vector player_ang = getproperty(VF_ANGLES);
	makevectors(player_ang);

	vector forward = v_forward;
	entity current = lock_on_target;

	// search for monsters
	for (entity e = world; (e = find(e, classname, "monster")); )
	{
		if (!e || e.health <= 0 || e == current || e.ai_mode == AI_RUNBACK)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)
			continue;

		// prioritize the next one clockwise in screen space
		// or just pick the next with higher dot (closer to forward)
		if (dot > best_dot)
		{
			best_dot = dot;
			best = e;
		}
	}

	// search for players
	for (entity e = world; (e = find(e, classname, "player")); )
	{
		if (!e || e.health <= 0 || e == current)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)
			continue;

		// prioritize the next one clockwise in screen space
		// or just pick the next with higher dot (closer to forward)
		if (dot > best_dot)
		{
			best_dot = dot;
			best = e;
		}
	}

	if (best && best != world)
		lock_on_target = best;
	else
		lock_on_target = current; // optional: reset if no valid targets left
};