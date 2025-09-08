//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	#define FIRSTFRAME 0

	float speed = 3; // default animation speed 3 (normal), 1 (slow), 6 (fast)
	float framedur = frameduration(self.modelindex, self.frame);
	self.lerpfrac -= (frametime * speed) * 2; // adjust according to how fast you want a lerp animation to move

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
			self.frame = $stand;
		else // Moving
		{
			speed = 4;
			self.frame = $move;
		}
	}

	while (self.lerpfrac < 0) // protects against sudden low framerates
	{
		self.frame2 = self.frame; 				 // if we're at 0, frame2 became redundant anyway
		self.frame += 1;						 // move on to the next frame
		if (self.frame >= self.frame + framedur) //this should be relative to the current animation that should be shown
			self.frame = FIRSTFRAME;			 // restart it
		self.lerpfrac += 1;						 //go to the start of the frame
	}

	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");

	self.frame1time += frametime * speed;
	self.frame2time = self.frame1time;
};
