//
// trigger_zone - used for when the player enters different zones (dungeons, towns, etc)
//

void() trigger_zone_touch =
{
	// =========================================================
	// MONSTER BEHAVIOR - prevent crossing territories
	// =========================================================
	if (other.flags & FL_MONSTER && other.ai_mode != AI_RUNBACK)
	{
		other.enemy = world;
		other.ai_mode = AI_RUNBACK;
		other.anistate = ANISTATE_RUN;

		// clear movement states
		other.avoid_dir = 0;
		other.avoid_time = 0;
		other.velocity = '0 0 0';

		return; // don't process player logic
	}

	// =========================================================
	// PLAYER VALIDATION
	// =========================================================
	if (other.classname != "player")
		return;
	if (!other.loggedin)
		return;

	// =========================================================
	// MAP TYPE CHECK
	// =========================================================
	string mdl = world.model;
	float len = strlen(mdl);
	float is_hmp = (len >= 3 && substring(mdl, len - 3, 3) == "hmp");

	// =========================================================
	// STATE SNAPSHOT
	// =========================================================
	float old_pvp = other.pvp;

	float was_overworld = (old_pvp == 2);
	float is_overworld  = (self.pvp == 2 && is_hmp);

	float pvp_changed = (old_pvp != self.pvp);
	float overworld_changed = (was_overworld != is_overworld);

	// =========================================================
	// APPLY PVP STATE
	// =========================================================
	if (pvp_changed)
	{
		if (!self.pvp) // entering safe zone
		{
			other.pvp = 0;
			other.pvp_autoflagged = FALSE;
			other.incombat = FALSE;
			other.incombat_finished = time;
			other.pvpenable_count = 0;
			other.pvpenable_finished = time;
		}
		else
		{
			other.pvp = self.pvp;
		}
	}

	// =========================================================
	// ZONE NAME DISPLAY
	// =========================================================
	if (other.zonename != self.zonename)
	{
		other.zonename = self.zonename;

		if (other.zonename_finished < time)
			other.zonename_finished = time + 3;
	}

	// =========================================================
	// MUSIC HANDLER
	// =========================================================

	if (other.old_music != other.music)
		other.old_music = other.music; // stash old track

	if (other.music != self.music)	
		other.music = self.music;
};

void() trigger_zone =
{
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = trigger_zone_touch;

	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.model = "";
};

//
// changelevel- move players between maps
//

void() trigger_changelevel_touch =
{
	if (other.classname != "player")
		return;
	if (!other.loggedin)
		return;

	other.spawnloc = self.spawnloc;
	string newmap = strcat(":", self.map);
	clustertransfer(other, newmap);
};

void() trigger_changelevel =
{
	//return; // Remove when map cluster on Linux is fixed

	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	self.touch = trigger_changelevel_touch;

	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.model = "";
};

/*
===============
SUB_UseTargets
===============
- Fires all entities with matching targetname
- Supports killtarget
- Supports delay (spawns a helper thinker)
*/

void(entity ent, entity activator) SUB_FireTargets;

void() SUB_DelayThink =
{
	SUB_FireTargets(self.owner, self.enemy);
	remove(self);
};

void(entity ent, entity act) SUB_UseTargets =
{
	entity t;

	activator = act; // set the global explicitly

	if (ent.killtarget) // killtarget first
	{
		t = find(world, targetname, ent.killtarget);
		while (t)
		{
			remove(t);
			t = find(t, targetname, ent.killtarget);
		}
	}

	if (ent.delay > 0) // delay handling
	{
		t = spawn();
		t.owner = ent;
		t.enemy = act;
		t.think = SUB_DelayThink;
		t.nextthink = time + ent.delay;
		return;
	}

	// fire immediately
	SUB_FireTargets(ent, act);
};

void(entity ent, entity act) SUB_FireTargets =
{
	entity t;

	activator = act; // set global activator

	if (!ent.target)
		return;

	t = find(world, targetname, ent.target);
	while (t)
	{
		if (t.use)
		{
			self = t;     // critical: set correct self
			t.use();      // now runs in proper context
		}
		t = find(t, targetname, ent.target);
	}
};

/*
================
trigger_multiple
================
- Fires target(s) when touched
- Can be set to repeat with wait/delay
- Use spawnflag 1 ("notouch") for only use-activated
*/
void() trigger_multi_use;
void() trigger_multi_reset;

void() trigger_multi_touch =
{
    if (other.classname != "player")
        return;
	if (!other.loggedin)
		return;

    SUB_UseTargets(self, other);

	// prevent spam
	self.touch = info_null;
	self.nextthink = time + self.wait;
	self.think = trigger_multi_reset;
};

void() trigger_multi_reset =
{
	self.touch = trigger_multi_touch;
};

void() trigger_multi_use_reset =
{
	self.use = trigger_multi_use;
};

void() trigger_multi_use =
{
	SUB_UseTargets(self, activator);

	self.use = info_null;
	self.nextthink = time + self.wait;
	self.think = trigger_multi_use_reset;
};

void() trigger_multiple =
{
	self.modelindex = 0;
	self.solid = SOLID_TRIGGER;
	
	if (self.spawnflags & 1) // "notouch" mode
		self.use = trigger_multi_use;
	else
		self.touch = trigger_multi_touch;

	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.model = "";
};

/*
===============
trigger_once
===============
- Fires targets once on touch or use
- Supports wait/delay via SUB_UseTargets
- Spawnflag 1 = use only (not touch)
*/

void() trigger_once_touch =
{
    if (other.classname != "player")
        return;
	if (!other.loggedin)
		return;

    SUB_UseTargets(self, other);
    remove(self);
};

void() trigger_once_use =
{
    SUB_UseTargets(self, activator);
    remove(self);
};

void() trigger_once =
{
	self.solid = SOLID_TRIGGER;
    if (self.spawnflags & 1) // "notouch" mode
        self.use = trigger_once_use;
    else
    {
        setsize(self, self.mins, self.maxs);
        self.touch = trigger_once_touch;
    }
};