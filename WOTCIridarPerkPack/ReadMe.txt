
"IRIAstralGrasp",
"IRIAstralGraspPerk",
"IRIAstralGraspSpirit",
"IRIAstralGraspSpiritDeathPerk",
"IRIPredatorStrikePerk",
"IRISiphon",
"IRIObelisk",

================================================== ENGLISH DESCRIPTION ==================================================

[WOTC] Iridar's Perk Pack

This mod adds various abilities that can be used by other mods that add soldier classes, items or provide other ways for soldiers to gain abilities. By itself this mod does absolutely nothing; it relies on other mods to put the new abilities to use.

I intend to put most of my new abilities into this mod, as it will make it more convenient for different mods to reuse the abilities without duplicating code.

Perks in this mod are currently split into the following groups:[list]
[*] [b][url=https://steamcommunity.com/workshop/filedetails/discussion/2833581072/3412056228825697883/]Bounty Hunter:[/url][/b] 21 perks.
[*] [b][url=https://steamcommunity.com/workshop/filedetails/discussion/2833581072/3412056228825699302/]Templar:[/url][/b] 1 perk.
[/list]
Click on the group name to see the list of abilities in that group.

[h1]REQUIREMENTS[/h1]
[list][*] [url=https://steamcommunity.com/workshop/filedetails/?id=1134256495][b]X2 WOTC Community Highlander[/b][/url]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2363075446][WOTC] Iridar's Template Master - Core[/url][/b][/list]
Safe to add mid-campaign.

[h1]COMPATIBILITY[/h1]

Perks in this mod are already configured for [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133397762]Ability To Slot Reassignment[/url][/b] and [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1280477867]Musashi's RPG Overhaul[/url][/b]. Make sure to subscribe to [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2569592723][WOTC] Musashi's Mods Fixes[/url][/b] if you use either of these mods.

This mod should not conflict with anything, it has no mod class overrides and makes no changes to other abilities or items that could cause compatibility issues.

[h1]CONFIGURATION[/h1]

Many aspects of this mod are configurable through configuration files in:
[code]..\steamapps\workshop\content\268500\2833581072\Config\[/code]
Each group of abilities will have its own set of configuration files in its own folder.

Some of the abilities' properties can be configured through XComGame.ini in the group's config folder. Such properties are highlighted in-game with non-standard font color.

[h1]CREDITS[/h1]

Thanks to [b]Mitzruti[/b] for porting [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2094355561]Chimera Squad Ability Icons[/url][/b], some of those icons are used in this mod.
Thanks to [b]NeIVIeSiS[/b] for making some of the ability icons in this mod.
Thanks to [b]XCOMrades[/b] for helping me develop and finance this mod, and for providing Russian translation.

Please [b][url=https://www.patreon.com/Iridar]support me on Patreon[/url][/b] if you require tech support, have a suggestion for a feature, or simply wish to help me create more awesome mods.

================================================== TEMPLAR ABILITIES ==================================================

[h1]Soul Shot[/h1]

[quote]Template name: IRI_TM_SoulShot

This ability needs to be attached to a weapon with an ExtraDamage with the damage tag: "IRI_TM_SoulShot". Animations expect the caster to have primary Shard Gauntlets.[/quote]

A powerful ranged attack that scales with Focus and generates Focus on kills. 2 turn cooldown.

================================================== BOUNTY HUNTER ABILITIES ==================================================

[h1]SQUADDIE ABILITIES[/h1]

[h1]Headhunter[/h1]
[quote]Template name: IRI_BH_Headhunter

Must be attached to a weapon. Defaults to primary weapon if no slot is specified.[/quote]

Killing an enemy with your Handcannon permanently increases its critical chance against other enemies of that type by +1%. This bonus is cumulative.

[i]This is mostly a flavor passive that allows a Bounty Hunter to gradually become more effective against specific enemy types over the course of a campaign.[/i]

[h1]Handcannon[/h1]
[quote]Template name: IRI_BH_FirePistol

Must be attached to a weapon.[/quote]

Fire your handcannon at a target. It is incredibly destructive, but its ammunition is limited and must be used sparingly.

[i]This is mostly a copy of standard Pistol Shot.[/i]

[h1]Nightfall[/h1]
[quote]Template name: IRI_BH_Nightfall[/quote]

Activate to enter Nightfall for 2 turns, an advanced form of concealment with reduced detection radius. 5 turn cooldown.[list]
[*] Nightfall cannot be activated while you're flanked.
[*] Nightfall has a very small detection radius, but otherwise functions like regular concealment, and without special training will be broken by attacking.
[*] Nightfall is not broken when other soldiers in your squad break concealment.
[*] If you are already concealed when Nightfall is activated, then your concealment will not be broken if Nightfall runs out naturally.[/list]

[i]This is the central Bounty Hunter ability. Use it to safely get into flanking positions and empower your attacks through Dead of Night.[/i]

[h1]Dead of Night[/h1]
[quote]Template name: IRI_BH_Nightfall_Passive[/quote]

Gain +100% Crit Chance against enemies that do not see you. Gain +1 Crit Damage for every 20% of Crit Chance above 100%.

[i]Another core ability. Keep in mind that "do not see you" mechanic works with more things than just concealment. This description may seem complicated, but the overall idea is that if the enemy doesn't see you, you're guaranteed to cause critical damage, and the more critical chance you have, the more damage you will deal. [/i]



[h1]SPECIALIZATION: RAIDER[/h1]

Raider is the explosive specialization. It focuses specifically on a type of gameplay where you sneak up on an enemy and deliver a large chunk of damage, all in one turn. 

[h1]Corporal: Explosive Action[/h1]
[quote]Template name: IRI_BH_ExplosiveAction[/quote]

Breaking concealment by attacking grants one non-move Action Point. Triggers once per turn, so you can't benefit from it twice by breaking regular concealment, and then Nightfall concealment. Only player-activated abilities may trigger Explosive Action.

[i]This is the staple ability for the Raider specialization: ideally, you will combine Nightfall with an explosive to weaken and expose the enemy, and then use the extra action for another attack, causing even more damage.[/i]

[h1]Sergeant: Homing Mine[/h1]
[quote]Template name: IRI_BH_HomingMine[/quote]

Attach a claymore onto an enemy (does not alert the enemy). The Homing mine will explode upon that enemy taking damage. Shots against the mined target are guaranteed to hit.

[i]This is the regular Reaper ability. It is very powerful, but rarely gets picked, because it is so late in the ability tree and has some stiff competition. Homing Mine has excellent utility and damage, and it works great with Bounty Hunters, who can enter Nightfall, sneak up with one action, then apply a Mine and attack on the second turn of Nightfall, causing a massive burst of damage, and then having another attack in store thanks to Explosive Action.[/i]

[h1]Lieutenant: Double Payload[/h1]
[quote]Template name: IRI_BH_DoublePayload

Has effect only on HomingMine ability.[/quote]

Homing Mine gains +1 additional charge and deals +100% bonus damage to the main target.

[i]A simple improvement to the Homing Mine.[/i]

[h1]Captain: Bomb Raider[/h1]
[quote]Template name: IRI_BH_BombRaider[/quote]

Gain a Grenade slot. Your explosive attacks can inflict critical damage (20% chance for +2 damage).

[i]This ability allows explosives to benefit from Dead of Night, making critical hits guaranteed when using explosives while in Nightfall concealment or throwing grenades around objects that block line of sight.[/i]

[h1]Major: Witch Hunt[/h1]
[quote]Template name: IRI_BH_WitchHunt[/quote]

Your critical hits against psionic units set them on fire. Applied by all attacks that can cause critical damage, including explosives, if you have Bomb Raider.

[i]Not gonna lie, this ability exists mostly because of the fun name, though it surely will come useful against psionics, especially if you can blow up a whole pod with them, or if the priority target has psionic escorts.[/i]

[h1]Colonel: Lights Out[/h1]
[quote]Template name: IRI_BH_BlindingFire[/quote]

Your critical hits blind enemies for 1 turn, preventing them from seeing you. Applied by all attacks that can cause critical damage. 

Blinded enemies cannot see any units or objects, so they cannot take most of their offensive or supportive actions, making this a very effective crowd control tool. Since blinded enemies cannot see you, Dead of Night will work against them even outside Nightfall concealment. 



[h1]SPECIALIZATION: CHASER[/h1]

Chaser is the in-your-face specialization. It's all about getting into [i]close range[/i] and then blowing enemies' heads off with the Handcannon.

[h1]Corporal: Dark Night[/h1]
[quote]Template name: IRI_BH_DarkNight_Passive[/quote]

Attacking no longer breaks Nightfall concealment.

[i]This is a huge improvement to Nightfall. [/i]

[i]Offensively, it lets you perform attacks that benefit from Dead of Night on both turns of Nightfall. Though it does mean that you always want to attack on the turn you enter Nightfall, as opposed to other specializations, that can spend an extra turn sneaking up into a better position.[/i]

[i]Defensively, it means that most of the time, Nightfall concealment will break by running out naturally, which happens at the start of your turn. So when you use Nightfall, the enemies will not threaten the Bounty Hunter for two turns.[/i]

[h1]Sergeant: Night Dive[/h1]
[quote]Template name: IRI_BH_ShadowTeleport

Must be attached to a weapon located in a pistol holster.[/quote]

Enter Nightfall concealment and fire a special psionic round from your handcannon that creates a rift in space and teleports you to a flanking position within 4 tiles of the target. Takes away all action points and grants one non-move Action Point. Shares 5 turn cooldown with Nightfall. 3 uses per mission. If the target cannot be flanked, you can teleport to any visible tile near it.

[i]Chaser prefers to be in close range, and Night Dive delivers. While diving up to an enemy would normally be very risky, the Nightfall concealment should make it more of a calculated gamble and less of a guaranteed suicide mission. The action economy on this ability means the run-up and teleport distance don't matter, you're always gonna end up with an enemy in front of you and an action to attack them.[/i]

[h1]Lieutenant: Nothing Personal[/h1]
[quote]Template name: IRI_BH_NothingPersonal_Passive

Must be attached to a weapon located in a pistol holster. That weapon must have an ExtraDamage with the "IRI_BH_NothingPersonal" tag, which will be added to weapon's normal damage. Requires Night Dive to work off.[/quote]

Enemies targeted by Night Dive will take double damage from your next normal handcannon shot due to residual psionic energy from the rift coating the bullet. The damage caused by the amplified attack will count as both regular and psionic damage.

[i]This ability enhances the gameplay sequence of "teleport with Night Dive -> blow up the enemy with a Handcannon shot". [/i]

[h1]Captain: Night Rounds[/h1]
[quote]Template name: IRI_BH_NightRounds[/quote]

Gain am Ammo slot and +40% Crit Chance against enemies that do not take cover.

[i]This ability allows you to take a more creative approach with your Bounty Hunter's loadout... Who am I kidding, everyone is just going to use Talon Ammo. Anyway, the overall idea is to provide a utility/damage boost through Experimental Ammo at the cost of a materiel investment, and to bring your Crit Chance against unflankable enemies, such as robots, on par with Crit Chance against regular meatbags.[/i]

[h1]Major: Feeling Lucky[/h1]
[quote]Template name: IRI_BH_FeelingLucky_Passive

Must be attached to a weapon that uses ammo.[/quote]

Whenever you enter Nightfall, your handcannon will gain +1 Ammo. This ammo is lost if not spent by the time Nightfall concealment is broken.

[i]Chaser relies so much on the Handcannon for the damage output, and this ability will let you fire more handcannon shots per mission, while giving you an incentive to fire at least one Handcannon shot during Nightfall.[/i]

[h1]Colonel: Named Bullet[/h1]
[quote]Template name: IRI_BH_NamedBullet

Must be attached to a weapon located in a pistol holster.[/quote]

Use your handcannon to fire a special bullet with the target's name on it. The bullet ricochets inside the target, applying its damage three times. 1 use per mission.

[i]This is essentially an alternative to Fan Fire, but the key difference is that individual Fan Fire shots can hit or miss on their own, while missing with the Named Bullet will mean missing out on the entire damage output. Better not miss it! Needless to say, you want to combine Named Bullet withNightfall for an absolutely disgusting amount of damage.[/i]



[h1]SPECIALIZATION: HITMAN[/h1]

Hitman is the "long range" specialization. It uses vektor rifle volleys to methodically pick enemies apart at squadsight ranges.

[h1]Corporal: Night Watch[/h1]
[quote]Template name: IRI_BH_NightWatch

Must be attached to a primary weapon.[/quote]

Your vektor rifle gains Squadsight, allowing you to attack enemies within squadmates' sight, provided there is line of sight to the target. Night Watch does not suffer critical chance penalties normally associated with Squadsight. Squadsight attacks benefit from Dead of Night.

[i]The core ability of this specialization, it allows the Bounty Hunter to benefit from Dead of Night without relying on Nightfall concealment. Though you still can, and should, use Nightfall from time to time for that up close Handcannon shot.[/i]

[h1]Sergeant: Nightmare[/h1]
[quote]Template name: IRI_BH_Nightmare[/quote]

Gain +20 Aim and +20% Crit Chance when attacking uncovered targets that do not see you. Applies only when attacking enemies that are flanked or do not take cover at all.

[i]This is a mandatory boost to otherwise less-than-stellar vektor rifle accuracy at squadsight ranges, but it also forces you to go for flanks.[/i]

[h1]Lieutenant: Overwhelming Burst[/h1]
[quote]Template name: IRI_BH_BurstFire

Must be attached to a primary weapon, ideally to a weapon that is normally semi-automatic.[/quote]

Fire an automatic burst from your vektor rifle. Costs 2 ammo and applies damage 2 times. Squadsight aim penalties for this ability are increased by 100%. 5 turn cooldown. Hit chance calculations are done separately for each damage instance.

[i]This ability is like two-shot vektor Fan Fire. It's a damage boost that gives you an incentive to stay closer to enemies, just at the edge of squadsight range.[/i]

[h1]Captain: Unrelenting Pressure[/h1]
[quote]Template name: IRI_BH_UnrelentingPressure

Must be attached to the same weapon IRI_BH_BurstFire is attached to.[/quote]

Critical hits with your vektor rifle single target attacks reduce the current cooldown of Overwhelming Burst by 1 turn.

[i]This ability lets you use Overwhelming Burst more often, and gives you an incentive to attack as often as you can.[/i]

[h1]Major: Big Game Hunter[/h1]
[quote]Template name: IRI_BH_BigGameHunter[/quote]

Damaging an enemy grants +20% Crit Chance against them. This bonus is cumulative, but it is reset if you damage another enemy.

[i]This ability makes your repeated attacks against the same target hit stronger and stronger. Each hit of Overwhelming Burst will provide a stack of Big Game Hunter.[/i]

[h1]Colonel: Terminate[/h1]
[quote]Template name: IRI_BH_Terminate

Must be attached to a primary weapon.[/quote]

Mark an enemy for termination. Your single target attacks against the marked enemy will cause additional Vektor Rifle attacks. The mark lasts until the enemy dies. 1 use per mission. Terminate attacks do not suffer reaction fire penalties and can deal critical damage.

[i]Like Banish or Named Bullet, this ability lets you riddle a particular enemy with holes, just over a longer period of time.[/i]


[h1]GTS PERK[/h1]

[h1]Untraceable[/h1]
[quote]Template name: IRI_BH_Untraceable

Applies only to Nightfall and Night Dive by template name.[/quote]

If you don't attack for a turn, Nightfall's cooldown is additionally reduced by 1 turn. Applies to Night Dive as well.

[i]This ability simply lets you use Nightfall more often, especially it increases the likelihood that it will cooldown completely while you're moving between engagements on a large map.[/i]



---

TODO: Restore this

{
    "sfStandalone": [
        "IRIBountyHunter",
		"IRIShadowTeleportPerk",
		"IRINothingPersonalPerk",
		"IRINamedShotPerk",
		"IRISoulShot2",
		"IRIVolt",
		"IRITerminatePerk",
		"IRIHomingMinePerkBH",
		"IRIThunderLancePerk",
		"IRIPerkPackUI",
		"IRIZephyrStrikePerkOnly",
		"IRIReflect",
		"IRISpectralStride",
		"IRIAmplify",
		"IRIRend",
		"IRIReaperTakedownPerk",
		"IRIInvert",
		"IRIGhost",
		"IRIRifleGrenadePerk"
    ]
}


[Engine.ScriptPackages]
+NonNativePackages=AWOTCIridarPerkPack
+NonNativePackages=WOTCIridarPerkPack2
+NonNativePackages=WOTCIridarPerkPackFoxcom
+NonNativePackages=WOTCIridarPerkPackBountyHunter
+NonNativePackages=WOTCIridarPerkPackSkirmisher
+NonNativePackages=WOTCIridarPerkPackTemplar
+NonNativePackages=WOTCIridarPerkPackClassRework

[UnrealEd.EditorEngine]
+ModEditPackages=AWOTCIridarPerkPack
+ModEditPackages=WOTCIridarPerkPack2
+ModEditPackages=WOTCIridarPerkPackFoxcom
+ModEditPackages=WOTCIridarPerkPackBountyHunter
+ModEditPackages=WOTCIridarPerkPackSkirmisher
+ModEditPackages=WOTCIridarPerkPackTemplar
+ModEditPackages=WOTCIridarPerkPackClassRework