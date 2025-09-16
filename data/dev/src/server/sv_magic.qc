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
		self.spell_count = self.spell_count + 1;
	}
	else
		sprint(self, PRINT_HIGH, "You cannot learn any more spells!\n");
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