//
// Damage routines
//

void(entity targ, entity attacker, float damage) DoDamage;

// returns 1 if the entity is in front (in sight) of self, used for blocking
float(entity enemy, entity peaking) infront_block =
{
	makevectors (peaking.angles);
	vector vec = normalize (enemy.origin - peaking.origin);
	float dot = vec * v_forward;

	if (dot > 0.45)
		return TRUE;
	return FALSE;
};


void() DoAttack_Melee =
{
	if (self.melee_finished > time)
		return;

	// Stamina drain on swing
	if (self.classname == "player")
	{
		float stamcalc = self.skill_endurance * 0.015; // calculation
		if (self.stamina < self.attack_stamina)
			return;
		self.stamina -= (self.attack_stamina - stamcalc);
	}

	// Calculate damage by weapon
	float damage = random_range(self.attack_power_min, self.attack_power_max);

	// add skill damage
	float howmuch = 0.1;
	if (!self.attack_type) // unarmed
		damage = damage + (self.skill_unarmed * howmuch);
	else if (self.attack_type == 1) // slash
		damage = damage + (self.skill_slash * howmuch);
	else if (self.attack_type == 2) // pierce
		damage = damage + (self.skill_pierce * howmuch);
	else // bashing
		damage = damage + (self.skill_bash * howmuch);

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 64, MOVE_TRIGGERS, self);
	sound (self, CHAN_WEAPON, "sword1.wav", 1, ATTN_NORM);

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO)
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

		// check & add backstab skill damage
		if (!infront_block(self, trace_ent) && /* self.crouch && */ trace_ent.enemy != self)
		{
			float bs_damage = (self.skill_backstab * howmuch);
			if (bs_damage < 1)
				bs_damage = 1;
			float backstab = TRUE;
			sound (trace_ent, CHAN_AUTO, "backstab.wav", 1, ATTN_NORM);	

			if (self.classname == "player")
			{
				string eventlog_print = (strcat("^1Backstab! +", ftos(bs_damage), " damage !!\n"));
				stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
			}
		}

		if (trace_ent.blocking && !backstab)
		{
			sound (trace_ent, CHAN_BODY, "shield1.wav", 1, ATTN_NORM);
			damage = damage - trace_ent.blockvalue;
			if (trace_ent.blockvalue > damage)
				damage = 1;
		}
		else
			sound (trace_ent, CHAN_BODY, "swordhit.wav", 1, ATTN_NORM);

		damage = ceil(damage); // round up final damage output

		float i;
		vector eye_level = [9, 0];
		eye_level_z = self.view_ofs_z; // match up blood spray to attackers view by z

		for (i=0; i < 2; i++)
			te_blood(trace_ent.origin + eye_level, trace_ent.velocity, 12); // spawn blood

		DoDamage(trace_ent, self, damage);
	}
	self.melee_finished = time + self.attack_speed;
};

void(entity targ) Player_CheckLevelUp;
void(entity targ, entity attacker) DoDeath = 
{
	if (attacker.classname == "player")
	{
		if (targ.flags & FL_MONSTER)
		{
			GiveExperience(attacker, targ.exp_min, targ.exp);
			GiveGold(attacker, targ.gold_min, targ.gold);
		}
		if (targ.classname == "player") // PVP Kill
		{
			attacker.reaper_marks += targ.level;
			if (targ.gold > 1)
				GiveGold(attacker, ceil(targ.gold / 4), ceil(targ.gold / 4));
		}
	}

	if (targ.th_die)
	{
		if (targ.noise3) // death sound
			sound (targ, CHAN_VOICE, targ.noise3, 1, ATTN_NORM);

		targ.think = targ.th_die;
		targ.nextthink = time;
	}
	else
		print(self.classname, "'s th_die routine is missing\n");
};

// Main damage function
void(entity targ, entity attacker, float damage) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1 || targ.deadflag == DEAD_DEAD)
		return;
	if (targ.flags & FL_MONSTER && targ.ai_mode == AI_RUNBACK)
		return;
	if (targ.flags & FL_MONSTER && attacker.flags & FL_MONSTER) // prevent monster in-fighting
		return;

	if (damage <= 0)
		damage = 1;

	if (damage > 0)
	{
		targ.health = targ.health - damage;
		string eventlog_print;

		if (attacker.classname == "player")
		{
			eventlog_print = (strcat("You hit for ^2", ftos(damage), " ^7damage\n"));
			stuffcmd (attacker, sprintf("conecho event %s\n", eventlog_print));
		}
		if (targ.classname == "player")
		{
			eventlog_print = (strcat("You've taken ^1", ftos(damage), " ^7damage\n"));
			stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
		}

		// PVP
		if (targ.classname == "player" && attacker.classname == "player")
		{
			if (targ.incombat_finished < time)
			{
				eventlog_print = (strcat("^1You engage in combat!\n"));
				stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
				stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
				targ.incombat_finished = attacker.incombat_finished = time + 30;
			}
		}
	}

	// Monster stuff
	if (targ.flags & FL_MONSTER)
	{
		if (targ.noise2) // pain sound
			sound (trace_ent, CHAN_VOICE, targ.noise2, 1, ATTN_NORM);

		targ.goalentity = targ.enemy = attacker; // Go after last attacker
	}

	if (targ.health <= 0)
	{
		targ.deadflag = TRUE;
		DoDeath(targ, attacker);
	}
};

void(entity attacker, float radius, float damage, float setfire, float diminish) DoRadiusDamage =
{
	for (entity targ = world;(targ = find(targ, radius_candamage, "TRUE"));)
	{
		if (vlen(targ.origin - self.origin) <= radius)
		{
			float dmg = damage;
			if (diminish)
			{
				float distance_length = vlen(targ.origin - self.origin);
				float distance_factor = 1 - (distance_length / radius);
				dmg = ceil(damage * distance_factor);
			}
			DoDamage(targ, attacker, dmg);
		}
	}
};