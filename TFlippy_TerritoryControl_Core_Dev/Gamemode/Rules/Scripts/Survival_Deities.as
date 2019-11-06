#include "DeityCommon.as";

void onInit(CRules@ this)
{
	Reset(this, getMap());
}

void onRestart(CRules@ this)
{
	Reset(this, getMap());
}

void onRulesRestart(CMap@ this, CRules@ rules)
{
	Reset(rules, this);
}

void Reset(CRules@ this, CMap@ map)
{
	int count = getPlayerCount();
	for (int i = 0; i < count; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player !is null)
		{
			player.set_u8("deity_id", 0);
			
			CBlob@ blob = player.getBlob();
			if (blob !is null)
			{
				blob.set_u8("deity_id", 0);
			}
		}
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player !is null && blob !is null)
	{
		u8 deity_id = player.get_u8("deity_id");
		blob.set_u8("deity_id", deity_id);
		
		switch (deity_id)
		{
			case Deity::mithrios:
			{
				blob.Tag("mithrios");
	
				blob.SetLight(true);
				blob.SetLightRadius(16.0f);
				blob.SetLightColor(SColor(255, 255, 0, 0));
			}
			break;
			
			case Deity::ivan:
			{
				blob.Tag("ivan");
			}
			break;
		}
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	print("rip");

	if (attacker !is null)
	{
		CBlob@ attacker_blob = attacker.getBlob();
		if (attacker_blob !is null)
		{
			u8 deity_id = attacker_blob.get_u8("deity_id");
			switch (deity_id)
			{
				case Deity::mithrios:
				{
					CBlob@ altar = getBlobByName("altar_mithrios");
					if (altar !is null)
					{
						altar.add_f32("deity_power", 5);
						print("add");
					}
				}
				break;
			}
		}
	}
}