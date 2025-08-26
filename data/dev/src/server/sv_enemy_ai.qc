//
// All monster and enemy AI functions are handled here
//

const float AI_IDLE = 0;
const float AI_CHASE = 1;
const float AI_ATTACK = 2;
const float AI_RUNBACK = 3;

.float ai_mode;
.float ai_patrolidle;
.float ai_standstill;
.float ai_backup_finished;
.entity ai_runback_temp;

void() monster_ai_think;
void() DoAttack_Melee;

// range values
float	RANGE_CLOSE				= 0;
float	RANGE_MELEE				= 1;
float	RANGE_NEAR				= 2;
float	RANGE_MID				= 3;
float	RANGE_FAR				= 4;

void(float speed) TurnToTarget =
{
	vector dir, target_angles;
	float turn_speed, diff;

	if (self.classname == "npc")
	{
		if (self.goalentity)
			dir = normalize(self.goalentity.origin - self.origin);
		else
			dir = normalize(self.idealangles);
	}
	else
		dir = normalize(self.goalentity.origin - self.origin); 

    target_angles = vectoangles(dir);
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

void() monster_ai_melee =
{
	if (self.melee_finished < time && self.stagger_finished < time)
	{
		if (self.noise1)
			sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
		if (self.enemy)
			self.enemy.incombat_finished = time + 15;
		DoAttack_Melee();
	}

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};

void() monster_ai_move =
{
	if (self.stagger_finished > time)
		return;

	if (self.enemy)
	{
		if (self.ai_backup_finished > time)
			walkmove(self.angles_y, self.speed * -1); // keep AI slightly back from target

		if (range(self.enemy) == RANGE_CLOSE)
			self.ai_backup_finished = time + random_range(0.7, 2.5); // too close, back up a bit
		if (range(self.enemy) == RANGE_MELEE)
			return; // don't move
	}
	movetogoal(self.speed);

	self.velocity = '0 0 0';
	if (self.ai_mode == AI_RUNBACK) // prevent monster from stepping into player
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
	makevectors(self.angles);

// Debugging
//	string l = ftos(self.ai_mode);
//	print(l, "\n");

	if (self.ai_mode == AI_IDLE)
	{
		if (self.health != self.max_health) // monsters have full health in patrol mode
			self.health = self.max_health;

		// Randomly turn and move
		if (self.ai_patrolidle < time)
		{
			self.angles_x = 0;
			self.idealangles_y = random()*360;
			self.ai_patrolidle = time + 3 + random()*6;
			if (random() < 0.35)
				self.ai_standstill = time + 1 + random()*8;
			TurnToTarget(self.turn_speed);
		}
		else
		{
			if (self.ai_standstill < time)
				walkmove(self.angles_y, self.speed / 4);
		}

		// Patroling randomly, searching for players nearby
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (vlen(targ.origin - self.origin) <= self.sight_range && targ.deadflag != DEAD_DEAD && visible(targ) && infront_stealth(targ, self) && targ.bonfire == FALSE)
			{
				if (self.noise)
					sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
				self.goalentity = self.enemy = targ;
				self.ai_mode = AI_CHASE;
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
		if (b >= 2000)
		{
			self.goalentity = self.ai_runback_temp;
			if (!self.goalentity)
				print ("Error in monster ai\n");

			self.enemy = world;
			self.ai_mode = AI_RUNBACK;
		}
	}
	else // AI is jogging back close to spawn spot
	{
		if (b > 50)
		{
			if (self.origin_z > self.ai_runback_temp.origin_z)
				self.origin_z -= 1;
			else
				self.origin_z += 1;

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
		}
	}

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
			if (range(self.enemy) == RANGE_MELEE || range(self.enemy) == RANGE_CLOSE)
			{
				if (!self.enemy.incombat)
				{
					self.enemy.incombat = TRUE; // turn on during an attack incase another monster somehow flags it off
					self.enemy.incombat_finished = time + 15;
				}
				self.ai_mode = AI_ATTACK;
				self.think = monster_ai_melee;
				self.nextthink = time + 0.1;
			}
			else
				self.ai_mode = AI_CHASE;
		}
		monster_ai_move();
	}
	else
		self.ai_mode = AI_IDLE;

	// enemy dead / used a bonfire
	if (self.enemy && self.enemy.health <= 0 || self.enemy.bonfire == TRUE)
	{
		self.oldenemy = self.enemy; // stash last killed or lost to bonfire
		self.enemy = self.goalentity = world;
		self.ai_mode = AI_IDLE;
	}

	// Debugging
	//print ("Dist: ", ftos(b), "\n");

	self.nextthink = time + 0.1;
};