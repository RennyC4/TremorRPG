//
// Magic spells and systems
//

void(string itemname) LearnSpell =
{
	float i;
	for (i = 0; i < self.spell_count; i=i+1)
	{
		if (self.spell[i] == itemname)
		{
			sprint(self, PRINT_HIGH, strcat(itemname, " is already known!\n"));
			return;
		}
	}

	if (self.spell_count < MAX_SPELLS)
	{
		self.spell[self.spell_count] = itemname;
		sprint(self, PRINT_HIGH, strcat(itemname, " has been learned!\n"));
		stuffcmd (self, sprintf("play %s\n", "learnspell.wav")); // sound
		self.spell_count += 1;
	}
	else
		sprint(self, PRINT_HIGH, "You cannot learn any more spells\n");
};

// called whenever we need to send player/client ONLY magic spell data to CSQC
void(entity player) SendMagicSpells =
{
    float i;

	msg_entity = player;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_MAGIC);
	WriteByte(MSG_MULTICAST, player.spell_count);
    for (i = 0; i < player.spell_count; i++)
        WriteString(MSG_MULTICAST, player.spell[i]);
	multicast(self.origin, MULTICAST_ONE_R);
};

string(string s) RemoveSpellPrefix =
{
    string prefix = "Spell - ";
    float prefix_len = strlen(prefix);

    // Check if the string starts with the prefix
    if (strlen(s) >= prefix_len && substring(s, 0, prefix_len) == prefix)
        return substring(s, prefix_len, strlen(s) - prefix_len);
    return s; // no prefix, return original string
};

void(string spellname) CSEv_EquipSpell_s =
{
	spellname = RemoveSpellPrefix(spellname);

	self.spell_equipped = spellname; // update selected spell

	if (spellname == "Thorn")
	{
		self.spell_power_min = 7;
		self.spell_power_max = 14;
	}

	stuffcmd (self, sprintf("play %s\n", "equipspell.wav")); // sound
	sprint(self, PRINT_HIGH, strcat("Magic spell: ", spellname, " memorized\n"));
};

void() CSEv_DoAttack_Magic_ = // CSQC
{
	if (self.deadflag == DEAD_DEAD || self.health <= 0)
		return;
	if (self.spell_equipped == "None")
		return;

	// calculate damage by weapon
	float damage = ceil(random_range(self.spell_power_min, self.spell_power_max));

	if (self.spell_equipped == "Thorn")
	{
		print ("Magic attack GO!\n");
	}
	else
		print ("Error: Magic spell doesn't exist!\n");
};