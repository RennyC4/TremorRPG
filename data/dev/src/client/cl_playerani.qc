//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	float speed = 1;
	
	// Climbing
	if (self.climbing)
	{
		float skill_climb = getstatf(STAT_SKILL_CLIMB);
		speed = 3 + (skill_climb * 0.02);
		self.frame = 0;
	}
	else
	{
		// Idle
		if (!self.velocity_x && !self.velocity_y)
		{
			speed = 3;
			self.frame = $stand;
		}
		else // Moving
		{
			speed = 4;
			self.frame = $move;
		}
	}
	self.frame1time += frametime * speed;
	self.nextthink = time;
};