// -----------------
// Player animations
// -----------------

.float ani_death;
.float anim_state;       // 0=idle, 1=run, 2=attack, 3=climb, 4=death, etc.
.float attack_triggered; // ensures one attack event per animation

// constants for clarity, these are strictly CSQC
#define ANIM_IDLE   	0
#define ANIM_RUN    	1
#define ANIM_ATTACK 	2
#define ANIM_CLIMB  	3
#define ANIM_DEATH  	4
#define ANIM_JUMP		5
#define ANIM_SIT		6
#define ANIM_CASTING	7
#define ANIM_CASTAOE	8
#define ANIM_CASTTARGET	9
#define ANIM_CASTSELF	10
#define ANIM_STUNNED	11

//
// Special animations sent from SSQC
//

void() OtherPlayer_Anistate =
{
	float speed = 1;
	float duration = frameduration(self.modelindex, self.frame);

	if (self.anistate == ANISTATE_ATTACK)
	{
		if (self.frame != frameforname(self.modelindex, "Slash"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Slash");
			self.anim_state = ANIM_ATTACK;
		}
	}

	if (self.anistate == ANISTATE_SIT)
	{
		if (self.frame != frameforname(self.modelindex, "Sit"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Sit");
			self.anim_state = ANIM_SIT;
		}
	}

	if (self.anistate == ANISTATE_CASTING)
	{
		if (self.frame != frameforname(self.modelindex, "Casting"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Casting");
			self.anim_state = ANIM_CASTING;
		}
	}

	if (self.anistate == ANISTATE_CASTAOE)
	{
		if (self.frame != frameforname(self.modelindex, "CastArea"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "CastArea");
			self.anim_state = ANIM_CASTAOE;
		}
	}

	if (self.anistate == ANISTATE_CASTTARGET)
	{
		if (self.frame != frameforname(self.modelindex, "CastTarget"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "CastTarget");
			self.anim_state = ANIM_CASTTARGET;
		}
	}

	if (self.anistate == ANISTATE_CASTSELF)
	{
		if (self.frame != frameforname(self.modelindex, "CastSelf"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "CastSelf");
			self.anim_state = ANIM_CASTSELF;
			speed = 1.5;
		}
	}

	if (self.anistate == ANISTATE_STUNNED)
	{
		if (self.frame != frameforname(self.modelindex, "Stunned"))
		{
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Stunned");
			self.anim_state = ANIM_STUNNED;
		}
	}

    speed *= frametime;

    if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
        speed /= 2; // fix minimap slowdown

    self.frame1time += speed;
    self.frame2time = self.frame1time;
};

//
// Local animations with some shared
//

void() Player_Animate =
{
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
		self.frame = frameforname(self.modelindex, "Idle");
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
		}
		speed *= frametime;

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
        }
		speed *= frametime;

		self.frame1time += speed;
		self.frame2time = self.frame1time;
		return;
	}

	// -----------------------------
    // Spell Charging Animation
    // -----------------------------
	if (self.cast_finished > time - 0.5) // add a 0.5 of leeway
	{
        if (self.anim_state != ANIM_CASTING)
        {
            self.frame = frameforname(self.modelindex, "Casting");
            self.frame1time = 0;
            self.anim_state = ANIM_CASTING;
        }
		speed *= frametime;

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
        }
		speed *= frametime;

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
        }
		speed *= frametime;

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
        }
		speed = 1.5;
		speed *= frametime;

        if (self.frame1time >= duration - 0.1) // Hold final frame at end
            self.frame1time = duration - 0.1;
        else
            self.frame1time += speed;
		return;
	}

	// -----------------------------
    // Jump Animation
    // -----------------------------
	if (!(self.flags & FL_ONGROUND) && !self.climbing)
	{
		if (self.anim_state != ANIM_JUMP && (self.velocity_z >= 200 || self.velocity_z <= -200))
		{
			self.frame = frameforname(self.modelindex, "Jump");
			self.frame1time = 0;
			self.anim_state = ANIM_JUMP;
		}
		speed *= frametime;

		if (self.frame1time >= duration - 0.1) // Hold final frame at end
			self.frame1time = duration - 0.1;
		else
		{
			self.frame1time += speed;
			self.frame2time = self.frame1time;
		}
		return; // skip rest
	}

    // -----------------------------
    // Reset death flag when alive again
    // -----------------------------
    if (self.anim_state == ANIM_DEATH)
        self.anim_state = ANIM_IDLE;

    // -----------------------------
    // Attack Animation
    // -----------------------------
    if (self.anim_attacking)
    {
        if (self.anim_state != ANIM_ATTACK)
        {
            self.frame = frameforname(self.modelindex, "Slash");
            self.frame1time = 0;
            self.attack_triggered = FALSE;
            self.anim_state = ANIM_ATTACK;
        }

        // Adjust speed by attack stat
        float attackspeed = getstatf(STAT_ATTACKSPEED);
        if (attackspeed != 0)
            speed /= attackspeed;

        // Trigger actual attack once per animation
        if (!self.attack_triggered && self.frame1time >= duration * 0.25)
        {
            sendevent("DoAttack_Melee", "");
            self.attack_triggered = TRUE;
        }

        // End attack
        if (self.frame1time >= duration)
        {
			self.frame1time = 0;
			self.frame = frameforname(self.modelindex, "Idle");
            self.anim_attacking = FALSE;
            self.attack_triggered = FALSE;
            self.anim_state = ANIM_IDLE;
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
        }

        float skill_climb = getstatf(STAT_SKILL_CLIMB);
        speed += (skill_climb * 0.005);
    }

    // -----------------------------
    // Idle / Run Animations
    // -----------------------------
    else
    {
        // Standing still → Idle
        if (!self.velocity_x && !self.velocity_y)
        {
            if (self.anim_state != ANIM_IDLE)
            {
                self.frame1time = 0;
                self.frame = frameforname(self.modelindex, "Idle");
                self.anim_state = ANIM_IDLE;
            }

            string gender = getstats(STAT_GENDER);
            if (gender == "Female")
                speed = 0.5;
        }
        else // Moving → Run
        {
            if (self.anim_state != ANIM_RUN)
            {
                self.frame = frameforname(self.modelindex, "Run");
                self.frame1time = 0;
                self.anim_state = ANIM_RUN;
            }
        }
    }

    // -----------------------------
    // Speed modifiers
    // -----------------------------
    speed *= frametime;

    if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
        speed /= 2; // fix minimap slowdown

    // -----------------------------
    // Advance animation time
    // -----------------------------
    self.frame1time += speed;
    self.frame2time = self.frame1time;
};