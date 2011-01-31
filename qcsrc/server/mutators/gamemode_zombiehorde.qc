float round_started;
float round_number;
float zombies_to_spawn;
float zombies_alive;

void zombiehorde_Initialize()
{	
	round_started = FALSE;
	round_number = 0;
	zombies_to_spawn = 0;	
	zombies_alive = 0;
}

void zombiehorde_SetupNextRound()
{
	round_started = FALSE;
	round_number = round_number + 1;
	zombies_to_spawn = floor(round_number / .3);
}

void zombiehorde_StartRound()
{
	local entity e;

	if (round_started == TRUE)
		return;

	round_started = TRUE;

	FOR_EACH_REALPLAYER(e)
		centerprint(e, strcat("-- ROUND ", ftos(round_number), " BEGINS NOW --\n"));

	float i;
	for (i = 0; i < zombies_to_spawn; i = i + 1) 
	{
		local entity zombie, oldself, spawnpoint;
		spawnpoint = SelectSpawnPoint(TRUE);
		zombie = spawn();
		oldself = self;
		self = zombie;
		self.classname = "monster_zombie";
		self.spawnflags |= MONSTERFLAG_NORESPAWN;
		self.origin = spawnpoint.origin;
		spawnfunc_monster_zombie();
		zombies_alive = zombies_alive + 1;
		self = oldself;
	}
}

void zombiehorde_ZombieDied()
{
	zombies_alive = zombies_alive - 1;

	if (round_started == TRUE)
	if (zombies_alive == 0)
	{
		zombiehorde_SetupNextRound();
		zombiehorde_StartRound();
	} else {
		local entity e;
		FOR_EACH_REALPLAYER(e)
			centerprint(e, strcat("-- There are ", ftos(zombies_alive), " zombies still alive --\n"));
	}
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerSpawn)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		// allow BOTs to be targets
		self.takedamage |= DAMAGE_AIM;
	} else if (clienttype(self) == CLIENTTYPE_REAL) {
		if (round_started == FALSE) {
			zombiehorde_SetupNextRound();
			zombiehorde_StartRound();
		}
	}

	return 1;
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerDies)
{
	print("DEBUG: I saw the death of ", self.netname);
	return 0;
}

MUTATOR_DEFINITION(gamemode_zombiehorde)
{
	MUTATOR_HOOK(PlayerSpawn, zombiehorde_PlayerSpawn, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerDies, zombiehorde_PlayerDies, CBC_ORDER_FIRST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");

		g_zombiehorde = 1;
		cvar_set("g_monsters", "1");
		cvar_set("g_monster_zombie_attack_run_damage", "10");
		cvar_set("g_monster_zombie_attack_run_delay", "100");
		cvar_set("g_monster_zombie_attack_run_range", "75");
		cvar_set("g_monster_zombie_attack_run_delay", "0.5");
		cvar_set("g_monster_zombie_attack_run_hitrange", "65");
		cvar_set("g_monster_zombie_attack_stand_damage", "10");
		cvar_set("g_monster_zombie_attack_stand_range", "65");
		cvar_set("g_monster_zombie_attack_stand_delay", "0.5");
		cvar_set("g_monster_zombie_attack_stand_hitrange", "65");
		cvar_set("g_monster_zombie_targetrange", "1000");
		cvar_set("g_monster_zombie_turnspeed", "5");
		cvar_set("g_monster_zombie_movespeed", "100");
		cvar_set("g_monster_zombie_stopspeed", "100");
		cvar_set("g_monster_zombie_health", "150");

		zombiehorde_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_zombiehorde = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
