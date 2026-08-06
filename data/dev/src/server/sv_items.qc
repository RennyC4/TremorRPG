//
// Items and all their different uses
//

void(entity player, string itemname, float count) RemoveFromInventory;

//
// Helper(s)
//

string(string line) Item_Value =
{
    float p;

    p = strstrofs(line, "=", 0);

    if (p == -1)
        return "";

    return substring(line, p + 1, strlen(line));
};

string(string line) Item_Key =
{
    float p;

    p = strstrofs(line, "=", 0);

    if (p == -1)
        return "";

    return strtolower(substring(line, 0, p));
};

//
//
//

void(string itemname, float id) Player_EquipItem =
{
	string line;
	string fix_itemname = string_tolower(string_remove_spaces(itemname));
	string readfile = strcat("itm/", fix_itemname, ".txt");

	float v = fopen(readfile, FILE_READ);
	if (v < 0)
	{
		print("Player_EquipItem: ", readfile, " not found\n");
		return;
	}

	// --- MAIN HAND EQUIP ---
	if (id == 0)
	{
		string main_hand_e = "";
		float attack_type_e = 0;
		float attack_power_min_e = 0;
		float attack_power_max_e = 0;
		float attack_speed_e = 1;
		float attack_stamina_e = 0;
		float attack_length_e = 0;
		float required_level = 1;

		// read txt
		while ((line = fgets(v)))
		{
			string key;
			string value;

			key = Item_Key(line);
			value = Item_Value(line);

			if (key == "price")
			{
				// ignored when equipping
			}
			else if (key == "name")
				main_hand_e = value;
			else if (key == "attack_type")
				attack_type_e = stof(value);
			else if (key == "attack_power_min")
				attack_power_min_e = stof(value);
			else if (key == "attack_power_max")
				attack_power_max_e = stof(value);
			else if (key == "attack_speed")
				attack_speed_e = stof(value);
			else if (key == "attack_stamina")
				attack_stamina_e = stof(value);
			else if (key == "attack_length")
				attack_length_e = stof(value);
			else if (key == "required_level")
				required_level = stof(value);
		}

		if (self.level < required_level)
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			fclose(v);
			return;
		}

		string lname = string_tolower(itemname);
		string lname2 = string_tolower(self.main_hand);

		// Return old weapon to inventory unless it’s an arrow
		if (strstrofs(lname2, "arrow", 0) == -1)
			AddToInventory(self, self.main_hand, 1);

		// Equip new weapon
		self.main_hand = main_hand_e;
		self.attack_type = attack_type_e;
		self.attack_power_min = attack_power_min_e;
		self.attack_power_max = attack_power_max_e;
		self.attack_speed = (attack_type_e == 4) ? 2 : attack_speed_e;
		self.attack_stamina = attack_stamina_e;
		self.attack_length = attack_length_e;

		// Remove equipped from inventory if not an arrow
		if (strstrofs(lname, "arrow", 0) == -1)
			RemoveFromInventory(self, itemname, 1);
	}

	// --- ARMOR EQUIP ---
	else if (id == 1)
	{
		string armorname_e = "";
		float armorvalue_e = 0;
		required_level = 1;

		while ((line = fgets(v)))
		{
			key = Item_Key(line);
			value = Item_Value(line);

			if (key == "name")
				armorname_e = value;
			else if (key == "armor")
				armorvalue_e = stof(value);
			else if (key == "required_level")
				required_level = stof(value);
		}

		if (self.level < required_level)
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			fclose(v);
			return;
		}

		if (self.armorname != "Plain Clothes") // Don't put starter item back in players inventory
			AddToInventory(self, self.armorname, 1);
		self.armorname = armorname_e;
		self.armorvalue = armorvalue_e;
		RemoveFromInventory(self, itemname, 1);
	}

	// --- OFF-HAND EQUIP ---
	else if (id == 2)
	{
		string off_hand_e = "";
		float blockvalue_e = 0;
		required_level = 1;

		while ((line = fgets(v)))
		{
			string key;
			string value;

			key = Item_Key(line);
			value = Item_Value(line);

			if (key == "name")
				off_hand_e = value;
			else if (key == "block")
				blockvalue_e = stof(value);
			else if (key == "required_level")
				required_level = stof(value);
			else if (key == "projectile_power_min")
				self.projectile_power_min = stof(value);
			else if (key == "projectile_power_max")
				self.projectile_power_max = stof(value);
		}

		if (self.level < required_level)
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			fclose(v);
			return;
		}

		AddToInventory(self, self.off_hand, 1);
		self.off_hand = off_hand_e;
		self.blockvalue = blockvalue_e;
		RemoveFromInventory(self, itemname, 1);
	}

	// --- HELMET EQUIP ---
	else if (id == 3)
	{
		string helmetname_e = "";
		float helmetvalue_e = 0;
		required_level = 1;

		while ((line = fgets(v)))
		{
			string key;
			string value;

			key = Item_Key(line);
			value = Item_Value(line);

			if (key == "name")
				helmetname_e = value;
			else if (key == "armor")
				helmetvalue_e = stof(value);
			else if (key == "required_level")
				required_level = stof(value);
		}

		if (self.level < required_level)
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			fclose(v);
			return;
		}

		if (self.helmetname != "None")
			AddToInventory(self, self.helmetname, 1);
		self.helmetname = helmetname_e;
		self.helmetvalue = helmetvalue_e;
		RemoveFromInventory(self, itemname, 1);
	}

	fclose(v);

	// --- Equip sound and message ---
	stuffcmd(self, sprintf("play %s\n", "item/equip.wav")); // play sound
	sprint(self, PRINT_HIGH, strcat(itemname, " equipped\n"));
};

void(float id, string itemname) CSEv_Player_UseItem_fs =
{
	if (id == 0) // health potion
	{
		if (HasItem(self, "Health Potion"))
		{
			self.velocity_x = self.velocity_y = 0;
			Player_RemoveCrouch(); // remove crouch
			self.alpha = 1;

			self.healthpot_heal_rate = self.max_health * 0.01; // heal 1% of max health
			self.healthpot_heal_remaining += ceil(self.max_health * 0.25); // add heal 25% per health potion
			self.potion_use_finished = time + 3; // slow player movement
			if (self.healthpot_finished < time)
				self.healthpot_finished = time + 3; // delay before first tick (drink time)

			self.anistate = ANISTATE_DRINK;
			pointparticles(PART_HEALTHPOTION, self.origin);

			stuffcmd (self, sprintf("play %s\n", "drink.wav")); // sound
			sprint(self, PRINT_HIGH, strcat(itemname, " used\n"));

			string eventlog_print = (strcat(itemname, " used\n"));
			stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

			RemoveFromInventory(self, itemname, 1);
		}
		else
			sprint(self, PRINT_HIGH, "You do not posses ", strcat(itemname, " \n"));
	}
	else if (id == 1) // lantern
	{
		if (!self.waterlevel)
		{
			if (!self.bonfire)
			{
				if (!self.lantern)
				{
					sound(self, CHAN_AUTO, "lantern.wav", 0.5, ATTN_NORM);
					sprint(self, PRINT_HIGH, strcat(itemname, " is lit\n"));
					self.effects |= EF_BRIGHTLIGHT;
					self.lantern = TRUE;
				}
				else
				{
					sound(self, CHAN_AUTO, "lantern.wav", 0.25, ATTN_NORM);
					sprint(self, PRINT_HIGH, strcat(itemname, " is unlit\n"));
					self.effects &= ~EF_BRIGHTLIGHT;
					self.lantern = FALSE;
				}
			}
		}
		else
			sprint(self, PRINT_HIGH, strcat(itemname, " cannot be lit underwater\n"));
	}
	else if (id == 2) // mana potion
	{
		if (HasItem(self, "Mana Potion"))
		{
			self.velocity_x = self.velocity_y = 0;
			Player_RemoveCrouch(); // remove crouch
			self.alpha = 1;

			self.manapot_heal_rate = self.max_mana * 0.01; // heal 1% of max mana
			self.manapot_heal_remaining += ceil(self.max_mana * 0.5); // add 50% per mana potion
			self.potion_use_finished = time + 3; // slow player movement
			if (self.manapot_finished < time)
				self.manapot_finished = time + 3; // delay before first tick (drink time)

			self.anistate = ANISTATE_DRINK;
			pointparticles(PART_MANAPOTION, self.origin);

			stuffcmd (self, sprintf("play %s\n", "drink.wav")); // sound
			sprint(self, PRINT_HIGH, strcat(itemname, " used\n"));

			eventlog_print = (strcat(itemname, " used\n"));
			stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

			RemoveFromInventory(self, itemname, 1);	
		}
		else
			sprint(self, PRINT_HIGH, "You do not posses ", strcat(itemname, " \n"));
	}
	else if (id == 3) // Add magic spell to magic screen
	{
		LearnSpell(itemname);
		RemoveFromInventory(self, itemname, 1);
	}
	else if (id == 4) // Small fish - consumable
	{
		self.health += 5;
		self.stamina += 5;

		if (self.health > self.max_health) // cap
			self.health = self.max_health;
		if (self.stamina >= 100) // cap
			self.stamina = 100;

		stuffcmd (self, sprintf("play %s\n", "eat.wav")); // sound
		eventlog_print = (strcat("^5", itemname, ":^2 +5 HP +5 Stam"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

		RemoveFromInventory(self, itemname, 1);
	}
	else
		print("Player_UseItem: Item use ID not found\n");
};

void() CSEv_User_UnequipMainhand_ =
{
    if (self.main_hand == "Unarmed")
    {
        sprint(self, PRINT_HIGH, "Main hand is already unequipped\n");
        return;
    }

    string lname = string_tolower(self.main_hand); // case-insensitive check

    // strstrofs() returns -1 if not found, so we check for != -1 directly
	if (strstrofs(lname, "arrow", 0) == -1)
		AddToInventory(self, self.main_hand, 1); // Only re-add to inventory if it's NOT an arrow-type item

    // Reset combat stats to unarmed
    self.attack_power_min = 1;
    self.attack_power_max = 1;

    // Unarmed speed scales with skill
    self.attack_speed = 3 - (self.skill_unarmed * 0.0145);
    if (self.attack_speed < 0.1)
        self.attack_speed = 0.1; // lower bound

    self.attack_stamina = 5;
    self.attack_type = 0;   // unarmed
    self.attack_length = 32;
    self.main_hand = "Unarmed";

    stuffcmd(self, sprintf("play %s\n", "item/equip.wav")); // play sound
    sprint(self, PRINT_HIGH, "Main hand unequipped\n");
};

void() CSEv_User_UnequipOffhand_ =
{
	if (self.off_hand == "Empty")
	{
		sprint(self, PRINT_HIGH, "Off hand is unequipped already\n");
		return;
	}

	AddToInventory(self, self.off_hand, 1); // add old item back to inventory

	self.off_hand = "Empty";
	self.blockvalue = 0;
	self.projectile_power_min = 0;
	self.projectile_power_max = 0;

	stuffcmd (self, sprintf("play %s\n", "item/equip.wav")); // sound
	sprint(self, PRINT_HIGH, strcat("Off hand unequipped\n"));
};

void() CSEv_User_UnequipArmor_ =
{
	if (self.armorname == "Plain Clothes")
	{
		sprint(self, PRINT_HIGH, "Armor is unequipped already\n");
		return;
	}

	if (self.armorname != "Plain Clothes") // do not add starter item
		AddToInventory(self, self.armorname, 1); // add old item back to inventory

	self.armorname = "Plain Clothes";
	self.armorvalue = 0;

	stuffcmd (self, sprintf("play %s\n", "item/equip.wav")); // sound
	sprint(self, PRINT_HIGH, strcat("Armor unequipped\n"));
};

void() CSEv_User_UnequipHelmet_ =
{
	if (self.helmetname == "None")
	{
		sprint(self, PRINT_HIGH, "Helmet is unequipped already\n");
		return;
	}

	if (self.helmetname != "None") // do not put "none" in users inventory
		AddToInventory(self, self.helmetname, 1); // add old item back to inventory

	self.helmetname = "None";
	self.helmetvalue = 0;

	stuffcmd (self, sprintf("play %s\n", "item/equip.wav")); // sound
	sprint(self, PRINT_HIGH, strcat("Helmet unequipped\n"));
};