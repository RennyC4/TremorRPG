//
// Lock on targetting
//

entity() FindLockTarget;
float(entity e) IsValidLockTarget;
float(entity from, entity to) HasLOS;
void(entity target) SmoothFaceEntity;

.entity lock_target;	// current locked entity (monster/player)
.float  lock_on; 	// 0/1 toggle
.float  lock_next;	// debounce for toggles/switches (time)

float LOCK_RANGE        = 2000;	// max distance to pick/keep a lock
float LOCK_FOV_COS      = 0.60;	// cos(FOV/2). 0.60 ~ ~104° cone; tighten to ~0.90 for ~50°
float LOCK_LOS_STEP     = 16;	// los trace hull size step (point trace is fine too)
float LOCK_SWITCH_COOLD = 0.18;	// seconds between switch presses
float LOCK_TURN_SPEED   = 32;	// higher = snappier turn toward target (server smoothing)
float LOCK_BREAK_TIME   = 0.25;	// grace time when LOS lost before breaking lock

// impulses
float IMP_LOCK_TOGGLE = 140;
float IMP_LOCK_NEXT   = 141;
float IMP_LOCK_PREV   = 142;

// remember last time we saw the target for grace period
.float lock_los_lost_time;

void() ShowLockMarker_think =
{
	if (self.scale > 4)
		self.scale -= 0.5;
	else
		self.scale = 4;
	self.nextthink = time;
};

void(entity player, entity target) ShowLockMarker =
{
    if (!target)
		return;
	if (player.reticle)
		return;

	entity x = spawn();
	x.owner = player;
	x.aiment = target;
	x.drawonlytoclient = player;
	x.movetype = MOVETYPE_FOLLOW;
	x.effects = EF_NODEPTHTEST;
	x.classname = "reticle";
	x.scale = 24;
	x.view_ofs_z = target.maxs_z / 2;
	setmodel(x, "progs/targetdot.spr");
	setsize(x, [-0, -0, 0], [0, 0, 0]);
	x.think = ShowLockMarker_think;
	x.nextthink = time;

	player.reticle = x; // link 'em
};

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
    if (self.impulse == IMP_LOCK_TOGGLE && time >= self.lock_next)
    {
        self.lock_next = time + 0.25;
        if (!self.lock_on)
        {
            entity t = FindLockTarget();
            if (t)
            {
				self.lock_on = 1;
                self.lock_target = t;
                self.lock_los_lost_time = 0;
				if (!self.reticle)
					ShowLockMarker(self, t); // show flash on new target
            }
        }
        else
        {
			if (self.reticle)
			{
				remove(self.reticle);
				self.reticle = world;
			}
            self.lock_on = 0;
            self.lock_target = world;
        }
        self.impulse = 0;
    }
    else if (self.lock_on && time >= self.lock_next && (self.impulse == IMP_LOCK_NEXT || self.impulse == IMP_LOCK_PREV))
    {
        self.lock_next = time + LOCK_SWITCH_COOLD;

		// find best neighbor target to the RIGHT or LEFT of current target based on screen-space angle
		entity best = world;
		float bestAngle = -99999;
		float wantSign = (self.impulse == IMP_LOCK_NEXT) ? 1 : -1;

        entity e = find(world, classname, "monster");
        while (e)
        {
            if (IsValidLockTarget(e) && e != self.lock_target && vlen(e.origin - self.origin) <= LOCK_RANGE && HasLOS(self, e))
            {
                // signed angle using right vector
                makevectors(self.v_angle);
                vector to = normalize((e.origin + e.view_ofs) - (self.origin + self.view_ofs));
                float side = v_right * to;	// negative = left, positive = right
                float front = v_forward * to;	// how centered

                if (front > 0.1 && side * wantSign > 0) // only candidates on the intended side and somewhat in front
                {
                    float score = side * 100 + front * 10; // prefer farther to that side but still in front
                    if (score > bestAngle)
					{
						bestAngle = score;
						best = e;
					}
                }
            }
            e = find(e, classname, "monster");
        }

        if (best)
		{
			if (self.reticle) // remove last target
			{
				remove(self.reticle);
				self.reticle = world;
			}
			self.lock_target = best;
			if (!self.reticle)
				ShowLockMarker(self, best); // show reticle on new target
		}
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
		if (self.reticle)
		{
			remove(self.reticle);
			self.reticle = world;
		}
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
			if (self.reticle)
			{
				remove(self.reticle);
				self.reticle = world;
			}
            self.lock_on = 0;
            self.lock_target = world;
            return;
        }
    }
    else
        self.lock_los_lost_time = 0;

    if (d > LOCK_RANGE * 1.2) // a little hysteresis
    {
		if (self.reticle)
		{
			remove(self.reticle);
			self.reticle = world;
		}
		self.lock_on = 0;
        self.lock_target = world;
        return;
    }

    // gently steer the view
    SmoothFaceEntity(t);
};

// true if e is valid target
float(entity e) IsValidLockTarget
{
    if (!e)
		return FALSE;
    if (e.health <= 0)
		return FALSE;
    if (!e.takedamage)
		return FALSE;
    if (e == self)
		return FALSE;
    return TRUE;
};

// line of sight check (point trace to target's eye/center)
float(entity from, entity to) HasLOS =
{
    vector a = from.origin + from.view_ofs;
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

    // include other players
    e = find(world, classname, "player");
    while (e)
    {
        if (IsValidLockTarget(e))
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

// angular helpers
float(float a, float b) AngleDelta =
{
    float d = a - b;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
};

float(float cur, float target, float speed, float dt) ApproachAngle =
{
    float d = AngleDelta(target, cur);
    float step = speed * d * dt; // proportional
    return cur + step;
};

// smoothly steer self.v_angle toward target (server-side assist)
// NOTE: This adjusts server v_angle; CSQC camera can fully override if you use it
void(entity target) SmoothFaceEntity =
{
    if (!target)
		return;

    vector a = self.origin + self.view_ofs;
    vector b = target.origin + target.view_ofs;
    vector dir = normalize(b - a);
    vector ang = vectoangles(dir);

    float dt = frametime; // or sys_frametime depending on your mod
    //self.v_angle_y = ApproachAngle(self.v_angle_y, ang_y, LOCK_TURN_SPEED, dt);
	self.angles_y = ApproachAngle(self.v_angle_y, ang_y, LOCK_TURN_SPEED, dt);

    // clamp pitch a bit (no extreme up/down)
    float desiredPitch = ang_x;
    if (desiredPitch > 50) desiredPitch = 50;
    if (desiredPitch < -50) desiredPitch = -50;
    self.v_angle_x = ApproachAngle(self.v_angle_x, desiredPitch, LOCK_TURN_SPEED, dt);

	self.fixangle = TRUE;
};