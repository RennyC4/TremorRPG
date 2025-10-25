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
	
	speed = 1; // reset speed after attacking animations

	if (self.anistate == ANISTATE_STUNNED)
		self.frame = frameforname(self.modelindex, "Stunned");
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

float(void) Monster_PreDraw =
{
    Monster_Animate();
	Skeleton_ObjectDraw();

    self.movetype = MOVETYPE_STEP;

	// prepare rollback
	vector OldOrigin = self.origin;
	vector OldAngles = self.angles;
		
    float flSuccess;

    for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
    {
        if (input_timelength == 0)
            break;

		flSuccess = walkmove(self.angles_y, self.speed);

        if (!flSuccess)
            continue;

		self.origin += v_forward * self.speed * input_timelength; // extra smoothing - slides monsters though

        movetogoal(self.speed);
    }

    // rollback
    setorigin(self, OldOrigin);
    self.angles = OldAngles;
    self.movetype = MOVETYPE_NONE;

    addentity(self);

    return PREDRAW_NEXT;
};