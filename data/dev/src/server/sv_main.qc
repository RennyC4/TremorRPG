//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

void() main = {};

//called for each frame that QC runs
void() StartFrame = {};

// Send SSQC values to CSQC
void() SSQC_SendValuesToCSQC =
{
	clientstat(STAT_GUID, EV_STRING, player_guid);
};

void() worldspawn =
{	
	precache_everything();
	SSQC_SendValuesToCSQC();
};

void() SpectatorConnect = {};