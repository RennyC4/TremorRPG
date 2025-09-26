//
// Magic system handlers
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
	else if (spellname == "Light Heal")
	{
		self.spell_power_min = 25;
		self.spell_power_max = 50;
	}

	stuffcmd (self, sprintf("play %s\n", "equipspell.wav")); // sound
	sprint(self, PRINT_HIGH, strcat("Magic spell: ", spellname, " memorized\n"));
};

//
// Magic Spells
//

void(float damage) Cast_Thorn =
{
	float spell_length = 500;
	float parry = FALSE;

	makevectors (self.v_angle);
	sound (self, CHAN_WEAPON, "magic/thorn_cast.wav", 1, ATTN_NORM);

	vector selfmid = self.origin;
	selfmid_z += (self.mins_z + self.maxs_z) * 0.5;
	vector source = selfmid;

	damage = damage + (self.skill_offensivemagic * 0.1); // initial damage
	traceline (source, source + v_forward * spell_length, MOVE_TRIGGERS, self);

	if (trace_fraction == 1.0)
	{
		entity snd = spawn();
		setmodel(snd, string_null);
		setorigin (snd, trace_endpos);
		snd.think = sub_remove;
		snd.nextthink = time + 0.1;
		sound (snd, CHAN_AUTO, "magic/thorn_misc.wav", 1, ATTN_STATIC);

		pointparticles(PART_MAGIC_THORN2, trace_endpos);
		return; // hit nothing
	}

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO)
	{
		if (self.classname == "player" && trace_ent.classname == "player") // PVP checks
		{
			if (self.pvp != 1 || trace_ent.pvp != 1)
				return;
			else
			{
				self.incombat = trace_ent.incombat = TRUE; // Turn off health regen, flag players for incombat
				self.incombat_finished = trace_ent.incombat_finished = time + 30; // keep players locked in combat
			}
		}

		if (trace_ent.parry_finished < time)
			parry = FALSE;
		else
			parry = TRUE;

		if (!parry)
		{
			// armor calculations, armor doesn't help as much compared to melee
			if (trace_ent.armorvalue / 3 > damage)
				damage = 1;
			else
				damage = damage - (trace_ent.armorvalue / 3);
			// spell resist calculations
			damage -= (trace_ent.skill_spellresist * 0.1);
			// blocking calculations
			if (check_block(self, trace_ent) && trace_ent.blocking)
				damage = damage - (trace_ent.blockvalue / 3);

			// blood logic + effects
			vector mid = trace_ent.origin;
			mid_z += (trace_ent.mins_z + trace_ent.maxs_z) * 0.5;
			vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
			te_blood(mid, vel, 12);
			
			damage = ceil(damage); // round up final damage output
			DoDamage(trace_ent, self, damage);

			sound (trace_ent, CHAN_AUTO, "magic/thorn_misc.wav", 1, ATTN_STATIC);
			sound (trace_ent, CHAN_AUTO, "magic/thorn_hit.wav", 1, ATTN_NORM);
			pointparticles(PART_MAGIC_THORN1, mid);
		}
		else // parry
		{
			sound (trace_ent, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
			sound (trace_ent, CHAN_AUTO, "magic/thorn_misc.wav", 1, ATTN_STATIC);
			pointparticles(PART_MAGIC_THORN2, trace_endpos);
			string eventlog_print = (strcat("^2Successful parry!"));
			stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
		}
	}
	else
	{
		snd = spawn();
		setmodel(snd, string_null);
		setorigin (snd, trace_endpos);
		snd.think = sub_remove;
		snd.nextthink = time + 0.1;
		sound (snd, CHAN_AUTO, "magic/thorn_misc.wav", 1, ATTN_STATIC);

		pointparticles(PART_MAGIC_THORN2, trace_endpos);
	}
};

void(float amount) Cast_LightHeal =
{
	amount = amount + (self.skill_defensivemagic * 0.1);
	self.health += amount;
	if (self.health > self.max_health)
		self.health = self.max_health;

	string eventlog_print = (strcat("^6Light Heal: ^2+", ftos(amount), "hp\n"));
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
	sound (self, CHAN_AUTO, "magic/lightheal.wav", 1, ATTN_NORM);

	self.cast_finished_spell = ""; // important: always clear this after the spell is fired
	pointparticles(PART_MAGIC_LIGHTHEAL, self.origin);
};

.float casting_loop;
void() Player_CastMagic = // called from player postthink
{
	float spellpower = ceil(random_range(self.spell_power_min, self.spell_power_max));

	// Charging sound
	if (self.cast_finished > time)
	{
		if (self.casting_loop < time)
		{
			pointparticles(PART_MAGIC_CASTING, self.origin);
			sound (self, CHAN_VOICE, "magic/casting.wav", 1, ATTN_NORM);
			self.casting_loop = time + 1.5;
		}
	}

	// Charging is finished, unleash spell
	if (self.cast_finished < time && self.cast_finished_spell != "")
	{
		if (self.cast_finished_spell == "Light Heal")
		{
			Cast_LightHeal(spellpower);
			self.mana -= 20;
		}
	}
};


void() CSEv_DoAttack_Magic_ = // CSQC
{
	if (self.deadflag == DEAD_DEAD || self.health <= 0)
		return;
	if (self.spell_equipped == "None")
		return;
	if (self.cancast_finished > time) // for insta-cast spells
		return;
	if (self.melee_finished > time)
		return;
	if (self.cast_finished > time)
		return;

	// calculate base spell power by selected spell
	float spellpower = ceil(random_range(self.spell_power_min, self.spell_power_max));

	if (self.spell_equipped == "Thorn")
	{
		if (self.mana >= 8)
		{
			Cast_Thorn(spellpower);
			self.cancast_finished = time + 0.5;
			self.mana -= 8;
		}
		else
			sprint (self, PRINT_HIGH, "^1Not enough mana!\n");
	}
	else if (self.spell_equipped == "Light Heal")
	{
		if (self.mana >= 20)
		{
			self.cast_finished_spell = self.spell_equipped; // this is cleared once the spell is done casting
			self.cast_finished = time + 3; // casting time	
		}
		else
			sprint (self, PRINT_HIGH, "^1Not enough mana!\n");
	}
	else
		print ("Error CSEv_DoAttack_Magic_: Magic spell doesn't exist!\n");
};