//
// Experience / Leveling systems
//

void(entity targ) Player_CheckLevelUp =
{
    if (targ.exp >= targ.exp_next)
    {
		targ.level += 1;
		targ.skillpoints += 10;
		targ.max_health += 12;
		targ.max_mana += 5;

		sound (targ, CHAN_AUTO, "levelup.wav", 1, ATTN_NORM);
		string eventlog_print = (strcat("^3Level ", ftos(targ.level), " reached!\n"));
		localcmd("conecho event ", eventlog_print, "\n"); // push eventlog console message
		stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
		targ.exp = targ.exp_oldnext = targ.exp_next; // cap exp on level up properly
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
	string eventlog_print = (strcat("^3", ftos(amount), "^7 gold received!\n"));
	stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
};