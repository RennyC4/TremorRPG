//
// Used for when the player enters different zones
//

void() trigger_zone_touch =
{
	if (other.classname != "player")
		return;

	if (other.message != self.message || self.music != self.music)
		print ("Sent zone information to player\n"); // just print once for debugging

	if (other.music != self.music)
	{
		other.music = self.music;
		stuffcmd (other, sprintf("music %s\n", self.music));
	}
	if (other.message != self.message)
		other.message = self.message;

	//print (self.music, "\n");
	// TODO: PVP Flag stuff
};

void() trigger_zone =
{
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = trigger_zone_touch;

	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

void() func_illusionary =
{
	setmodel(self, self.model);
	self.solid = SOLID_NOT;
};

void() info_null ={};