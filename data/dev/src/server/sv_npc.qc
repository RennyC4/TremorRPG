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

// TODO: Should update respawn location etc
void() bonfire_think =
{
	pointparticles(PART_BONFIRE, self.origin);
	self.nextthink = time + 0.1;
};

void() bonfire_use =
{
	if (self.user && self.user.bonfire_finished < time)
	{
		if (self.user.bonfire == FALSE)
		{
			// Restore stats
			self.user.health = self.user.max_health;
			self.user.mana = self.user.max_mana;
			self.user.stamina = 100;
			// Remove pvp auto flag
			self.user.pvp_autoflagged = FALSE;
			self.user.pvpenable_count = 0;
			// Remove combat
			self.user.incombat_finished = time;
			self.user.incombat = FALSE;

			// Simulate sitting (we're enabling crouch, without alpha)
			setsize(self.user, [-16, -16, 0], [16, 16, 28]);
			self.user.view_ofs = [0, 0, 24];
			self.user.crouch = TRUE;
			self.user.movetype = MOVETYPE_NONE; // Stop user movement
			self.user.velocity = '0 0 0';

			string eventlog_print = "^5You rest at the bonfire ...\n";
			stuffcmd (self.user, sprintf("conecho event %s\nwf\n", eventlog_print));

			CSEv_Player_SaveChar(self.user); // Save user character

			self.user.bonfire = TRUE;
			self.user.bonfire_finished = time + 3;
		}
		else
		{
			self.user.crouch = FALSE;
			setsize(self.user, [-16, -16, 0], [16, 16, 56]);
			self.user.view_ofs = [0, 0, 48];
			self.user.movetype = MOVETYPE_WALK; // Stop user movement

			string eventlog_print = "^5You stand back up ...\n";
			stuffcmd (self.user, sprintf("conecho event %s\n", eventlog_print));
			self.user.bonfire = FALSE;
		}
	}
	self.think = bonfire_think;
	self.nextthink = time + 0.1;
};

void() set_bonfire =
{
	precache_model("models/bonfire.iqm");
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.classname = "bonfire";
	self.radius_candamage = "FALSE"; // uses string
	self.th_use = bonfire_use;

	setmodel(self, "models/bonfire.iqm");
	setsize(self, [-16, -16, 0], [16, 16, 56]);
	setorigin(self, self.origin + v_up * 64);
	
	self.think = bonfire_think;
	self.nextthink = time + 0.1;
};