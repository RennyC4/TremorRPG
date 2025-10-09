//
// Monster animation handler
//

const float AI_IDLE = 0;
const float AI_CHASE = 1;
const float AI_ATTACK = 2;
const float AI_RUNBACK = 3;
const float AI_PATROL = 4;

void() Monster_Animate =
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

		if (self.ai_mode == AI_IDLE)
			self.frame = frameforname(self.modelindex, "Idle");
		else // moving
		{
			if (self.ai_mode == AI_ATTACK)
			{
				if (self.frame != (self.frame = frameforname(self.modelindex, "Slash")))
					self.frame1time = 0; // reset timestamp
				self.frame = frameforname(self.modelindex, "Slash");
				speed = 1.5;
			}
			else
				self.frame = frameforname(self.modelindex, "Run");
		}
	}

	speed = (speed * frametime);
//	if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp") // mini-map only on over world, full mini-map affects player animation speed for some reason
//		speed /= 2;

	if (self.health > 0)
	{
		self.frame1time += speed;
		self.frame2time += speed;
	}
	//print (ftos(frameduration(self.modelindex,self.frame)), "\n");
};

float(void) Monster_PreDraw =
{
	Monster_Animate();
	addentity(self);
    return PREDRAW_NEXT;
};