//
// Main Damage routines
//

void(entity targ, entity attacker, float damage) DoDamage;

void() DoAttack_Melee =
{
	if (self.melee_finished > time)
		return;

	// Calculate Damage
	float damage = random_range(self.attack_power_min, self.attack_power_max);

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, MOVE_EVERYTHING, self);

	sound (self, CHAN_WEAPON, "sword1.wav", 1, ATTN_NORM);

	if (trace_ent.takedamage)
	{
		DoDamage(trace_ent, self, damage);
		sound (trace_ent, CHAN_BODY, "swordhit.wav", 1, ATTN_NORM);
	}

	self.melee_finished = time + self.attack_speed;
};

void(entity targ) Player_CheckLevelUp;
void(entity targ, entity attacker) DoDeath = 
{
	if (attacker.classname == "player")
	{
		GiveExperience(attacker, targ.exp_min, targ.exp);
		GiveGold(attacker, targ.gold_min, targ.gold);
	}

	if (targ.th_die)
	{
		if (targ.noise3) // death sound
			sound (targ, CHAN_VOICE, targ.noise3, 1, ATTN_NORM);

		targ.deadflag = DEAD_DEAD;
		targ.think = targ.th_die;
		targ.nextthink = time;
	}
	else
		print(self.classname, "'s th_die routine is missing\n");
};

void(entity targ, entity attacker, float damage) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1)
		return;
	if (targ.flags & FL_MONSTER && targ.ai_mode == AI_RUNBACK)
		return;

	if (damage > 0)
	{
		targ.health = targ.health - damage;

		if (attacker.classname == "player")
			sprint(attacker, PRINT_HIGH, "You hit for ", ftos(damage), " damage\n");
		if (self.flags & FL_MONSTER && targ.classname == "player")
			sprint(targ, PRINT_HIGH, "You've taken ", ftos(damage), " damage\n");
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
		DoDeath(targ, attacker);
		targ.deadflag = TRUE;
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