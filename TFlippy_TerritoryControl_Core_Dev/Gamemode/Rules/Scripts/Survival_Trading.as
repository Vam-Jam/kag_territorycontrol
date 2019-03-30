#include "TradingCommon.as";
#include "Descriptions.as"
#include "GameplayEvents.as"
#include "Survival_Structs.as";

#define SERVER_ONLY

int coinsOnDamageAdd = 5;
int coinsOnKillAdd = 25;
int coinsOnDeathLose = 10;
int min_coins = 50;

const int coinsOnDeathLosePercent = 20;
const int coinsOnTKLose = 50;

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 5;
const int coinsOnKillSiege = 100;

const int coinsOnCapFlag = 100;

const int coinsOnBuild = 4;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 20;

const int warmupFactor = 3;

const u32 MAX_COINS = 30000;

//
string cost_config_file = "tdm_vars.cfg";
bool kill_traders_and_shops = false;

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "tradingpost")
	{
		if (kill_traders_and_shops)
		{
			blob.server_Die();
			KillTradingPosts();
		}
		else
		{
			MakeTradeMenu(blob);
		}
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null && cost > 0)
	{
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu(CBlob@ trader)
{
	//load config

	s32 menu_width = 3;
	s32 menu_height = 4;

	// build menu
	CreateTradeMenu(trader, Vec2f(menu_width, menu_height), "Buy goods");

	//
	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));

	addItemForCoin(trader, "Bomb", 25, true, "$mat_bombs$", "mat_bombs", descriptions[1]);
	addItemForCoin(trader, "Working Mine", 60, true, "$mine$", "faultymine", "A completely unsafe and working mine.");
	addItemForCoin(trader, "Arrows", 10, true, "$mat_arrows$", "mat_arrows", descriptions[2]);

	addItemForCoin(trader, "Drill", 100, true, "$drill$", "drill", descriptions[43]);
	addItemForCoin(trader, "Bucket", 5, true, "$bucket$", "bucket", "A bucket for storing water.");
	addItemForCoin(trader, "Lantern", 5, true, "$lantern$", "lantern", "A lantern for lighting up the dark");
	
	addItemForCoin(trader, "Wood", 25, true, "$mat_wood$", "mat_wood", "Woody timber.");
	addItemForCoin(trader, "Stone", 50, true, "$mat_stone$", "mat_stone", "Rocky stone.");

}

// load coins amount

void Reset(CRules@ this)
{
	//load the coins vars now, good a time as any
	if (this.exists("tdm_costs_config"))
		cost_config_file = this.get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	coinsOnDamageAdd = cfg.read_s32("coinsOnDamageAdd", coinsOnDamageAdd);
	coinsOnKillAdd = cfg.read_s32("coinsOnKillAdd", coinsOnKillAdd);
	coinsOnDeathLose = cfg.read_s32("coinsOnDeathLose", coinsOnDeathLose);
	min_coins = cfg.read_s32("minCoinsOnRestart", min_coins);

	kill_traders_and_shops = !(cfg.read_bool("spawn_traders_ever", true));

	if (kill_traders_and_shops)
	{
		KillTradingPosts();
	}

	//at least 50 coins to play with each round
	for (int i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		player.server_setCoins(Maths::Max(player.getCoins(), min_coins));
	}

}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}


void KillTradingPosts()
{
	CBlob@[] tradingposts;
	bool found = false;
	if (getBlobsByName("tradingpost", @tradingposts))
	{
		for (uint i = 0; i < tradingposts.length; i++)
		{
			CBlob @b = tradingposts[i];
			b.server_Die();
		}
	}
}

// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null)
	{
		CBlob@ victimBlob = victim.getBlob();
		
		const u32 victim_coins = victim.getCoins();
		
		f32 reward_factor = 0.10f;
		u32 dropped_coins = 0.00f;
	
		const bool hasKiller = killer !is null;
	
		if (victim.getTeamNum() < 7)
		{
			TeamData@ team_data;
			GetTeamData(victim.getTeamNum(), @team_data);
		
			if (team_data !is null)
			{
				u16 upkeep = team_data.upkeep;
				u16 upkeep_cap = team_data.upkeep_cap;
				f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);
				
				if (upkeep_ratio >= UPKEEP_RATIO_PENALTY_COIN_DROP) reward_factor += 0.20f;
			}
		}
	
		if (hasKiller)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				if (killer.getTeamNum() < 7)
				{
					TeamData@ team_data;
					GetTeamData(killer.getTeamNum(), @team_data);
				
					if (team_data !is null)
					{
						u16 upkeep = team_data.upkeep;
						u16 upkeep_cap = team_data.upkeep_cap;
						f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);
					
						if (upkeep_ratio <= UPKEEP_RATIO_BONUS_COIN_GAIN) reward_factor += 0.20f;
					}
				}
			}
		
		}
			
		dropped_coins = victim_coins * reward_factor;
			
		if (hasKiller)
		{
			f32 killer_reward = dropped_coins;
		
			if (killer.getTeamNum() < 7)
			{
				TeamData@ team_data;
				GetTeamData(killer.getTeamNum(), @team_data);
			
				if (team_data !is null)
				{
					if (team_data.tax_enabled)
					{
						CPlayer@ leader = getPlayerByUsername(team_data.leader_name);
						if (leader !is null)
						{
							killer_reward *= 0.50f;
							leader.server_setCoins(Maths::Clamp(leader.getCoins() + killer_reward, 0, MAX_COINS));
						}
					}
				}
			}
			
			killer.server_setCoins(Maths::Clamp(killer.getCoins() + killer_reward, 0, MAX_COINS));
		}
		else if (victimBlob !is null) server_DropCoins(victimBlob.getPosition(), dropped_coins);
		
		victim.server_setCoins(Maths::Clamp(victim.getCoins() - dropped_coins, 0, MAX_COINS));
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (attacker !is null && attacker !is victim)
	{
		CBlob@ blob = attacker.getBlob();
	
		if (blob !is null) attacker.server_setCoins(attacker.getCoins() + DamageScale * coinsOnDamageAdd / this.attackdamage_modifier + (blob.getConfig() == "bandit" ? 10 : 0));
	}

	return DamageScale;
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	//only important on server
	if (!getNet().isServer())
		return;

	if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);

		CPlayer@ p = g.getPlayer();
		if (p !is null)
		{
			u32 coins = 0;

			switch (g.getType())
			{
				case GE_built_block:

				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if (tile == CMap::tile_castle)
					{
						coins = coinsOnBuild;
					}
					else if (tile == CMap::tile_wood)
					{
						coins = coinsOnBuildWood;
					}
				}

				break;

				case GE_built_blob:

				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();

					if (name.findFirst("door") != -1 ||
					        name == "wooden_platform" ||
					        name == "trap_block" ||
					        name == "spikes")
					{
						coins = coinsOnBuild;
					}
					else if (name == "building")
					{
						coins = coinsOnBuildWorkshop;
					}
				}

				break;

				case GE_hit_vehicle:
					coins = coinsOnHitSiege;
					break;

				case GE_kill_vehicle:
					coins = coinsOnKillSiege;
					break;

				case GE_captured_flag:
					coins = coinsOnCapFlag;
					break;
			}

			if (coins > 0)
			{
				if (this.isWarmup())
					coins /= warmupFactor;

				p.server_setCoins(p.getCoins() + coins);
			}
		}
	}
}