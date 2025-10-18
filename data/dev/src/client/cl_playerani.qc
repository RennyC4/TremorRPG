// -----------------
// Player animations
// -----------------

.float ani_death;
.float anim_state;       // 0=idle, 1=run, 2=attack, 3=climb, 4=death, etc.
.float attack_triggered; // ensures one attack event per animation

// constants for clarity
#define ANIM_IDLE   0
#define ANIM_RUN    1
#define ANIM_ATTACK 2
#define ANIM_CLIMB  3
#define ANIM_DEATH  4
#define ANIM_JUMP	5

void() Player_Animate =
{
    float speed = 1;
    float duration = frameduration(self.modelindex, self.frame);

    // -----------------------------
    // Death Animation
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
    
	// -----------------------------
    // Jump Animation
    // -----------------------------
	if (!(self.flags & FL_ONGROUND))
	{
		if (self.anim_state != ANIM_JUMP && (self.velocity_z >= 200 || self.velocity_z <= -200))
		{
			self.frame = frameforname(self.modelindex, "Jump");
			if (self.velocity_z <= -200)
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
            sendevent("User_DoAttack_Melee", "");
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