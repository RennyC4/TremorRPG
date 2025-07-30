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
		precache_model(newent.model);
		//TODO: fix up inline model names
		if (substring(newent.model, 0, 1) == "*")
			newent.model = sprintf("%s:%s", newent.model, oself.model);
		newent.origin += oself.origin;
		callfunction(self.classname); //gotta make sense of it by calling its spawn function
		self = oself;
    }
};

//
// part_foundain - particle effect for water foundtains
//

void() part_fountain_think =
{
	pointparticles(PART_FOUNTAIN, self.origin);
	self.nextthink = time + 0.1;
}

void() part_fountain =
{
	precache_sound ("ambience/fountain.wav");
	ambientsound(self.origin, "ambience/fountain.wav", 1, ATTN_STATIC);

	setmodel(self, string_null);
	self.think = part_fountain_think;
	self.nextthink = time + 0.1;
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

    if (self.first_frame)
		self.frame = self.first_frame;
	
    // Only animate if given a frame range
    if (!self.last_frame)
        return;

	// Randomize start from between first/last frame
	if (self.spawnflags & 1)
	{
		self.frame = self.first_frame;
		local float diff;
		diff = self.last_frame - self.first_frame;

		self.frame = self.frame + ceil(random()*diff);
	}
	
    // Default animation speed to 10 fps
    if (!self.speed)
        self.speed = 10 / 60;

	self.nextthink = time + self.speed;
	self.think = misc_model_think;
};