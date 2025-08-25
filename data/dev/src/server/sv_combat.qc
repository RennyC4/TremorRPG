//
// Damage routines
//

void(entity targ, entity attacker, float damage) DoDamage;
vector() AttackDir;

// Camera shake
void(entity e, float howmuch) DoCamera_Shake =
{
	if (e.classname != "player")
		return;
	if (e.camera_toggle) // disable in 3rd person mode
		return;

	if (random() < 0.5)
	{
		e.angles_x += howmuch;
		if (random() < 0.5)
			e.angles_y += howmuch;
		else
			e.angles_y -= howmuch;
	}
	else
	{
		e.angles_x += (howmuch * -1);
		if (random() < 0.5)
			e.angles_y += howmuch;
		else
			e.angles_y -= howmuch;
	}
	e.fixangle = TRUE;
};

// returns 1 if the entity is in front (in sight) of self, used for blocking
float(entity enemy, entity defender) check_block =
{
	makevectors (defender.angles);
	vector vec = normalize (enemy.origin - defender.origin);
	float dot = vec * v_forward;

	if (dot > 0.7)
		return TRUE;
	return FALSE;
};

// return 1 if monster or player are behind each other using findfloat
float(entity defender) check_backstab =
{
	vector properangle = defender.angles;
	properangle_x = properangle_z = 0;
	makevectors (properangle);

	for (entity a = world;(a = findfloat(a, canbackstab, TRUE));)
	{
		if (vlen(a.origin - (defender.origin - v_forward * 32)) < 15)
			return TRUE;
	}
	return FALSE;
};

void() DoAttack_ShieldBash =
{
	if (self.melee_finished > time)
		return;

	if (self.flags & FL_ONGROUND)
		self.velocity = [0, 0];

	// Stamina drain on swing
	if (self.classname == "player")
	{
		float stamcalc = 15 - (self.skill_endurance * 0.015); // calculation, same as regular sword swing
		if (self.stamina < stamcalc)
			return;
		self.stamina -= stamcalc;
	}

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + AttackDir() * 48, MOVE_TRIGGERS, self);

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO)
	{
		// PVP
		if (self.classname == "player" && trace_ent.classname == "player")
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
		{
			// Pushing
			vector dir = trace_ent.origin - self.origin;
			dir = normalize(dir);
			trace_ent.velocity = '0 0 0';
			trace_ent.flags &= ~FL_ONGROUND;
			trace_ent.velocity_z += 125;
			trace_ent.velocity = trace_ent.velocity + dir * 200;
			//
			if (trace_ent.stagger_finished < time)
			{
				trace_ent.stagger_finished = time + 1.5;
				trace_ent.lockview_finished = time + 1.5;
			}
			DoCamera_Shake(trace_ent, 16);
			sound (trace_ent, CHAN_BODY, "shield2.wav", 1, ATTN_NORM);
		}
		else // Parry
		{
			float parry = TRUE;
			string eventlog_print = (strcat("^2Successful parry!"));
			stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
			// apply effects
			self.stagger_finished = time + 2;
			self.lockview_finished = time + 2;
			sound (self, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
		}
	}
	sound (self, CHAN_WEAPON, "shield3.wav", 1, ATTN_NORM);
	self.melee_finished = time + 1.5;
	self.lockview_finished = time + 1.5;
};

// Main melee attack function
void() DoAttack_Melee =
{
	if (self.melee_finished > time)
		return;

	if (self.flags & FL_ONGROUND)
		self.velocity = [0, 0];

	// Stamina drain on swing
	if (self.classname == "player")
	{
		float stamcalc = self.skill_endurance * 0.015; // calculation
		if (self.stamina < self.attack_stamina)
		{
			sprint(self, PRINT_HIGH, "^1Out of stamina ...\n");
			return;
		}
		self.stamina -= (self.attack_stamina - stamcalc);
	}

	// calculate damage by weapon
	float damage = ceil(random_range(self.attack_power_min, self.attack_power_max));

	// add skill damage
	float howmuch = 0.1;
	if (!self.attack_type) // unarmed
		damage = damage + (self.skill_unarmed * howmuch);
	else if (self.attack_type == 1) // slash
		damage = damage + (self.skill_slash * howmuch);
	else if (self.attack_type == 2) // pierce
		damage = damage + (self.skill_pierce * howmuch);
	else // bashing
		damage = damage + (self.skill_bash * howmuch);

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + AttackDir() * self.attack_length, MOVE_TRIGGERS, self);
	sound (self, CHAN_WEAPON, "sword1.wav", 1, ATTN_NORM);

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO)
	{
		// PVP
		if (self.classname == "player" && trace_ent.classname == "player")
		{
			if (self.pvp != 1 || trace_ent.pvp != 1)
				return;
			else
			{
				self.incombat = trace_ent.incombat = TRUE; // Turn off health regen, flag players for incombat
				self.incombat_finished = trace_ent.incombat_finished = time + 30; // keep players locked in combat
			}
		}

		if (self.fall_maxspeed >= 100)
			float jumpattack = TRUE;
		else
			jumpattack = FALSE;

		// check & add backstab skill damage
		float bs_damage = 0;
		float backstab = FALSE;
		if (check_backstab(trace_ent) && !jumpattack)
		{
			bs_damage = (self.skill_backstab * howmuch);
			if (bs_damage < 1)
				bs_damage = 1;
			backstab = TRUE;
			sound (trace_ent, CHAN_AUTO, "backstab.wav", 1, ATTN_NORM);	

			if (self.classname == "player")
			{
				string eventlog_print = (strcat("^1Backstab! +", ftos(bs_damage), " damage !!\n"));
				stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
			}
			if (trace_ent.classname == "player")
			{
				if (trace_ent.stagger_finished < time)
				{
					eventlog_print = (strcat("^1You've been staggered!"));
					stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
					trace_ent.lockview_finished = time + 3;
					trace_ent.stagger_finished = time + 3; // stagger, stamina is out
				}
			}
		}

		// blocking
		float parry = FALSE;
		if (check_block(self, trace_ent) && trace_ent.blocking && !backstab)
		{
			float stamcalc_block = 20 - (self.skill_endurance * 0.015); // calculation

			if (trace_ent.parry_finished < time)
			{
				if (trace_ent.stamina >= stamcalc_block)
				{
					damage = damage - trace_ent.blockvalue;
					if (trace_ent.blockvalue > damage)
						damage = 1;

					trace_ent.stamina -= stamcalc_block;
					DoCamera_Shake(trace_ent, 8);
				}
				else
				{
					if (trace_ent.stagger_finished < time)
					{
						if (trace_ent.classname == "player")
						{
							eventlog_print = (strcat("^1You've been staggered!"));
							stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
						}
						DoCamera_Shake(trace_ent, 12);
						damage = damage - ceil(trace_ent.blockvalue / 2); // save a tiny bit of damage still
						trace_ent.stamina = 0;
						trace_ent.blocking = FALSE;
						trace_ent.lockview_finished = time + 3;
						trace_ent.stagger_finished = time + 3; // stagger, stamina is out
					}
				}
			}
			else // parry
			{
				parry = TRUE;
				sound (self, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
				eventlog_print = (strcat("^2Successful parry!"));
				stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
				// apply effects
				self.lockview_finished = time + 3;
				self.stagger_finished = time + 3;
			}
			sound (trace_ent, CHAN_BODY, "shield1.wav", 1, ATTN_NORM);
		}

		if (!parry)
		{
			if (jumpattack) // add jump attack damage
				damage += (self.fall_maxspeed * 0.05);

			// armor calculations
			if (trace_ent.armorvalue > damage)
				damage = 1;
			else
				damage = damage - trace_ent.armorvalue;

			// blood effects
			float i;
			vector eye_level = [9, 0];
			eye_level_z = self.view_ofs_z; // match up blood spray to attackers view by z

			for (i=0; i < 2; i++)
				te_blood(trace_ent.origin + eye_level, trace_ent.velocity, 12); // spawn blood

			damage = ceil(damage); // round up final damage output
			DoDamage(trace_ent, self, damage);
			DoCamera_Shake(trace_ent, 16);
			sound (trace_ent, CHAN_AUTO, "swordhit.wav", 1, ATTN_NORM);
		}
	}
	self.melee_finished = time + self.attack_speed;
	self.lockview_finished = time + self.attack_speed;
};

void(entity targ) Player_CheckLevelUp;
void(entity targ, entity attacker) DoDeath = 
{
	if (attacker.classname == "player")
	{
		if (targ.flags & FL_MONSTER)
		{
			GiveExperience(attacker, targ.exp_min, targ.exp);
			GiveGold(attacker, targ.gold_min, targ.gold);
		}
		if (targ.classname == "player") // PVP kill
		{
			attacker.reaper_marks += targ.level;
			if (targ.gold > 1)
				GiveGold(attacker, ceil(targ.gold / 4), ceil(targ.gold / 4));
		}
	}

	if (targ.th_die)
	{
		if (targ.noise3) // death sound
			sound (targ, CHAN_VOICE, targ.noise3, 1, ATTN_NORM);

		targ.think = targ.th_die;
		targ.nextthink = time;
	}
	else
		print(self.classname, "'s th_die routine is missing\n");
};

// Main damage function
void(entity targ, entity attacker, float damage) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1 || targ.deadflag == DEAD_DEAD)
		return;
	if (targ.flags & FL_MONSTER && targ.ai_mode == AI_RUNBACK)
		return;
	if (targ.flags & FL_MONSTER && attacker.flags & FL_MONSTER) // prevent monster in-fighting
		return;

	if (damage <= 0)
		damage = 1;

	if (damage > 0)
	{
		targ.health = targ.health - damage;
		string eventlog_print;

		if (attacker.classname == "player")
		{
			eventlog_print = (strcat("You hit for ^2", ftos(damage), " ^7damage\n"));
			stuffcmd (attacker, sprintf("conecho event %s\n", eventlog_print));
		}
		if (targ.classname == "player")
		{
			eventlog_print = (strcat("You've taken ^1", ftos(damage), " ^7damage\n"));
			stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
		}

		// PVP
		if (targ.classname == "player" && attacker.classname == "player")
		{
			if (targ.incombat_finished < time)
			{
				eventlog_print = (strcat("^1You engage in combat!\n"));
				stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
				stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
				targ.incombat_finished = attacker.incombat_finished = time + 30;
			}
		}
	}

	// Monster stuff
	if (targ.flags & FL_MONSTER)
	{
		if (targ.noise2) // pain sound
			sound (trace_ent, CHAN_VOICE, targ.noise2, 1, ATTN_NORM);

		// TODO: Aggo stuff?
		targ.goalentity = targ.enemy = attacker; // go after last attacker
	}

	if (targ.health <= 0)
	{
		targ.deadflag = TRUE;
		DoDeath(targ, attacker);
	}
};

void(entity attacker, float radius, float damage, float setfire, float diminish) DoRadiusDamage =
{
	for (entity targ = world;(targ = findfloat(targ, radius_candamage, TRUE));)
	{
		if (vlen(targ.origin - self.origin) <= radius)
		{
			float dmg = damage;
			if (diminish)
			{
				float distance_length = vlen(targ.origin - self.origin);
				float distance_factor = 1 - (distance_length / radius);
				dmg = ceil(damage * distance_factor);
			}
			DoDamage(targ, attacker, dmg);
		}
	}
};