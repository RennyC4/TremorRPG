//
// NPCs, most are defined in the maps themselves (hmp / bsp)
//

void(entity targ, entity client) SendNPCInventory;
void() npc_ai_think;
.string npc_dialog; // reference npc file scripts
.float npc_inventory_grabbed; // boolean

void() npc_use =
{
	if (!self.user)
		return;
	if (self.user.menu != MENU_OFF)
		return;

	self.user.velocity = [0, 0];

	string contents, line = "";

	// grab NPC dialogue from file
	string readfile = strcat("npc_", self.netname, "_d.txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		while ((line = fgets(v)))
		{
			contents = strcat(contents, line, "\n");
			self.npc_dialog = contents;
		}
	}
	else
	{
		print ("Error: NPC dialogue file not found\n");
		return;
	}
	fclose(v);

	if (!self.npc_inventory_grabbed) // only grab the inventory ONCE *important*
	{
		// Grab NPC inventory from file
		string what = "";
		readfile = strcat("npc_", self.netname, "_i.txt");
		float b = fopen(readfile, FILE_READ);
		if (b >= 0)
		{
			if (line = fgets(b)) // Get item count from text file
				self.read_inv_count = stof(line);

			float i;
			for (i = 0; i < self.read_inv_count; i++)
			{
				if (line = fgets(b)) // Add item
				{
					what = line;
					AddToInventory(self, line, 0);
				}
				if (line = fgets(b)) // Add count to item, NPCs use item count as buying price
					AddToInventory(self, what, stof(line));
			}
			SendNPCInventory(self, self.user); // Send NPC inventory to CSQC
		}
		fclose(b);
		// We don't send an error if an NPC doesn't have an inventory as not all are vendors

		msg_entity = self.user;
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, CSQC_NPCINFO); // custom opcode for "open npc dialog"
		WriteString(MSG_MULTICAST, self.netname);
		WriteString(MSG_MULTICAST, self.npc_dialog);
		multicast(self.origin, MULTICAST_ONE_R);

		self.npc_inventory_grabbed = TRUE;
	}
	// Open player NPC window
	self.user.menu = MENU_DIALOGUE;

	self.think = npc_ai_think;
	self.nextthink = time + 0.1;
};

void() npc_ai_think =
{
	for (entity b = world; (b = find(b, classname, "player"));) // search for customer nearby
	{
		if (vlen(b.origin - self.origin) < 100)
			self.goalentity = b;
		else
			self.goalentity = world;
	}
	if (!self.netname)
	{
		print("Error: NPC without a netname defined!\n");
		self.netname = "error";
	}
	TurnToTarget(10);

	self.nextthink = time + 0.1;
};

void() set_npc =
{
	precache_model(self.model);

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.classname = "npc";
	self.radius_candamage = FALSE;
	self.colormod = '100 100 0'; // Yellow
	self.idealangles = self.angles;
	self.th_use = npc_use;

	//self.th_die = npc_death;
	//self.exp = 0;

	self.saveorigin = self.origin + v_up * 1; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;

	self.think = npc_ai_think;
	self.nextthink = time + 0.1;
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
			sound (self, CHAN_AUTO, "bonfire1.wav", 1, ATTN_NORM);
		}
		/*
		else
			// Moved to sv_player.qc for various reasons
		*/
	}
	self.think = bonfire_think;
	self.nextthink = time + 0.1;
};

void() set_bonfire =
{
	precache_model("models/bonfire.glb");
	precache_sound("bonfire1.wav");
	precache_sound("bonfire2.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.classname = "bonfire";
	self.radius_candamage = FALSE;
	self.th_use = bonfire_use;
	self.effects = EF_DIMLIGHT;

	setmodel(self, "models/bonfire.glb");
	setsize(self, [-16, -16, 0], [16, 16, 80]);
	setorigin(self, self.origin + v_up * 64);
	droptofloor();

	ambientsound(self.origin, "bonfire2.wav", 1, ATTN_STATIC);

	self.think = bonfire_think;
	self.nextthink = time + 0.1;
};