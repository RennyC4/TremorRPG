// Enemies, most are defined in the maps themselves (hmp / bsp)

void() monster_respawn =
{
	self.solid = SOLID_TRIGGER;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.alpha = 1; // removeme
	self.health = self.max_health;
	self.radius_candamage = "TRUE"; // uses string
	self.ai_mode = AI_IDLE; // return to idling

	setorigin (self, self.saveorigin); // respawn at initial spawn spot

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};

void() monster_death =
{
	if (self.ai_runback_temp)
		remove(self.ai_runback_temp);

	self.goalentity = self.enemy = world; // reset targets

	self.alpha = 0.1;
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = "FALSE"; // uses string

	self.think = monster_respawn;
	self.nextthink = time + self.respawn_finished;
};

void() set_monster =
{
	precache_model(self.model);

	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_AIM;
	self.classname = "monster";
	self.radius_candamage = "TRUE"; // uses string
	self.colormod = '100 0 0'; // Red
	self.flags |= FL_MONSTER;
	self.th_die = monster_death;

	if (!self.exp)
		self.exp = 1;

	self.saveorigin = self.origin + v_up * 1; // stash initial spawn spot

	setmodel(self, "models/testplayer.iqm"); // remove me
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
};