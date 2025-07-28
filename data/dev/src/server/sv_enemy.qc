// Empty

void() monster_test =
{
    precache_model(self.model);
    setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.classname = "monster";
	self.colormod = '100 0 0'; // Red

	self.saveorigin = self.origin; // stash initial spawn spot
};