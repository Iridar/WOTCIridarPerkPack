class X2UnifiedProjectile_ThunderLance extends X2UnifiedProjectile;

/*
ConfigureNewProjectile
SetupVolley
AddProjectileVolley Adding new volley: X2UnifiedProjectile_ThunderLance
Tick BEGIN TICKING
FireProjectileInstance Running 0
*/

var private int		LocIndex;
var private float	LocfDeltaT;
var private bool	LocbShowImpactEffects;
//var private bool bLogged;

const ImpactDelay = 2.0f; // # Impact Delay # 

function DoMainImpact(int Index, float fDeltaT, bool bShowImpactEffects)
{
	LocIndex = Index;
	LocfDeltaT = fDeltaT;
	LocbShowImpactEffects = bShowImpactEffects;

	//`AMLOG("RUNNING:" @ LocIndex @ LocfDeltaT @ LocbShowImpactEffects);

	SetTimer(ImpactDelay, false, nameof(DoMainImpactDelayed)); // # Impact Delay # 
}
private function DoMainImpactDelayed()
{
	//`AMLOG("PLAY IMPACT:" @ LocIndex @ LocfDeltaT @ LocbShowImpactEffects);

	super.DoMainImpact(LocIndex, LocfDeltaT, LocbShowImpactEffects);
}

/*
function SetupVolley()
{
	`AMLOG("Running");
	super.SetupVolley();
}

function ConfigureNewProjectile(X2Action_Fire InFireAction, 
								AnimNotify_FireWeaponVolley InVolleyNotify,
								XComGameStateContext_Ability AbilityContext,
								XComWeapon InSourceWeapon)
{
	`AMLOG("Running");
	super.ConfigureNewProjectile(InFireAction, InVolleyNotify, AbilityContext, InSourceWeapon);
}

function FireProjectileInstance(int Index)
{
	`AMLOG("Running" @ Index); 
	super.FireProjectileInstance(Index);
}

state Executing
{
	event BeginState(Name PreviousStateName)
	{		
		SetupVolley();
	}

	event EndState(Name PreviousStateName)
	{
		
	}

	simulated event Tick( float fDeltaT )
	{
		local int Index, i;
		local bool bAllProjectilesDone;

		local bool bShouldEnd, bShouldUpdate, bProjectileEffectsComplete, bStruckTarget;
		local float timeDifferenceForRecoil;
		local float originalfDeltaT;

		if (!bLogged)
		{
			`AMLOG("BEGIN TICKING");
			bLogged = true;
		}

		originalfDeltaT = fDeltaT;
		bAllProjectilesDone = true; //Set to false if any projectiles are 1. still to be created 2. being created 3. still in flight w. effects

		for( Index = 0; Index < Projectiles.Length; ++Index )
		{

			//Update existing projectiles, fire any projectiles that are pending
			if( Projectiles[Index].bFired )
			{
				if( OrdnanceType == class'X2TargetingMethod_MECMicroMissile'.default.OrdnanceTypeName )
				{
					//Travel Speed for Micromissile is the scalar value of how a gravity thrown bomb would be like
					 fDeltaT = Projectiles[Index].ProjectileElement.TravelSpeed * originalfDeltaT;
				}

				Projectiles[ Index ].ActiveTime += fDeltaT;
				if (!Projectiles[ Index ].bWaitingToDie)
				{
					Projectiles[ Index ].AliveTime += fDeltaT;
				}

				// Traveling projectiles should be forcibly deactivated once they've reaced their destination (and the trail has caught up).
				if(Projectiles[Index].ParticleEffectComponent != None && (Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_Traveling) && (WorldInfo.TimeSeconds >= (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime)))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
				}

				bStruckTarget = StruckTarget(Index, fDeltaT);
				bShouldEnd = (WorldInfo.TimeSeconds > Projectiles[Index].EndTime) && !Projectiles[Index].bWaitingToDie;
				bShouldEnd = bShouldEnd || bStruckTarget;

				bShouldUpdate = Projectiles[Index].ProjectileElement.bAttachToSource || Projectiles[Index].ProjectileElement.bAttachToTarget ||
					((Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_RangedConstant) && (!Projectiles[Index].bConstantComplete));

				bProjectileEffectsComplete = (Projectiles[ Index ].ParticleEffectComponent == none || Projectiles[ Index ].ParticleEffectComponent.HasCompleted( ));

				if (bShouldEnd)
				{
					//The projectile has reached its destination / conclusion. Begin the destruction process.
					EndProjectileInstance( Index, fDeltaT );
				}

				if (ProjectileShouldImpact(Index))
				{
					if(bShouldEnd)
					{
						DoMainImpact(Index, fDeltaT, bStruckTarget); //Impact(s) that should play when the shot "reaches the target"
					}
					else if (!Projectiles[Index].bWaitingToDie)
					{
						DoTransitImpact(Index, fDeltaT); //Impact(s) that should play while the shot is in transit
					}					
				}

				ProcessReturn( Index );

				if (!bShouldEnd || bShouldUpdate || bStruckTarget)
				{
					//The projectile is in flight or a mode that wants continued position updates after ending
					UpdateProjectileDistances( Index, fDeltaT );
				}

				// always update the trail
				UpdateProjectileTrail( Index );

				bAllProjectilesDone = bAllProjectilesDone && bProjectileEffectsComplete && Projectiles[Index].bWaitingToDie;

				// A fallback to catch bad projectile effects that are lasting too long (except for the constants)
				if (!bProjectileEffectsComplete && (WorldInfo.TimeSeconds > (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime + 10.0)) && (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_RangedConstant))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
					//`RedScreen("Projectile " $ Index  $ " vfx for weapon " $ FireAction.SourceItemGameState.GetMyTemplateName() $ " still hasn't completed after 10 seconds past expected completion time");
				}

				//DebugParamsOut( Index );
			}
			//Adding Recoil from firing Chang You 2015-6-14
			else if(!Projectiles[Index].bRecoilFromFiring)
			{
				//start moving the aim to the missed position to simulate recoil
				if(WorldInfo.TimeSeconds >= Projectiles[Index].StartTime - 0.1f)
				{
					//if the first shot is too early, we need to readjust all the following shots to a later time.
					if(bFirstShotInVolley)
					{
						timeDifferenceForRecoil = Projectiles[Index].StartTime - WorldInfo.TimeSeconds;
						for( i = 0; i < Projectiles.Length; ++i )
						{
							Projectiles[i].StartTime += 0.1f - Max(timeDifferenceForRecoil, 0.0f);
						}
						bFirstShotInVolley = false;
					}
					RecoilFromFiringProjectile(Index);
					Projectiles[Index].bRecoilFromFiring = true;
				}
				bAllProjectilesDone = false;
			}
			else if( WorldInfo.TimeSeconds >= Projectiles[Index].StartTime )
			{
				bAllProjectilesDone = false;
				FireProjectileInstance(Index);
				--Index; // reprocess this projectile to do all the updates so that lifetime accumulators and timers are in reasonable sync
			}
			else
			{
				//If there are unfired projectiles...
				bAllProjectilesDone = false;
			}
		}

		if( bSetupVolley && bAllProjectilesDone )
		{		
			for( Index = 0; Index < Projectiles.Length; ++Index )
			{
				Projectiles[ Index ].SourceAttachActor.Destroy( );
				Projectiles[ Index ].TargetAttachActor.Destroy( );
			}
			Destroy( );
		}
	}

Begin:
}*/
/*
const ProjectileImpactDelay = 2.0f;

var private float PlayingTimeAfterShouldEnd;
var private bool  bProcessingImpactDelay;
var private float totalplaytime;
var private bool  bDelayProcessed;

state Executing
{
	event BeginState(Name PreviousStateName)
	{		
		SetupVolley();
	}

	event EndState(Name PreviousStateName)
	{
		
	}

	simulated event Tick( float fDeltaT )
	{
		local int Index, i;
		local bool bAllProjectilesDone;
		local bool bShouldEnd, bShouldUpdate, bProjectileEffectsComplete, bStruckTarget;
		local float timeDifferenceForRecoil;

		`AMLOG(totalplaytime);
		totalplaytime += fDeltaT;

		if (!bDelayProcessed && bProcessingImpactDelay)
		{
			PlayingTimeAfterShouldEnd += fDeltaT;
			if (PlayingTimeAfterShouldEnd < ProjectileImpactDelay)
			{
				`AMLOG(`ShowVar(PlayingTimeAfterShouldEnd));
				return;
			}
			bProcessingImpactDelay = false;
			bDelayProcessed = true;
			`AMLOG("=== FINISHED PROCESSING DELAY ===");
		}

		bAllProjectilesDone = true; //Set to false if any projectiles are 1. still to be created 2. being created 3. still in flight w. effects

		for( Index = 0; Index < Projectiles.Length; ++Index )
		{

			//Update existing projectiles, fire any projectiles that are pending
			if( Projectiles[Index].bFired )
			{
				Projectiles[ Index ].ActiveTime += fDeltaT;
				if (!Projectiles[ Index ].bWaitingToDie)
				{
					Projectiles[ Index ].AliveTime += fDeltaT;
				}

				// Traveling projectiles should be forcibly deactivated once they've reaced their destination (and the trail has caught up).
				if(Projectiles[Index].ParticleEffectComponent != None && (Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_Traveling) && (WorldInfo.TimeSeconds >= (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime)))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
				}

				bStruckTarget = StruckTarget(Index, fDeltaT);
				bShouldEnd = (WorldInfo.TimeSeconds > Projectiles[Index].EndTime) && !Projectiles[Index].bWaitingToDie;
				bShouldEnd = bShouldEnd || bStruckTarget;

				if (!bDelayProcessed && bShouldEnd)
				{
					`AMLOG("=== BEGIN PROCESSING DELAY ===");
					bProcessingImpactDelay = true;
					return;
				}

				bShouldUpdate = Projectiles[Index].ProjectileElement.bAttachToSource || Projectiles[Index].ProjectileElement.bAttachToTarget ||
					((Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_RangedConstant) && (!Projectiles[Index].bConstantComplete));

				bProjectileEffectsComplete = (Projectiles[ Index ].ParticleEffectComponent == none || Projectiles[ Index ].ParticleEffectComponent.HasCompleted( ));

				if (bShouldEnd)
				{
					//The projectile has reached its destination / conclusion. Begin the destruction process.
					EndProjectileInstance( Index, fDeltaT );
				}

				if (ProjectileShouldImpact(Index))
				{
					if(bShouldEnd)
					{
						DoMainImpact(Index, fDeltaT, bStruckTarget); //Impact(s) that should play when the shot "reaches the target"
					}
					else if (!Projectiles[Index].bWaitingToDie)
					{
						DoTransitImpact(Index, fDeltaT); //Impact(s) that should play while the shot is in transit
					}					
				}

				ProcessReturn( Index );

				if (!bShouldEnd || bShouldUpdate || bStruckTarget)
				{
					//The projectile is in flight or a mode that wants continued position updates after ending
					UpdateProjectileDistances( Index, fDeltaT );
				}

				// always update the trail
				UpdateProjectileTrail( Index );

				bAllProjectilesDone = bAllProjectilesDone && bProjectileEffectsComplete && Projectiles[Index].bWaitingToDie;

				// A fallback to catch bad projectile effects that are lasting too long (except for the constants)
				if (!bProjectileEffectsComplete && (WorldInfo.TimeSeconds > (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime + 10.0)) && (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_RangedConstant))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
					//`RedScreen("Projectile " $ Index  $ " vfx for weapon " $ FireAction.SourceItemGameState.GetMyTemplateName() $ " still hasn't completed after 10 seconds past expected completion time");
				}

				//DebugParamsOut( Index );
			}
			//Adding Recoil from firing Chang You 2015-6-14
			else if(!Projectiles[Index].bRecoilFromFiring)
			{
				//start moving the aim to the missed position to simulate recoil
				if(WorldInfo.TimeSeconds >= Projectiles[Index].StartTime - 0.1f)
				{
					//if the first shot is too early, we need to readjust all the following shots to a later time.
					if(bFirstShotInVolley)
					{
						timeDifferenceForRecoil = Projectiles[Index].StartTime - WorldInfo.TimeSeconds;
						for( i = 0; i < Projectiles.Length; ++i )
						{
							Projectiles[i].StartTime += 0.1f - Max(timeDifferenceForRecoil, 0.0f);
						}
						bFirstShotInVolley = false;
					}
					RecoilFromFiringProjectile(Index);
					Projectiles[Index].bRecoilFromFiring = true;
				}
				bAllProjectilesDone = false;
			}
			else if( WorldInfo.TimeSeconds >= Projectiles[Index].StartTime )
			{
				bAllProjectilesDone = false;
				FireProjectileInstance(Index);
				--Index; // reprocess this projectile to do all the updates so that lifetime accumulators and timers are in reasonable sync
			}
			else
			{
				//If there are unfired projectiles...
				bAllProjectilesDone = false;
			}
		}

		if( bSetupVolley && bAllProjectilesDone )
		{		
			for( Index = 0; Index < Projectiles.Length; ++Index )
			{
				Projectiles[ Index ].SourceAttachActor.Destroy( );
				Projectiles[ Index ].TargetAttachActor.Destroy( );
			}
			Destroy( );
		}
	}

Begin:
}
*/