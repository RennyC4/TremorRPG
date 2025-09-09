//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	#define FIRSTFRAME 0

	float speed = 3; // default animation speed 3 (normal), 1 (slow), 6 (fast)
	float duration = frameduration(self.modelindex, self.frame);

	// Grab health and do death stuff here

	if (self.flags & FL_ONGROUND || self.flags & FL_PARTIALGROUND)
		self.jump = FALSE; // remove animation early

	// Attack
	if (self.attacking)
	{
		self.frame = $slash;
		// SendEvent Melee: DoAttack_Melee();
		// TODO: Grab attack speed and calulate into duration
		duration -= (frametime * speed);
		if (self.frame1time >= duration)
			self.attacking = FALSE;
	}
	else
	{
		// Jump
		if (self.jump && !self.climbing)
		{
			speed = 4;
			duration -= (frametime * speed);
			if (self.frame1time >= duration)
				self.jump = FALSE;
			self.frame = $jump;
		}
		else if (self.climbing) // Climbing
		{
			self.jump = FALSE;
			float skill_climb = getstatf(STAT_SKILL_CLIMB);
			speed = 3 + (skill_climb * 0.02);
			self.frame = $climb;
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
	}

	// Lerping isn't working properly
	/*
	self.lerpfrac -= frametime * 4;
	while (self.lerpfrac < 0) // protects against sudden low framerates
	{
		self.frame2 = self.frame; 				  // if we're at 0, frame2 became redundant anyway
		self.frame += 1;						  // move on to the next frame
		if (self.frame >= (self.frame + (duration -= (frametime * speed)))) //this should be relative to the current animation that should be shown
			self.frame = FIRSTFRAME;			  // restart it
		self.lerpfrac += 1;						  //go to the start of the frame
	}
	*/

	self.frame1time += frametime * speed;
	self.frame2time += frametime * speed;

	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};
