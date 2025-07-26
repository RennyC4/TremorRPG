/*
setprop - put down buildings on terrain
*/

void() setprop =
{
    precache_model(self.model);
    setmodel(self, self.model);
	self.solid = SOLID_BSP;
};