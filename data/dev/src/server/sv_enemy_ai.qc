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

	if (self.goalentity)
	{
		dir = normalize(self.goalentity.origin - self.origin);
		target_angles = vectoangles(dir);
	}
	else
		target_angles = self.idealangles;

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

	makevectors(self.angles);

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

    // Use the monster's attack reach directly
    float melee_len = self.attack_length;

    // Fallback for monsters that don't define attack_length
    if (!melee_len || melee_len <= 0)
        melee_len = 64;

    if (r <= 40)
        return RANGE_CLOSE;
    else if (r > 40 && r <= melee_len)
        return RANGE_MELEE;
    else if (r > melee_len && r <= melee_len + 20)
        return RANGE_NEAR;
    else if (r > melee_len + 20 && r < 200)
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

// this visible function returns TRUE even if sight line crossed contents (above and below water), takes view_ofs into account
float (entity targ) visible_ofs =
{
 	traceline (self.origin + self.view_ofs, targ.origin + targ.view_ofs, TRUE, self); // "true", see through other monsters

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
			self.anistate = ANISTATE_ARCHERY;

		if (self.attack_type == 4)
			self.ai_doattack = time + (self.attack_speed / 2); // launch attack (bow)
		else
			self.ai_doattack = time + (self.attack_speed / 4); // launch normal attack

		self.melee_finished = time + self.attack_speed;
	}
	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};

.float avoid_dir;
.float avoid_time;
.vector last_origin;
.float stuck_time;
float() monster_ai_move =
{
	if (self.stagger_finished > time)
		return 0;
	if (self.melee_finished > time)
		return 0;

    vector dir;

    // horizontal direction based on facing
    dir = [cos(deg2rad(self.angles_y)), sin(deg2rad(self.angles_y)), 0];
    dir.z = 0;

    float move_dist = self.speed * 75 * frametime;
    if (self.ai_mode == AI_PATROL)
        move_dist *= 0.25;

    vector newpos = self.origin + dir * move_dist;

    // --- Initialize avoidance memory ---
    if (!self.avoid_dir)
    {
        self.avoid_dir = (random(0, 1) < 0.5) ? 1 : -1; // 1 = left, -1 = right
        self.avoid_time = 0;
    }

    // --- Trace forward ---
    tracebox(self.origin, self.mins, self.maxs, newpos, 0, self);
    if (trace_fraction < 1)
    {
        // --- Try stepping up ---
        vector step_pos = self.origin + '0 0 18';
        tracebox(step_pos, self.mins, self.maxs, step_pos + dir * move_dist, 0, self);
        if (trace_fraction == 1)
            self.origin = step_pos + dir * move_dist;
        else
        {
            // --- Slide around obstacle using avoidance memory ---
            float turn_angle = 30 * self.avoid_dir;
            vector slide_dir = [cos(deg2rad(self.angles_y + turn_angle)),
                                sin(deg2rad(self.angles_y + turn_angle)), 0];
            vector slide_pos = self.origin + slide_dir * move_dist;
            tracebox(self.origin, self.mins, self.maxs, slide_pos, 0, self);

            if (trace_fraction == 1)
            {
                self.angles_y += turn_angle;   // turn slightly
                self.origin = slide_pos;
                self.avoid_time = time + 0.5;  // remember for 0.5s
            }
            else
                self.avoid_dir *= -1; // Reverse avoidance if blocked
        }
    }
    else
    {
        // path clear, reset avoidance after time expires
        if (time > self.avoid_time)
        {
            self.avoid_dir = 0;
            self.avoid_time = 0;
        }
        self.origin = newpos;
    }

    // --- Snap to ground ---
    vector start = self.origin + '0 0 16';
    vector end   = self.origin - '0 0 128';
    tracebox(start, self.mins, self.maxs, end, 0, self);
    if (trace_fraction < 1)
        self.origin = start + (end - start) * trace_fraction;

    // --- Stuck detection ---
    if (!self.last_origin)
        self.last_origin = self.origin;

    if (vlen(self.origin - self.last_origin) < 1) // very small movement
    {
        self.stuck_time += frametime;
        if (self.stuck_time > 0.5) // stuck for >0.5s
        {
            // Force a random turn to get unstuck
            self.angles_y += random(-180, 180);
            self.stuck_time = 0;
        }
    }
    else
        self.stuck_time = 0; // reset counter if moving

    self.last_origin = self.origin; // store current position
    setorigin(self, self.origin);

    return 1; // move successful
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
.float impact_frame;
void() monster_ai_think =
{
	self.SendFlags = 1;
	makevectors(self.angles);

	// Debugging
	//string l = ftos(self.ai_mode);
	//print(l, "\n");

	if (self.stagger_finished > time)
	{
		self.ai_attacktriggered = TRUE; // pre-maturely end attacking stuff, otherwise it'll still follow through oddly
		self.ai_doattack = time;

		if (self.impact_frame > time)
			self.anistate = ANISTATE_IMPACT;
		else
			self.anistate = ANISTATE_STUNNED;

		self.nextthink = time + 0.1;
		return;
	}
	self.impact_frame = time + 1; // impact frame timing

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
			if (self.ai_move_dist != 1)
			{
				self.angles_x = 0;
				self.idealangles_y = random()*360;
				if (self.ai_move_dist > 1)
					self.ai_patrolidle = time + 2 + random()*5;
				if (random() < 0.44)
					self.ai_standstill = time + 2 + random()*10;
				TurnToTarget(self.turn_speed);
				self.ai_mode = AI_IDLE;
				self.anistate = ANISTATE_NONE;
			}
			else // standing guard in an area
			{
				self.angles_x = 0;
				self.ai_mode = AI_IDLE;
				self.anistate = ANISTATE_NONE;
			}
		}
		else
		{
			if (self.ai_standstill < time)
			{
				monster_ai_move();
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
		vector target = self.ai_runback_temp.origin;
		float dist = vlen(self.origin - target);

		if (dist > 50)
		{
			float base_speed = 50; // min speed
			float scale = 2;       // speed vs distance

			// move horizontally toward spawn
			vector flat_target = [target_x, target_y, self.origin_z];
			vector dir = normalize(flat_target - self.origin);
			self.velocity = dir * (base_speed + dist * 0.5);

			// smooth vertical alignment
			float dz = target_z - self.origin_z;
			float step = frametime * (base_speed + fabs(dz) * scale);
			if (fabs(dz) > 1)
				self.origin_z += step * (dz > 0 ? 1 : -1);

			// terrain hugging
			vector start = self.origin + '0 0 16';   // start slightly above
			vector end   = self.origin - '0 0 128';  // trace down a bit
			tracebox(start, self.mins, self.maxs, end, MOVE_NORMAL, self);

			if (trace_fraction < 1)
			{ // snap to floor, but not instantly
				float ground_z = trace_endpos_z;
				float diff = ground_z - self.origin_z;
				if (fabs(diff) > 2)
					self.origin_z += diff * 0.25; // smooth correction
				else
					self.origin_z = ground_z; // snap if very close
			}

			setorigin(self, self.origin);

			// cosmetics & logic
			self.alpha = 0.25;
			self.effects |= EF_ADDITIVE;

			self.enemy = world;
			self.goalentity = self.ai_runback_temp;
			self.movetype = MOVETYPE_NOCLIP;

			if (self.health != self.max_health)
				self.health = self.max_health;
		}
		else // reached spawn
		{
			tracebox(self.saveorigin, self.mins, self.maxs, self.saveorigin, MOVE_NORMAL, self);
			if (trace_startsolid || trace_fraction < 1)
			{
				self.nextthink = time + 1;
				self.think = monster_ai_think;
				return;
			}

			setorigin(self, self.saveorigin + v_up * 5);
			self.enemy = world;
			self.goalentity = world;
			self.movetype = MOVETYPE_STEP;

			self.ai_standstill = time + 4 + random()*4; // chill for a bit

			self.ai_mode = AI_IDLE;
			self.anistate = ANISTATE_NONE;

			self.alpha = 1;
			self.effects &= ~EF_ADDITIVE;
			self.velocity = '0 0 0';
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
					//if (range(self.enemy) == RANGE_MELEE || range(self.enemy) == RANGE_CLOSE)
					dist = vlen(self.enemy.origin - self.origin);
					if (dist <= self.attack_length)
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
						if (!self.enemy.incombat)
						{
							self.enemy.incombat = TRUE;
							self.enemy.incombat_finished = time + 15;
						}
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
						if (self.attack_type == 4) // bow
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
		self.goalentity = self.ai_runback_temp;
		if (!self.goalentity)
			print ("error in monster ai\n");

		self.enemy = world;
		self.ai_mode = AI_RUNBACK;
		self.anistate = ANISTATE_RUN;
	}

	// Debugging
	//print ("Dist: ", ftos(b), "\n");

	self.nextthink = time + 0.1;
};