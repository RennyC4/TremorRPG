//
// Player-type monster and enemy AI functions are handled here
//

const float AI_IDLE = 0;
const float AI_CHASE = 1;
const float AI_ATTACK = 2;
const float AI_RUNBACK = 3;
const float AI_PATROL = 4;
const float AI_DODGE = 5;

.float ai_mode;
.float ai_patrolidle;
.float ai_standstill;
.float ai_backup_finished;
.float ai_move_dist;
.float ai_doattack;
.float ai_attacktriggered;

void(float flIsNew) Monster_SendFlags;
void() monster_ai_think;
void() monster_respawn;
void(vector ang) CSEv_DoAttack_Melee_v;
void(vector ang) CSEv_DoAttack_Arrow_v;
void(entity e) NPC_CommitState;
void(string lootfile, vector pos) Spawn_LootChest;

// range values
float	RANGE_CLOSE				= 0;
float	RANGE_MELEE				= 1;
float	RANGE_NEAR				= 2;
float	RANGE_MID				= 3;
float	RANGE_FAR				= 4;

void() monster_death =
{
	Spawn_LootChest(self.displayname, self.origin);

	self.angles_x = 0;
	self.enemy = world; // reset targets
	self.velocity = '0 0 0'; // slide fix
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = FALSE;
	self.anistate = ANISTATE_DEATH;

	self.think = monster_respawn;
	self.nextthink = time + self.respawn_finished;
    Monster_SendFlags(FALSE);    // delta compare
    NPC_CommitState(self);   // snapshot
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

// Returns TRUE if 'target' is roughly in front of 'self'
float(entity targ) infront =
{
	makevectors (self.angles);
	vector vec = normalize (targ.origin - self.origin);
	float dot = vec * v_forward;
	
	if ( dot > 0.5)
		return TRUE;

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
	if (self.blocking)
		return 0;
	if (self.stagger_finished > time)
		return 0;
	if (self.melee_finished > time)
		return 0;

    vector dir;

    // horizontal direction based on facing
    dir = [cos(deg2rad(self.angles_y)), sin(deg2rad(self.angles_y)), 0];
    dir.z = 0;

    float move_dist = self.speed;
    if (self.ai_mode == AI_PATROL)
        move_dist *= 0.25;
    else if (self.ai_mode == AI_DODGE)
        move_dist *= 0.75;

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
        self.stuck_time += 0.05;
        if (self.stuck_time > 0.5) // stuck for >0.5s
        {
            // Force a random turn to get unstuck
            self.angles_y += random(-180, 180);
            self.stuck_time = 0;
        }
    }
    else
        self.stuck_time = 0; // reset counter if moving

    setorigin(self, self.origin);
	touchtriggers(self, self.origin);

    return 1; // move successful
};

// main monster ai execution function
.float impact_frame;
void() monster_ai_update_state =
{
	makevectors(self.angles);

	if (self.ai_mode == AI_DODGE)
	{
		if (self.dodge_finished < time && !self.ai_dodge)
		{
			self.dodge_angle = self.angles_y; // store angle

			// pick random direction to dodge in
			self.dodgedir = ceil(random() * 3); // 3 directions (0 = back, 1 = left, 2 = right)
			if (!self.dodgedir)
				self.angles_y -= 180; // backward
			else if (self.dodgedir == 1)
				self.angles_y -= 90; // left
			else
				self.angles_y += 90; // right
			//

			self.ai_dodge = TRUE;
		}
		else
			monster_ai_move(); // dodge movement

		// dodge is over, back to fighting
		if (self.dodge_finished < time && self.ai_dodge)
		{
			self.ai_attacktriggered = TRUE; 	// important: remove incoming attack logic
			self.ai_doattack = time - 0.25; 	// important: remove incoming attack logic

			self.angles_y = self.dodge_angle; // restore angle
			self.ai_mode = AI_CHASE;
			self.anistate = ANISTATE_NONE;
			self.ai_dodge = FALSE;
		}

		self.nextthink = time + 0.1;
		return;
	}

    // ---------------------------
    // Manual waterlevel check
    // ---------------------------
    vector feet_pos = self.origin + '0 0 8';
    vector waist_pos = self.origin + '0 0 24';
    vector head_pos = self.origin + '0 0 48';

    float cont_feet = pointcontents(feet_pos);
    float cont_waist = pointcontents(waist_pos);
    float cont_head = pointcontents(head_pos);

    self.waterlevel = 0;
    if (cont_feet == CONTENT_WATER) self.waterlevel = 1;
    if (cont_waist == CONTENT_WATER) self.waterlevel = 2;
    if (cont_head == CONTENT_WATER) self.waterlevel = 3;

    // ---------------------------
    // Force run-back if water above waist
    // ---------------------------
    if (self.waterlevel >= 2 && self.ai_mode != AI_RUNBACK)
    {
        self.enemy = world;
        self.ai_mode = AI_RUNBACK;
		self.avoid_dir = 0;
		self.avoid_time = 0;
        self.anistate = ANISTATE_RUN;

        return;
    }

    // ---------------------------
    // Stagger / impact handling
    // ---------------------------
    if (self.stagger_finished > time)
    {
        self.ai_attacktriggered = TRUE;
        self.ai_doattack = time;

        if (self.impact_frame > time)
            self.anistate = ANISTATE_IMPACT;
        else
            self.anistate = ANISTATE_STUNNED;

        return;
    }
    self.impact_frame = time + 1; // impact frame timing

    // ---------------------------
    // Idle / Patrol behavior
    // ---------------------------
    if (self.ai_mode == AI_IDLE || self.ai_mode == AI_PATROL)
    {
        if (!self.enemy)
        {
            if (self.health < self.max_health)
                self.health++;
            else
                self.health = self.max_health;
        }

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
            else
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

		// Detect nearby players
		for (entity targ = findradius(self.origin, self.sight_range); targ; targ = targ.chain)
		{
			if (targ.classname != "player")
				continue;

			float lvl_diff = targ.level - self.level;

			// Ignore players 20+ levels above the monster
			if (lvl_diff >= 20)
				continue;

			float sight_mult = 1.0;
			if (lvl_diff > 0)
			{
				sight_mult = 1.0 - (lvl_diff * 0.05); // -5% per level
				if (sight_mult < 0)
					sight_mult = 0;
			}

			float effective_sight = self.sight_range * sight_mult;

			// findradius() already filtered by max sight_range, but higher level
			// players have a smaller effective detection radius.
			if (vlen(targ.origin - self.origin) > effective_sight)
				continue;

			if (targ.deadflag == DEAD_DEAD)
				continue;

			if (!visible(targ))
				continue;

			if (!infront_stealth(targ, self))
				continue;

			if (targ.bonfire == TRUE)
				continue;

			if (targ.flags & FL_NOTARGET)
				continue;

			if (self.noise)
				sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

			self.enemy = targ;
			self.ai_mode = AI_CHASE;
			self.anistate = ANISTATE_RUN;

			targ.incombat = TRUE;
			targ.incombat_finished = time + 15;

			string eventlog_print = "^1You engage in combat!\n";
			stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));

			break; // Stop after acquiring the first valid target
		}
    }

    // ---------------------------
    // Distance from spawn handling
    // ---------------------------
    float b = vlen(self.origin - self.saveorigin);
    float ai_move_dist_check = (self.ai_move_dist <= 1) ? 2000 : self.ai_move_dist;

	if (self.enemy && self.enemy != world)
		ai_move_dist_check *= 2; // double leash range when in combat

    if (self.ai_mode != AI_RUNBACK && b >= ai_move_dist_check)
    {
        self.enemy = world;

        self.ai_mode = AI_RUNBACK;
		self.avoid_dir = 0;
		self.avoid_time = 0;
        self.anistate = ANISTATE_RUN;
    }

    // ---------------------------
    // Run-back behavior
    // ---------------------------
    if (self.ai_mode == AI_RUNBACK)
    {
		self.enemy = world;
		vector target = self.saveorigin;
        float dist = vlen(self.origin - target);

        if (dist > 75)
        {
            vector flat_target = [target_x, target_y, self.origin_z];
            vector dir = normalize(flat_target - self.origin);

			// Face target
			vector ang = vectoangles(dir);
			self.angles_y = ang_y;

            //self.velocity = dir * self.speed;
			self.origin += dir * self.speed;

            // smooth vertical alignment
            float dz = target_z - self.origin_z;
            float climb_rate = 2;
            if (fabs(dz) > 1)
                self.origin_z += climb_rate * (dz > 0 ? 1 : -1);

            // terrain hugging
            vector start = self.origin + '0 0 16';
            vector end = self.origin - '0 0 128';
            tracebox(start, self.mins, self.maxs, end, MOVE_NORMAL, self);

            if (trace_fraction < 1)
            {
                float ground_z = trace_endpos_z;
                float diff = ground_z - self.origin_z;

                if (fabs(diff) > 2)
                    self.origin_z += diff * 0.25;
                else
                    self.origin_z = ground_z;
            }

			// Relink properly
            setorigin(self, self.origin);

            // cosmetics
            self.alpha = 0.25;
            self.effects |= EF_ADDITIVE;

            self.enemy = world;

			if (self.movetype != MOVETYPE_NOCLIP)
				self.movetype = MOVETYPE_NOCLIP;

            if (self.health != self.max_health)
                self.health = self.max_health;
			self.takedamage = DAMAGE_NO;
        }
        else
        {
            tracebox(self.saveorigin, self.mins, self.maxs, self.saveorigin, MOVE_NORMAL, self);
            if (trace_startsolid || trace_fraction < 1)
            {
                self.think = monster_ai_think;
                self.nextthink = time + 1;
                return;
            }

            setorigin(self, self.saveorigin + v_up * 5);
            self.enemy = world;

            self.movetype = MOVETYPE_STEP;
			self.takedamage = DAMAGE_AIM;

            self.ai_standstill = time + 4 + random()*4;
            self.ai_mode = AI_IDLE;
            self.anistate = ANISTATE_NONE;

            self.alpha = 1;
            self.effects &= ~EF_ADDITIVE;
            self.velocity = '0 0 0';
            movetofloor(self);
        }
		return;
    }

	// ---------------------------
	// Combat & Defensive Behavior
	// ---------------------------
	if (self.enemy)
	{
		self.stamina = 100; // needed to pass some combat checks

		// ---------------------------
		// Handle active blocking
		// ---------------------------
		if (self.blocking)
		{
			if (time >= self.block_finished)
			{
				// Block duration ended
				self.blocking = FALSE;
				self.anistate = ANISTATE_NONE;
			}
			else
			{
				// Maintain block animation
				self.anistate = ANISTATE_BLOCK;
				self.nextthink = time + 0.05; // refresh quickly during block
				return; // skip other actions while blocking
			}
		}

		// ---------------------------
		// Turn to target if not staggered
		// ---------------------------
		if (self.stagger_finished < time)
		{
			if (self.melee_finished > time)
				TurnToTarget(self.turn_speed / 2);
			else
				TurnToTarget(self.turn_speed);
		}

		// ---------------------------
		// Chase mode if not running back
		// ---------------------------
		if (self.ai_mode != AI_RUNBACK)
			self.ai_mode = AI_CHASE;

		if (self.enemy.flags & FL_CLIENT && self.enemy.classname == "player" && self.enemy.health > 0)
		{
			dist = vlen((self.enemy.origin - self.origin));

			// ---------------------------
			// Defensive maneuvers: dodge
			// ---------------------------
			float attacking = (self.enemy.melee_finished > time || self.enemy.spellani_finished > time);

			if (attacking && !self.dodge_checked) // Player started a new attack
			{
				self.dodge_checked = TRUE;

				if (self.dodge_finished < time && self.dodge_cooldown < time && infront(self.enemy) && self.dodge_chance > 0)
				{
					if (random() < self.dodge_chance)
					{
						self.dodge_angle = self.angles_y;
						self.dodgedir = floor(random() * 3);

						if (!self.dodgedir)
							self.angles_y = anglemod(self.angles_y + 180);
						else if (self.dodgedir == 1)
							self.angles_y = anglemod(self.angles_y - 90);
						else
							self.angles_y = anglemod(self.angles_y + 90);

						self.ai_mode = AI_DODGE;
						self.anistate = ANISTATE_DODGE;
						self.dodge_finished = time + 0.8;
						self.dodge_cooldown = time + 1.2;
						self.godmode_finished = time + 0.4; // little more lee-way than player

						self.ai_dodge = TRUE;
						return;
					}
				}
			}
			else if (!attacking) // ready for the next attack
				self.dodge_checked = FALSE;

			// ---------------------------
			// Defensive maneuvers: block
			// ---------------------------
			if ((self.enemy.melee_finished > time || self.enemy.spellani_finished > time) &&
				 !self.blocking && infront(self.enemy) && self.blockvalue > 0)
			{
				if (random() < self.block_chance)
				{
					self.blocking = TRUE;
					self.anistate = ANISTATE_BLOCK;
					self.block_finished = time + 0.5; // block lasts 0.5s
					self.nextthink = time + 0.05; // refresh think quickly
					return; // skip attacks until block ends
				}
			}

			// ---------------------------
			// Attack logic
			// ---------------------------
			if (self.melee_finished < time && self.stagger_finished < time)
			{
				// Ranged attack
				if (self.attack_type == 4)
				{
					if (dist > RANGE_MELEE && visible(self.enemy))
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
				else if (dist <= self.attack_length)
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
			else if (self.stagger_finished < time)
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

		// ---------------------------
		// Movement
		// ---------------------------
		if (self.ai_mode != AI_RUNBACK)
			monster_ai_move();
	}

    // ---------------------------
    // Handle dead target / bonfire
    // ---------------------------
    if (self.enemy && (self.enemy.health <= 0 || self.enemy.bonfire == TRUE))
    {
        self.angles_x = 0;
        self.oldenemy = self.enemy;

        self.enemy = world;
        self.ai_mode = AI_RUNBACK;
		self.avoid_dir = 0;
		self.avoid_time = 0;
        self.anistate = ANISTATE_RUN;
    }
};

void() monster_ai_think =
{
    monster_ai_update_state();   // Monster logic + movement
    Monster_SendFlags(FALSE);    // delta compare
    NPC_CommitState(self);   // snapshot

    self.nextthink = time + 0.1;
};