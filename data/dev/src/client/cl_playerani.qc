//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	float speed = 1; // default base speed
	float duration = frameduration(self.modelindex, self.frame);

	if (self.health <= 0) // Death
	{
		if (self.frame != $death)
		{
			self.frame1time = 0; // reset timestamp
			self.frame = $death;
		}
		else
		{
			if (self.frame1time >= duration - 0.1)
				self.frame1time = self.frame1time; // hold
			else
				self.frame1time += frametime;
		}
	}
	else // Alive
	{
		if (self.climbing) // Climbing
		{
			float skill_climb = getstatf(STAT_SKILL_CLIMB);
			speed += (skill_climb * 0.005);
			self.frame = $climb;
		}
		else
		{
			if (!self.velocity_x && !self.velocity_y) // Idle
				self.frame = $stand;
			else // Moving
				self.frame = $move;
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