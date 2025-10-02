//
// func_illusionary - brush entity that can be walked through
//

void() func_illusionary =
{
	setmodel(self, self.model);
	self.solid = SOLID_NOT;
};