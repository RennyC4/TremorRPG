//
// Player animations
//

void() Player_Animate =
{
	float speed = 1; // default base speed
	float duration = frameduration(self.modelindex, self.frame);

	if (self.health <= 0) // death
	{
		if (self.frame != $death)
		{
			self.frame1time = 0; // reset timestamp
			self.frame = frameforname(self.modelindex, "Death");
		}
		else
		{
			if (self.frame1time >= duration - 0.1)
				self.frame1time = self.frame1time; // hold
			else
				self.frame1time += frametime;
		}
	}
	else // alive
	{
		if (self.climbing) // climbing
		{
			float skill_climb = getstatf(STAT_SKILL_CLIMB);
			speed += (skill_climb * 0.005);
			self.frame = frameforname(self.modelindex, "Climb");
		}
		else
		{
			if (!self.velocity_x && !self.velocity_y) // idle
				self.frame = frameforname(self.modelindex, "Idle");
			else // moving
				self.frame = frameforname(self.modelindex, "Run");
		}
	}

	speed = (speed * frametime);
	if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp") // mini-map only on over world, full mini-map affects player animation speed for some reason
		speed /= 2;

	if (self.health > 0)
	{
		self.frame1time += speed;
		self.frame2time += speed;
	}
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};