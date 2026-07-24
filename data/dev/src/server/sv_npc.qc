//
// NPCs, most are defined in the maps themselves (hmp / bsp)
//

void(entity targ, entity client) SendNPCInventory;
void(entity player) DeleteInventory;
void() npc_ai_think;
.string npc_dialog; // reference npc file scripts

.string npc_quests;
.string npc_turnins;

string(entity npc, entity player) NPC_HasAvailableQuest;
string(entity npc, entity player) NPC_HasTurnInQuest;
void(entity player, entity npc) NPC_LoadQuestOptions;

//
// Helper function
//

void(entity npc, entity player) NPC_SendDialogue =
{
    NPC_LoadQuestOptions(player, npc);

    msg_entity = player;

    WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
    WriteByte(MSG_MULTICAST, CSQC_NPCINFO);

    WriteString(MSG_MULTICAST, npc.netname);
    WriteString(MSG_MULTICAST, npc.npc_dialog);

    WriteString(MSG_MULTICAST, player.npc_available_quest);
    WriteString(MSG_MULTICAST, player.npc_available_name);

    WriteString(MSG_MULTICAST, player.npc_turnin_quest);
    WriteString(MSG_MULTICAST, player.npc_turnin_name);

    multicast(npc.origin, MULTICAST_ONE_R);
};

//
// NPC_CommitState - Networking, mostly used for monsters / npcs
//

void(entity e) NPC_CommitState =
{
    e.last_origin = e.origin;
    e.last_angles = e.angles;
    e.last_velocity = e.velocity;
    e.last_flags = e.flags;
    e.last_effects = e.effects;
    e.last_health = e.health;
    e.last_max_health = e.max_health;
    e.last_modelindex = e.modelindex;
    e.last_main_hand = e.main_hand;
    e.last_off_hand = e.off_hand;
    e.last_anistate = e.anistate;
    e.last_attack_speed = e.attack_speed;
	e.last_alpha = e.alpha;
	e.last_displayname = e.displayname;
	e.last_speed = e.speed;
	e.last_level = e.level;
	e.last_ai_mode = e.ai_mode;
	e.last_movetype = e.movetype;
};

void(entity player, entity npc) NPC_LoadQuestOptions =
{
	string available;
	string turnin;

	player.npc_available_quest = "";
	player.npc_turnin_quest = "";

	available = NPC_HasAvailableQuest(npc, player);
	turnin = NPC_HasTurnInQuest(npc, player);

	entity q;

	player.npc_available_name = "";
	player.npc_turnin_name = "";

	if (available)
	{
		q = Quest_Find(available);

		if (q)
			player.npc_available_name = q.quest_name;
	}

	if (turnin)
	{
		q = Quest_Find(turnin);

		if (q)
			player.npc_turnin_name = q.quest_name;
	}

	player.npc_available_quest = available;
	player.npc_turnin_quest = turnin;

	// Debugging
	/*
	dprint(sprintf("^5NPC Quest Check:^7 %s\n", npc.netname));

	if (available)
		dprint(sprintf("^2 Available:^7 %s\n", available));

	if (turnin)
		dprint(sprintf("^3 Turn In:^7 %s\n", turnin));
	*/
};

void(string id) CSEv_QuestAccept_s =
{
    Quest_Accept(self, id);

    NPC_LoadQuestOptions(self, self.enemy);
    NPC_SendDialogue(self.enemy, self);    // we'll make this helper
};

void(string id) CSEv_QuestTurnIn_s =
{
    Quest_TurnIn(self, id);

    NPC_LoadQuestOptions(self, self.enemy);
    NPC_SendDialogue(self.enemy, self);
};

void() npc_use =
{
	if (!self.user)
		return;
	if (self.user.menu != MENU_OFF)
		return;

	self.user.velocity = [0, 0];

	string contents = "";
	string line = "";

	// grab NPC dialogue from file
	string readfile = strcat("npc/", self.netname, "_d.txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		while ((line = fgets(v)))
			contents = strcat(contents, line, "\n");
		self.npc_dialog = contents;
	}
	else
	{
		// Not all NPC's wish to talk, keep it in debug print however
		print("Possible error: NPC dialogue file not found -> ", self.netname, "\n");
		return;
	}
	fclose(v);

	DeleteInventory(self); // clear any inventory first, fixes gold doubling

	if (!self.type) //type 0, regular NPC; may or may not buy/sell items
	{
		// Grab NPC inventory from file
		string what = "";
		readfile = strcat("npc/", self.netname, "_i.txt");
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
			self.user.npc_vendor = 1; // Buy/Sell button
			fclose(b);
		}
		else // no item list found for npc
		{
			SendNPCInventory(self, self.user); // Clear NPC inventory when they have nothing either
			self.user.npc_vendor = 0; // CSQC: don't draw buy button for player
		}
	}
	else if (self.type == 1) // type 1, banking npc
		self.user.npc_vendor = 2; // Banking button
	else if (self.type == 2)
		self.user.npc_vendor = 3; // Sell wood button

	Quest_Event(self.user, "talk", strtolower(self.netname)); // quest update tracking

	// Open player NPC window, load available quests
	// *warning* Load Quest before sending packet!
	NPC_LoadQuestOptions(self.user, self);
	
	NPC_SendDialogue(self, self.user);
	/*
	msg_entity = self.user;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_NPCINFO); // custom opcode for "open npc dialog"
	WriteString(MSG_MULTICAST, self.netname);
	WriteString(MSG_MULTICAST, self.npc_dialog);
	WriteString(MSG_MULTICAST, self.user.npc_available_quest);
	WriteString(MSG_MULTICAST, self.user.npc_available_name);

	WriteString(MSG_MULTICAST, self.user.npc_turnin_quest);
	WriteString(MSG_MULTICAST, self.user.npc_turnin_name);
	multicast(self.origin, MULTICAST_ONE_R);
	*/

	self.user.menu = MENU_DIALOGUE;
	stuffcmd (self.user, sprintf("play %s\n", "menu/menu_open.wav"));
};

float(entity ePVEnt, float flChanged) NPC_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_NPC);

	WriteShort(MSG_ENTITY, self.modelindex);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);

	WriteByte(MSG_ENTITY, self.part_vfx);

	return TRUE;
};

void(entity npc) NPC_LoadQuests =
{
	float f;
	string line;

	string filename;

	filename = strcat("npc/", npc.netname, "_q.txt");
	f = fopen(filename, FILE_READ);

	if (f < 0)
		return;

	while ((line = fgets(f)))
	{
		line = strtrim(line);

		if (line == "")
			continue;

		if (substring(line, 0, 6) == "offer=")
		{
			npc.npc_quests = strcat(npc.npc_quests, substring(line, 6, strlen(line)), "\n");
		}

		else if (substring(line, 0, 7) == "turnin=")
		{
			npc.npc_turnins = strcat(npc.npc_turnins, substring(line, 7, strlen(line)), "\n");
		}
	}

	fclose(f);
};

//
// Check if NPC has an available quest
//
// Returns quest id or ""
//

string(entity npc, entity player) NPC_HasAvailableQuest =
{
	string line;
	float pos;
	string id;

	line = npc.npc_quests;

	while (line != "")
	{
		pos = strstrofs(line, "\n", 0);

		if (pos >= 0)
		{
			id = substring(line, 0, pos);
			line = substring(line, pos + 1, strlen(line));
		}
		else
		{
			id = line;
			line = "";
		}

		id = strtolower(id);

		if (Quest_CanOffer(player, id))
			return id;
	}

	return "";
};


//
// Check if NPC has a quest ready for turn in
//
// Returns quest id or ""
//

string(entity npc, entity player) NPC_HasTurnInQuest =
{
	string line;
	float pos;
	string id;

	line = npc.npc_turnins;

	while (line != "")
	{
		pos = strstrofs(line, "\n", 0);

		if (pos >= 0)
		{
			id = substring(line, 0, pos);
			line = substring(line, pos + 1, strlen(line));
		}
		else
		{
			id = line;
			line = "";
		}

		id = strtolower(id);

		if (Quest_CanTurnIn(player, id))
			return id;
	}

	return "";
};

//
// npc entity
//
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
	NPC_LoadQuests(self);
	self.th_use = npc_use;
	self.view_ofs = '0 0 48';

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	droptofloor();

	self.SendEntity = NPC_SendEntity;
	self.SendFlags = 1;
};

//
// Bonfire NPC
//

float(entity ePVEnt, float flChanged) Bonfire_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_BONFIRE);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	return TRUE;
};

void() bonfire_use =
{
	if (self.user && self.user.bonfire_finished < time)
	{
		if (self.user.bonfire == FALSE)
		{
			self.user.lantern = FALSE;
			self.user.effects &= ~EF_BRIGHTLIGHT;

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
			self.user.anistate = ANISTATE_SIT;

			CSEv_Player_SaveChar(self.user, 0); // full save

			string eventlog_print = "^5You rest at the bonfire\n";
			stuffcmd (self.user, sprintf("conecho event %s\nwf\n", eventlog_print));

			self.user.bonfire = TRUE;
			self.user.bonfire_finished = time + 3;
			sound (self, CHAN_AUTO, "bonfire1.wav", 1, ATTN_NORM);
		}
		/*
		else
			// Moved to sv_player.qc for various reasons
		*/
	}
};

void() set_bonfire =
{
	self.SendEntity = Bonfire_SendEntity;
	self.solid = SOLID_SLIDEBOX;
	self.th_use = bonfire_use;
	setsize(self, [-16, -16, 0], [16, 16, 80]);
	droptofloor();

	self.SendFlags = 1;
};