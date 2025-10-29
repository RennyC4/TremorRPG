// ============================
// CONFIG
// ============================
const float LOCK_ON_FOV  = 0.86;
const float LOCK_ON_DIST = 2000;

float lock_on_active;
entity lock_on_target;
entity lockon_focus; // smoothed tracking entity
float lockon_smoothness = 5; // higher = faster snapping
vector lockon_angles;

// Utility
float(vector a, vector b) vdot = { return a_x * b_x + a_y * b_y + a_z * b_z; };

float LerpYaw(float current, float target, float smoothness, float dt)
{
    float delta = target - current;

    // normalize delta to -180..180
    while (delta > 180)  delta -= 360;
    while (delta < -180) delta += 360;

    // soft frame-rate independent alpha
    float alpha = smoothness * dt / (1 + smoothness * dt);

    return current + delta * alpha;
}

// ============================
// VISIBILITY CHECK
// ============================
float(entity targ) LockOn_Visible =
{
	vector start = self.origin + self.view_ofs;
	vector end   = targ.origin + targ.view_ofs;

	traceline(start, end, TRUE, world);
	if (trace_fraction == 1 || trace_ent == targ)
		return TRUE;
	return FALSE;
};

// ============================
// LOCK-ON UI DRAWING
// ============================
void(vector where) CSQC_LockOn_Plaques =
{
	vector plaque_coord = project(where);

	if (plaque_coord_y > g_height / 2)
		plaque_coord_y = g_height / 2;

	plaque_coord_x -= 16;
	plaque_coord_y -= 16;

	if (plaque_coord_z > 0)
	{
		string name = (lock_on_target.classname == "player") ?
			lock_on_target.netname : lock_on_target.displayname;

		drawstring(plaque_coord + [1,1], name, [10,10], [0,0,0], 1, 0);
		drawstring(plaque_coord, name, [10,10], [1,1,1], 1, 0);
	}

	// health bar
	plaque_coord_x -= 12;
	plaque_coord_y += 8;
	vector hbar_size = '50 4 0';
	hbar_size_x = (lock_on_target.health / lock_on_target.max_health) * hbar_size_x;
	if (plaque_coord_z > 0)
	{
		drawfill(plaque_coord + [1,3], hbar_size, '0 0 0', 1, 0);
		drawfill(plaque_coord + [0,2], hbar_size, '0.5 0 0', 1, 0);
	}

	// level
	plaque_coord_x += 28;
	string lvl = ftos(lock_on_target.level);
	if (plaque_coord_z > 0)
	{
		drawstring(plaque_coord + [25,-1], lvl, [10,10], [0,0,0], 1, 0);
		drawstring(plaque_coord + [24,-2], lvl, [10,10], [1,.8,0], 1, 0);
	}

	// crosshair
	vector target_coord = project(where);
	target_coord_x -= 32;
	target_coord_y -= 32;
	if (target_coord_y > g_height / 1.75)
		target_coord_y = g_height / 1.75;
	if (target_coord_z > 0)
		drawpic(target_coord, "progs/targetdot.spr_0", [64,64], '1 1 1', 1, 0);
};

void() CSQC_LockOn_Update =
{
    float player_health = getstatf(STAT_HEALTH);
    float atbonfire = getstatf(STAT_BONFIRE);

    if (lock_on_active && lock_on_target && lock_on_target.health > 0)
    {
        vector dir = normalize(lock_on_target.origin - vPlayerOrigin);
        vector target_ang = vectoangles(dir);

        // smooth yaw (Y axis) with wrap-around & soft frame-rate adjustment
        lockon_angles_y = LerpYaw(lockon_angles_y, target_ang_y, lockon_smoothness, frametime);

        // optional: pitch/roll instantaneous
        lockon_angles_x = target_ang_x;
        lockon_angles_z = target_ang_z;

        vector new_angles = [lockon_angles_x, lockon_angles_y, lockon_angles_z];

        setproperty(VF_ANGLES, new_angles);
        setproperty(VF_CL_VIEWANGLES_Y, lockon_angles_y);
    }

    // auto unlock
    if (lock_on_active && (!lock_on_target || player_health <= 0 || atbonfire || lock_on_target.health <= 0 || vlen(lock_on_target.origin - vPlayerOrigin) > LOCK_ON_DIST || lock_on_target.ai_mode == AI_RUNBACK))
    {
        lock_on_target = world;
        lock_on_active = FALSE;
        sendevent("PitchUpdate", "v", lockon_angles);
    }
};

// ============================
// LOCK-ON TOGGLE
// ============================
void() CSQC_LockOn_Toggle =
{
	if (lock_on_active)
	{
		lock_on_active = FALSE;
		lock_on_target = world;
		if (lockon_focus) { remove(lockon_focus); lockon_focus = world; }
		sendevent("PitchUpdate", "v", lockon_angles);
		return;
	}

	entity best = world;
	float best_dist = LOCK_ON_DIST;
	vector player_ang = getproperty(VF_ANGLES);
	makevectors(player_ang);
	vector forward = v_forward;

	// find monsters
	for (entity e = world; (e = find(e, classname, "monster")); )
	{
		if (!e || e.health <= 0 || e.ai_mode == AI_RUNBACK || e == self)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > LOCK_ON_DIST) continue;
		dir = normalize(dir);

		float dot = vdot(forward, dir);
		if (dot < LOCK_ON_FOV) continue;
		if (!LockOn_Visible(e)) continue;

		if (dist < best_dist)
		{
			best_dist = dist;
			best = e;
		}
	}

	// find players
	for (entity e = world; (e = find(e, classname, "player")); )
	{
		if (!e || e.health <= 0 || e.pvp != 1 || e == self)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > LOCK_ON_DIST) continue;
		dir = normalize(dir);

		float dot = vdot(forward, dir);
		if (dot < LOCK_ON_FOV) continue;
		if (!LockOn_Visible(e)) continue;

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

		// spawn focus entity
		if (!lockon_focus)
			lockon_focus = spawn();
		lockon_focus.origin = lock_on_target.origin + lock_on_target.view_ofs;

		// set initial direction
		vector dir = normalize(lockon_focus.origin - vPlayerOrigin);
		lockon_angles = vectoangles(dir);

		sendevent("PitchUpdate", "v", lockon_angles);
	}
	else
	{
		lock_on_target = world;
		lock_on_active = FALSE;
	}
};

// ============================
// LOCK-ON CYCLE
// ============================
void() CSQC_LockOn_Cycle =
{
	if (!lock_on_active)
		return;

	entity best = world;
	float best_dot = -1;
	vector player_ang = getproperty(VF_ANGLES);
	makevectors(player_ang);
	vector forward = v_forward;
	entity current = lock_on_target;

	for (entity e = world; (e = find(e, classname, "monster")); )
	{
		if (!e || e.health <= 0 || e == current || e.ai_mode == AI_RUNBACK || e == self)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);
		if (dot < LOCK_ON_FOV) continue;
		if (!LockOn_Visible(e)) continue;
		if (dot > best_dot)
		{
			best_dot = dot;
			best = e;
		}
	}

	for (entity e = world; (e = find(e, classname, "player")); )
	{
		if (!e || e.health <= 0 || e == current || e.pvp != 1 || e == self)
			continue;

		vector dir = normalize(e.origin - self.origin);
		float dot = vdot(forward, dir);
		if (dot < LOCK_ON_FOV) continue;
		if (!LockOn_Visible(e)) continue;
		if (dot > best_dot)
		{
			best_dot = dot;
			best = e;
		}
	}

	if (best && best != world)
	{
		lock_on_target = best;
		if (lockon_focus)
			lockon_focus.origin = lock_on_target.origin + lock_on_target.view_ofs;
	}
	sendevent("PitchUpdate", "v", lockon_angles);
};