#include "Hitters.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.maxQuantity = 50;
	this.Tag("mat_gas");
	this.Tag("dangerous");
}

void DoExplosion(CBlob@ this)
{
	if (!this.hasTag("dead"))
	{
		f32 quantity = this.getQuantity();
		if (quantity > 0)
		{
			if (isClient())
			{
				this.getSprite().PlaySound("gas_leak.ogg");
			}
		
			if (isServer())
			{
				for (int i = 0; i < (quantity / 10) + XORRandom(quantity / 10) ; i++)
				{
					CBlob@ blob = server_CreateBlob("crakgas", -1, this.getPosition());
					blob.setVelocity(Vec2f(XORRandom(20) - 10, -XORRandom(10)));
					blob.server_SetTimeToDie(10 + XORRandom(10));
				}
			}
		}
		
		this.Tag("dead");
		this.getSprite().Gib();
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if (blob !is null ? !blob.isCollidable() : !solid) return;
		f32 vellen = this.getOldVelocity().Length();

		if (vellen > 5.0f)
		{
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}