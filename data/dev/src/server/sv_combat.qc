//
// Main Damage routines
//

void(entity targ, entity attacker) DoDeath = {};

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