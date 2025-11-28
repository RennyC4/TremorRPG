//
// Misc stuff, entity effects/drawing and so forth
//

.float cnt;

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
// Dlight - Dynamic Light
//

float(void) Dlight_PreDraw =
{
    float lev = self.light_lev;
    float want_noshadow = 0;

    if (autocvar_tremor_lighting == "simple")
    {
        want_noshadow = 1;
        lev /= 1.5;
    }
    else if (self.spawnflags & 1)
    {
        want_noshadow = 1;
        lev /= 1.5;
    }

    if (want_noshadow)
        self.pflags |= PFLAGS_NOSHADOW;
    else
        self.pflags &= ~PFLAGS_NOSHADOW;

    if (self.spawnflags & 2)
        self.pflags |= PFLAGS_CORONA;
    else
        self.pflags &= ~PFLAGS_CORONA;

    if (lev < 5) lev = 5; // stop dlight culling flicker

    dynamiclight_add(self.origin, lev, [self.color_x, self.color_y, self.color_z], self.style, "", self.pflags);

    // Only use addentity if this has a visible model
    // addentity(self);

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

    self.pflags |= PFLAGS_CORONA;
    dynamiclight_add(self.origin, 300, [1, .5, 0], 1, "", self.pflags);

    // Only for local player
    for (entity e = world; (e = find(e, classname,"player")); )
	{
		float dist = vlen(e.origin - self.origin);
		if (dist <= 125)
			Draw_BonFireUse = TRUE;
	}

    addentity(self);
    return PREDRAW_NEXT;
};