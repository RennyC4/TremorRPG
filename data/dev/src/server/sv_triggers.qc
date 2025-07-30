//
// Used for when the player enters different zones
//

void() trigger_zone_touch =
{
	if (other.classname != "player")
		return;

	if (other.music != self.music)
	{
		other.music = self.music;
		stuffcmd (other, sprintf("music %s\n", self.music));
	}
	if (other.zonename != self.zonename)
	{
		other.zonename = self.zonename;
		if (other.zonename_finished < time)
			other.zonename_finished = time + 3; // display in csqc hud
	}

	// TODO: PVP Flag stuff
};

void() trigger_zone =
{
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = trigger_zone_touch;

	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.model = "";
};

void() func_illusionary =
{
	setmodel(self, self.model);
	self.solid = SOLID_NOT;
};

void() info_null ={};