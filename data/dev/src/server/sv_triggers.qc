//
// Used for when the player enters different zones
//

void() trigger_zone_touch =
{
	if (other.classname != "player")
		return;

	if (other.pvp != self.pvp)
	{
		if (!self.pvp) // remove all PVP flags when pvp = 0
		{
			other.pvp_autoflagged = FALSE;
			other.incombat = FALSE;
			other.incombat_finished = time;
			other.pvpenable_count = 0;
			other.pvpenable_finished = time;
		}

		other.pvp = self.pvp;
	}
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