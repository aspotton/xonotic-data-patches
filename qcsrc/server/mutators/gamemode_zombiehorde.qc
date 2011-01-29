void zombiehorde_Initialize()
{
	//precache_model("models/player/zombie.dpm");
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerSpawn)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		entity zombie, oldself, player;
		zombie = spawn();
		oldself = self;
		self = zombie;
		spawnfunc_monster_zombie();
		self = oldself;
	}

	return 1;
}

MUTATOR_DEFINITION(gamemode_zombiehorde)
{
	MUTATOR_HOOK(PlayerSpawn, zombiehorde_PlayerSpawn, CBC_ORDER_LAST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");

		g_zombiehorde = 1;
		cvar_set("g_monsters", "1");
		cvar_set("g_monster_zombie_targetrange", "1000");
		cvar_set("g_monster_zombie_turnspeed", "5");
		cvar_set("g_monster_zombie_movespeed", "100");

		zombiehorde_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_zombiehorde = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
