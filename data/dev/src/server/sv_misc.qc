/*
setprop - put down buildings on terrain
*/

void() setprop =
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
		print(sprintf("ent %i: %S\n", i, entdata));
		if (!entdata)
			continue; //can happen when editing
		self = newent = spawn();
		parseentitydata(newent, strcat("{\n", entdata, "\n}")); //reads it into the entity
		//TODO: fix up inline model names
		if (substring(newent.model, 0, 1) == "*")
			newent.model = sprintf("%s:%s", newent.model, oself.model);

		newent.origin += oself.origin;
		callfunction(self.classname); //gotta make sense of it by calling its spawn function
		self = oself;
    }
};