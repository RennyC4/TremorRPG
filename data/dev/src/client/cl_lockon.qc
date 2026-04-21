// ============================
// Lock On
// ============================
const float LOCK_ON_FOV  = 0.86;
const float LOCK_ON_DIST = 2000;

float lock_on_active;
entity lock_on_target;
entity lockon_focus; // smoothed tracking entity
float lockon_smoothness = 5; // higher = faster snapping
vector lockon_angles;

float(entity targ) Monster_Visible;

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

// =======================================
// LOCKON FOCUS FOLLOW ENTITY
// =======================================
void() CSQC_LockOn_Focus_Update =
{
	if (!lock_on_active || !lock_on_target || lock_on_target.health <= 0)
		return;

	if (!lockon_focus)
		lockon_focus = spawn();

	vector desired_pos = lock_on_target.origin + lock_on_target.view_ofs;
	vector current_pos = lockon_focus.origin;

	// smooth positional lerp for focus
	float dt = frametime;
	float focus_speed = 10; // adjust for snappiness
	vector new_pos = current_pos + (desired_pos - current_pos) * min(1, focus_speed * dt);

	lockon_focus.origin = new_pos;
};

void() CSQC_LockOn_Update =
{
    float player_health = getstatf(STAT_HEALTH);
    float atbonfire = getstatf(STAT_BONFIRE);

    // --- Update smooth follow position ---
    CSQC_LockOn_Focus_Update();

    if (lock_on_active && lock_on_target && lock_on_target.health > 0)
    {
        // --- EARLY AUTO-UNLOCK (PVP checks before any rotation) ---
        if (
            ((self.flags & FL_CLIENT) && self.pvp != 1 && (lock_on_target.flags & FL_CLIENT)) || // self turned off PVP
            ((lock_on_target.flags & FL_CLIENT) && lock_on_target.pvp != 1)                     // target turned off PVP
        )
        {
            sendevent("PitchUpdate", "v", lockon_angles);
            lock_on_target = world;
            lock_on_active = FALSE;

            if (lockon_focus)
            {
                remove(lockon_focus);
                lockon_focus = world;
            }
            return; // stop immediately so it doesn’t continue rotating
        }

        // --- Normal lock-on aim update ---
        if (lockon_focus) // use smoothed focus entity, not target directly
            vector dir = normalize(lockon_focus.origin - vPlayerOrigin);
        else
            dir = normalize(lock_on_target.origin - vPlayerOrigin);

        vector dir2 = normalize(lock_on_target.origin - vPlayerOrigin);

        vector target_ang = vectoangles(dir);
        vector target_angx = vectoangles(dir2);

        // only yaw is smoothed
        lockon_angles_y = LerpYaw(lockon_angles_y, target_ang_y, lockon_smoothness, frametime);

        // keep pitch/roll instantaneous
        lockon_angles_x = target_angx_x;
        lockon_angles_z = target_ang_z;

        vector new_angles = [target_angx_x, lockon_angles_y, 0];

        setproperty(VF_ANGLES, new_angles);
        setproperty(VF_CL_VIEWANGLES_Y, lockon_angles_y);
    }

    // --- Auto unlock (redundant safety) ---
    if (lock_on_active && (
        !lock_on_target ||
        player_health <= 0 ||
        atbonfire ||
        lock_on_target.health <= 0 ||
        ((self.flags & FL_CLIENT) && self.pvp != 1 && (lock_on_target.flags & FL_CLIENT)) ||
        ((lock_on_target.flags & FL_CLIENT) && lock_on_target.pvp != 1) ||
        vlen(lock_on_target.origin - vPlayerOrigin) > LOCK_ON_DIST ||
        lock_on_target.ai_mode == AI_RUNBACK))
    {
        sendevent("PitchUpdate", "v", lockon_angles);
        lock_on_target = world;
        lock_on_active = FALSE;

        if (lockon_focus)
        {
            remove(lockon_focus);
            lockon_focus = world;
        }
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
		if (!Monster_Visible(e)) continue;

		if (dist < best_dist)
		{
			best_dist = dist;
			best = e;
		}
	}

	// find players
	for (entity e = world; (e = find(e, classname, "player")); )
	{
		if (!e || e.health <= 0 || e.pvp != 1 || e == self || self.pvp != 1)
			continue;

		vector dir = e.origin - self.origin;
		float dist = vlen(dir);
		if (dist > LOCK_ON_DIST) continue;
		dir = normalize(dir);

		float dot = vdot(forward, dir);
		if (dot < LOCK_ON_FOV) continue;
		if (!Monster_Visible(e)) continue;

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
		if (!Monster_Visible(e)) continue;
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
		if (!Monster_Visible(e)) continue;
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