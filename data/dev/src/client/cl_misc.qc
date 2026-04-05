//
// Misc stuff, entity effects/drawing and so forth
//

.float cnt;

// check if player is looking at target | direction from viewer → target
float(entity viewer, entity target) is_facing =
{
    vector dir = target.origin - viewer.origin;
    dir_z = 0; // ignore vertical difference
    dir = normalize(dir);

    makevectors([0, viewer.angles_y, 0]); // yaw only

    float dot = dir * v_forward;

    if (dot > 0.925) // strict small cone
        return TRUE;

    return FALSE;
};

//
// Water Fountain
//

float(void) Fountain_PreDraw =
{
	if (self.last_update_time < time)
	{
		if (timeofday != TIME_NIGHT)
		{
			pointparticles(PART_FOUNTAIN, self.origin);
			if (self.cnt < time)
			{
				sound(self, CHAN_VOICE, "ambience/fountain.wav", 1, ATTN_IDLE);
				self.cnt = time + 9.8;
			}
		}
		else // shut off at night
		{
			if (self.cnt > time)
			{
				sound(self, CHAN_VOICE, __NULL__, 1, ATTN_IDLE);
				self.cnt = time;
			}
		}
		self.last_update_time = time + 0.1;
	}

    addentity(self);
    return PREDRAW_NEXT;
};

//
// Wall Torch 1
//

float(void) WallTorch1_PreDraw =
{
	if (self.last_update_time < time)
	{
		makevectors(self.angles);
		pointparticles(PART_WTORCH1, self.origin + v_forward * 18 + v_up * 22);
		self.last_update_time = time + 0.1;
	}

    addentity(self);
    return PREDRAW_NEXT;
};

//
// Wall Torch 2
//

float(void) WallTorch2_PreDraw =
{
	if (self.last_update_time < time)
	{
		makevectors(self.angles);
		pointparticles(PART_WTORCH1, self.origin + v_forward * 2 + v_up * 38);
		self.last_update_time = time + 0.1;
	}

    addentity(self);
    return PREDRAW_NEXT;
};

//
// Bonfire
//

float(void) Bonfire_PreDraw =
{
    if (self.last_update_time < time)
    {
        pointparticles(PART_BONFIRE, self.origin);
        self.last_update_time = time + 0.2;
    }

    self.pflags = PFLAGS_CORONA;
	self.light_lev = 450;
	self.color = [1, .25, 0];
	self.style = 6;
	self.view_ofs = [0, 0, 46];

    // Only for local player
    for (entity e = world; (e = find(e, classname,"player")); )
	{
		float dist = vlen(e.origin - self.origin);
		if (dist <= (USEDISTANCE * 1.13) && e.entnum == player_localentnum && visible_ofs(e) && is_facing(e, self))
			Draw_BonfireUse = TRUE;
	}

    addentity(self);
    return PREDRAW_NEXT;
};

//
// Dynamic Light
//

float(void) Dlight_PreDraw =
{
    addentity(self);
    return PREDRAW_NEXT;
};

//
// NPCs
//

float(void) NPC_PreDraw =
{
	for (entity b = world; (b = find(b, classname, "player"));) 
	{
		float dist = vlen(b.origin - self.origin);
		if (dist <= 125 && visible_ofs(b))
		{
			self.goalentity = b;
			TurnToTarget(0.75);
		}
		else
		{
			self.goalentity = world;
			TurnToTarget(0.35);
		}
	}

    // Only for local player
    for (entity e = world; (e = find(e, classname,"player")); )
	{
		float dist = vlen(e.origin - self.origin);
		if (dist <= (USEDISTANCE * 1.13) && e.entnum == player_localentnum && visible_ofs(e) && is_facing(e, self))
			Draw_NPCUse = TRUE;
	}

	// Wizard particles
	if (self.part_vfx == 1)
	{
		if (self.last_update_time < time)
		{
			pointparticles(PART_WIZARD_F, self.origin);
			self.last_update_time = time + 0.1;
		}
	}

	// animate
	float speed = 1;
	speed *= frametime;

    if (autocvar_minimap == "full" && substring(world.model, -3, 3) == "hmp")
        speed /= 2; // fix minimap on animation speed

    self.frame1time += speed;

    addentity(self);
    return PREDRAW_NEXT;
};