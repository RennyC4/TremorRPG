//
// Damage routines
//

void(entity targ, entity attacker, float damage, float silent) DoDamage;
void(entity attacker, vector org, float radius, float damage, float diminish, float silent) DoRadiusDamage;
void(entity player, string itemname, float count) RemoveFromInventory;
void() CSEv_User_UnequipMainhand_;
float(entity player, string itemname) HasItem;

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
	if (self.cast_finished > time)
		return;

	if (self.flags & FL_ONGROUND)
		self.velocity = [0, 0];

	// stamina drain on swing
	if (self.classname == "player")
	{
		float stamcalc = 15 - (self.skill_endurance * 0.015); // calculation, same as regular sword swing
		if (self.stamina < stamcalc)
			return;
		self.stamina -= stamcalc;
	}

	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 48, MOVE_TRIGGERS, self);

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO && trace_ent.godmode_finished < time)
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
				trace_ent.anistate = ANISTATE_IMPACT;
				trace_ent.stagger_finished = time + 1.5;
				trace_ent.lockview_finished = time + 1.5;
			}
			// Knock target out of casting
			trace_ent.cast_finished_spell = "";
			trace_ent.cast_finished = time;
			//
			sound (trace_ent, CHAN_BODY, "shield2.wav", 1, ATTN_NORM);
		}
		else // parry
		{
			float parry = TRUE;
			string eventlog_print = (strcat("^2Successful parry!"));
			stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));
			trace_ent.anistate = ANISTATE_PARRY;
			trace_ent.melee_finished = time + 0.5;

			pointparticles(PART_PARRY, trace_ent.origin + v_forward * 32 + v_up * trace_ent.view_ofs_z);

			// apply effects
			self.anistate = ANISTATE_IMPACT;
			self.stagger_finished = time + 3.5;
			self.lockview_finished = time + 3.5;
			sound (self, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
		}
	}
	sound (self, CHAN_WEAPON, "shield3.wav", 1, ATTN_NORM);
	self.melee_finished = time + 1;
	self.lockview_finished = time + 1;
};

// Main melee attack function
.float staminamessage_finished;
.float inair_swing_sfx;
void(vector ang) CSEv_DoAttack_Melee_v =
{
	if (self.flags & FL_ONGROUND)
		self.velocity = [0, 0];
	
	// calculate damage by weapon
	float damage = ceil(random_range(self.attack_power_min, self.attack_power_max));

	// add skill damage
	float howmuch = 0.1;
	if (!self.attack_type) // unarmed
	{
		damage += (self.skill_unarmed * 0.055);
		self.attack_speed = 3 - (self.skill_unarmed * 0.0145); // unarmed speed is tied to skill
		if (self.attack_speed < 0.1)
			self.attack_speed = 0.1; // cap
	}
	else if (self.attack_type == 1) // slash
		damage += (self.skill_slash * howmuch);
	else if (self.attack_type == 2) // pierce
		damage += (self.skill_pierce * howmuch);
	else if (self.attack_type == 3) // bashing
		damage += (self.skill_bash * howmuch);
	else
		damage += (self.skill_archery * howmuch);

	if (self.flags & FL_CLIENT)
	{
		if (ang) // sent from CSQC when lock-on is active
		{
			makevectors (ang);
			self.angles_x = ang_x;
			self.fixangle = TRUE;
		}
		else
			makevectors (self.v_angle);
	}
	else
		makevectors (self.angles);

	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * self.attack_length, MOVE_TRIGGERS, self);

	if (!self.inair_swing_sfx)
	{
		if (!self.attack_type)
			sound (self, CHAN_WEAPON, "punch1.wav", 1, ATTN_NORM);
		else if (self.attack_type == 1)
			sound (self, CHAN_WEAPON, "sword1.wav", 1, ATTN_NORM);
		else if (self.attack_type == 2)
			sound (self, CHAN_WEAPON, "dagger1.wav", 1, ATTN_NORM);
		else if (self.attack_type == 3)
			sound (self, CHAN_WEAPON, "club1.wav", 1, ATTN_NORM);
	}

	if (!(self.flags & FL_ONGROUND))
		self.inair_swing_sfx = TRUE;

	if (trace_ent.takedamage && trace_ent.health > 0 && trace_ent.deadflag == DEAD_NO && trace_ent.jumpattack_hit_finished < time && trace_ent.godmode_finished < time)
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

		if (!(self.flags & FL_ONGROUND) && self.inair_count >= 15)
			float jumpattack = TRUE;
		else
			jumpattack = FALSE;

		// check & add backstab skill damage
		float bs_damage = 0;
		float backstab = FALSE;
		if (check_backstab(trace_ent) && !jumpattack)
		{
			bs_damage = (self.skill_backstab * howmuch);
			if (self.attack_type == 2) // add piercing bonus damage
				bs_damage += ceil(self.skill_pierce * (howmuch / 1.5));

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
					damage -= trace_ent.blockvalue;
					trace_ent.stamina -= stamcalc_block;

					vector dir = trace_ent.origin - self.origin; // Push back
					dir = normalize(dir);
					trace_ent.velocity = '0 0 0';
					trace_ent.flags &= ~FL_ONGROUND;
					trace_ent.velocity = trace_ent.velocity + dir * 150;
					trace_ent.melee_finished = time + 0.5;
					trace_ent.anistate = ANISTATE_BLOCK;
					pointparticles(PART_BLOCK, trace_ent.origin + v_forward * 32 + v_up * trace_ent.view_ofs_z);
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
						damage = damage - ceil(trace_ent.blockvalue / 2); // save a tiny bit of damage still
						trace_ent.stamina = 0;
						trace_ent.blocking = FALSE;
						trace_ent.lockview_finished = time + 3;
						trace_ent.stagger_finished = time + 3; // stagger, stamina is out
					}
				}
				//
			}
			else // parry
			{
				parry = TRUE;
				sound (trace_ent, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);
				eventlog_print = (strcat("^2Successful parry!"));
				stuffcmd (trace_ent, sprintf("conecho event %s\n", eventlog_print));

				trace_ent.melee_finished = time + 0.75;
				trace_ent.anistate = ANISTATE_PARRY;

				pointparticles(PART_PARRY, trace_ent.origin + v_forward * 32 + v_up * trace_ent.view_ofs_z);

				// apply effects
				self.stagger_finished = time + 3.5;
				self.lockview_finished = time + 3.5;
			}
			sound (trace_ent, CHAN_AUTO, "shield1.wav", 1, ATTN_NORM);
		}

		if (!parry)
		{
			if (jumpattack)
			{
				damage += damage * 1.20; // damage multiplier
				trace_ent.jumpattack_hit_finished = time + 2;
			}

			// adds an additional time on hit if someone is casting
			if (trace_ent.cast_finished > time)
				trace_ent.cast_finished += 0.8;

			// armor calculations
			damage -= trace_ent.armorvalue;

			// blood logic + effects
			vector mid = trace_ent.origin;
			vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
			mid_z += (trace_ent.mins_z + trace_ent.maxs_z) * 0.5;
			te_blood(mid, vel, 12);
			
			damage = ceil(damage); // round up final damage output
			if (self.attack_type == 1) // Slashing uses radius for cleave
				DoRadiusDamage(self, self.origin + v_forward * 48, self.attack_length * 1.40, damage, FALSE, FALSE);
			else
			{
				DoDamage(trace_ent, self, damage, FALSE);
				if (self.attack_type == 3 && random() <= 0.10) // Club bonus (10%)
				{
					vector dir = trace_ent.origin - self.origin; // Pushing
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
					// Knock target out of casting
					trace_ent.cast_finished_spell = "";
					trace_ent.cast_finished = time;
					//
				}
			}

			// Hit sounds
			if (!self.attack_type)
			{
				if (random() < 0.5)
					sound (trace_ent, CHAN_AUTO, "punchhit.wav", 1, ATTN_NORM);
				else
					sound (trace_ent, CHAN_AUTO, "punchhit2.wav", 1, ATTN_NORM);
			}
			else if (self.attack_type == 1)
			{
				if (random() < 0.5)
					sound (trace_ent, CHAN_AUTO, "swordhit.wav", 1, ATTN_NORM);
				else
					sound (trace_ent, CHAN_AUTO, "swordhit2.wav", 1, ATTN_NORM);
			}
			else if (self.attack_type == 2)
			{
				if (random() < 0.5)
					sound (trace_ent, CHAN_AUTO, "daggerhit.wav", 1, ATTN_NORM);
				else
					sound (trace_ent, CHAN_AUTO, "daggerhit2.wav", 1, ATTN_NORM);
			}
			else
			{
				if (random() < 0.5)
					sound (trace_ent, CHAN_AUTO, "clubhit.wav", 1, ATTN_NORM);
				else
					sound (trace_ent, CHAN_AUTO, "clubhit2.wav", 1, ATTN_NORM);
			}
		}
	}
};

void() arrow_think =
{
	self.angles = vectoangles(self.velocity);
	self.nextthink = time + 0.1;
};

void() arrow_touch =
{
	float parry = FALSE;

	if (other != self.owner && other.takedamage && other.health > 0 && other.deadflag == DEAD_NO && other.godmode_finished < time)
	{
		float bow_power = ceil(random_range(self.owner.projectile_power_min, self.owner.projectile_power_max));
		float arrow_power = ceil(random_range(self.owner.attack_power_min, self.owner.attack_power_max));
		float damage = bow_power + arrow_power + (self.owner.skill_archery * 0.1);

		// --- PVP Check ---
		if (self.owner.classname == "player" && other.classname == "player")
		{
			if (self.owner.pvp != 1 || other.pvp != 1)
				return;

			self.owner.incombat = other.incombat = TRUE;
			self.owner.incombat_finished = other.incombat_finished = time + 30;
		}

		// --- Parry Detection ---
		if (other.parry_finished > time)
			parry = TRUE;

		// --- Blocking ---
		if (check_block(self, other) && other.blocking)
		{
			float stamcalc_block = 20 - (other.skill_endurance * 0.015);

			// --- Regular Block ---
			if (other.parry_finished < time)
			{
				if (other.stamina >= stamcalc_block)
				{
					damage -= other.blockvalue;
					other.stamina -= stamcalc_block;

					vector dir = normalize(other.origin - self.origin);
					other.velocity = '0 0 0';
					other.flags &= ~FL_ONGROUND;
					other.velocity = dir * 150;

					other.melee_finished = time + 0.5;
					other.anistate = ANISTATE_BLOCK;
					pointparticles(PART_BLOCK, other.origin + v_forward * 32 + v_up * other.view_ofs_z);
				}
				else
				{
					// --- Stagger on Stamina Depletion ---
					if (other.stagger_finished < time)
					{
						if (other.classname == "player")
						{
							string eventlog_print = "^1You've been staggered!";
							stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));
						}

						damage -= ceil(other.blockvalue / 2); // partial block
						other.stamina = 0;
						other.blocking = FALSE;
						other.lockview_finished = time + 3;
						other.stagger_finished = time + 3;
					}
				}
			}
			else // --- Parry ---
			{
				parry = TRUE;
				sound(other, CHAN_AUTO, "parry.wav", 1, ATTN_NORM);

				string eventlog_print = "^2Successful parry!";
				stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));

				other.melee_finished = time + 0.75;
				other.anistate = ANISTATE_PARRY;
			}

			sound(other, CHAN_AUTO, "shield1.wav", 1, ATTN_NORM);
		}

		// --- Damage Application ---
		if (!parry)
		{
			damage -= ceil(other.armorvalue);

			// If still blocking and block was not handled, apply minor block reduction
			if (check_block(self, other) && other.blocking)
				damage -= ceil(other.blockvalue);

			damage = ceil(max(damage, 1)); // never deal 0 damage

			// Blood effect
			vector mid = other.origin;
			vector vel = [crandom(), crandom(), fabs(crandom())] * 100;
			mid_z += (other.mins_z + other.maxs_z) * 0.5;
			te_blood(mid, vel, 6);

			DoDamage(other, self.owner, damage, FALSE);
			sound(self, CHAN_BODY, "arrow2.wav", 1, ATTN_NORM);
		}

		remove(self);
		return;
	}
	
	// --- Stick to wall ---
	if (other.solid == SOLID_BSP && self.velocity != '0 0 0')
	{
		sound(self, CHAN_BODY, "arrow2.wav", 1, ATTN_NORM);
		self.movetype = MOVETYPE_FLY;
		self.velocity = '0 0 0';
		self.touch = info_null;
		self.think = sub_remove;
		self.nextthink = time + 6;
	}
};

void(vector ang) CSEv_DoAttack_Arrow_v =
{
	entity arrow = spawn();
	arrow.owner = self;
	arrow.movetype = MOVETYPE_TOSS;
	arrow.solid = SOLID_BBOX;
	arrow.hitcontentsmaski = CONTENTBITS_POINTSOLID;

	if (self.flags & FL_CLIENT)
	{
		if (ang)
		{
			makevectors(ang);
			self.angles_x = ang_x;
			self.fixangle = TRUE;
		}
		else
			makevectors(self.v_angle);

		// Add lift for smoother, longer flight arcs
		float lift_scale = 0.25; // tweak 0.1–0.25
		vector forward = v_forward;
		vector up = v_up;

		forward = normalize(forward + up * lift_scale);
		arrow.velocity = forward * 1000;
		arrow.angles = vectoangles(arrow.velocity);
	}
	else // monster
	{
		if (self.enemy)
		{
			vector src = self.origin + '0 0 32';
			vector dst = self.enemy.origin + self.enemy.view_ofs;
			vector toTarget = dst - src;
			float dist = vlen(toTarget);

			vector target_vel = self.enemy.velocity;
			float proj_speed = 1000;
			float t_lead = dist / proj_speed;
			vector predicted = dst + target_vel * t_lead;

			vector dir = normalize(predicted - src);
			dir_z += dist * 0.0004; // gravity compensation
			dir = normalize(dir);

			makevectors(vectoangles(dir));
		}
		else
			makevectors(self.angles);

		vector forward = v_forward;
		arrow.velocity = forward * 1000;
		arrow.angles = vectoangles(arrow.velocity);
	}

	setmodel(arrow, "models/arrow.glb");
	setsize(arrow, '0 0 0', '0 0 0');
	setorigin(arrow, self.origin + v_forward * 8 + '0 0 16');

	arrow.touch = arrow_touch;
	arrow.think = arrow_think;
	arrow.nextthink = time + 0.1;

	sound(self, CHAN_WEAPON, "arrow1.wav", 1, ATTN_NORM);

	// Monsters don't need to check inventory
	if (self.flags & FL_MONSTER)
		return;

	// Remove one arrow from inventory
	RemoveFromInventory(self, self.main_hand, 1);

	// Player: unequip when out of arrows
	if (!HasItem(self, self.main_hand))
		CSEv_User_UnequipMainhand_();
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
void(entity targ, entity attacker, float damage, float silent) DoDamage =
{
	if (!targ)
		return;
	if (targ.health < 1 || targ.deadflag == DEAD_DEAD)
		return;
	if (targ.flags & FL_MONSTER && targ.ai_mode == AI_RUNBACK)
		return;
	if (targ.flags & FL_MONSTER && attacker.flags & FL_MONSTER) // prevent monster in-fighting
		return;
	if (targ.godmode_finished > time)
		return;

	if (damage <= 0)
		damage = 1;

	if (!(targ.flags & FL_GODMODE))
		targ.health = targ.health - damage;

	string eventlog_print;

	if (attacker.classname == "player")
	{
		eventlog_print = (strcat("You hit for ^2", ftos(damage), " ^7damage\n"));
		stuffcmd (attacker, sprintf("conecho event %s\n", eventlog_print));
	}
	if (targ.classname == "player" && !silent)
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

	// Knock player out of drinking a potion
	if (targ.potion_use_finished > time)
	{
		targ.healthpot_heal_rate = 0;
		targ.healthpot_heal_remaining = 0;
		targ.healthpot_finished = time;

		targ.manapot_heal_rate = 0;
		targ.manapot_heal_remaining = 0;
		targ.manapot_finished = time;

		targ.potion_use_finished = time;

		eventlog_print = (strcat("^1You drop your potion!\n"));
		stuffcmd (targ, sprintf("conecho event %s\n", eventlog_print));
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

void(entity attacker, vector org, float radius, float damage, float diminish, float silent) DoRadiusDamage =
{
	for (entity targ = world; (targ = findfloat(targ, radius_candamage, TRUE));)
	{
		if (vlen(targ.origin - org) <= radius && targ != self && targ.godmode_finished < time)
		{
			float dmg = damage;
			if (diminish)
			{
				float distance_length = vlen(targ.origin - org);
				float distance_factor = 1 - (distance_length / radius);
				dmg = ceil(damage * distance_factor);
			}
			if (!silent)
				DoDamage(targ, attacker, dmg, FALSE);
			else
				DoDamage(targ, attacker, dmg, TRUE); // no event log update
		}
	}
};