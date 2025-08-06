// NPCs, most are defined in the maps themselves (hmp / bsp)

void() set_npc =
{
	precache_model(self.model);

	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.classname = "npc";
	self.radius_candamage = "FALSE"; // uses string
	self.colormod = '100 100 0'; // Yellow

	//self.th_die = npc_death;

	self.exp = 0;

	self.saveorigin = self.origin + v_up * 1; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;

//	self.think = npc_ai_think;
//	self.nextthink = time + 0.1;
};

void() set_bonfire =
{
	precache_model("models/bonfire.iqm");
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.classname = "bonfire";
	self.radius_candamage = "FALSE"; // uses string
	self.colormod = '10 0 0'; // Yellow

	setmodel(self, "models/bonfire.iqm");
	setsize(self, [-16, -16, 0], [16, 16, 56]);
	setorigin(self, self.origin + v_up * 64);
};