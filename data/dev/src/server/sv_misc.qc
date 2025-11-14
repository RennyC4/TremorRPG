/*
setprop - put down buildings on terrain
*/

void() set_prop =
{
    precache_model(self.model);

	self.angles = '0 0 0';
	self.solid = SOLID_BSP;
    setmodel(self, self.model);

	// Obtain other ents inside .bsps
    int i;
    entity newent;
    entity oself = self;
    int numents = (int)terrain_edit(TEREDIT_ENT_COUNT);
    for (i = 1; i < numents; i++)
    {
		string entdata = (string)terrain_edit(TEREDIT_ENT_GET, (__variant)(int)i); // { classname foo origin "x y z" }
		//print(sprintf("ent %i: %S\n", i, entdata));
		if (!entdata)
			continue; //can happen when editing
		self = newent = spawn();
		parseentitydata(newent, strcat("{\n", entdata, "\n}")); //reads it into the entity
		//TODO: fix up inline model names
		if (substring(newent.model, 0, 1) == "*")
			newent.model = sprintf("%s:%s", newent.model, oself.model);
		precache_model(newent.model);
		newent.origin += oself.origin;
		callfunction(self.classname); //gotta make sense of it by calling its spawn function
		self = oself;
    }
};

//
// set_dlight - set a dynamic light
//

string autocvar_tremor_lighting;
void() set_dlight =
{
	if (autocvar_tremor_lighting == "simple")
	{
		self.pflags = PFLAGS_FULLDYNAMIC;
		self.pflags |= PFLAGS_NOSHADOW;
	}
	else
	{
		self.pflags = PFLAGS_FULLDYNAMIC;
		if (self.spawnflags & 1)
		{
			self.pflags |= PFLAGS_NOSHADOW;
			self.light_lev /= 1.5;
		}
	}
	if (self.spawnflags & 2)
		self.pflags |= PFLAGS_CORONA;
};

//
// part_foundain - particle effect for water fountains
//

void() part_fountain_think =
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
	self.nextthink = time + 0.1;
};

void() part_fountain =
{
	precache_sound ("ambience/fountain.wav");
	setmodel(self, string_null);

	self.think = part_fountain_think;
	self.nextthink = time + 0.1 + random()*1;
};

//
// misc_walltorch1 - particle effect for fancy wall torch
//

void() misc_walltorch1_think =
{
	makevectors(self.angles);
	pointparticles(PART_WTORCH1, self.origin + v_forward * 18 + v_up * 22);
	self.nextthink = time + 0.1;
};

void() misc_walltorch1 =
{
	precache_model("models/walltorch1.glb");
	setmodel(self, "models/walltorch1.glb");

	self.think = misc_walltorch1_think;
	self.nextthink = time + 0.1 + random()*1;
};

//
// misc_walltorch2 - wall torch 2, same as above w/ different design
//

void() misc_walltorch2_think =
{
	makevectors(self.angles);
	pointparticles(PART_WTORCH2, self.origin + v_forward * 2 + v_up * 38);
	self.nextthink = time + 0.1;
};

void() misc_walltorch2 =
{
	precache_model("models/walltorch2.glb");
	setmodel(self, "models/walltorch2.glb");

	self.think = misc_walltorch2_think;
	self.nextthink = time + 0.1 + random()*1;
};


//
// misc_barrel - decor object
//

void() misc_barrel =
{
	precache_model("models/barrel.glb");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;

	setmodel(self, "models/barrel.glb");
	setsize(self, [-14, -14, 0], [14, 14, 28]);

	droptofloor();
};

//
// misc_tree1 - regular tree
//

void() misc_tree =
{
	precache_model("models/tree.glb");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;

	setmodel(self, "models/tree.glb");
	setsize(self, [-16, -16, 0], [16, 16, 100]);

	droptofloor();
};

//
// misc_tree2 - dead tree
//

void() misc_tree2 =
{
	precache_model("models/tree2.glb");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;

	setmodel(self, "models/tree2.glb");
	setsize(self, [-12, -12, 0], [12, 12, 100]);

	droptofloor();
};

/*
* misc_model.qc
*
* Author: Joshua Skelton joshua.skelton@gmail.com
*/

.float first_frame; // The starting frame of the animation
.float last_frame; // The ending frame of the animation

void() misc_model_think =
{
    self.nextthink = time + fabs(self.speed);
    self.frame = self.frame + sign(self.speed);
    self.frame = wrap(self.frame, self.first_frame, self.last_frame);
};

/*
* misc_model
*
* An entity for displaying models. A frame range can be given to animate the
* model.
*
* mdl: The model to display. Can be of type mdl, bsp, or spr.
* frame: The frame to display. Can be used to offset the animation.
* first_frame: The starting frame of the animation.
* last_frame: The last frame of the animation.
*/

void() misc_model =
{
    precache_model(self.model);
    setmodel(self, self.model);
	setsize(self, [0,0,0],[0,0,0]);

    if (self.first_frame)
		self.frame = self.first_frame;

	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.worldlight = TRUE;

    // Only animate if given a frame range
    if (!self.last_frame)
        return;

	// Randomize start from between first/last frame
	if (self.spawnflags & 1)
	{
		self.frame = self.first_frame;
		float diff;
		diff = self.last_frame - self.first_frame;

		self.frame = self.frame + ceil(random()*diff);
	}

    // Default animation speed to 10 fps
    if (!self.speed)
        self.speed = 10 / 60;

	self.nextthink = time + self.speed;
	self.think = misc_model_think;
};