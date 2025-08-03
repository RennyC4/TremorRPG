// All monster and enemy AI functions are handled here

const float AI_IDLE = 0;
const float AI_CHASE = 1;
const float AI_ATTACK = 2;
const float AI_RUNBACK = 3;

.float ai_mode;
.float ai_patrolidle;
.float ai_standstill;
.entity ai_runback_temp;

void() monster_ai_think;
void() DoAttack_Melee;

// range values
float	RANGE_CLOSE				= 0;
float	RANGE_MELEE				= 1;
float	RANGE_NEAR				= 2;
float	RANGE_MID				= 3;
float	RANGE_FAR				= 4;

// returns 1 if the entity is in front (in sight) of self
float(entity targ) infront =
{
	makevectors (self.angles);
	vector vec = normalize (targ.origin - self.origin);
	float dot = vec * v_forward;

	if (dot > 0.45)
		return TRUE;
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
	if (self.melee_finished < time)
	{
		if (self.noise1)
			sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);

		DoAttack_Melee();
	}

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};

void() monster_ai_move =
{
	movetogoal(self.speed / 2);
	walkmove(self.angles_y, self.speed / 2);

	self.velocity = '0 0 0';
	self.flags -= (self.flags & FL_ONGROUND);
	vector forward = v_forward * 150;
	self.velocity = forward;
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
		// Randomly turn and move
		if (self.ai_patrolidle < time)
		{
			self.angles_x = 0;
			self.angles_y = random()*360;
			self.ai_patrolidle = time + 3 + random()*6;
			if (random() < 0.35)
				self.ai_standstill = time + 1 + random()*8;
		}
		else
		{
			if (self.ai_standstill < time)
				walkmove(self.angles_y, self.speed / 4);
		}

		// Patroling randomly, searching for players nearby
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (vlen(targ.origin - self.origin) <= 500 && targ.deadflag != DEAD_DEAD && visible(targ))
			{
				if (self.noise)
					sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
				self.goalentity = self.enemy = targ;
				self.ai_mode = AI_CHASE;
				targ.incombat = TRUE; // flag player for combat
			}
		}
	}

	// Keep track of saved origin
	float b = vlen(self.origin - self.saveorigin);
	if (self.ai_mode != AI_RUNBACK)
	{
		if (b >= 2000)
		{
			if (self.enemy)
				self.enemy.incombat = FALSE;

			self.goalentity = self.ai_runback_temp;
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
		vector view = vectoangles(self.goalentity.origin - self.origin);
		self.angles_y = view_y;
		self.angles_x = view_x;

		if (self.ai_mode != AI_RUNBACK)
			self.ai_mode = AI_CHASE;

		if (self.enemy.flags & FL_CLIENT && self.enemy.classname == "player" && self.enemy.health > 0)
		{
			if (infront(self.enemy) && (range(self.enemy) == RANGE_MELEE || range(self.enemy) == RANGE_CLOSE))
			{
				if (!self.enemy.incombat)
					self.enemy.incombat = TRUE; // turn on during an attack incase another monster somehow flags it off
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

	// Enemy dead
	if (self.enemy && self.enemy.health <= 0)
	{
		self.oldenemy = self.enemy; // stash last killed
		self.enemy = self.goalentity = world;
		self.ai_mode = AI_IDLE;
	}

	//print ("Dist: ", ftos(b), "\n");

	self.nextthink = time + 0.1;
};