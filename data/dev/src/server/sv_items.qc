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
	sprint(self, PRINT_HIGH, strcat(itemname, " equipped\n"));
};

void(float id, string itemname) Player_UseItem =
{
	if (id == 0) // health potion
	{
		// TODO: Health potions will recover 1/4th of your health, can carry only 2 at first
		self.health = min(self.health + 25, self.max_health);
		sprint(self, PRINT_HIGH, strcat(itemname, " used\n"));
	}
	else
		print("Player_UseItem: Item use ID not found\n");
};