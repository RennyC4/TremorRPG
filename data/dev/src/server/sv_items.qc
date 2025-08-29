//
// Items and all their different uses
//

void(string itemname, float id) Player_EquipItem =
{
	string line;
	string fix_itemname = string_remove_spaces(itemname);
	string readfile = strcat("itm_", fix_itemname, ".txt");

	float v = fopen(readfile, FILE_READ);

	if (id == 0) // Main hand (weapons etc) equip
	{
		if (v >= 0)
		{
			if (line = fgets(v)) // skip price on equipping
			if (line = fgets(v)) // weapon name
				string main_hand_e = line;
			if (line = fgets(v)) // attack type
				float attack_type_e = stof(line);
			if (line = fgets(v)) // attack power min
				float attack_power_min_e = stof(line);
			if (line = fgets(v)) // attack power max
				float attack_power_max_e = stof(line);
			if (line = fgets(v)) // attack power speed
				float attack_speed_e = stof(line);
			if (line = fgets(v)) // attack stamina
				float attack_stamina_e = stof(line);
			if (line = fgets(v)) // attack length
				float attack_length_e = stof(line);
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		// Add weapon to inventory
		AddToInventory(self, self.main_hand, 1);

		// Equip new weapon
		self.main_hand = main_hand_e;
		self.attack_type = attack_type_e;
		self.attack_power_min = attack_power_min_e;
		self.attack_power_max = attack_power_max_e;
		self.attack_speed = attack_speed_e;
		self.attack_stamina = attack_stamina_e;
		self.attack_length = attack_length_e;
	}
	else if (id == 1) // Main armor to equip
	{
		if (v >= 0)
		{
			if (line = fgets(v)) // skip price on equipping
			if (line = fgets(v)) // armor name
				string armorname_e = line;
			if (line = fgets(v)) // armor value
				float armorvalue_e = stof(line);
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		// Add old armor to inventory
		AddToInventory(self, self.armorname, 1);

		// Equip new armor
		self.armorname = armorname_e;
		self.armorvalue = armorvalue_e;
	}
	else if (id == 2) // Off-hand to equip
	{
		if (v >= 0)
		{
			if (line = fgets(v)) // skip price on equipping
			if (line = fgets(v)) // armor name
				string off_hand_e = line;
			if (line = fgets(v)) // armor value
				float blockvalue_e = stof(line);
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		// Add old armor to inventory
		AddToInventory(self, self.off_hand, 1);

		// Equip new armor
		self.off_hand = off_hand_e;
		self.blockvalue = blockvalue_e;
	}
	stuffcmd (self, sprintf("play %s\n", "item/equip.wav")); // sound
	sprint(self, PRINT_HIGH, strcat(itemname, " equipped\n"));
};

void(float id, string itemname) Player_UseItem =
{
	if (id == 0) // health potion
	{
		self.crouch = FALSE; // remove crouching if enabled
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.alpha = 1;

		self.healthpot_heal_rate = self.max_health * 0.01; // heal 1% of max health
		self.healthpot_heal_remaining += ceil(self.max_health * 0.25); // add heal 25% per health potion
		self.healthpot_use_finished = time + 3; // slow player movement
		self.healthpot_finished = time + 3; // delay before first tick (drink time)

		stuffcmd (self, sprintf("play %s\n", "drink.wav")); // sound
		sprint(self, PRINT_HIGH, strcat(itemname, " used\n"));
	}
	else
		print("Player_UseItem: Item use ID not found\n");
};