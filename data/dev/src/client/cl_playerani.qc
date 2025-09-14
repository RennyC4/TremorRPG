//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	float speed = 1;
	float duration = frameduration(self.modelindex, self.frame);
	float duration2 = duration + (frametime * speed); // if animation uses speed

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
			speed = 1 + (skill_climb * 0.02);
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

	if (self.health > 0)
	{
		self.frame1time += frametime * speed;
		self.frame2time += frametime * speed;
	}
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};
