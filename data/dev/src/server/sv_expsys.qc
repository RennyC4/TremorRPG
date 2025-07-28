// Experience / Leveling systems

void(entity targ) Player_CheckLevelUp =
{
    if (targ.exp >= targ.exp_next)
    {
		targ.level += 1;
		print (targ.netname, " leveled up to level ", ftos(targ.level), "!\n");

		targ.exp_next = 100 * (targ.level * targ.level * 1.5);
		print ("Current EXP: ", ftos(targ.exp), "\n");
		print ("EXP Needed: ", ftos(targ.exp_next), "\n");
    }
};

void(entity targ, float expmin, float expmax) GiveExperience =
{
	float amount = ceil(random_range(expmin, expmax));

	targ.exp += amount; // give exp
	print ("EXP Given: ", ftos(amount), "\n");

	Player_CheckLevelUp(targ);
};

void(entity targ, float goldmin, float goldmax) GiveGold =
{
	float amount = ceil(random_range(goldmin, goldmax));

	targ.gold += amount; // give exp
	print ("Gold Given: ", ftos(amount), "\n");
};