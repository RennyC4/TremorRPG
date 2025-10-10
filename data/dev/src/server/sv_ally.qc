//
// Allies: Most are defined in the maps themselves (hmp / bsp), allies are town guards etc and are special characters
//

void() ally_respawn =
{
	self.solid = SOLID_SLIDEBOX;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.alpha = 1; // removeme when we have animations + proper model
	self.health = self.max_health;
	self.radius_candamage = TRUE;
	self.ai_mode = AI_IDLE; // return to idling

	setorigin (self, self.saveorigin); // respawn at initial spawn spot

	//self.think = ally_ai_think;
	//self.nextthink = time + 0.1;
};

void() set_ally =
{
	if (self.model)
		precache_model(self.model); // model

	/*
	if (self.noise)
		precache_sound(self.noise); // sight sound
	if (self.noise1)
		precache_sound(self.noise1); // attack sound
	if (self.noise2)
		precache_sound(self.noise2); // pain sound
	if (self.noise3)
		precache_sound(self.noise3); // death sound
	*/

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_NO; // Change later?
	self.classname = "ally";
	self.radius_candamage = TRUE; // can be affected by radius damage

	//self.flags |= FL_MONSTER;
	//self.th_die = ally_death;

	if (!self.sight_range)
		self.sight_range = 500;
	if (!self.exp)
		self.exp = 1;
//	if (!self.noise)
//		self.noise = "monsters/sight1.wav";
	if (!self.ai_move_dist)
		self.ai_move_dist = 2000;

	self.saveorigin = self.origin + v_up * 1; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;
	self.frame = 1;

	//monster_ai_spawnrunback();
	//self.think = monster_ai_think;
	//self.nextthink = time + 0.1 + random()*1; // stagger start think
	//self.SendEntity = Monster_SendEntity;
};