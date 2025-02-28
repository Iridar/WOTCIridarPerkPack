class X2AbilityToHitCalc_Volt extends X2AbilityToHitCalc_StandardAim;

function InternalRollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, bool bIsPrimaryTarget, const out AbilityResultContext ResultContext, out EAbilityHitResult Result, out ArmorMitigationResults ArmorMitigated, out int HitChance)
{
	local int i, RandRoll, Current, ModifiedHitChance;
	local EAbilityHitResult DebugResult, ChangeResult;
	local ArmorMitigationResults Armor;
	local XComGameState_Unit TargetState, UnitState;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local bool bRolledResultIsAMiss, bModHitRoll;
	local bool HitsAreCrits;
	local string LogMsg;
	local ETeam CurrentPlayerTeam;
	local ShotBreakdown m_ShotBreakdown;

	// Don't modify primary target hit calculation for ArcWave'd Rend and Soul Shot.
	if (bIsPrimaryTarget)
	{
		switch (kAbility.GetMyTemplateName())
		{
		case 'IRI_TM_ArcWave':
		case 'IRI_TM_SoulShot_ArcWave':
			super.InternalRollForAbilityHit(kAbility, kTarget, bIsPrimaryTarget, ResultContext, Result, ArmorMitigated, HitChance);
			return;
		default:
			break;
		}
	}

	History = `XCOMHISTORY;

	`log("===" $ GetFuncName() $ "===", true, 'XCom_HitRolls');
	`log("Attacker ID:" @ kAbility.OwnerStateObject.ObjectID, true, 'XCom_HitRolls');
	`log("Target ID:" @ kTarget.PrimaryTarget.ObjectID, true, 'XCom_HitRolls');
	`log("Ability:" @ kAbility.GetMyTemplate().LocFriendlyName @ "(" $ kAbility.GetMyTemplateName() $ ")", true, 'XCom_HitRolls');

	ArmorMitigated = Armor;     //  clear out fields just in case
	HitsAreCrits = bHitsAreCrits;
	if (`CHEATMGR != none)
	{
		if (`CHEATMGR.bForceCritHits)
			HitsAreCrits = true;

		if (`CHEATMGR.bNoLuck)
		{
			`log("NoLuck cheat forcing a miss.", true, 'XCom_HitRolls');
			Result = eHit_Miss;			
			return;
		}
		if (`CHEATMGR.bDeadEye)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
			if( !`CHEATMGR.bXComOnlyDeadEye || !UnitState.ControllingPlayerIsAI() )
			{
				`log("DeadEye cheat forcing a hit.", true, 'XCom_HitRolls');
				Result = eHit_Success;
				if( HitsAreCrits )
					Result = eHit_Crit;
				return;
			}
		}
	}

	HitChance = GetHitChance_Volt(kAbility, kTarget, m_ShotBreakdown, true); // Iridar - use a custom GetHitChance function.

	RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
	Result = eHit_Miss;

	`log("=" $ GetFuncName() $ "=", true, 'XCom_HitRolls');
	`log("Final hit chance:" @ HitChance, true, 'XCom_HitRolls');
	`log("Random roll:" @ RandRoll, true, 'XCom_HitRolls');
	//  GetHitChance fills out m_ShotBreakdown and its ResultTable
	for (i = 0; i < eHit_Miss; ++i)     //  If we don't match a result before miss, then it's a miss.
	{
		Current += m_ShotBreakdown.ResultTable[i];
		DebugResult = EAbilityHitResult(i);
		`log("Checking table" @ DebugResult @ "(" $ Current $ ")...", true, 'XCom_HitRolls');
		if (RandRoll < Current)
		{
			Result = EAbilityHitResult(i);
			`log("MATCH!", true, 'XCom_HitRolls');
			break;
		}
	}	
	if (HitsAreCrits && Result == eHit_Success)
		Result = eHit_Crit;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));

	// Iridar - force crits against psionic units
	if (TargetState != none && TargetState.IsPsionic())
	{
		Result = eHit_Crit;
		return;
	}
	// Iridar - end
	
	if (UnitState != none && TargetState != none)
	{
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				if (EffectState.GetX2Effect().ChangeHitResultForAttacker(UnitState, TargetState, kAbility, Result, ChangeResult))
				{
					`log("Effect" @ EffectState.GetX2Effect().FriendlyName @ "changing hit result for attacker:" @ ChangeResult,true,'XCom_HitRolls');
					Result = ChangeResult;
				}
			}
		}
		foreach TargetState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				if (EffectState.GetX2Effect().ChangeHitResultForTarget(EffectState, UnitState, TargetState, kAbility, bIsPrimaryTarget, Result, ChangeResult))
				{
					`log("Effect" @ EffectState.GetX2Effect().FriendlyName @ "changing hit result for target:" @ ChangeResult, true, 'XCom_HitRolls');
					Result = ChangeResult;
				}
			}
		}
	}
	
	// Aim Assist (miss streak prevention)
	bRolledResultIsAMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result);
	
	//  reaction  fire shots and guaranteed hits do not get adjusted for difficulty
	if( UnitState != None &&
		!bReactionFire &&
		!bGuaranteedHit && 
		m_ShotBreakdown.SpecialGuaranteedHit == '')
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
		CurrentPlayerTeam = PlayerState.GetTeam();

		if( bRolledResultIsAMiss && CurrentPlayerTeam == eTeam_XCom )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, TargetState, HitChance);

			if( RandRoll < ModifiedHitChance )
			{
				Result = eHit_Success;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an XCom MISS to become a HIT!", true, 'XCom_HitRolls');
			}
		}
		else if( !bRolledResultIsAMiss && (CurrentPlayerTeam == eTeam_Alien || CurrentPlayerTeam == eTeam_TheLost) )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, TargetState, HitChance);

			if( RandRoll >= ModifiedHitChance )
			{
				Result = eHit_Miss;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an Alien HIT to become a MISS!", true, 'XCom_HitRolls');
			}
		}
	}

	`log("***HIT" @ Result, !bRolledResultIsAMiss, 'XCom_HitRolls');
	`log("***MISS" @ Result, bRolledResultIsAMiss, 'XCom_HitRolls');

	if (TargetState != none)
	{
		//  Check for Lightning Reflexes
		if (bReactionFire && TargetState.bLightningReflexes && !bRolledResultIsAMiss)
		{
			Result = eHit_LightningReflexes;
			`log("Lightning Reflexes triggered! Shot will miss.", true, 'XCom_HitRolls');
		}
	}	

	if (UnitState != none && TargetState != none)
	{
		LogMsg = class'XLocalizedData'.default.StandardAimLogMsg;
		LogMsg = repl(LogMsg, "#Shooter", UnitState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Target", TargetState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Ability", kAbility.GetMyTemplate().LocFriendlyName);
		LogMsg = repl(LogMsg, "#Chance", bModHitRoll ? ModifiedHitChance : HitChance);
		LogMsg = repl(LogMsg, "#Roll", RandRoll);
		LogMsg = repl(LogMsg, "#Result", class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[Result]);
		`COMBATLOG(LogMsg);
	}
}


protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local XComGameState_Unit TargetState;
	local ShotBreakdown EmptyShotBreakdown;

	// Pretend to not make changes for these two abilities.
	// This function will be called for these two abilities only for primary targets.
	switch (kAbility.GetMyTemplateName())
	{
	case 'IRI_TM_ArcWave':
	case 'IRI_TM_SoulShot_ArcWave':
		return super.GetHitChance(kAbility, kTarget, m_ShotBreakdown, bDebugLog);
	default:
		break;
	}

	//  reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;

	// We're guaranteed hit.
	super(X2AbilityToHitCalc).AddModifier(100, kAbility.GetMyTemplate().LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);

	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	if (TargetState != none && TargetState.IsPsionic())
	{
		// And guaranteed crit against psionics.
		super(X2AbilityToHitCalc).AddModifier(100, kAbility.GetMyTemplate().LocFriendlyName, m_ShotBreakdown, eHit_Crit, bDebugLog);
	}

	FinalizeHitChance(m_ShotBreakdown, bDebugLog);

	return m_ShotBreakdown.FinalHitChance;
}

// Used for everything that is NOT primary target of Arc Wave'd Rend and Soul Shot.
private function int GetHitChance_Volt(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local XComGameState_Unit TargetState;
	local ShotBreakdown EmptyShotBreakdown;

	//  reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;

	// We're guaranteed hit.
	super(X2AbilityToHitCalc).AddModifier(100, kAbility.GetMyTemplate().LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);

	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	if (TargetState != none && TargetState.IsPsionic())
	{
		// And guaranteed crit against psionics.
		super(X2AbilityToHitCalc).AddModifier(100, kAbility.GetMyTemplate().LocFriendlyName, m_ShotBreakdown, eHit_Crit, bDebugLog);
	}

	FinalizeHitChance(m_ShotBreakdown, bDebugLog);

	return m_ShotBreakdown.FinalHitChance;
}

defaultproperties
{
	bGuaranteedHit = true
	bAllowCrit = false
}
