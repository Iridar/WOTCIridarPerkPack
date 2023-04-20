class X2Action_ApplyWeaponDamageToTerrain_NoFlinch extends X2Action_ApplyWeaponDamageToTerrain;

// Same as original, but does not flinch nearby units.

simulated state Executing
{
	simulated event BeginState(name nmPrevState)
	{
		super.BeginState(nmPrevState);
	}

	simulated function SpawnExplosionParticles()
	{
		local ParticleSystem Explosion;

		Explosion = ParticleSystem(DynamicLoadObject("FX_Explosion_Grenade_Launcher.P_Grenade_Launcher_Explosion", class'ParticleSystem'));
		WorldInfo.MyEmitterPool.SpawnEmitter(Explosion, DamageEvent.HitLocation);
	}

	simulated function ShowDamagePopup()
	{	
		local XComDestructibleActor DestructibleActor;
		local Vector DisplayLocation;
		local UIUnitFlag UnitFlags;
		local XComPresentationLayer PresentationLayer;

		PresentationLayer = `PRES;

		if(TargetedDestructible != none)
		{
			DestructibleActor = XComDestructibleActor(TargetedDestructible.GetVisualizer());
			if(DestructibleActor != None)
			{
				if(DestructibleActor.SkipDamageFlyovers)
					return;

				DisplayLocation = DestructibleActor.GetTargetingFocusLocation();

				class'UIWorldMessageMgr'.static.DamageDisplay(DisplayLocation, DestructibleActor.GetVisualizedStateReference(), "", eTeam_All, , DamageEvent.DamageAmount);

				UnitFlags = `PRES.m_kUnitFlagManager.GetFlagForObjectID( DestructibleActor.ObjectID );
				if (UnitFlags != none)
					UnitFlags.RespondToNewGameState(StateChangeContext.GetLastStateInInterruptChain( ), false);
			}
		}

		PresentationLayer.m_kUnitFlagManager.RealizeCover( -1, StateChangeContext.AssociatedState.HistoryIndex );
	}

	// REMOVED
	/*
	function NearbyUnitsUpdateStance()
	{
		
		
		local XComGameState_Unit UnitState;
		local XGUnit UnitVisualizer;
		local XComGameStateHistory History;
		local float DistanceFromHitLocation;
		local float CheckForStanceUpdateRadius;
		local float FlinchRadius;		
		local X2Action CurrentVisualizerAction;

		CheckForStanceUpdateRadius = DamageEvent.DamageRadius + class'XComWorldData'.const.WORLD_StepSize * DamageInfluenceRadiusMultiplier;

		//Threshold for cosmetic / incidental environmental damage such as door kicks, window smashes, bullets passing through things. We don't want gratuitous flinching.
		if(DamageEvent.DamageRadius <= 16.0f) 
		{
			FlinchRadius = DamageEvent.DamageRadius + (class'XComWorldData'.const.WORLD_StepSize * 2.0f);
		}
		else
		{
			FlinchRadius = CheckForStanceUpdateRadius;
		}
		

		History = `XCOMHISTORY;
		VisualizationMgr = `XCOMVISUALIZATIONMGR;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if(UnitState.IsAlive() && !UnitState.bRemovedFromPlay)
			{
				UnitVisualizer = XGUnit(UnitState.GetVisualizer());
				if (UnitVisualizer != None && UnitVisualizer.GetPawn().Physics != PHYS_RigidBody)
				{
					DistanceFromHitLocation = VSize(UnitVisualizer.Location - DamageEvent.HitLocation);
					if(DistanceFromHitLocation <= CheckForStanceUpdateRadius)
					{
						//Notify nearby units that they may need to change their stance
						UnitVisualizer.IdleStateMachine.CheckForStanceUpdateOnIdle();

						//If the unit isn't doing anything, play a flinch
						CurrentVisualizerAction = VisualizationMgr.GetCurrentActionForVisualizer(UnitVisualizer);
						if( (CurrentVisualizerAction == none || CurrentVisualizerAction.bCompleted) && DistanceFromHitLocation <= FlinchRadius)
						{
							UnitVisualizer.IdleStateMachine.PerformFlinch();
						}
					}
				}
			}
		}
	}*/

	function InitiateCameraShakeAndDistort()
	{		
		local string ShakeAnim;
		local float Intensity;

		if(DamageEvent.DamageTiles.Length < default.CameraShakeTileThreshold_Medium)
		{
			ShakeAnim = default.CameraShake_Small;
			Intensity = default.CameraShakeIntensity_Small;
		}
		else if(DamageEvent.DamageTiles.Length < default.CameraShakeTileThreshold_Large)
		{
			ShakeAnim = default.CameraShake_Medium;
			Intensity = default.CameraShakeIntensity_Medium;
		}
		else
		{
			ShakeAnim = default.CameraShake_Large;
			Intensity = default.CameraShakeIntensity_Large;
		}
				
		`CAMERASTACK.PlayCameraAnim(ShakeAnim, 1.0f, Intensity, false, true);
		`PRES.StartDistortUI(2.5f);
	}


	simulated event Tick(float fDeltaT)
	{
		if (bRequiresTick)
		{
			UpdatePartialTileUpdate(fDeltaT);
		}
		else if (bFinishedTick)
		{
			//foreach DamageEvent.FractureTiles(iterTile)
			//{
			//	//iterTile.Z = 92;
			//	`SHAPEMGR.DrawTile(iterTile, 0, 255, 255, 0.4);
			//}

			if (DamageEvent.DamageTiles.Length > default.CameraShakeTileThreshold_Small)
			{
				InitiateCameraShakeAndDistort();
			}

			`XWORLD.HandleDestructionVisuals(DamageEvent);
		}
	}

Begin:

	if(DamageEvent != none)
	{
		//NearbyUnitsUpdateStance(); // REMOVED

		if (bRequiresTick)
		{
			while (!bFinishedTick)
			{
				sleep(0.01f);
			}
		}
		else
		{
			if (DamageEvent.DamageTiles.Length > default.CameraShakeTileThreshold_Small)
			{
				InitiateCameraShakeAndDistort();
			}

			`XWORLD.HandleDestructionVisuals(DamageEvent);

			`XEVENTMGR.TriggerEvent('HandleDestructionVisuals', self, self, none);			
		}

		ShowDamagePopup();

		// temporary until we figure out how damage is going to be visualized, spawn
		// an explosion for explosion damage
		if(DamageEvent.bSpawnExplosionVisuals)
		{
			SpawnExplosionParticles();
		}
	}

	CompleteAction();
}
