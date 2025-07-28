// Empty

void() monster_test_death =
{
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
};

void() monster_test =
{
	precache_model(self.model);

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.classname = "monster";
	self.colormod = '100 0 0'; // Red
	self.th_die = monster_test_death;

	self.saveorigin = self.origin; // stash initial spawn spot

	setmodel(self, "models/testplayer.iqm"); // remove me
	setsize(self, [-16, -16, 0], [16, 16, 56]);
};