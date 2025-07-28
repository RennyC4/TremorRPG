// Empty

void() monster_respawn =
{
	self.solid = SOLID_SLIDEBOX;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.alpha = 1; // removeme
	self.health = 100;
	self.radius_candamage = "TRUE"; // uses string
	setorigin (self, self.saveorigin); // respawn at initial spawn spot
};

void() monster_death =
{
	self.alpha = 0.1;
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = "FALSE"; // uses string

	self.think = monster_respawn;
	self.nextthink = time + 10;
};

void() set_monster =
{
	precache_model(self.model);

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.classname = "monster";
	self.radius_candamage = "TRUE"; // uses string
	self.colormod = '100 0 0'; // Red
	self.th_die = monster_death;

	if (!self.exp)
		self.exp = 200; // removeme

	self.saveorigin = self.origin; // stash initial spawn spot

	setmodel(self, "models/testplayer.iqm"); // remove me
	setsize(self, [-16, -16, 0], [16, 16, 56]);
};