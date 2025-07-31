// Experience / Leveling systems

void(entity targ) Player_CheckLevelUp =
{
    if (targ.exp >= targ.exp_next)
    {
		targ.level += 1;
		targ.skillpoints += 5;
		targ.max_health += 12;
		targ.max_mana += 5;

		sound (targ, CHAN_AUTO, "levelup.wav", 1, ATTN_NORM);
		sprint (self, PRINT_HIGH, "^3Level ", ftos(targ.level), " reached!\n");

		targ.exp_next = 100 * (targ.level * targ.level * 1.15);
    }
};

void(entity targ, float expmin, float expmax) GiveExperience =
{
	float amount = random_range(expmin, expmax);
	targ.exp += amount; // give exp
	Player_CheckLevelUp(targ);
};

void(entity targ, float goldmin, float goldmax) GiveGold =
{
	float amount = random_range(goldmin, goldmax);
	targ.gold += amount; // give gold
};