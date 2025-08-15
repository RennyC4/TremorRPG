//
// CSQC 3rd person camera
//

vector plyr_pos;
void() Camera_Third =
{
    camang = getproperty(VF_ANGLES);
    makevectors(camang);

    campos = getproperty(VF_ORIGIN) - v_forward * 100 + v_up * 20;
    plyr_pos = getproperty(VF_ORIGIN);

    tracebox(plyr_pos, '-16 -16 -16', '16 16 16', campos, MOVE_NOMONSTERS, self);

    setproperty(VF_ORIGIN, trace_endpos);
    setproperty(VF_AFOV, 90);
	setviewprop(VF_VIEWENTITY, 0);

/*
    if (self.entnum == player_localentnum)
	{
        addentity(self);
		self.renderflags &= ~RF_EXTERNALMODEL;
    }
*/
};