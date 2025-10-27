//
// Player-type monster and enemy AI functions are handled here
//

const float AI_IDLE = 0;
const float AI_CHASE = 1;
const float AI_ATTACK = 2;
const float AI_RUNBACK = 3;
const float AI_PATROL = 4;

.float ai_mode;
.float ai_patrolidle;
.float ai_standstill;
.float ai_backup_finished;
.entity ai_runback_temp;
.float ai_move_dist;
.float ai_doattack;
.float ai_attacktriggered;

void() monster_ai_think;
void() monster_respawn;
void(vector ang) CSEv_DoAttack_Melee_v;
void(vector ang) CSEv_DoAttack_Arrow_v;

// range values
float	RANGE_CLOSE				= 0;
float	RANGE_MELEE				= 1;
float	RANGE_NEAR				= 2;
float	RANGE_MID				= 3;
float	RANGE_FAR				= 4;

void() monster_death =
{
	self.SendFlags = 1;
	self.angles_x = 0;
	self.goalentity = self.enemy = world; // reset targets
	self.velocity = '0 0 0'; // slide fix
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = FALSE;
	self.anistate = ANISTATE_DEATH;

	self.think = monster_respawn;
	self.nextthink = time + self.respawn_finished;

};

void(float speed) TurnToTarget =
{
	vector dir, target_angles;
	float turn_speed, diff;

	if (self.classname == "npc")
	{
		if (self.goalentity)
		{
			dir = normalize(self.goalentity.origin - self.origin);
			target_angles = vectoangles(dir);
		}
		else
			target_angles = self.idealangles;
	}
	else
	{
		dir = normalize(self.goalentity.origin - self.origin); 
		target_angles = vectoangles(dir);
	}

    diff = anglemod(target_angles_y - self.angles_y);

    if (diff > 180)		diff -= 360;
    if (diff < -180)	diff += 360;

    turn_speed = speed;

    if (diff > turn_speed)
        self.angles_y = anglemod(self.angles_y + turn_speed);
    else if (diff < -turn_speed)
        self.angles_y = anglemod(self.angles_y - turn_speed);
    else
        self.angles_y = anglemod(self.angles_y + diff); // snap final tiny difference
};

void() PitchToTarget =
{
	if (!self.enemy)
		return;

	vector dir_to_enemy = normalize(self.enemy.origin - self.origin);
	vector forward = v_forward;

	float dot = dotproduct(forward, dir_to_enemy);

	// Define FOV cone — e.g., 90° vision cone = 45° to each side
	float fov_cos = cos(45);

	if (dot >= fov_cos)
	{
		vector view = vectoangles(self.enemy.origin - self.origin);
		self.angles_x = view_x;
	}
};

// returns 1 if the entity is in front (in sight) of self, used for stealth
float(entity enemy, entity peaking) infront_stealth =
{
	makevectors (peaking.angles);
	vector vec = normalize (enemy.origin - peaking.origin);
	float dot = vec * v_forward;

	if (!enemy.crouch)
		return TRUE;
	else
	{
		float howmuch = ((enemy.skill_stealth * 0.4) * 0.01); // value increases as players stealth stat is increased
		if (enemy.skill_stealth < 25)
			return TRUE; // Put some points into stealth, otherwise you're easily spotted

		if (dot > howmuch)
			return TRUE;
	}
	return FALSE;
};

// returns the range categorization of an entity reletive to self
float(entity targ) range =
{
	float r = vlen(self.origin - targ.origin);

	if (r <= 40)
		return RANGE_CLOSE;
	else if (r > 40 && r <= 75)
		return RANGE_MELEE;
	else if (r > 75 && r <= 85)
		return RANGE_NEAR;
	else if (r > 85 && r < 200)
		return RANGE_MID;
	return RANGE_FAR;
};

// this visible function returns TRUE even if sight line crossed contents (above and below water)
float (entity targ) visible =
{
 	traceline (self.origin, targ.origin, TRUE, self); // "true", see through other monsters

	if (trace_fraction == 1)
 		return TRUE;
	else
	 	return FALSE;
};

void() monster_ai_attack =
{
	if (self.melee_finished < time && self.stagger_finished < time)
	{
		if (self.noise1)
			sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
		if (self.enemy)
			self.enemy.incombat_finished = time + 15;

		if (!self.attack_type)
			self.anistate = ANISTATE_PUNCH;
		else if (self.attack_type == 1)
			self.anistate = ANISTATE_SLASH;
		else if (self.attack_type == 2)
			self.anistate = ANISTATE_STAB;
		else if (self.attack_type == 3)
			self.anistate = ANISTATE_SMASH;
		else if (self.attack_type == 4)
		{
			// TODO: Look at player
			self.anistate = ANISTATE_ARCHERY;

		}

		if (self.attack_type == 4)
			self.ai_doattack = time + (self.attack_speed / 2); // launch attack (bow)
		else
			self.ai_doattack = time + (self.attack_speed / 4); // launch attack
		self.melee_finished = time + self.attack_speed;
	}
	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};

void() monster_ai_move =
{
	if (self.stagger_finished > time)
		return;
	if (self.melee_finished > time)
		return;

	if (self.enemy)
	{
		if (self.ai_backup_finished > time && self.melee_finished < time)
		{
			walkmove(self.angles_y, self.speed * -1); // keep monster slightly back from target
			self.anistate = ANISTATE_RUN;
		}

		if (range(self.enemy) == RANGE_CLOSE)
			self.ai_backup_finished = time + random_range(0.7, 2.5); // too close, back up a bit
		if (range(self.enemy) == RANGE_MELEE)
			return; // don't move
	}

	movetogoal(self.speed);
	if (self.flags & FL_ONGROUND) // allow monsters to slide off stuff, this is a hack
		self.flags &= ~FL_ONGROUND;

	self.velocity = '0 0 0';
	if (self.ai_mode == AI_RUNBACK) // monster is running back to origin
	{
		self.flags -= (self.flags & FL_ONGROUND);
		vector forward = v_forward * 150;
		self.velocity = forward;
	}
};

void() monster_ai_spawnrunback =
{
	if (!self.ai_runback_temp)
	{
		self.ai_runback_temp = spawn();
		self.ai_runback_temp.owner = self;
		setmodel(self.ai_runback_temp, string_null);
		setorigin(self.ai_runback_temp, self.origin);
	}
};

// main monster ai execution function
void() monster_ai_think =
{
	self.SendFlags = 1;
	makevectors(self.angles);

	// Debugging
	//string l = ftos(self.ai_mode);
	//print(l, "\n");

	if (self.stagger_finished > time)
	{
		self.anistate = ANISTATE_STUNNED;
		self.nextthink = time + 0.1;
		return;
	}

	// monster is walking normal its beat (no target)
	if (self.ai_mode == AI_IDLE || self.ai_mode == AI_PATROL)
	{
		if (!self.enemy)
		{
			if (self.health < self.max_health) // monsters regen health when they're idle patrolling
				self.health ++;
			else
				self.health = self.max_health;
		}

		// randomly turn and move
		if (self.ai_patrolidle < time)
		{
			self.angles_x = 0;
			self.idealangles_y = random()*360;
			if (self.ai_move_dist > 1)
				self.ai_patrolidle = time + 2 + random()*5;
			if (random() < 0.35)
				self.ai_standstill = time + 2 + random()*10;
			TurnToTarget(self.turn_speed);
			self.ai_mode = AI_IDLE;
			self.anistate = ANISTATE_NONE;
		}
		else
		{
			if (self.ai_standstill < time)
			{
				if (!walkmove(self.angles_y, self.speed / 4)) // failed, changed direction
					self.idealangles_y = random() * 360;
				self.ai_mode = AI_PATROL;
				self.anistate = ANISTATE_RUN;
			}
		}

		// Patrolling randomly, searching for players nearby
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (vlen(targ.origin - self.origin) <= self.sight_range && targ.deadflag != DEAD_DEAD && visible(targ) && infront_stealth(targ, self) && targ.bonfire == FALSE)
			{
				if (self.noise)
					sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
				self.goalentity = self.enemy = targ;
				self.ai_mode = AI_CHASE;
				self.anistate = ANISTATE_RUN;
				targ.incombat = TRUE; // flag player for combat
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
		// monsters have default range of 2000 for chasing a target if they're not patrolling
		if (self.ai_move_dist <= 1)
			float ai_move_dist_check = 2000;
		else
			ai_move_dist_check = self.ai_move_dist;
			
		if (b >= ai_move_dist_check)
		{
			self.goalentity = self.ai_runback_temp;
			if (!self.goalentity)
				print ("error in monster ai\n");

			self.enemy = world;
			self.ai_mode = AI_RUNBACK;
			self.anistate = ANISTATE_RUN;
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
			self.anistate = ANISTATE_NONE;

			// remove ghost effect
			self.alpha = 1;
			self.effects &= ~EF_ADDITIVE;
		}
	}

	// monster got something
	if (self.goalentity) 
	{
		if (self.stagger_finished < time)
		{
			if (self.melee_finished > time) // TODO? : Monster attack tracking can be done animation+per-monster
				TurnToTarget(self.turn_speed / 2);
			else
				TurnToTarget(self.turn_speed);
		}
	
		if (self.ai_mode != AI_RUNBACK)
			self.ai_mode = AI_CHASE;

		if (self.enemy.flags & FL_CLIENT && self.enemy.classname == "player" && self.enemy.health > 0)
		{
			if (self.melee_finished < time && self.stagger_finished < time)
			{
				// Ranged attack (bow)
				if (self.attack_type == 4)
				{
					if (range(self.enemy) > RANGE_MELEE && visible(self.enemy))
					{
						if (!self.enemy.incombat)
						{
							self.enemy.incombat = TRUE;
							self.enemy.incombat_finished = time + 15;
						}
						self.ai_attacktriggered = FALSE;
						self.ai_mode = AI_ATTACK;
						self.anistate = ANISTATE_NONE;
						self.think = monster_ai_attack;
					}
					else
					{
						self.ai_mode = AI_CHASE;
						self.anistate = ANISTATE_RUN;
					}
				}
				// Melee attack
				else
				{
					if (range(self.enemy) == RANGE_MELEE || range(self.enemy) == RANGE_CLOSE)
					{
						if (!self.enemy.incombat)
						{
							self.enemy.incombat = TRUE;
							self.enemy.incombat_finished = time + 15;
						}
						self.ai_attacktriggered = FALSE;
						self.ai_mode = AI_ATTACK;
						self.anistate = ANISTATE_NONE;
						self.think = monster_ai_attack;
					}
					else
					{
						self.ai_mode = AI_CHASE;
						self.anistate = ANISTATE_RUN;
					}
				}
			}
			else
			{
				if (self.stagger_finished < time)
				{
					if (self.ai_doattack < time && !self.ai_attacktriggered)
					{
						if (self.attack_type == 4)
							CSEv_DoAttack_Arrow_v(self.angles);
						else
							CSEv_DoAttack_Melee_v(self.angles);

						self.ai_attacktriggered = TRUE;
					}
					else if (self.melee_finished < time)
					{
						self.anistate = ANISTATE_NONE;
						self.ai_attacktriggered = FALSE;
					}
				}
			}
			PitchToTarget();
		}
		monster_ai_move();
	}

	// enemy dead / used a bonfire
	if (self.enemy && (self.enemy.health <= 0 || self.enemy.bonfire == TRUE))
	{
		self.angles_x = 0;
		self.oldenemy = self.enemy; // stash last killed or lost to bonfire
		self.enemy = self.goalentity = world;
		self.ai_mode = AI_IDLE;
		self.anistate = ANISTATE_NONE;
	}

	// Debugging
	//print ("Dist: ", ftos(b), "\n");

	self.nextthink = time + 0.1;
};