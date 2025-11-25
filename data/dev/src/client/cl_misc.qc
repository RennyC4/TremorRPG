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

    // Handle no-shadow flag
    if (autocvar_tremor_lighting == "simple")
    {
        self.pflags |= PFLAGS_NOSHADOW;
        lev /= 1.5;
    }
    else
    {
        // Only keep NOSHADOW if spawnflag 1 explicitly requests it
        if (self.spawnflags & 1)
        {
            self.pflags |= PFLAGS_NOSHADOW;
            lev /= 1.5;
        }
        else
            self.pflags &= ~PFLAGS_NOSHADOW; // wipe it
    }

    // Corona flag
    if (self.spawnflags & 2)
        self.pflags |= PFLAGS_CORONA;
    else
        self.pflags &= ~PFLAGS_CORONA;

    dynamiclight_add(self.origin, lev, [self.color_x, self.color_y, self.color_z], self.style, "", self.pflags);

    addentity(self);
    return PREDRAW_NEXT;
};
