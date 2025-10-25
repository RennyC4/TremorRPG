const float lock_on_fov = 0.86;
const float lock_on_dist = 2000;

float lock_on_active;
entity lock_on_target;

float(vector a, vector b) vdot = {return a_x * b_x + a_y * b_y + a_z * b_z;};

float(entity targ) LockOn_Visible =
{
	vector start = self.origin + self.view_ofs;
	vector end = targ.origin + targ.view_ofs; // add nudge?

	traceline(start, end, TRUE, world);
	if (trace_fraction == 1 || trace_ent == targ)
		return TRUE; // clear line of sight return FALSE; 
};

void(vector where) CSQC_LockOn_Plaques =
{
	vector plaque_coord = project(where);

	if (plaque_coord_y > g_height / 2) // snap plaque
		plaque_coord_y = g_height / 2;

	plaque_coord_x -= 16; // center it
	plaque_coord_y -= 16;

	if (plaque_coord_z > 0)
	{
		if (lock_on_target.classname == "player")
		{
			drawstring(plaque_coord+[1,1], lock_on_target.netname, [10, 10], [0, 0, 0], 1, 0); // shadow
			drawstring(plaque_coord, lock_on_target.netname, [10, 10], [1, 1, 1], 1, 0);
		}
		else
		{
			drawstring(plaque_coord+[1,1], lock_on_target.displayname, [10, 10], [0, 0, 0], 1, 0); // shadow
			drawstring(plaque_coord, lock_on_target.displayname, [10, 10], [1, 1, 1], 1, 0);
		}
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

vector lockon_angles;
void() CSQC_LockOn_Update =
{
	float player_health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

	if (lock_on_active && lock_on_target && lock_on_target.health > 0)
	{
		vector dir = normalize(lock_on_target.origin - vPlayerOrigin); // don't change vPlayerOrigin, otherwise things break
		vector ang = vectoangles(dir);

		setproperty(VF_ANGLES, ang);
		setproperty(VF_CL_VIEWANGLES_Y, ang_y);

		//setproperty(VF_CL_VIEWANGLES, ang);
		lockon_angles = ang;
	}

	// auto unlock
	if (lock_on_active && (!lock_on_target || player_health <= 0 || atbonfire || lock_on_target.health <= 0 || vlen(lock_on_target.origin - vPlayerOrigin) > lock_on_dist || lock_on_target.ai_mode == AI_RUNBACK))
	{
		lock_on_target = world;
		lock_on_active = FALSE;
		sendevent("PitchUpdate", "v", lockon_angles);
	}
};

void() CSQC_LockOn_Toggle =
{
	if (lock_on_active) // unlock
	{
		lock_on_active = FALSE;
		lock_on_target = world;
		sendevent("PitchUpdate", "v", lockon_angles);
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
		if (!e || e.health <= 0 || e.ai_mode == AI_RUNBACK || e == self)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > lock_on_dist)
			continue;

		dir = normalize(dir);

		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)	continue;
		if (!LockOn_Visible(e)) continue;

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
		if (!e || e.health <= 0 || e.pvp != 1 || e == self)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > lock_on_dist)
			continue;

		dir = normalize(dir);

		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)	continue;
		if (!LockOn_Visible(e)) continue;

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
		sendevent("PitchUpdate", "v", lockon_angles);
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
		if (!e || e.health <= 0 || e == current || e.ai_mode == AI_RUNBACK || e == self)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)	continue;
		if (!LockOn_Visible(e)) continue;

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
		if (!e || e.health <= 0 || e == current || e.pvp != 1 || e == self)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);

		if (dot < lock_on_fov)	continue;
		if (!LockOn_Visible(e)) continue;

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
	sendevent("PitchUpdate", "v", lockon_angles);
};