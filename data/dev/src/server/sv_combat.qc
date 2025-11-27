//
// Damage routines
//

void(entity targ, entity attacker, float damage, float silent) DoDamage;
float(entity attacker, vector org, float radius, float damage, float diminish, float silent) DoRadiusDamage;
void(entity player, string itemname, float count) RemoveFromInventory;
void() CSEv_User_UnequipMainhand_;
float(entity player, string itemname) HasItem;
void(entity targ, entity attacker, float damage) RegisterAttacker;
void() DoJob_Hatchet;
void() DoJob_Pick;

.entity last_hit_attacker;
.float last_hit_time;
.float attack_id;
.float last_hit_attackid;

float(entity enemy, entity defender) check_block =
{
    vector vec = enemy.origin - defender.origin;
    vec_z = 0; // flatten to XY plane (ignore Z / vertical)
    vec = normalize(vec);

    // calculate defender's forward direction using yaw only
    makevectors([0, defender.angles_y, 0]); // only yaw
    float dot = vec * v_forward;

    if (dot > 0.7)
        return TRUE;
    return FALSE;
};

// return 1 if monster or player are behind each other using findfloat
float(entity defender) check_backstab =
{
	vector properangle = defender.angles;
	properangle_x = properangle_z = 0;
	makevectors (properangle);

	for (entity a = world;(a = findfloat(a, canbackstab, TRUE));)
	{
		if (vlen(a.origin - (defender.origin - v_forward * 32)) < 15)
			return TRUE;
	}
	return FALSE;
};

void() DoAttack_ShieldBash =
{
	if (self.melee_finished > time)
		return;
	if (self.cast_finished > time)
		return;

	if (self.flags & FL_ONGROUND)
		self.velocity = [0, 0];

	// stamina drain on swing
	if (self.classname == "player")
	{
		float stamcalc = 15 - (self.skill_endurance * 0.015); // calculation, same as regular sword swing
		if (self.stamina < stamcalc)
			return;
		self.stamina -= stamcalc;
	}

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 48, MOVE_TRIGGERS, self);

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO && trace_ent.godmode_finished < time)
	{
		// PVP
		if (self.classname == "player" && trace_ent.classname == "player")
		{
			if (self.pvp != 1 || trace_ent.pvp != 1)
				return;
			else
			{
				self.incombat = trace_ent.incombat = TRUE; // Turn off health regen, flag players for incombat
				self.incombat_finished = trace_ent.incombat_finished = time + 30; // keep players locked in combat
			}
		}
		if (trace_ent.parry_finished < time)
		{
			// Pushing
			vector dir = trace_ent.origin - self.origin;
			dir = normalize(dir);
			trace_ent.velocity = '0 0 0';
			trace_ent.flags &= ~FL_ONGROUND;
			trace_ent.velocity_z += 125;
			trace_ent.velocity = trace_ent.velocity + dir * 200;
			//
			if (trace_ent.stagger_finished < time)
			{
				trace_ent.anistate = ANISTATE_IMPACT;
				trace_ent.stagger_finished = time + 1.5;
				trace_ent.lockview_finished = time + 1.5;
			}
			// Knock target out of casting
			trace_ent.cast_finished_spell = "";
			trace_ent.cast_finished = time;
			//
			sound (trace_ent, CHAN_BODY, "shield2.wav", 1, ATTN_NORM);
		}
		else // parry
		{
			float parry = TRUE;
			string eventlog_print = (strcat("^2Successful parry!"));
			stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
			trace_ent.anistate = ANISTATE_PARRY;
			trace_ent.melee_finished = time + 0.5;

			// apply effects
			self.anistate = ANISTATE_IMPACT;
			self.stagger_finished = time + 3.5;
			self.lockview_finished = time + 3.5;
			sound (self, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
		}
	}
	sound (self, CHAN_WEAPON, "shield3.wav", 1, ATTN_NORM);
	self.melee_finished = time + 1;
	self.lockview_finished = time + 1;
};

// =======================================
// MAIN MELEE ATTACK FUNCTION - Traceline
// =======================================
.float staminamessage_finished;
.float inair_swing_sfx;
void(vector ang) CSEv_DoAttack_Melee_v =
{
	// Hatchet runs its own code if one is equipped
	if (self.main_hand == "Hatchet")
	{
		DoJob_Hatchet();
		return;
	}
	// Mining runs its own code if one is equipped
	if (self.main_hand == "Mining Pick")
	{
		DoJob_Pick();
		return;
	}

    // -------------------------------
    // Increment attack_id safely
    // -------------------------------
    if (!self.attack_id)
        self.attack_id = 1;
    else
        self.attack_id = (self.attack_id + 1) % 100000; // wrap after 100k

    if (self.flags & FL_ONGROUND)
        self.velocity = [0, 0];

    // calculate base damage
    float damage = ceil(random_range(self.attack_power_min, self.attack_power_max));

    // add skill scaling
    float howmuch = 0.1;
    if (!self.attack_type) // unarmed
    {
        damage += (self.skill_unarmed * 0.055);
        self.attack_speed = 3 - (self.skill_unarmed * 0.0145);
        if (self.attack_speed < 0.1)
            self.attack_speed = 0.1;
    }
    else if (self.attack_type == 1) // slash
        damage += (self.skill_slash * howmuch);
    else if (self.attack_type == 2) // pierce
        damage += (self.skill_pierce * howmuch);
    else if (self.attack_type == 3) // bashing
        damage += (self.skill_bash * howmuch);
    else
        damage += (self.skill_archery * howmuch);

    // Aim direction
    if (self.flags & FL_CLIENT)
    {
        if (ang) // lock-on active
        {
            makevectors(ang);
            self.angles_x = ang_x;
            self.fixangle = TRUE;
        }
        else
            makevectors(self.v_angle);
    }
    else
        makevectors(self.angles);

    vector source = self.origin + '0 0 16';
    traceline(source, source + v_forward * self.attack_length, MOVE_TRIGGERS, self);

    // Play swing SFX (only once per air-swing)
    if (!self.inair_swing_sfx)
    {
        if (!self.attack_type)
            sound(self, CHAN_WEAPON, "punch1.wav", 1, ATTN_NORM);
        else if (self.attack_type == 1)
            sound(self, CHAN_WEAPON, "sword1.wav", 1, ATTN_NORM);
        else if (self.attack_type == 2)
            sound(self, CHAN_WEAPON, "dagger1.wav", 1, ATTN_NORM);
        else if (self.attack_type == 3)
            sound(self, CHAN_WEAPON, "club1.wav", 1, ATTN_NORM);
    }
    if (!(self.flags & FL_ONGROUND))
        self.inair_swing_sfx = TRUE;

    // ===========================
    // RADIUS DAMAGE FOR SLASH
    // ===========================
    if (self.attack_type == 1)
    {
        // Radius cleave attack handles jump, parry, FX, and attack_id internally
        DoRadiusDamage(self, self.origin + v_forward * 42, self.attack_length * 1.4, damage, TRUE, FALSE);
        return; // skip the rest of the function
    }

    // ===========================
    // DIRECT HIT LOGIC (non-slash)
    // ===========================
    entity targ = trace_ent;
    if (!targ || !targ.takedamage || targ.health <= 0 || targ.deadflag != DEAD_NO)
        return;
    if ((self.flags & FL_MONSTER) && (targ.flags & FL_MONSTER))
        return; // monsters cannot hit each other

    // Prevent repeat hits from jump attacks
    if (targ.jumpattack_hit_finished > time || targ.godmode_finished > time)
        return;

    // -------------------------------
    // PVP checks
    // -------------------------------
    if (self.classname == "player" && targ.classname == "player")
    {
        if (self.pvp != 1 || targ.pvp != 1)
            return;

        self.incombat = targ.incombat = TRUE;
        self.incombat_finished = targ.incombat_finished = time + 30;
    }

    // -------------------------------
    // Jump attack logic
    // -------------------------------
    float jumpattack = FALSE;
    if (!(self.flags & FL_ONGROUND) && self.inair_count >= 20)
        jumpattack = TRUE;

    // -------------------------------
    // Backstab check
    // -------------------------------
    float backstab = FALSE;
    float bs_damage = 0;
    if (check_backstab(targ) && !jumpattack)
    {
        bs_damage = (self.skill_backstab * howmuch);
        if (self.attack_type == 2)
            bs_damage += ceil(self.skill_pierce * (howmuch / 1.5));
        if (bs_damage < 1)
            bs_damage = 1;
        backstab = TRUE;
        sound(targ, CHAN_AUTO, "backstab.wav", 1, ATTN_NORM);

        if (self.classname == "player")
            stuffcmd(self, sprintf("conecho event ^1Backstab! +%g damage !!\n", bs_damage));

        if (targ.classname == "player" && targ.stagger_finished < time)
        {
            stuffcmd(targ, "conecho event ^1You've been staggered!\n");
            targ.lockview_finished = targ.stagger_finished = time + 3;
        }
    }

    // -------------------------------
    // Block / Parry logic
    // -------------------------------
    float parry = FALSE;
    if (check_block(self, targ) && targ.blocking && !backstab)
    {
        float stamcalc_block = 20 - (self.skill_endurance * 0.015);

        if (targ.parry_finished < time)
        {
            if (targ.stamina >= stamcalc_block)
            {
                damage -= targ.blockvalue;
                targ.stamina -= stamcalc_block;

                vector dir = normalize(targ.origin - self.origin);
				targ.velocity = '0 0 0';
                targ.flags &= ~FL_ONGROUND;
                targ.velocity = dir * 150;
				
                targ.melee_finished = time + 0.5;
                targ.anistate = ANISTATE_BLOCK;
                pointparticles(PART_BLOCK, targ.origin + v_forward * 32 + v_up * targ.view_ofs_z);
				float blocked = TRUE;
            }
            else if (targ.stagger_finished < time)
            {
                stuffcmd(targ, "conecho event ^1You've been staggered!\n");
                damage -= ceil(targ.blockvalue / 2);
                targ.stamina = 0;
                targ.blocking = FALSE;
                targ.lockview_finished = targ.stagger_finished = time + 3;
            }
        }
        else // parry
        {
            parry = TRUE;
            sound(targ, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
            stuffcmd(targ, "conecho event ^2Successful parry!\n");

            targ.melee_finished = time + 0.75;
            targ.anistate = ANISTATE_PARRY;

            // apply stagger to attacker
            self.stagger_finished = self.lockview_finished = time + 3.5;
        }
        sound(targ, CHAN_AUTO, "shield1.wav", 1, ATTN_NORM);
    }

    if (parry)
        return;

    // -------------------------------
    // Final damage application
    // -------------------------------
    if (jumpattack)
    {
        damage += damage * 1.20;
        targ.jumpattack_hit_finished = time + 2;
    }

	// Hit player / monster executing a charging up spell
	float max_cast = 5.0; // maximum time the cast can be extended
	if (targ.cast_finished > time)
	{
		float remaining = targ.cast_finished - time;
		float add = 0.8 / (1 + remaining * 0.5); // diminishing return factor
		targ.cast_finished += add;

		// enforce maximum
		if ((targ.cast_finished - time) > max_cast)
			targ.cast_finished = time + max_cast;
	}

    damage -= targ.armorvalue;
    damage += bs_damage;
    damage = ceil(damage);
    if (damage < 1)
        damage = 1;

    // Apply damage
	if (!blocked)
	{
		targ.stagger_finished = time + 0.8; // impact frame on target only
		if (targ.melee_finished > time)
			targ.melee_finished = time;
	}
    DoDamage(targ, self, damage, FALSE);

    // FX and hit sounds
    vector mid = targ.origin;
    vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
    mid_z += (targ.mins_z + targ.maxs_z) * 0.5;
    te_blood(mid, vel, 12);

    if (!self.attack_type)
        sound(targ, CHAN_AUTO, random() < 0.5 ? "punchhit.wav" : "punchhit2.wav", 1, ATTN_NORM);
    else if (self.attack_type == 2)
        sound(targ, CHAN_AUTO, random() < 0.5 ? "daggerhit.wav" : "daggerhit2.wav", 1, ATTN_NORM);
    else
        sound(targ, CHAN_AUTO, random() < 0.5 ? "clubhit.wav" : "clubhit2.wav", 1, ATTN_NORM);

    // Bonus effects: Club knockback and stagger
	float club_stagger = 0.10;
	if (jumpattack)	club_stagger = 0.20;

    if (self.attack_type == 3 && random() <= club_stagger)
    {
        dir = normalize(targ.origin - self.origin);
        targ.flags &= ~FL_ONGROUND;
        targ.velocity = dir * 200;
        targ.velocity_z += 125;

        if (targ.stagger_finished < time)
            targ.lockview_finished = targ.stagger_finished = time + 1.5;

        targ.cast_finished_spell = "";
        targ.cast_finished = time;
    }
};

// =======================================
// ARROWS
// =======================================

void() arrow_think =
{
	self.angles = vectoangles(self.velocity);
	self.nextthink = time + 0.1;
};

void() arrow_touch =
{
	float parry = FALSE;
	makevectors(self.angles);

	if (other != self.owner && other.takedamage && other.health > 0 && other.deadflag == DEAD_NO && other.godmode_finished < time)
	{
        if ((self.owner.flags & FL_MONSTER) && (other.flags & FL_MONSTER))
            return; // monsters cannot hit each other

		float bow_power = ceil(random_range(self.owner.projectile_power_min, self.owner.projectile_power_max));
		float arrow_power = ceil(random_range(self.owner.attack_power_min, self.owner.attack_power_max));
		float damage = bow_power + arrow_power + (self.owner.skill_archery * 0.1);

		// --- PVP Check ---
		if (self.owner.classname == "player" && other.classname == "player")
		{
			if (self.owner.pvp != 1 || other.pvp != 1)
				return;

			self.owner.incombat = other.incombat = TRUE;
			self.owner.incombat_finished = other.incombat_finished = time + 30;
		}

		// --- Parry Detection ---
		if (other.parry_finished > time)
			parry = TRUE;

		// --- Blocking ---
		self.angles_x = self.angles_z = 0; // delete angles before check_block is ran
		if (check_block(self.owner, other) && other.blocking)
		{
			float stamcalc_block = 20 - (other.skill_endurance * 0.015);

			makevectors(other.angles);
			// --- Regular Block ---
			if (other.parry_finished < time)
			{
				if (other.stamina >= stamcalc_block)
				{
					damage -= other.blockvalue;
					other.stamina -= stamcalc_block;

					vector dir = normalize(other.origin - self.origin);
					other.velocity = '0 0 0';
					other.flags &= ~FL_ONGROUND;
					other.velocity = dir * 150;
				
					other.melee_finished = time + 0.5;
					other.anistate = ANISTATE_BLOCK;
					pointparticles(PART_BLOCK, other.origin + v_forward * 32 + v_up * other.view_ofs_z);
					float blocked = TRUE;
				}
				else
				{
					// --- Stagger on Stamina Depletion ---
					if (other.stagger_finished < time)
					{
						if (other.classname == "player")
						{
							string eventlog_print = "^1You've been staggered!";
							stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));
						}

						damage -= ceil(other.blockvalue / 2); // partial block
						other.stamina = 0;
						other.blocking = FALSE;
						other.lockview_finished = time + 3;
						other.stagger_finished = time + 3;
					}
				}
			}
			else // --- Parry ---
			{
				parry = TRUE;
				sound(other, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);

				eventlog_print = "^2Successful parry!";
				stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));
				
				other.melee_finished = time + 0.75;
				other.anistate = ANISTATE_PARRY;
			}

			sound(other, CHAN_AUTO, "shield1.wav", 1, ATTN_NORM);
		}

		// --- Damage Application ---
		if (!parry)
		{
			damage -= ceil(other.armorvalue);

			// If still blocking and block was not handled, apply minor block reduction
			if (check_block(self.owner, other) && other.blocking)
				damage -= ceil(other.blockvalue);

			damage = ceil(max(damage, 1)); // never deal 0 damage

			// Blood effect
			vector mid = other.origin;
			vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
			mid_z += (other.mins_z + other.maxs_z) * 0.5;
			te_blood(mid, vel, 6);

    // Apply damage
			if (!blocked)
			{
				other.stagger_finished = time + 0.8; // impact frame on target only
				if (other.melee_finished > time)
					other.melee_finished = time;
			}
			DoDamage(other, self.owner, damage, FALSE);
			sound(self, CHAN_BODY, "arrow2.wav", 1, ATTN_NORM);
		}

		remove(self);
		return;
	}
	
	// --- Stick to wall ---
	if (other.solid == SOLID_BSP && self.velocity != '0 0 0')
	{
		sound(self, CHAN_BODY, "arrow2.wav", 1, ATTN_NORM);
		self.movetype = MOVETYPE_FLY;
		self.velocity = '0 0 0';
		self.touch = info_null;
		self.think = sub_remove;
		self.nextthink = time + 6;
	}
};

void(vector ang) CSEv_DoAttack_Arrow_v =
{
	entity arrow = spawn();
	arrow.owner = self;
	arrow.movetype = MOVETYPE_TOSS;
	arrow.solid = SOLID_BBOX;
	arrow.classname = "projectile";
	arrow.hitcontentsmaski = CONTENTBITS_POINTSOLID;

	if (self.flags & FL_CLIENT)
	{
		if (ang)
		{
			makevectors(ang);
			self.angles_x = ang_x;
			self.fixangle = TRUE;
		}
		else
			makevectors(self.v_angle);

		// Add lift for smoother, longer flight arcs
		float lift_scale = 0.25; // tweak 0.1–0.25
		vector forward = v_forward;
		vector up = v_up;

		forward = normalize(forward + up * lift_scale);
		arrow.velocity = forward * 1000;
		arrow.angles = vectoangles(arrow.velocity);
	}
	else // monster
	{
		if (self.enemy)
		{
			vector src = self.origin + '0 0 32';
			vector dst = self.enemy.origin + self.enemy.view_ofs;
			vector toTarget = dst - src;
			float dist = vlen(toTarget);

			vector target_vel = self.enemy.velocity;
			float proj_speed = 1000;
			float t_lead = dist / proj_speed;
			vector predicted = dst + target_vel * t_lead;

			vector dir = normalize(predicted - src);
			dir_z += dist * 0.0004; // gravity compensation
			dir = normalize(dir);

			makevectors(vectoangles(dir));
		}
		else
			makevectors(self.angles);

		forward = v_forward;
		arrow.velocity = forward * 1000;
		arrow.angles = vectoangles(arrow.velocity);
	}

	setmodel(arrow, "models/arrow.glb");
	setsize(arrow, '0 0 0', '0 0 0');
	setorigin(arrow, self.origin + v_forward * 8 + '0 0 16');

	arrow.touch = arrow_touch;
	arrow.think = arrow_think;
	arrow.nextthink = time + 0.1;

	sound(self, CHAN_WEAPON, "arrow1.wav", 1, ATTN_NORM);

	// Monsters don't need to check inventory
	if (self.flags & FL_MONSTER)
		return;

	// Remove one arrow from inventory
	RemoveFromInventory(self, self.main_hand, 1);

	// Player: unequip when out of arrows
	if (!HasItem(self, self.main_hand))
		CSEv_User_UnequipMainhand_();
};

void(entity targ) Player_CheckLevelUp;
void(entity targ, entity attacker) DoDeath =
{
    // MONSTER DEATH (shared rewards)
    if (targ.flags & FL_MONSTER)
    {
		if (attacker.classname == "player") // Only reward players, ignore monsters killing each other
			MonsterReward(targ, attacker);
    }

    // PVP KILL
    if (targ.classname == "player" && attacker.classname == "player")
    {
        attacker.reaper_marks += targ.level;

        if (targ.gold > 1)
        {
            float steal = ceil(targ.gold / 4);
            GiveGold(attacker, self, steal, steal);
        }
    }

    // Play death animation / sound
    if (targ.th_die)
    {
        if (targ.noise3)
            sound(targ, CHAN_VOICE, targ.noise3, 1, ATTN_NORM);

        targ.think = targ.th_die;
        targ.nextthink = time;
    }
    else
        print(targ.classname, "'s th_die routine is missing\n");
};

// =======================================
// MAIN DAMAGE FUNCTION
// =======================================
void(entity targ, entity attacker, float damage, float silent) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1 || targ.deadflag == DEAD_DEAD)
		return;
	if (targ.flags & FL_MONSTER && targ.ai_mode == AI_RUNBACK)
		return;
	if (targ.flags & FL_MONSTER && attacker.flags & FL_MONSTER)
		return;
	if (targ.godmode_finished > time)
		return;

	if (damage <= 0)
		damage = 1;

	// apply actual damage
	if (!(targ.flags & FL_GODMODE))
	{
		targ.health -= damage;
		RegisterAttacker(targ, attacker, damage);
	}

	string eventlog_print;

	// attacker feedback
	if (attacker.classname == "player")
	{
		eventlog_print = strcat("You hit for ^2", ftos(damage), " ^7damage\n");
		stuffcmd(attacker, sprintf("conecho event %s\n", eventlog_print));
	}

	// victim feedback
	if (targ.classname == "player" && !silent)
	{
		eventlog_print = strcat("You've taken ^1", ftos(damage), " ^7damage\n");
		stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));
	}

	// PVP engage
	if (targ.classname == "player" && attacker.classname == "player")
	{
		if (targ.incombat_finished < time)
		{
			eventlog_print = "^1You engage in combat!\n";
			stuffcmd(attacker, sprintf("conecho event %s\n", eventlog_print));
			stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));
			targ.incombat_finished = attacker.incombat_finished = time + 30;
		}
	}

	// cancel potions
	if (targ.potion_use_finished > time)
	{
		targ.healthpot_heal_rate = targ.healthpot_heal_remaining = 0;
		targ.healthpot_finished = time;
		targ.manapot_heal_rate = targ.manapot_heal_remaining = 0;
		targ.manapot_finished = time;
		targ.potion_use_finished = time;

		stuffcmd(targ, "conecho event ^1You drop your potion!\n");
	}

	// monsters
	if (targ.flags & FL_MONSTER)
	{
		if (targ.noise2)
			sound(targ, CHAN_VOICE, targ.noise2, 1, ATTN_NORM);

		targ.goalentity = targ.enemy = attacker;
	}

	// death
	if (targ.health <= 0)
	{
		targ.deadflag = TRUE;
		DoDeath(targ, attacker);
	}
};

// =======================================
// RADIUS ATTACK FUNCTION
// =======================================
float(entity attacker, vector org, float radius, float damage, float diminish, float silent) DoRadiusDamage =
{
    float did_damage = FALSE;

    // Determine jump attack
    float jumpattack = FALSE;
    if (!(attacker.flags & FL_ONGROUND) && attacker.inair_count >= 15)
        jumpattack = TRUE;

    // Ensure attack ID exists
    if (!attacker.attack_id)
        attacker.attack_id = 1;

    for (entity targ = world; (targ = findfloat(targ, radius_candamage, TRUE));)
    {
        if (targ == attacker)
            continue;
	    if ((targ.flags & FL_MONSTER) && (attacker.flags & FL_MONSTER))
			continue; // skip monster vs monster
		if (targ == self)
			continue;
        if (vlen(targ.origin - org) > radius)
            continue;
        if (targ.godmode_finished > time)
            continue;
        if (!targ.takedamage || targ.health <= 0 || targ.deadflag != DEAD_NO)
            continue;
		if (targ.jumpattack_hit_finished > time)
			continue;

        // Prevent duplicate hits per swing
        if (targ.last_hit_attacker == attacker && targ.last_hit_attackid == attacker.attack_id)
            continue;

        targ.last_hit_attacker = attacker;
        targ.last_hit_attackid = attacker.attack_id;

        // Jump attack per-target timer
        if (jumpattack && targ.jumpattack_hit_finished > time)
            continue;

        // Damage calculation
        float dmg = damage;
        if (diminish)
        {
            float distance_length = vlen(targ.origin - org);
            float distance_factor = 1 - pow(distance_length / radius, 1.5); // gentler falloff
            dmg = damage * distance_factor;
            if (dmg < damage * 0.3) // minimum 30% damage
                dmg = damage * 0.3;
        }

        // -------------------------------
        // PVP checks
        // -------------------------------
        if (attacker.classname == "player" && targ.classname == "player")
        {
            // If either player has PVP disabled, skip damage
            if (attacker.pvp != 1 || targ.pvp != 1)
                continue;

            attacker.incombat = targ.incombat = TRUE;
            attacker.incombat_finished = targ.incombat_finished = time + 30;
        }

        // Apply jump attack bonus
        if (jumpattack)
        {
            dmg += dmg * 1.20;
            targ.jumpattack_hit_finished = time + 2;
        }

		// -------------------------------
		// Backstab check
		// -------------------------------
		float backstab = FALSE;
		float bs_damage = 0;
		float howmuch = 0.1;
		if (check_backstab(targ) && !jumpattack)
		{
			bs_damage = (attacker.skill_backstab * howmuch);
			if (attacker.attack_type == 2)
				bs_damage += ceil(attacker.skill_pierce * (dmg / 1.5));
			if (bs_damage < 1)
				bs_damage = 1;
			backstab = TRUE;

			sound(targ, CHAN_AUTO, "backstab.wav", 1, ATTN_NORM);

			if (attacker.classname == "player")
				stuffcmd(attacker, sprintf("conecho event ^1Backstab! +%g damage !!\n", bs_damage));

			if (targ.classname == "player" && targ.stagger_finished < time)
			{
				stuffcmd(targ, "conecho event ^1You've been staggered!\n");
				targ.lockview_finished = targ.stagger_finished = time + 3;
			}

			dmg += bs_damage;
		}

        // -------------------------------
        // Block / Parry logic
        // -------------------------------
        float parry = FALSE;

        if (check_block(attacker, targ) && targ.blocking)
        {
            float stamcalc_block = 20 - (attacker.skill_endurance * 0.015);

            if (targ.parry_finished < time)
            {
                if (targ.stamina >= stamcalc_block)
                {
                    dmg -= targ.blockvalue;
                    targ.stamina -= stamcalc_block;

					vector dir = normalize(targ.origin - self.origin);
					targ.velocity = '0 0 0';
					targ.flags &= ~FL_ONGROUND;
					targ.velocity = dir * 150;
                    targ.melee_finished = time + 0.5;
                    targ.anistate = ANISTATE_BLOCK;
                    pointparticles(PART_BLOCK, targ.origin + v_forward * 32 + v_up * targ.view_ofs_z);
					float blocked = TRUE;
                }
                else if (targ.stagger_finished < time)
                {
                    stuffcmd(targ, "conecho event ^1You've been staggered!\n");
                    dmg -= ceil(targ.blockvalue / 2);
                    targ.stamina = 0;
                    targ.blocking = FALSE;
                    targ.lockview_finished = targ.stagger_finished = time + 3;
                }
            }
            else // parry
            {
                parry = TRUE;
                sound(targ, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
                stuffcmd(targ, "conecho event ^2Successful parry!\n");

                targ.melee_finished = time + 0.75;
                targ.anistate = ANISTATE_PARRY;

                attacker.stagger_finished = attacker.lockview_finished = time + 3.5;
            }
            sound(targ, CHAN_AUTO, "shield1.wav", 1, ATTN_NORM);
        }

        if (parry)
            continue;

        // -------------------------------
        // Final damage application
        // -------------------------------
        dmg -= targ.armorvalue;
		dmg = (ceil(dmg)); // round
        if (dmg < 1)
            dmg = 1;

		// Apply damage
		if (!blocked)
		{
			targ.stagger_finished = time + 0.8; // impact frame on target only
			if (targ.melee_finished > time)
				targ.melee_finished = time;
		}
		DoDamage(targ, attacker, dmg, silent);
        did_damage = TRUE;

        // -------------------------------
        // Visual & Audio feedback
        // -------------------------------
        vector mid = targ.origin;
        vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
        mid_z += (targ.mins_z + targ.maxs_z) * 0.5;
        te_blood(mid, vel, 12);

        if (!attacker.attack_type)
            sound(targ, CHAN_AUTO, random() < 0.5 ? "punchhit.wav" : "punchhit2.wav", 1, ATTN_NORM);
        else if (attacker.attack_type == 1)
            sound(targ, CHAN_AUTO, random() < 0.5 ? "swordhit.wav" : "swordhit2.wav", 1, ATTN_NORM);
        else if (attacker.attack_type == 2)
            sound(targ, CHAN_AUTO, random() < 0.5 ? "daggerhit.wav" : "daggerhit2.wav", 1, ATTN_NORM);
        else
            sound(targ, CHAN_AUTO, random() < 0.5 ? "clubhit.wav" : "clubhit2.wav", 1, ATTN_NORM);
    }

    return did_damage;
};

//
// RegisterAttacker: Used to keep track of players who have dealt damage to a monster, used for rewards
//
void(entity targ, entity attacker, float damage) RegisterAttacker =
{
    if (!attacker || attacker.classname != "player")
        return;

    for (float i = 0; i < 8; i++)
    {
        // already recorded as attacker — add damage
        if (targ.attackers[i] == attacker)
        {
            targ.attacker_damage[i] += damage;
            return;
        }

        // free slot — record new attacker
        if (!targ.attackers[i])
        {
            targ.attackers[i] = attacker;
            targ.attacker_damage[i] = damage;
            return;
        }
    }
};