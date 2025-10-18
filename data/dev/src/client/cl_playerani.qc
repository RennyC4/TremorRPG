//
// Player animations
//

.float ani_death;

void() Player_Animate =
{
	float speed = 1; // default base speed
	float duration = frameduration(self.modelindex, self.frame);

	if (self.health <= 0) // death
	{
		if (!self.ani_death)
		{
			self.frame1time = 0; // reset timestamp
			self.frame = frameforname(self.modelindex, "Death");
			self.ani_death = TRUE;
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
		if (self.ani_death)
			self.ani_death = FALSE;
		if (self.attacking)
		{
			float attackspeed = getstatf(STAT_ATTACKSPEED); // attack speed affects speed of animation
			if (attackspeed > 0)
				speed /= attackspeed;

			// TODO: attack animation tied to weapon type
			if (self.frame != frameforname(self.modelindex, "Slash"))
			{
				self.frame1time = 0; // reset timestamp
				self.frame = frameforname(self.modelindex, "Slash");
			}

			if (self.frame1time >= duration - 0.1)
				self.attacking = FALSE;

			//print (ftos(duration), "\n");
			//print (ftos(speed), "\n");
		}
		else
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
				{
					if (self.frame != frameforname(self.modelindex, "Idle"))
						self.frame1time = 0; // reset timestamp

					string gender = getstats(STAT_GENDER);
					if (gender == "Female")
						speed = 0.5;

					self.frame = frameforname(self.modelindex, "Idle");
				}
				else // moving
					self.frame = frameforname(self.modelindex, "Run");
			}
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