//
// Monster animation handler
//

void() Monster_Animate =
{
	float speed = 1; // default base speed
	float duration = frameduration(self.modelindex, self.frame);

	if (self.anistate == ANISTATE_DEATH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Death")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Death");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += frametime;
		return;
	}

	// adjust speed by attack stat
	if (self.attack_speed)
	{
		if (!self.attack_type) // punch speed
			speed /= self.attack_speed * 0.5;
		else
			speed /= self.attack_speed * 0.75;
	}

	speed *= frametime;

	if (self.anistate == ANISTATE_PUNCH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Punch")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Punch");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	if (self.anistate == ANISTATE_SLASH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Slash")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Slash");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	if (self.anistate == ANISTATE_STAB)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Stab")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Stab");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	if (self.anistate == ANISTATE_SMASH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Smash")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Smash");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	if (self.anistate == ANISTATE_ARCHERY)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Archery")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Archery");

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	speed = 1; // reset speed after attacking animations

	if (self.anistate == ANISTATE_STUNNED)
		self.frame = frameforname(self.modelindex, "Stunned");
	
	if (self.anistate == ANISTATE_IMPACT)
	{
		if (self.frame != frameforname(self.modelindex, "Impact"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Impact");
		}
		speed *= frametime;

        if (self.frame1time >= duration - 0.1) // Switch frame at the end
            self.frame1time = duration - 0.1;

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}
	
	
	if (self.anistate == ANISTATE_NONE)
		self.frame = frameforname(self.modelindex, "Idle");
	if (self.anistate == ANISTATE_RUN)
		self.frame = frameforname(self.modelindex, "Run");

	speed = (speed * frametime);

//	if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp") // mini-map only on over world, full mini-map affects player animation speed for some reason
//		speed /= 2;

	self.frame1time += speed;
	self.frame2time += speed;
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};

.float avoid_dir;
.float avoid_time;
.vector last_origin;
.float stuck_time;
vector() monster_ai_calc_move_delta =
{
    vector dir = [cos(deg2rad(self.angles_y)), sin(deg2rad(self.angles_y)), 0];
    dir.z = 0;

    float move_dist = self.speed * 75 * frametime;
    if (self.ai_mode == AI_PATROL)
        move_dist *= 0.25;

    vector delta = dir * move_dist;

    // --- Initialize avoidance memory ---
    if (!self.avoid_dir)
    {
        self.avoid_dir = (random(0,1) < 0.5) ? 1 : -1;
        self.avoid_time = 0;
    }

    vector newpos = self.origin + delta;
    tracebox(self.origin, self.mins, self.maxs, newpos, 0, self);
    if (trace_fraction < 1)
    {
        // try stepping up
        vector step_pos = self.origin + '0 0 18';
        tracebox(step_pos, self.mins, self.maxs, step_pos + delta, 0, self);
        if (trace_fraction == 1)
        {
            delta = step_pos + delta - self.origin;
        }
        else
        {
            // slide around obstacle using avoidance memory
            float turn_angle = 30 * self.avoid_dir;
            vector slide_dir = [cos(deg2rad(self.angles_y + turn_angle)),
                                sin(deg2rad(self.angles_y + turn_angle)), 0];
            vector slide_pos = self.origin + slide_dir * move_dist;
            tracebox(self.origin, self.mins, self.maxs, slide_pos, 0, self);
            if (trace_fraction == 1)
            {
                delta = slide_pos - self.origin;
                self.angles_y += turn_angle;
                self.avoid_time = time + 0.5;
            }
            else
            {
                self.avoid_dir *= -1; // reverse avoidance
                delta = '0 0 0';
            }
        }
    }
    else
    {
        // path clear, reset avoidance after time expires
        if (time > self.avoid_time)
        {
            self.avoid_dir = 0;
            self.avoid_time = 0;
        }
    }

    // --- Ground snap ---
    vector start = self.origin + '0 0 16';
    vector end   = self.origin - '0 0 128';
    tracebox(start, self.mins, self.maxs, end, 0, self);
    if (trace_fraction < 1)
        delta = start + (end - start) * trace_fraction - self.origin;

    // --- Stuck detection ---
    if (!self.last_origin)
        self.last_origin = self.origin;

    if (vlen(delta) < 1) // very small movement
    {
        self.stuck_time += frametime;
        if (self.stuck_time > 0.5)
        {
            self.angles_y += random(-180, 180);
            self.stuck_time = 0;
        }
    }
    else
        self.stuck_time = 0;

    self.last_origin = self.origin; // store current origin for next frame

    return delta;
};

float(void) Monster_PreDraw =
{
    Monster_Animate();
	/*
    self.movetype = MOVETYPE_STEP;

    vector OldOrigin = self.origin;
    vector OldAngles = self.angles;

    vector total_delta = '0 0 0';
    vector move_delta;

    // --- Predict movement over all missed client frames ---
    for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
    {
        move_delta = monster_ai_calc_move_delta();
        total_delta += move_delta;
    }

    // --- Smooth interpolation ---
    float smooth_factor = 0.15 * frametime; // adjust for smoothing
    vector predicted_origin = self.origin + total_delta * smooth_factor;

    // --- Store predicted position temporarily ---
    self.origin = predicted_origin;
	*/
    // --- Draw monster at smoothed predicted position ---
    Skeleton_ObjectDraw();
    addentity(self);

	/*
    // --- Rollback to authoritative server position ---
    setorigin(self, OldOrigin);
    self.angles = OldAngles;
    self.movetype = MOVETYPE_NONE;
	*/

    return PREDRAW_NEXT;
};