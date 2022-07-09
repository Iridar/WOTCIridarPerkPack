X2ModBuildCommon v1.2.1 successfully installed. 
Edit .scripts\build.ps1 if you want to enable cooking. 
 
Enjoy making your mod, and may the odds be ever in your favor. 
 
 
Created with Enhanced Mod Project Template v1.0 
 
Get news and updates here: 
https://github.com/Iridar/EnhancedModProjectTemplate 



TODO: 
- mod desc
- Terminate breaks on scamper, in general works like shit?


XComTemplateCreator.ini
;[WOTCIridarTemplateMaster.X2Item_TemplateCreator]

;+Create_X2ItemTemplate = (C = "X2WeaponTemplate", T = "IRI_BountyPistol_CV")




[WOTC] Iridar's Perk Pack

This mod adds various abilities that can be used by other mods that add soldier classes, items or other ways for soldiers to gain abilities. By itself this mod does absolutely nothing. In the future, I intend to put most of my new abilities into this mod, as it will make it more convenient for different mods to reuse the abilities without duplicating code.

Perks in this mod are currently split into the following groups:[list]
[*] [b][url=]Bounty Hunter:[/url][/b] 21 perks.
[*] [b][url=]Templar:[/url][/b]: 1 perk.
[/list]
Click on the group name to see the list of abilities in a group.

[h1]REQUIREMENTS[/h1]
[list][*] [url=https://steamcommunity.com/workshop/filedetails/?id=1134256495][b]X2 WOTC Community Highlander[/b][/url]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2363075446][WOTC] Iridar's Template Master - Core[/url][/b][/list]
Safe to add mid-campaign.

[h1]COMPATIBILITY[/h1]

Perks in this mod are already configured for [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2133397762]Ability To Slot Reassignment[/url][/b] and [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1280477867]Musashis RPG Overhaul[/url][/b]. Make sure to subscribe to [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2569592723][WOTC] Musashi's Mods Fixes[/url][/b] if you use either of these mods.

This mod should not conflict with anything, it has no mod class overrides and makes no changes to other abilities or items that could cause compatibility issues, except for:[list]
[*] Adds suppression animations to Vektor Rifles.[/list]

[h1]CONFIGURATION[/h1]

Many aspects of this mod are configurable through configuration files in:
[code]..\steamapps\workshop\content\268500\2571476425\Config\[/code]
Each group of abilities will have its own set of configuration files in its own folder.
Some of the abilities' properties can be configured through XComGame.ini in the group's config folder. Such properties are highlighted in-game with various colors.

[h1]CREDITS[/h1]

Thanks to [b]Mitzruti[/b] for porting [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2094355561]Chimera Squad Ability Icons[/url][/b], some of those icons are used in this mod.
Thanks to [b]NeIVIeSiS[/b] for making some of the ability icons in this mod.
Thanks to [b]XCOMrades[/b] for helping me develop and finance this mod, and for providing Russian translation.

Please [b][url=https://www.patreon.com/Iridar]support me on Patreon[/url][/b] if you require tech support, have a suggestion for a feature, or simply wish to help me create more awesome mods.

Iridar's Bounty Hunter Abilities

Iridar's Templar Abilities

[b]Soul Shot[/b]
Template name: IRI_TM_SoulShot
This ability needs to be attached to a weapon with an ExtraDamage with the damage tag: "IRI_TM_SoulShot". Animations expect the caster to have primary Shard Gauntlets.

A powerful ranged attack that scales with Focus and generates Focus on kills. 2 turn cooldown.
