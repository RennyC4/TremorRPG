//
// Player animations
//

$frame climb death stand jump move slash

void() Player_Animate =
{
	#define FIRSTFRAME 0

	float speed = 3; // default animation speed 3 (normal), 1 (slow), 6 (fast)
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
				self.frame1time += frametime * 3;
		}
	}
	else // Alive
	{
		if (self.melee_finished > time) // Attack
		{
			speed = 3; // TODO: Calculate speed with melee_finished timer stuff
			self.frame = $slash;
			duration -= (frametime * speed);

			// SendEvent Melee: DoAttack_Melee();
		}
		else
		{
			if (self.jump && !self.climbing) // Jump
			{
				if (self.gender == "Male") speed = 4;
				else 					   speed = 3;

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
				if (!self.velocity_x && !self.velocity_y) // Idle
					self.frame = $stand;
				else // Moving
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

	if (self.health > 0)
	{
		self.frame1time += frametime * speed;
		self.frame2time += frametime * speed;
	}
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};
