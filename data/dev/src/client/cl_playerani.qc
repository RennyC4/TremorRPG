// -----------------
// Player animations
// -----------------

.float ani_death;
.float attack_triggered; // ensures one attack event per animation
.float air_walk_timer; // counts down after leaving the ground
.float ground_grace_timer;

//
// Special animations sent from SSQC
//

void(float newframe, float animstate, float animenum) SetOtherPlayerAnim =
{
	if (self.frame != newframe)
	{
		self.frame1time = 0;
		self.frame = newframe;
		self.anim_state = animenum;
	}

	self.anistate = animstate;
};

void() OtherPlayer_Anistate =
{
	float speed = 1;
	float f;

	// -------------------
	// Animation selection
	// -------------------

	if (self.anistate == ANISTATE_SLASH)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Slash"), ANISTATE_SLASH, ANIM_SLASH);

	else if (self.anistate == ANISTATE_STAB)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Stab"), ANISTATE_STAB, ANIM_SLASH);

	else if (self.anistate == ANISTATE_PUNCH)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Punch"), ANISTATE_PUNCH, ANIM_PUNCH);

	else if (self.anistate == ANISTATE_SMASH)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Smash"), ANISTATE_SMASH, ANIM_SMASH);

	else if (self.anistate == ANISTATE_ARCHERY)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Archery"), ANISTATE_ARCHERY, ANIM_ARCHERY);

	else if (self.anistate == ANISTATE_SIT)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Sit"), ANISTATE_SIT, ANIM_SIT);

	else if (self.anistate == ANISTATE_CASTING)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Casting"), ANISTATE_CASTING, ANIM_CASTING);

	else if (self.anistate == ANISTATE_CASTAOE)
		SetOtherPlayerAnim(frameforname(self.modelindex, "CastArea"), ANISTATE_CASTAOE, ANIM_CASTAOE);

	else if (self.anistate == ANISTATE_CASTTARGET)
		SetOtherPlayerAnim(frameforname(self.modelindex, "CastTarget"), ANISTATE_CASTTARGET, ANIM_CASTTARGET);

	else if (self.anistate == ANISTATE_CASTSELF)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "CastSelf"), ANISTATE_CASTSELF, ANIM_CASTSELF);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_STUNNED)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Stunned"), ANISTATE_STUNNED, ANIM_STUNNED);

	else if (self.anistate == ANISTATE_IMPACT)
		SetOtherPlayerAnim(frameforname(self.modelindex, "Impact"), ANISTATE_IMPACT, ANIM_IMPACT);

	else if (self.anistate == ANISTATE_DRINK)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "Drink"), ANISTATE_DRINK, ANIM_DRINK);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_AIRMELEE)
		SetOtherPlayerAnim(frameforname(self.modelindex, "AirMelee"), ANISTATE_AIRMELEE, ANIM_AIRMELEE);

	else if (self.anistate == ANISTATE_DODGE)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "Dodge"), ANISTATE_DODGE, ANIM_DODGE);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_STEPDODGE)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "StepDodge"), ANISTATE_STEPDODGE, ANIM_STEPDODGE);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_STEPCOUNTER)
		SetOtherPlayerAnim(frameforname(self.modelindex, "StepCounter"), ANISTATE_STEPCOUNTER, ANIM_STEPCOUNTER);

	else if (self.anistate == ANISTATE_BASH)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "Bash"), ANISTATE_BASH, ANIM_BASH);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_PARRY)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "Parry"), ANISTATE_PARRY, ANIM_PARRY);

		makevectors(self.angles);
		pointparticles(PART_PARRY,
			self.origin + v_forward * 32 + v_up * self.view_ofs_z);

		speed = 1.25;
	}

	else if (self.anistate == ANISTATE_JUMP)
	{
		SetOtherPlayerAnim(frameforname(self.modelindex, "Jump"), ANISTATE_JUMP, ANIM_JUMP);
		speed = 1.5;
	}

	else if (self.anistate == ANISTATE_FISHCAST)
		SetOtherPlayerAnim(frameforname(self.modelindex, "FishingCast"), ANISTATE_FISHCAST, ANIM_FISHCAST);

	else if (self.anistate == ANISTATE_FISHIDLE)
		SetOtherPlayerAnim(frameforname(self.modelindex, "FishingIdle"), ANISTATE_FISHIDLE, ANIM_FISHIDLE);

	// ------------
	// Frame timing
	// ------------

	speed *= frametime;

	if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
		speed /= 2;

	self.frame1time += speed;
	self.frame2time = self.frame1time;
};

//
// These 'animations' are done through rotations of the skeleton itself
//

void() Skeleton_Animate =
{
	//vector ang = getproperty(VF_ANGLES);
    skel_build(self.skeletonindex, self, self.modelindex, 0, 0, 0, 1);

    float yaw = 0;

    if (self.dodgedir > 0) // dodge rotation
    {
        if (self.dodgedir == 1) yaw = -90;   // left
        else if (self.dodgedir == 2) yaw = 90;   // right
        else if (self.dodgedir == 3) yaw = -180; // back
        else if (self.dodgedir == 4) yaw = -135; // back-left
        else if (self.dodgedir == 5) yaw = -45;  // front-left
        else if (self.dodgedir == 6) yaw = 135;  // back-right
        else if (self.dodgedir == 7) yaw = 45;   // front-right
    }
	else // no dodge
		yaw = 0;

	makevectors([0, yaw, 0]);
	skel_premul_bone(self.skeletonindex, skel_find_bone(self.skeletonindex, "mixamorig:Hips"), '0 0 0', v_forward, v_right, v_up);
};

//
// Local animations with some shared
//

void() Player_Animate =
{
	float player_loggedin = getstatf(STAT_LOGGEDIN);
	if (!player_loggedin)
		return;

    float speed = 1;
    float duration = frameduration(self.modelindex, self.frame);

    // -----------------------------
    // Death Animation - This always comes first
    // -----------------------------
    if (self.health <= 0)
    {
        if (self.anim_state != ANIM_DEATH)
        {
            self.frame = frameforname(self.modelindex, "Death");
            self.frame1time = 0;
            self.anim_state = ANIM_DEATH;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }

        // Hold final frame at end
        if (self.frame1time >= duration - 0.1)
            self.frame1time = duration - 0.1;
        else
            self.frame1time += frametime;

        return; // skip rest when dead
    }
	else if (self.anim_state == ANIM_DEATH)
	{
		self.anim_state = ANIM_IDLE;
		self.frame1time = 0;
		self.anim_attacking = FALSE; // turn off attack animation flag
		self.frame = frameforname(self.modelindex, "Idle");
	}

	// -----------------------------
	// Air Melee Animation
	// -----------------------------
	if (self.anistate == ANISTATE_AIRMELEE)
	{
		self.anim_attacking = FALSE; // prevent extra on-ground swing animation

		if (self.frame != frameforname(self.modelindex, "AirMelee"))
		{
			self.attack_triggered = FALSE;
			self.next_attack_time = 0.15;
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "AirMelee");
			self.anim_state = ANIM_AIRMELEE;
		}

		speed = 1;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		float frame_interval = 10 / 60; // 0.16s (60fps)

		if (self.frame1time >= self.next_attack_time)
		{
			if (!(self.flags & FL_ONGROUND))
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]);

				//print(sprintf("Air melee triggered at %.2f sec\n", self.frame1time));
				self.next_attack_time += frame_interval; // schedule next attack
			}
		}

		// Hold final frame at end
		if (self.frame1time >= duration - 0.1)
			self.frame1time = duration - 0.1;
		else
			self.frame1time += speed;

		return;
	}

	// -----------------------------
	// Step Counter Attack Animation
	// -----------------------------
	if (self.anistate == ANISTATE_STEPCOUNTER)
	{
		self.anim_attacking = FALSE; // turn off attack animation flag
		if (self.frame != frameforname(self.modelindex, "StepCounter"))
		{
			self.attack_triggered = FALSE;
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "StepCounter");
			self.anim_state = ANIM_STEPCOUNTER;
		}

		speed = 1;
		speed *= frametime;
		
		if (!self.attack_triggered)
		{
			if (self.frame1time >= duration * 0.4)
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]);
				self.attack_triggered = TRUE;
			}

		}

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		// Hold final frame at end
		if (self.frame1time >= duration - 0.1)
			self.frame1time = duration - 0.1;
		else
			self.frame1time += speed;

		return;
	}

	// -----------------------------
    // Archery Animation
    // -----------------------------
	if (self.anistate == ANISTATE_ARCHERY)
	{
		if (self.flags & FL_ONGROUND)
		{
			if (self.frame != frameforname(self.modelindex, "Archery"))
			{
				self.attack_triggered = FALSE;
				self.frame1time = 0;
				self.frame = frameforname(self.modelindex, "Archery");
				self.anim_state = ANIM_ARCHERY;
			}
			speed = 1;

			// Trigger actual attack once per animation
			if (!self.attack_triggered)
			{
				if (self.frame1time >= duration * 0.5)
				{
					if (lock_on_active)
						sendevent("DoAttack_Arrow", "v", lockon_angles);
					else
						sendevent("DoAttack_Arrow", "v", [0,0,0]); // send nothing when lock-on is off
					self.attack_triggered = TRUE;
				}
			}			
				
			speed *= frametime;
			if (self.frame1time >= duration - 0.1) // Hold final frame at end
				self.frame1time = duration - 0.1;
			else
				self.frame1time += speed;
			return;
		}
		else
			self.anistate = ANISTATE_NONE;
	}

	// -----------------------------
    // Dodge Animation
    // -----------------------------
	if (self.anistate == ANISTATE_DODGE)
	{
		if (self.frame != frameforname(self.modelindex, "Dodge"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Dodge");
			self.anim_state = ANIM_DODGE;
			self.anim_attacking = FALSE; // turn off attack animation flag
			sound (self, CHAN_AUTO, "jump.wav", 1, ATTN_NORM);
		}

		speed = 1.5;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		if (self.frame1time >= duration - 0.1)
			self.frame1time = duration - 0.1;
		else
			self.frame1time += speed;
		return;
	}
	
	// -----------------------------
    // Step Dodge Animation
    // -----------------------------
	if (self.anistate == ANISTATE_STEPDODGE)
	{
		if (self.frame != frameforname(self.modelindex, "StepDodge"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "StepDodge");
			self.anim_state = ANIM_STEPDODGE;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed = 1.5;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		if (self.frame1time >= duration - 0.1)
			self.frame1time = duration - 0.1;
		else
			self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Fishing Idle Animation
    // -----------------------------
	if (self.anistate == ANISTATE_FISHIDLE)
	{
		if (self.frame != frameforname(self.modelindex, "FishingIdle"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "FishingIdle");
			self.anim_state = ANIM_FISHIDLE;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed = 1;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		if (self.frame1time >= duration - 0.1)
			self.frame1time = 0; // loop
		else
			self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Drink Animation
    // -----------------------------
	if (self.anistate == ANISTATE_DRINK)
	{
		if (self.frame != frameforname(self.modelindex, "Drink"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Drink");
			self.anim_state = ANIM_DRINK;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed = 1.5;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Parry Animation
    // -----------------------------
	if (self.anistate == ANISTATE_PARRY)
	{
		if (self.frame != frameforname(self.modelindex, "Parry"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Parry");
			self.anim_state = ANIM_PARRY;
			self.anim_attacking = FALSE; // turn off attack animation flag

			makevectors(self.angles);
			pointparticles(PART_PARRY, self.origin + v_forward * 32 + v_up * self.view_ofs_z);
		}
		speed = 1.25;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}
	
	// -----------------------------
    // Block Animation
    // -----------------------------
	if (self.anistate == ANISTATE_BLOCK)
	{
		if (self.frame != frameforname(self.modelindex, "Block"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Block");
			self.anim_state = ANIM_BLOCK;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed = 1;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

	// -----------------------------
    // (Shield) Bash Animation
    // -----------------------------
	if (self.anistate == ANISTATE_BASH)
	{
		if (self.frame != frameforname(self.modelindex, "Bash"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Bash");
			self.anim_state = ANIM_BASH;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed = 1.5;
		speed *= frametime;
		
		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Stunned / Dizzy Animation
    // -----------------------------
	if (self.anistate == ANISTATE_STUNNED)
	{
		if (self.frame != frameforname(self.modelindex, "Stunned"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Stunned");
			self.anim_state = ANIM_STUNNED;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	// -----------------------------
    // Impact
    // -----------------------------
	if (self.anistate == ANISTATE_IMPACT)
	{
		if (self.frame != frameforname(self.modelindex, "Impact"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Impact");
			self.anim_state = ANIM_IMPACT;
			self.anim_attacking = FALSE; // turn off attack animation flag
		}
		speed *= frametime;

        if (self.frame1time >= duration - 0.1) // Switch frame at the end
            self.frame1time = duration - 0.1;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	// -----------------------------
    // Bonfire Sit Animation
    // -----------------------------
	if (self.bonfire)
	{
        if (self.anim_state != ANIM_SIT)
        {
            self.frame = frameforname(self.modelindex, "Sit");
            self.frame1time = 0;
            self.anim_state = ANIM_SIT;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	// -----------------------------
    // Spell Charging Animation
    // -----------------------------
	if (self.anistate == ANISTATE_CASTING)
	{
        if (self.anim_state != ANIM_CASTING)
        {
            self.frame = frameforname(self.modelindex, "Casting");
            self.frame1time = 0;
            self.anim_state = ANIM_CASTING;
			self.anim_attacking = FALSE; // turn off attack animation flag 
        }
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	// -----------------------------
    // Spell Cast - Area of Effect
    // -----------------------------
	if (self.anistate == ANISTATE_CASTAOE)
	{
        if (self.anim_state != ANIM_CASTAOE)
        {
            self.frame = frameforname(self.modelindex, "CastArea");
            self.frame1time = 0;
            self.anim_state = ANIM_CASTAOE;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Spell Cast - Target
    // -----------------------------
	if (self.anistate == ANISTATE_CASTTARGET)
	{
        if (self.anim_state != ANIM_CASTTARGET)
        {
            self.frame = frameforname(self.modelindex, "CastTarget");
            self.frame1time = 0;
            self.anim_state = ANIM_CASTTARGET;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}
	
	// -----------------------------
    // Spell Cast - Self
    // -----------------------------
	if (self.anistate == ANISTATE_CASTSELF)
	{
        if (self.anim_state != ANIM_CASTSELF)
        {
            self.frame = frameforname(self.modelindex, "CastSelf");
            self.frame1time = 0;
            self.anim_state = ANIM_CASTSELF;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }
		speed = 1.5;
		speed *= frametime;

		if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
			speed /= 2; // fix minimap on animation speed

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

    // -----------------------------
    // Jump / Air-Walk Grace Animation
    // -----------------------------

	float levitating = (self.levitate_finished > time);

	if (self.flags & FL_ONGROUND)
		self.ground_grace_timer = 0.1; // 100ms forgiveness
	else
		self.ground_grace_timer -= frametime;

	int inAir = (self.ground_grace_timer <= 0) && !self.climbing && !levitating;
    if (inAir)
    {
        // Start or continue air-walk grace period
        if (self.air_walk_timer <= 0)
            self.air_walk_timer = 1; // 1 second grace

        self.air_walk_timer -= frametime;

        // Trigger jump animation
        if (self.velocity_z >= 200 || self.air_walk_timer <= 0 || self.anistate == ANISTATE_JUMP)
        {
            if (self.anim_state != ANIM_JUMP)
            {
                self.frame = frameforname(self.modelindex, "Jump");
                self.frame1time = 0;
                self.anim_state = ANIM_JUMP;
                self.anim_attacking = FALSE;
				sound (self, CHAN_AUTO, "jump.wav", 1, ATTN_NORM);
            }
        }

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
		else
			speed = 1.5; // jump animation speed is faster
    }
    else
        self.air_walk_timer = 0; // reset when grounded

    // -----------------------------
    // Reset death flag when alive again
    // -----------------------------
    if (self.anim_state == ANIM_DEATH)
        self.anim_state = ANIM_IDLE;

    // -----------------------------
    // Attack Animation
    // -----------------------------
    if (self.anim_attacking || self.anistate == ANISTATE_PUNCH || self.anistate == ANISTATE_SLASH || self.anistate == ANISTATE_STAB || self.anistate == ANISTATE_SMASH)
    {
		if (self.anim_state != ANIM_SLASH && self.anim_state != ANIM_STAB && self.anim_state != ANIM_PUNCH && self.anim_state != ANIM_SMASH && self.anim_state != ANIM_FISHCAST) // && self.anim_state != ANIM_ARCHERY)
		{
			if (!self.attack_type)
			{
				if (self.main_hand == "Fishing Rod")
				{
					self.frame = frameforname(self.modelindex, "FishingCast");
					self.anim_state = ANIM_FISHCAST;
				}
				else
				{
					self.frame = frameforname(self.modelindex, "Punch");
					self.anim_state = ANIM_PUNCH;
				}
			}
			else if (self.attack_type == 1)
			{
				self.frame = frameforname(self.modelindex, "Slash");
				self.anim_state = ANIM_SLASH;
			}
			else if (self.attack_type == 2)
			{
				self.frame = frameforname(self.modelindex, "Stab");
				self.anim_state = ANIM_STAB;
			}
			else if (self.attack_type == 3)
			{
				self.frame = frameforname(self.modelindex, "Smash");
				self.anim_state = ANIM_SMASH;
			}
			self.frame1time = 0;
			self.attack_triggered = FALSE;
		}

		// Adjust speed by attack stat
		float attackspeed = getstatf(STAT_ATTACKSPEED);
		if (attackspeed != 0 && self.anim_state != ANIM_ARCHERY)
		{
			if (!self.attack_type) // punch speed
				speed /= attackspeed * 0.5;
			else
				speed /= attackspeed * 0.75;
		}

        // Trigger actual attack once per animation
		if (!self.attack_triggered)
		{
			if (!self.attack_type && self.frame1time >= duration * 0.5) // Punch
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]); // send nothing when lock-on is off
				self.attack_triggered = TRUE;
			}
			else if (self.attack_type == 1 && self.frame1time >= duration * 0.25) // Slash
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]); // send nothing when lock-on is off
				self.attack_triggered = TRUE;
			}
			else if (self.attack_type == 2 && self.frame1time >= duration * 0.05) // Stab
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]); // send nothing when lock-on is off
				self.attack_triggered = TRUE;
			}
			else if (self.frame1time >= duration * 0.4) // Bash
			{
				if (lock_on_active)
					sendevent("DoAttack_Melee", "v", lockon_angles);
				else
					sendevent("DoAttack_Melee", "v", [0,0,0]); // send nothing when lock-on is off
				self.attack_triggered = TRUE;
			}
		}

        // End attack
        if (self.frame1time >= duration - 0.1)
        {
			if (self.anim_state != ANIM_FISHCAST) // not fishing, normal behavior
			{
				self.frame1time = 0;
				self.frame = frameforname(self.modelindex, "Idle");
				self.anim_attacking = FALSE;
				self.attack_triggered = FALSE;
				self.anim_state = ANIM_IDLE;
			}
			else
			{
				if (self.anistate == ANISTATE_FISHCAST)
					self.frame1time = duration - 0.1; // hold final frame
				else
				{
					self.frame1time = 0;
					self.frame = frameforname(self.modelindex, "Idle");
					self.anim_attacking = FALSE;
					self.attack_triggered = FALSE;
					self.anim_state = ANIM_IDLE;
				}
			}
        }
    }

    // -----------------------------
    // Climb Animation
    // -----------------------------
    else if (self.climbing)
    {
        if (self.anim_state != ANIM_CLIMB)
        {
            self.frame1time = 0;
            self.frame = frameforname(self.modelindex, "Climb");
            self.anim_state = ANIM_CLIMB;
			self.anim_attacking = FALSE; // turn off attack animation flag
        }

        float skill_climb = getstatf(STAT_SKILL_CLIMB);
        speed += (skill_climb * 0.005);
    }

	// -----------------------------
	// Idle / Run / Strafe Animations
	// -----------------------------
    else if (!(inAir || self.anim_attacking))
    {
		float move_speed_scale = 1;
        vector vel = self.velocity;
        float velspeed = vlen(vel);

		if (levitating)
			move_speed_scale = 0.5;

		if (levitating)
			velspeed *= 0.75;

        // Idle / Crouch / Block Idle
        if (velspeed < 5)
        {
            if (self.crouch)
            {
                if (self.anim_state != ANIM_CROUCHIDLE)
                    self.frame = frameforname(self.modelindex, "CrouchIdle"), self.anim_state = ANIM_CROUCHIDLE;
            }
            else if (self.blocking && self.off_hand != "Empty")
            {
                if (self.anim_state != ANIM_BLOCKIDLE)
                    self.frame = frameforname(self.modelindex, "BlockIdle"), self.anim_state = ANIM_BLOCKIDLE;
            }
            else
            {
                if (self.anim_state != ANIM_IDLE)
                {
                    self.frame1time = 0;
                    self.frame = frameforname(self.modelindex, "Idle");
                    self.anim_state = ANIM_IDLE;

                    string gender = getstats(STAT_GENDER);
                    if (gender == "Female") speed = 0.5;
                }
            }
        }
        else
        {
            // Moving → Run / Strafe / Backpedal
            vector fwd, right, up;
            makevectors(self.angles);
            fwd = v_forward;
            right = v_right;

            float forwarddot = dotproduct(normalize(vel), fwd);
            float rightdot   = dotproduct(normalize(vel), right);

            if (self.crouch)
            {
                if (self.anim_state != ANIM_CROUCHWALK)
                    self.frame = frameforname(self.modelindex, "CrouchWalk"), self.anim_state = ANIM_CROUCHWALK;
            }
            else if (self.blocking && self.off_hand != "Empty")
            {
                if (self.anim_state != ANIM_BLOCKWALK)
                    self.frame = frameforname(self.modelindex, "BlockWalk"), self.anim_state = ANIM_BLOCKWALK;
            }
            else
            {
                if (rightdot > 0.5)
                {
                    if (self.anim_state != ANIM_STRAFERIGHT)
                        self.frame = frameforname(self.modelindex, "StrafeRight"), self.anim_state = ANIM_STRAFERIGHT;
                }
                else if (rightdot < -0.5)
                {
                    if (self.anim_state != ANIM_STRAFELEFT)
                        self.frame = frameforname(self.modelindex, "StrafeLeft"), self.anim_state = ANIM_STRAFELEFT;
                }
                else if (forwarddot > 0)
                {
                    if (self.anim_state != ANIM_RUN)
                        self.frame = frameforname(self.modelindex, "Run"), self.anim_state = ANIM_RUN;
                }
                else if (forwarddot < 0)
                {
                    if (self.anim_state != ANIM_BACKPEDAL)
                        self.frame = frameforname(self.modelindex, "Backpedal"), self.anim_state = ANIM_BACKPEDAL;
                }
            }
        }
		speed *= move_speed_scale;
    }

    // -----------------------------
    // Speed modifiers
    // -----------------------------
    speed *= frametime;

    if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
        speed /= 2; // fix minimap on animation speed

    // -----------------------------
    // Advance animation time
    // -----------------------------
    self.frame1time += speed;
    self.frame2time = self.frame1time;
};