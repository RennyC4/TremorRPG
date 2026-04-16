//
// Monster animation handler
//

void() Ally_Animate =
{
	float speed = 1; // default base speed
	float duration = frameduration(self.modelindex, self.frame);

	if (self.anistate == ANISTATE_DEATH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Death")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Death");

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += frametime * speed;
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

	if (self.anistate == ANISTATE_BLOCK)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Block")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Block");

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		if (self.frame1time >= duration - 0.1)
			self.frame1time = self.frame1time; // hold
		else
			self.frame1time += speed;
		return;
	}

	if (self.anistate == ANISTATE_PUNCH)
	{
		if (self.frame != (self.frame = frameforname(self.modelindex, "Punch")))
			self.frame1time = 0; // reset timestamp
		self.frame = frameforname(self.modelindex, "Punch");

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

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

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

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

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

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

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

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

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

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

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Switch frame at the end
            self.frame1time = duration - 0.1;

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
		speed /= 2; // fix minimap on animation speed

	if (self.anistate == ANISTATE_NONE)
		self.frame = frameforname(self.modelindex, "Idle");
	if (self.anistate == ANISTATE_RUN)
		self.frame = frameforname(self.modelindex, "Run");

	speed = (speed * frametime);

	self.frame1time += speed;
	self.frame2time += speed;
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};

float(void) Ally_PreDraw =
{
	// interpolate stuff first to get proper angles/origin
	entity_interpolate(self);
	// animate and set objects after to get correct bone origins/angles
	Ally_Animate();

	// Allies have swords + shields already on their model (TODO: Remove them?)
	//Skeleton_ObjectDraw();

	addentity(self);
	
	return PREDRAW_NEXT;
};


