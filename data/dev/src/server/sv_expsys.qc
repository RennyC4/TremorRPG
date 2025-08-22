//
// Experience / Leveling / Skill point systems
//

.float levelup_finished;
void(entity targ) Player_CheckLevelUp =
{
    if (targ.exp >= targ.exp_next)
    {
		targ.level += 1;
		targ.skillpoints += 15;
		targ.max_health += 12;
		targ.max_mana += 5;

		sound (targ, CHAN_AUTO, "levelup.wav", 1, ATTN_NORM);

		string eventlog_print = (strcat("^3Level ", ftos(targ.level), " reached! +15 SP\n"));
		stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));

		targ.exp = targ.exp_oldnext = targ.exp_next; // cap exp on level up properly
		targ.exp_next = 100 * (targ.level * targ.level * 1.15);
    }
};

void(entity targ, float expmin, float expmax) GiveExperience =
{
	float amount = ceil(random_range(expmin, expmax));
	targ.exp += amount; // give exp

	string eventlog_print = (strcat("^2", ftos(amount), "^7 exp received!\n"));
	stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));

	Player_CheckLevelUp(targ);
};

void(entity targ, float goldmin, float goldmax) GiveGold =
{
	float amount = ceil(random_range(goldmin, goldmax));
	targ.gold += amount; // give gold

	string eventlog_print = (strcat("^3", ftos(amount), "^7 gold received!\n"));
	stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
};

// This is ugly / could be written better but eh
void(float which) CSEv_User_AddSkillPoint_f =
{
	if (self.skillpoints <= 0)
		return;

	float cap = (self.level * 10) + 10;
	if (!which)
	{
		if (self.skill_unarmed < cap)
		{
			self.skill_unarmed += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 1)
	{
		if (self.skill_slash < cap)
		{
			self.skill_slash += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 2)
	{
		if (self.skill_pierce < cap)
		{
			self.skill_pierce += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 3)
	{
		if (self.skill_unarmed < cap)
		{
			self.skill_bash += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 4)
	{
		if (self.skill_stealth < cap)
		{
			if (self.skill_stealth < 225)  // 0.9 infront(); 1 is dumb, this is maxed out
			{
				self.skill_stealth += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Stealth skill is maxed out\n");
			return;
		}
	}
	else if (which == 5)
	{
		if (self.skill_backstab < cap)
		{
			self.skill_backstab += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 6)
	{
		if (self.skill_offensivemagic < cap)
		{
			self.skill_offensivemagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 7)
	{
		if (self.skill_defensivemagic < cap)
		{
			self.skill_defensivemagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 8)
	{
		if (self.skill_neutralmagic < cap)
		{
			self.skill_neutralmagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 9)
	{
		if (self.skill_endurance < cap)
		{
			if (self.skill_endurance < 400)
			{
				self.skill_endurance += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Endurance skill is maxed out\n");
			return;
		}
	}
	else if (which == 10)
	{
		if (self.skill_spellresist < cap)
		{
			self.skill_spellresist += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 11)
	{
		if (self.skill_archery < cap)
		{
			self.skill_archery += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 12)
	{
		if (self.skill_healthregen < cap)
		{
			if (self.skill_healthregen < 240)
			{
				self.skill_healthregen += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Health regeneration skill is maxed out\n");
			return;
		}
	}
	else if (which == 13)
	{
		if (self.skill_manaregen < cap)
		{
			if (self.skill_healthregen < 240)
			{
				self.skill_manaregen += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Mana regeneration skill is maxed out\n");			
			return;
		}
	}
	else if (which == 14)
	{
		if (self.skill_haggle < cap)
		{
			self.skill_haggle += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 15)
	{
		if (self.skill_climb < cap)
		{
			if (self.skill_climb < 300)
			{
				self.skill_climb += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Climbing skill is maxed out\n");	
			return;
		}
	}
	else if (which == 16)
	{
		if (self.skill_swim < cap)
		{
			if (self.skill_swim < 300)
			{
				self.skill_swim += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Swimming skill is maxed out\n");	
			return;
		}
	}
	else if (which == 17)
	{
		if (self.skill_acrobatic < cap)
		{
			if (self.skill_climb < 300)
			{
				self.skill_acrobatic += 1;
				self.skillpoints -= 1;
			}
			else
				sprint(self, PRINT_HIGH, "Acrobatics skill is maxed out\n");	
			return;
		}
	}
	else
	{
		print ("error: skill doesn't exist\n");
		return;
	}
};
