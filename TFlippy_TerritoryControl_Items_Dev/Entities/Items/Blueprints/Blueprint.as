#include "Requirements.as"
#include "Requirements_Tech.as"

#include "TCTechs.as"

void onInit(CBlob@ this)
{
	this.addCommandID("study");
	
	string tech = "tech_" + this.getConfig().substr(3);
	this.set_string("tech_name", tech);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CButton@ button = caller.CreateGenericButton(0, Vec2f(0, 0), this, this.getCommandID("study"), "Study");
	button.SetEnabled(!HasFakeTech(getRules(), this.get_string("tech_name"), caller.getTeamNum()));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("study"))
	{
		if (!this.hasTag("used"))
		{
			GiveFakeTech(getRules(), this.get_string("tech_name"), this.getTeamNum());
		
			if (getNet().isServer())
			{
				this.server_Die();
			}
			
			this.Tag("used");
		}
	}
}