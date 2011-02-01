/*
 * TODO
 * ----
 * Zombies don't "see" the player if the player crouches
 * (FIXED) The numbers of zombies in play per round gets out of sync after round 1 (Seems worse with more people in the game..)
 * Zombies spawning over other zombies at the spawn locations
 * Zombies get stuck in wander mode and are not able to move
 * Add zombie kills to the player frags on the scoreboard
 * Zombies need better enemy detection and wander code that doesn't recalculate on every think
*/



float zhRoundNumber;
float zhRoundState;
entity zhRoundEntity;
float zhRoundDelay;
float zhZombiesToSpawn;
float zhZombiesAlive;

#define ROUND_WARMUP		1
#define ROUND_SETUP		2
#define ROUND_STARTING		4
#define	ROUND_STARTED		8
#define ROUND_ENDING		16

void zombiehorde_RoundThink();

void zombiehorde_Initialize()
{	
	zhRoundState = ROUND_WARMUP;
	zhRoundNumber = 0;
	zhRoundDelay = 0;
	zhZombiesToSpawn = 0;	
	zhZombiesAlive = 0;

	// Create the round entity used for logic
	zhRoundEntity = spawn();
	zhRoundEntity.think = zombiehorde_RoundThink;
	zhRoundEntity.nextthink = time + 1;
}

void zombiehorde_SpawnZombie()
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
	zhZombiesAlive++;
	self = oldself;
}

void zombiehorde_RoundThink() 
{
	switch (zhRoundState)
	{
		case ROUND_WARMUP:
		{
			local entity e;
			FOR_EACH_REALPLAYER(e)
				centerprint(e, "-- WAITING FOR PLAYERS --\n");

			self.nextthink = 1.0;
			break;
		}
		case ROUND_SETUP:
		{
			zhRoundNumber++;
			zhRoundDelay = 5;
			zhZombiesToSpawn = floor(zhRoundNumber / .3);
			print("ZOMBIES ALIVE: ", ftos(zhZombiesAlive), "\n");
			zhRoundState = ROUND_STARTING;

			self.nextthink = 1.0;
			break;
		}
		case ROUND_STARTING:
		{
			local entity e;
			FOR_EACH_REALPLAYER(e)
				if (zhRoundDelay > 1)
					centerprint(e, strcat("-- ROUND ", ftos(zhRoundNumber), " STARTS IN ", ftos(zhRoundDelay), " seconds --\n"));
				else
					centerprint(e, strcat("-- ROUND ", ftos(zhRoundNumber), " STARTS IN ", ftos(zhRoundDelay), " second --\n"));

			zhRoundDelay--;
			if (zhRoundDelay == 0)
				zhRoundState = ROUND_STARTED;

			self.nextthink = 1.0;
			break;
		}
		case ROUND_STARTED:
		{
			// Stagger the spawning of zombies slightly
			if (zhZombiesToSpawn > 0)
			if (random() * 5 < 2)
			{
				zombiehorde_SpawnZombie();
				zhZombiesToSpawn--;
			}

			// If all the zombies that needed to be killed for the round are dead,
			// setup the next round!
			if (zhZombiesAlive + zhZombiesToSpawn <= 0)
				zhRoundState = ROUND_ENDING;

			self.nextthink = time + 1.0;
			break;
		}
		case ROUND_ENDING:
		{
			// Placeholder state
			zhRoundState = ROUND_SETUP;
			self.nextthink = time;
			break;
		}
		default:
		{
			dprint("Unknown Zombie Horde round state: ", ftos(zhRoundState), "\n");
			self.nextthink = 1.0;
		}
	}
}

void zombiehorde_ZombieDied()
{
	zhZombiesAlive--;

	print("ZOMBIES ALIVE: ", ftos(zhZombiesAlive), "\n");
	print("ZOMBIES TO SPAWN: ", ftos(zhZombiesToSpawn), "\n");

	local entity e;
	if (zhZombiesAlive + zhZombiesToSpawn > 0)
		FOR_EACH_REALPLAYER(e)
			centerprint(e, strcat("-- There are ", ftos(zhZombiesToSpawn + zhZombiesAlive), " zombies to go --\n"));
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerSpawn)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		// allow BOTs to be targets
		self.takedamage |= DAMAGE_AIM;
	} else if (clienttype(self) == CLIENTTYPE_REAL) {
		// For now, game play begins after the first person spawns
		if (zhRoundState == ROUND_WARMUP)
			zhRoundState = ROUND_SETUP;
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
