//
// Lock on targetting
//

entity() FindLockTarget;
float(entity e) IsValidLockTarget;
float(entity from, entity to) HasLOS;

float LOCK_RANGE        = 2000;	// max distance to pick/keep a lock
float LOCK_FOV_COS      = 0.60;	// cos(FOV/2). 0.60 ~ ~104° cone; tighten to ~0.90 for ~50°
float LOCK_SWITCH_COOLD = 0.18;	// seconds between switch presses
float LOCK_BREAK_TIME   = 3;	// (was 0.25) grace time when LOS lost before breaking lock

// impulses
float IMP_LOCK_TOGGLE = 140;
float IMP_LOCK_CYCLE = 141;

.float lock_los_lost_time; // remember last time we saw the target for grace period

// helper function (aim magnet) to bios aim vector towards the locked target
vector() AttackDir =
{
	makevectors(self.angles);
    vector aim = v_forward;

	if (self.classname == "player")
	{
		if (self.lock_on && self.lock_target)
		{
			vector to = normalize((self.lock_target.origin + self.lock_target.view_ofs) - (self.origin + self.view_ofs));
			aim = normalize(aim * 0.7 + to * 0.3); // blend 30% toward target
		}
	}

    return aim;
};

void() LockOn_HandleInput =
{
	if (self.impulse == IMP_LOCK_TOGGLE && time >= self.lock_next) // toggle
    {
        self.lock_next = time + 0.25;

        if (!self.lock_on) // engage lock
        {
            entity t = FindLockTarget();
            if (t)
            {
                self.lock_on = 1;
                self.lock_target = t;
                self.lock_los_lost_time = 0;
            }
        }
        else // disengage lock
        {
            self.lock_on = 0;
            self.lock_target = world;
        }

        self.impulse = 0;
    }
	else if (self.lock_on && self.impulse == IMP_LOCK_CYCLE && time >= self.lock_next) // cycle targets
    {
        self.lock_next = time + LOCK_SWITCH_COOLD;

        entity best = world;
        float bestScore = -99999;

		// find monsters
        entity e = find(world, classname, "monster");
        while (e)
        {
            if (IsValidLockTarget(e) && e != self.lock_target && vlen(e.origin - self.origin) <= LOCK_RANGE && HasLOS(self, e))
            {
                makevectors(self.v_angle);
                vector to = normalize((e.origin + e.view_ofs) - (self.origin + self.view_ofs));
                float front = v_forward * to;

                if (front > 0.1) // must be somewhat in front
                {
                    float score = front * 100 - vlen(e.origin - self.origin);
                    if (score > bestScore)
                    {
                        bestScore = score;
                        best = e;
                    }
                }
            }
            e = find(e, classname, "monster");
        }

		// find pvp players
        e = find(world, classname, "player");
        while (e)
        {
            if (IsValidLockTarget(e) && e != self.lock_target && vlen(e.origin - self.origin) <= LOCK_RANGE && HasLOS(self, e) && e.pvp == 1)
            {
                makevectors(self.v_angle);
                to = normalize((e.origin + e.view_ofs) - (self.origin + self.view_ofs));
                front = v_forward * to;

                if (front > 0.1) // must be somewhat in front
                {
                    score = front * 100 - vlen(e.origin - self.origin);
                    if (score > bestScore)
                    {
                        bestScore = score;
                        best = e;
                    }
                }
            }
            e = find(e, classname, "player");
        }

        if (best)
            self.lock_target = best;

        self.impulse = 0;
    }
};

void() LockOn_Update =
{
    if (!self.lock_on)
		return;

    entity t = self.lock_target;
    if (!IsValidLockTarget(t))
    {
		self.lock_on = 0;
        self.lock_target = world;
        return;
    }

    // range + LOS checks
    float d = vlen(t.origin - self.origin);
    float los = HasLOS(self, t);

    if (!los)
    {
        if (self.lock_los_lost_time == 0)
			self.lock_los_lost_time = time;
        if (time - self.lock_los_lost_time > LOCK_BREAK_TIME)
        {
            self.lock_on = 0;
            self.lock_target = world;
            return;
        }
    }
    else
        self.lock_los_lost_time = 0;

    if (d > LOCK_RANGE * 1.2) // a little hysteresis
    {
		self.lock_on = 0;
        self.lock_target = world;
        return;
    }

	// Send lock on target info to CSQC
	// TODO: Optimize this because it's sending *every* frame
	if (self.classname == "player")
	{
		msg_entity = self;
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, CSQC_LOCKON_INFO);

		if (!t.displayname)
			WriteString(MSG_MULTICAST, t.netname);
		else
			WriteString(MSG_MULTICAST, t.displayname);
		
		WriteShort(MSG_MULTICAST, t.level);
		WriteShort(MSG_MULTICAST, t.health);
		WriteShort(MSG_MULTICAST, t.max_health);

		WriteCoord(MSG_MULTICAST, t.origin_x);
		WriteCoord(MSG_MULTICAST, t.origin_y);
		WriteCoord(MSG_MULTICAST, t.origin_z);

		multicast(self.origin, MULTICAST_ONE);
	}
};

// true if e is valid target
float(entity e) IsValidLockTarget =
{
    if (!e)
		return FALSE;
    if (e.health <= 0)
		return FALSE;
    if (!e.takedamage)
		return FALSE;
    if (e == self)
		return FALSE;
	if (e.ai_mode == AI_RUNBACK) // don't target monsters returning to their spawn origin
		return FALSE;

	if (e.classname == "player") // players targetting each other
	{
		if (self.pvp == 1 && e.pvp == 1)
			return TRUE;
		else
			return FALSE;
	}

    return TRUE;
};

// line of sight check (point trace to target's eye/center)
float(entity from, entity to) HasLOS =
{
	vector a;
	float a_height = from.view_ofs_z;
	if (self.camera_toggle)
		a = from.origin + [0, 0, 20+a_height]; // camera is on
	else
		a = from.origin + from.view_ofs;

    vector b = to.origin + to.view_ofs;
    traceline(a, b, TRUE, from);  // ignore 'from'
    return (trace_ent == to || trace_fraction >= 1);
};

// normalized dot product (forward-facing check)
float(entity from, entity to) ForwardDotTo =
{
    makevectors(from.v_angle); // sets v_forward, v_right, v_up
    vector tovec = normalize((to.origin + to.view_ofs) - (from.origin + from.view_ofs));
    return v_forward * tovec; // dot
};

// pick best target in cone, nearest angle first, then distance
entity() FindLockTarget =
{
    entity e, best = world;
    float bestScore = -99999;

    e = find(world, classname, "monster");
    while (e)
    {
        if (IsValidLockTarget(e))
        {
            float d = vlen(e.origin - self.origin);
            if (d <= LOCK_RANGE)
            {
                float f = ForwardDotTo(self, e);
                if (f >= LOCK_FOV_COS && HasLOS(self, e))
                {
                    // prioritize by how centered (dot) and secondarily distance
                    float score = f*1000 - d*0.1;
                    if (score > bestScore) { bestScore = score; best = e; }
                }
            }
        }
        e = find(e, classname, "monster");
    }

    // include other players if PVP mode is on
    e = find(world, classname, "player");
    while (e)
    {
        if (IsValidLockTarget(e) && e.pvp == 1)
        {
            d = vlen(e.origin - self.origin);
            if (d <= LOCK_RANGE)
            {
                f = ForwardDotTo(self, e);
                if (f >= LOCK_FOV_COS && HasLOS(self, e))
                {
                    score = f*1000 - d*0.1;
                    if (score > bestScore) { bestScore = score; best = e; }
                }
            }
        }
        e = find(e, classname, "player");
    }

    return best;
};
