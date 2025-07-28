//
// Main Damage routines
//
void(entity targ, entity attacker, float damage) DoDamage;
.float attack_finished;

void() DoAttack_Melee =
{
	if (self.attack_finished < time)
	{
		vector source;

		makevectors (self.v_angle);
		source = self.origin + '0 0 16';
		traceline (source, source + v_forward*64, FALSE, self);

		if (trace_fraction == 1.0)
			return;

		if (trace_ent.takedamage)
			DoDamage(trace_ent, self, 50);

		print("Melee Swing\n");
		self.attack_finished = time + 0.5;
	}
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
		targ.deadflag = DEAD_DEAD;
		targ.think = targ.th_die;
		targ.nextthink = time;
	}
	else
		print("Monster's th_die routine is missing\n");
};

void(entity targ, entity attacker, float damage) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1)
		return;

	if (damage > 0)
		targ.health = targ.health - damage;

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