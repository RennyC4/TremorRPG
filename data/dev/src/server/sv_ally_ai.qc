//
// Allies and special character AI functions are handled here
//

void() ally_ai_think;
void() ally_respawn;

void() ally_death =
{
	self.SendFlags = 1;
	self.goalentity = self.enemy = world; // reset targets
	self.velocity = '0 0 0'; // slide fix
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = FALSE;

	//self.think = ally_death2;
	//self.nextthink = time;
};

void() ally_ai_melee =
{
	if (self.melee_finished < time && self.stagger_finished < time)
	{
		if (self.noise1)
			sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
		if (self.enemy)
			self.enemy.incombat_finished = time + 15;

		// Done through CSQC when we get there
		self.melee_finished = time + self.attack_speed;
	}
	else
	{
		self.think = ally_ai_think;
		self.nextthink = time + 0.1;
	}
};

void() ally_ai_move =
{
	if (self.stagger_finished > time)
		return;

	if (self.enemy)
	{
		if (self.ai_backup_finished > time)
			walkmove(self.angles_y, self.speed * -1); // keep ally slightly back from target

		if (range(self.enemy) == RANGE_CLOSE)
			self.ai_backup_finished = time + random_range(0.7, 2.5); // too close, back up a bit
		if (range(self.enemy) == RANGE_MELEE)
			return; // don't move
	}
	movetogoal(self.speed);

	self.velocity = '0 0 0';
	if (self.ai_mode == AI_RUNBACK) // ally is running back to origin
	{
		self.flags -= (self.flags & FL_ONGROUND);
		vector forward = v_forward * 150;
		self.velocity = forward;
	}
};

void() ally_ai_spawnrunback =
{
	if (!self.ai_runback_temp)
	{
		self.ai_runback_temp = spawn();
		self.ai_runback_temp.owner = self;
		setmodel(self.ai_runback_temp, string_null);
		setorigin(self.ai_runback_temp, self.origin);
	}
};

// main ally ai execution function
void() ally_ai_think =
{
	self.SendFlags = 1;
	makevectors(self.angles);

	// Debugging
	//string l = ftos(self.ai_mode);
	//print(l, "\n");

	if (self.ai_mode == AI_IDLE || self.ai_mode == AI_PATROL)
	{
		if (self.health != self.max_health) // allies have full health in patrol mode
			self.health = self.max_health;

		// randomly turn and move
		if (self.ai_patrolidle < time)
		{
			self.angles_x = 0;
			self.idealangles_y = random()*360;
			if (self.ai_move_dist > 1)
				self.ai_patrolidle = time + 3 + random()*6;
			if (random() < 0.35)
				self.ai_standstill = time + 1 + random()*8;
			TurnToTarget(self.turn_speed);
			self.ai_mode = AI_IDLE;
		}
		else
		{
			if (self.ai_standstill < time)
			{
				if (!walkmove(self.angles_y, self.speed / 4)) // failed, changed direction
					self.idealangles_y = random() * 360;
				self.ai_mode = AI_PATROL;
			}
		}

		// Patrolling randomly, searching for monsters nearby
		for (entity targ = world;(targ = find(targ, classname, "monster"));)
		{
			if (vlen(targ.origin - self.origin) <= self.sight_range && targ.deadflag != DEAD_DEAD && visible(targ))
			{
				if (self.noise)
					sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
				self.goalentity = self.enemy = targ;
				self.ai_mode = AI_CHASE;
				targ.incombat = TRUE; // flag monsters for combat
				targ.incombat_finished = time + 15;
				string eventlog_print = (strcat("^1You engage in combat!\n"));
				stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));

			}
		}
	}

	// Keep track of saved origin
	float b = vlen(self.origin - self.saveorigin);
	if (self.ai_mode != AI_RUNBACK)
	{
		// allies have default range of 2000 for chasing a target if they're not patrolling
		if (self.ai_move_dist <= 1)
			float ai_move_dist_check = 2000;
		else
			ai_move_dist_check = self.ai_move_dist;
			
		if (b >= ai_move_dist_check)
		{
			self.goalentity = self.ai_runback_temp;
			if (!self.goalentity)
				print ("error in ally ai\n");

			self.enemy = world;
			self.ai_mode = AI_RUNBACK;
		}
	}
	else // AI is jogging back close to spawn spot
	{
		if (b > 50)
		{
			float base_speed = 50; // min speed
			float scale = 2; // speed vs dist

			float dz = self.ai_runback_temp.origin_z - self.origin_z;
			if (dz != 0) 
			{
				float speed = base_speed + fabs(dz) * scale; // speed vs dist
				float step = frametime * speed;

				if (fabs(dz) < step)
					self.origin_z = self.ai_runback_temp.origin_z; // snap when close
				else
					self.origin_z += step * (dz > 0 ? 1 : -1);
			}

			// ghost effect when moving back
			self.alpha = 0.25;
			self.effects |= EF_ADDITIVE;

			self.enemy = world;
			self.goalentity = self.ai_runback_temp;
			self.movetype = MOVETYPE_NOCLIP; // cheating but eh
			if (self.health != self.max_health)
				self.health = self.max_health; // restore health on trip back
		}
		else
		{
			setorigin(self, self.saveorigin);
			self.enemy = world;
			self.goalentity = world;
			self.movetype = MOVETYPE_STEP;
			self.ai_mode = AI_IDLE;

			// remove ghost effect
			self.alpha = 1;
			self.effects &= ~EF_ADDITIVE;
		}
	}

	if (self.goalentity) 
	{
		if (self.stagger_finished < time)
		{
			if (self.melee_finished > time) // TODO? : Ally attack tracking can be done animation+per-ally
				TurnToTarget(self.turn_speed / 2);
			else
				TurnToTarget(self.turn_speed);
		}

		if (self.ai_mode != AI_RUNBACK)
			self.ai_mode = AI_CHASE;

		if (self.enemy.classname == "monster" && self.enemy.health > 0)
		{
			if (range(self.enemy) == RANGE_MELEE || range(self.enemy) == RANGE_CLOSE)
			{
				if (!self.enemy.incombat)
				{
					self.enemy.incombat = TRUE; // turn on during an attack incase another ally somehow flags it off
					self.enemy.incombat_finished = time + 15;
				}
				self.ai_mode = AI_ATTACK;
				self.think = ally_ai_melee;
				self.nextthink = time + 0.1;
			}
			else
				self.ai_mode = AI_CHASE;
		}
		ally_ai_move();
	}

	// enemy dead / used a bonfire
	if (self.enemy && self.enemy.health <= 0)
	{
		self.oldenemy = self.enemy; // stash last killed or lost to bonfire
		self.enemy = self.goalentity = world;
		self.ai_mode = AI_IDLE;
	}

	// Debugging
	//print ("Dist: ", ftos(b), "\n");

	self.nextthink = time + 0.1;
};