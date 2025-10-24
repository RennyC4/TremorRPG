//
// Items and all their different uses
//
void(entity player, string itemname, float count) RemoveFromInventory;

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
			if (line = fgets(v)) // item required player level
				float required_level = stof(line);
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		if (self.level >= required_level)
		{
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

			// Remove new equipped from inventory
			RemoveFromInventory(self, itemname, 1);
		}
		else
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			return;
		}
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
			if (line = fgets(v)) // item required player level
				required_level = stof(line);
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		if (self.level >= required_level)
		{
			// Add old armor to inventory
			AddToInventory(self, self.armorname, 1);

			// Equip new armor
			self.armorname = armorname_e;
			self.armorvalue = armorvalue_e;
			// Remove new equipped from inventory
			RemoveFromInventory(self, itemname, 1);
		}
		else
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			return;
		}
	}
	else if (id == 2) // Off-hand to equip
	{
		if (v >= 0)
		{
			if (line = fgets(v)) // skip price on equipping
			if (line = fgets(v)) // off-hand name
				string off_hand_e = line;
			if (line = fgets(v)) // block value
				float blockvalue_e = stof(line);
			if (line = fgets(v)) // item required player level
				required_level = stof(line);

			// used for projectiles
			if (line = fgets(v)) // item min damage (projectiles)
				self.projectile_power_min = stof(line);
			else
				self.projectile_power_min = 0;
			if (line = fgets(v)) // item max damage (projectiles)
				self.projectile_power_max = stof(line);
			else
				self.projectile_power_max = 0;
		}
		else
		{
			print ("Player_EquipItem: ", readfile, " not found\n");
			return;
		}

		if (self.level >= required_level)
		{
			// Add old armor to inventory
			AddToInventory(self, self.off_hand, 1);

			// Equip new armor
			self.off_hand = off_hand_e;
			self.blockvalue = blockvalue_e;

			// Remove new equipped from inventory
			RemoveFromInventory(self, itemname, 1);
		}
		else
		{
			sprint(self, PRINT_HIGH, "Level requirement has not been met\n");
			return;
		}
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
		self.potion_use_finished = time + 3; // slow player movement
		if (self.healthpot_finished < time)
			self.healthpot_finished = time + 3; // delay before first tick (drink time)

		self.anistate = ANISTATE_DRINK;
		pointparticles(PART_HEALTHPOTION, self.origin);

		stuffcmd (self, sprintf("play %s\n", "drink.wav")); // sound
		sprint(self, PRINT_HIGH, strcat(itemname, " used\n"));
		RemoveFromInventory(self, itemname, 1);		
	}
	else if (id == 1) // lantern
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
	else if (id == 2) // mana potion
	{
		self.crouch = FALSE; // remove crouching if enabled
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
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
		RemoveFromInventory(self, itemname, 1);		
	}
	else if (id == 3) // Magic spell to add to magic screen
	{
		LearnSpell(itemname);
		RemoveFromInventory(self, itemname, 1);
	}
	else
		print("Player_UseItem: Item use ID not found\n");
};