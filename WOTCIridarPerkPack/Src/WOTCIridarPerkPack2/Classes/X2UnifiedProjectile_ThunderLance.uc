class X2UnifiedProjectile_ThunderLance extends X2UnifiedProjectile;

/* Order of calling functions in X2UnifiedProjectile:
ConfigureNewProjectile
SetupVolley
AddProjectileVolley Adding new volley: X2UnifiedProjectile_ThunderLance
Tick BEGIN TICKING
FireProjectileInstance Running 0
*/

var private float	LocfDeltaT;
var private bool	LocbShowImpactEffects;

var private float	LocfDeltaT_EndProjectile;

const ImpactDelay = 2.0f; // # Impact Delay # 

function DoMainImpact(int Index, float fDeltaT, bool bShowImpactEffects)
{
	LocfDeltaT = fDeltaT;
	LocbShowImpactEffects = bShowImpactEffects;

	SetTimer(ImpactDelay, false, nameof(DoMainImpactDelayed));
	SetTimer(1.0f, false, nameof(PlayGrenadePullSound));

	// Main projectile gets destroyed prematurely

	`AMLOG("IMPACT!");

	Projectiles[0].TargetAttachActor.PlayAkEvent(AkEvent(`CONTENT.RequestGameArchetype("XPACK_SoundCharacterFX.Skirmisher_Whiplash_Impact")), , , , Projectiles[0].InitialTargetLocation);
}

private function PlayGrenadePullSound()
{
	Projectiles[0].TargetAttachActor.PlayAkEvent(AkEvent(`CONTENT.RequestGameArchetype("SoundX2CharacterFX.Granade_Pull")), , , , Projectiles[0].InitialTargetLocation);
}

private function DoMainImpactDelayed()
{
	super.DoMainImpact(0, LocfDeltaT + ImpactDelay, LocbShowImpactEffects);

	// This will detonate the grenade projectiles.
	`XEVENTMGR.TriggerEvent('IRI_ThunderLanceImpactEvent');

	`AMLOG("DETONATION!");
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
					Projectiles[ Index ].ParticleEffectComponent = none;
				}

				bStruckTarget = StruckTarget(Index, fDeltaT);
				bShouldEnd = (WorldInfo.TimeSeconds > Projectiles[Index].EndTime) && !Projectiles[Index].bWaitingToDie;

				`AMLOG(`ShowVar(bShouldEnd) @ `ShowVar(bStruckTarget) @ `ShowVar(WorldInfo.TimeSeconds) @ `ShowVar(Projectiles[Index].EndTime));
				
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