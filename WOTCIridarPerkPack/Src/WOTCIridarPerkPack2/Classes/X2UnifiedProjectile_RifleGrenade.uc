class X2UnifiedProjectile_RifleGrenade extends X2UnifiedProjectile;

// This custom projectile is used for the Rifle Grenade visualization.
// 1. It makes the projectile actually look like a rifle grenade, which I couldn't do via normal means for some reason.
// 2. It alters the generated grenade path to remove the grenade roll and bouncing from it, and do other adjustments to it.

function FireProjectileInstance(int Index)
{		
	//Hit location and hit location modifying vectors
	local Vector SourceLocation;
	local Vector HitLocation;
	local Vector HitNormal;
	local Vector AimLocation;
	local Vector TravelDirection;
	local Vector TravelDirection2D;
	local float DistanceTravelled;	
	local Vector ParticleParameterDistance;
	local Vector ParticleParameterTravelledDistance;
	local Vector ParticleParameterTrailDistance;
	local EmitterInstanceParameterSet EmitterParameterSet; //The parameter set to use for the projectile
	local float SpreadScale;
	local Vector SpreadValues;
	local XGUnit TargetVisualizer;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local bool bAllowSpread;
	local array<ProjectileTouchEvent> OutTouchEvents;
	local float HorizontalSpread, VerticalSpread, SpreadLerp;
	local XKeyframe LastGrenadeFrame, LastGrenadeFrame2;
	local Vector GrenadeImpactDirection;
	local TraceHitInfo GrenadeTraceInfo;
	local XComGameState_Unit ShooterState;

	local SkeletalMeshActorSpawnable CreateSkeletalMeshActor;
	local XComAnimNodeBlendDynamic tmpNode;
	local CustomAnimParams AnimParams;
	local AnimSequence FoundAnimSeq;
	local AnimNodeSequence PlayingSequence;

	local float TravelDistance;
	local bool bDebugImpactEvents;
	local bool bCollideWithUnits;

	local vector AdjustedHitLocation;

	// Variables for Issue #10
	local XComLWTuple Tuple;

	//local ParticleSystem AxisSystem;
	//local ParticleSystemComponent PSComponent;

	ShooterState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( SourceAbility.InputContext.SourceObject.ObjectID ) );
	AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID( AbilityContextAbilityRefID ) );
	AbilityTemplate = AbilityState.GetMyTemplate( );
	
	SetupAim( Index, AbilityState, AbilityTemplate, SourceLocation, AimLocation);


	if (SourceAbility.IsResultContextMiss()) 
	{
		`LOG("Firing missed projectile at:" @ StoredInputContext.TargetLocations[0],, 'WOTCMoreSparkWeapons');
		AimLocation = StoredInputContext.TargetLocations[0];
	}

	bProjectileFired = true;

	//Calculate the travel direction for this projectile
	TravelDirection = AimLocation - SourceLocation;
	TravelDistance = VSize(TravelDirection);
	TravelDirection2D = TravelDirection;
	TravelDirection2D.Z = 0.0f;
	TravelDirection2D = Normal(TravelDirection2D);
	TravelDirection = Normal(TravelDirection);
	
	//If spread values are set, apply them in this block
	bAllowSpread = !Projectiles[Index].ProjectileElement.bTriggerHitReact;

	if(bAllowSpread && Projectiles[Index].ProjectileElement.ApplySpread)
	{
		//If the hit was a critical hit, tighten the spread significantly
		switch (AbilityContextHitResult)
		{
			case eHit_Crit: SpreadScale = Projectiles[Index].ProjectileElement.CriticalHitScale;
				break;
			case eHit_Miss: SpreadScale = Projectiles[Index].ProjectileElement.MissShotScale;
				break;
			default:
				if (AbilityTemplate.bIsASuppressionEffect)
				{
					SpreadScale = Projectiles[Index].ProjectileElement.SuppressionShotScale;
				}
				else
				{
					SpreadScale = 1.0f;
				}
		}

		if (TravelDistance >= Projectiles[Index].ProjectileElement.LongRangeDistance)
		{
			HorizontalSpread = Projectiles[Index].ProjectileElement.LongRangeSpread.HorizontalSpread;
			VerticalSpread = Projectiles[Index].ProjectileElement.LongRangeSpread.VerticalSpread;
		}
		else
		{
			SpreadLerp = TravelDistance / Projectiles[Index].ProjectileElement.LongRangeDistance;

			HorizontalSpread = SpreadLerp * Projectiles[ Index ].ProjectileElement.LongRangeSpread.HorizontalSpread + 
				(1.0f - SpreadLerp) * Projectiles[ Index ].ProjectileElement.ShortRangeSpread.HorizontalSpread;
			VerticalSpread = SpreadLerp * Projectiles[ Index ].ProjectileElement.LongRangeSpread.VerticalSpread + 
				(1.0f - SpreadLerp) * Projectiles[ Index ].ProjectileElement.ShortRangeSpread.VerticalSpread;
		}

		HorizontalSpread *= SpreadScale;
		VerticalSpread *= SpreadScale;

		// convert from full angle spread to half angle spread for the rand computation
		HorizontalSpread /= 2.0f;
		VerticalSpread /= 2.0f;

		// convert from angle measurements to radians
		HorizontalSpread *= DegToRad;
		VerticalSpread *= DegToRad;

		//Apply the spread values - lookup into the precomputed random spread table
		SpreadValues = RandomSpreadValues[ Projectiles[ Index ].VolleyIndex ].SpreadValues[ Projectiles[ Index ].MultipleProjectileIndex ];

		// Randomize the travel direction based on the spread table and scalars
		TravelDirection = VRandCone3( TravelDirection, HorizontalSpread, VerticalSpread, SpreadValues.X, SpreadValues.Y );
	
		//Recalculate aim based on the spread
		AimLocation = SourceLocation + TravelDirection * TravelDistance;
		TravelDirection2D = TravelDirection;
		TravelDirection2D.Z = 0.0f;
		TravelDirection2D = Normal( TravelDirection2D );
	}

	//Build the HitLocation
	bDebugImpactEvents = false;

	if( OrdnanceType != '' )
	{
		//when firing a single projectile, we can just fall back on the targeting path for now, since it would otherwise require re-calculating the trajectory
		Projectiles[Index].GrenadePath = `PRECOMPUTEDPATH;

		Projectiles[Index].GrenadePath.bNoSpinUntilBounce = true;

		//We don't start at the beginning of the path, especially for underhand throws
		Projectiles[Index].AliveTime = FindPathStartTime(Index, SourceLocation);

		HitNormal = -TravelDirection;
		HitLocation = AimLocation;
	}
	else if ((Projectiles[ Index ].ProjectileElement.ReturnsToSource && (AbilityContextHitResult == eHit_Miss)) ||
			 (Projectiles[ Index ].ProjectileElement.bAttachToTarget && (AbilityContextHitResult != eHit_Miss)))
	{
		// if the projectile comes back, only trace out to the aim location and no further		
		`XWORLD.GenerateProjectileTouchList(ShooterState, SourceLocation, AimLocation, OutTouchEvents, bDebugImpactEvents);

		HitLocation = OutTouchEvents[ OutTouchEvents.Length - 1 ].HitLocation;
		HitNormal = OutTouchEvents[OutTouchEvents.Length - 1].HitNormal;
		Projectiles[ Index ].ImpactInfo = OutTouchEvents[ OutTouchEvents.Length - 1 ].TraceInfo;
	}
	else
	{	
		//We want to allow some of the projectiles to go past the target if they don't hit it, so we set up a trace here that will not collide with the target. That way
		//the event list we generate will include impacts behind the target, but only for traveling type projectiles.
		//ranged types should hit the target so that InitialTargetDistance is the distance to the thing being hit.

		bCollideWithUnits = (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_Traveling);

		ProjectileTrace(HitLocation, HitNormal, SourceLocation, TravelDirection, bCollideWithUnits);
		HitLocation = HitLocation + (TravelDirection * 0.0001f); // move us KINDA_SMALL_NUMBER along the direction to be sure and get all the events we want
		`XWORLD.GenerateProjectileTouchList(ShooterState, SourceLocation, HitLocation, OutTouchEvents, bDebugImpactEvents);
		Projectiles[Index].ImpactInfo = OutTouchEvents[OutTouchEvents.Length - 1].TraceInfo;
	}
	
	//Derive the end time from the travel distance and speed if we are not of the grenade type.
	Projectiles[Index].AdjustedTravelSpeed = Projectiles[Index].ProjectileElement.TravelSpeed;      //  initialize to base travel speed
	DistanceTravelled = VSize(HitLocation - SourceLocation);

	//	=======================================================================================================================
	Projectiles[Index].ImpactEvents = StoredInputContext.ProjectileEvents;
	
	
	//Mark this projectile as having been fired
	Projectiles[Index].bFired = true;
	Projectiles[Index].bConstantComplete = false;
	Projectiles[Index].LastImpactTime = 0.0f;

	//Set up the initial source & target location
	Projectiles[Index].InitialSourceLocation = SourceLocation;
	Projectiles[Index].InitialTargetLocation = HitLocation;		
	Projectiles[Index].InitialTargetNormal = HitNormal;
	Projectiles[Index].InitialTravelDirection = TravelDirection;	
	Projectiles[Index].InitialTargetDistance = VSize(AimLocation - Projectiles[Index].InitialSourceLocation);

	TargetVisualizer = XGUnit( `XCOMHISTORY.GetVisualizer( AbilityContextPrimaryTargetID ) );
	if (TargetVisualizer != none)
	{
		Projectiles[Index].VisualizerToTargetOffset = Projectiles[Index].InitialTargetLocation - TargetVisualizer.Location;
	}

	//Create an actor that travels through space using the settings given by the projectile element definition
	if( Projectiles[Index].ProjectileElement.AttachSkeletalMesh == none )
	{
		Projectiles[Index].SourceAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));	
		Projectiles[Index].TargetAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));

		CreateProjectileCollision(Projectiles[Index].TargetAttachActor);
	}
	else
	{
		Projectiles[Index].SourceAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));
		CreateSkeletalMeshActor = Spawn(class'SkeletalMeshActorSpawnable', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));

		// ADDED BY IRIDAR
		CreateSkeletalMeshActor.SkeletalMeshComponent.SetSkeletalMesh(GetProjectileSkeletalMesh());
		// END OF ADDED

		Projectiles[Index].TargetAttachActor = CreateSkeletalMeshActor;

		if (Projectiles[Index].ProjectileElement.CopyWeaponAppearance && SourceWeapon.m_kGameWeapon != none)
		{
			SourceWeapon.m_kGameWeapon.DecorateWeaponMesh(CreateSkeletalMeshActor.SkeletalMeshComponent);
		}
		CreateSkeletalMeshActor.SkeletalMeshComponent.SetAnimTreeTemplate(Projectiles[Index].ProjectileElement.AttachAnimTree);
		CreateSkeletalMeshActor.SkeletalMeshComponent.AnimSets.AddItem(Projectiles[Index].ProjectileElement.AttachAnimSet);
		CreateSkeletalMeshActor.SkeletalMeshComponent.UpdateAnimations();

		CreateProjectileCollision(Projectiles[Index].TargetAttachActor);

		// literally, the only thing that sets this variable is AbilityGrenade - Josh
		if (AbilityState.GetMyTemplate().bHideWeaponDuringFire)
			SourceWeapon.Mesh.SetHidden(true);

		tmpNode = XComAnimNodeBlendDynamic(CreateSkeletalMeshActor.SkeletalMeshComponent.Animations.FindAnimNode('BlendDynamic'));
		if (tmpNode != none)
		{
			AnimParams.AnimName = 'NO_Idle';
			AnimParams.Looping = true;
			tmpNode.PlayDynamicAnim(AnimParams);
		}
	}

	// handy debugging helper, just uncomment this and the declarations at the top
	//	AxisSystem = ParticleSystem( DynamicLoadObject( "FX_Dev_Steve_Utilities.P_Axis_Display", class'ParticleSystem' ) );
	//	PSComponent = new(Projectiles[Index].TargetAttachActor) class'ParticleSystemComponent';
	//	PSComponent.SetTemplate(AxisSystem);
	//	PSComponent.SetAbsolute( false, false, false );
	//	PSComponent.SetTickGroup( TG_EffectsUpdateWork );
	//	PSComponent.SetActive( true );
	//	Projectiles[Index].TargetAttachActor.AttachComponent( PSComponent );

	if( Projectiles[Index].GrenadePath != none )
	{
		Projectiles[Index].GrenadePath.bUseOverrideSourceLocation = true;
		Projectiles[Index].GrenadePath.OverrideSourceLocation = Projectiles[Index].InitialSourceLocation;

		Projectiles[Index].GrenadePath.bUseOverrideTargetLocation = true;

		// ALTERED BY IRIDAR
		// This ability can't miss.
		//if (SourceAbility.IsResultContextMiss())
		//{	
			AdjustedHitLocation = StoredInputContext.TargetLocations[0];
			MaybeUpdateTargetForUnitOnTile(AdjustedHitLocation, StoredInputContext.SourceObject, StoredInputContext.PrimaryTarget);
			Projectiles[Index].GrenadePath.OverrideTargetLocation = AdjustedHitLocation;
			AdjustGrenadePath(Projectiles[Index].GrenadePath, AdjustedHitLocation);
		//}
		//else
		//{
		//	Projectiles[Index].GrenadePath.OverrideTargetLocation = TargetVisualizer.GetTargetingFocusLocation();
		//	AdjustGrenadePath(Projectiles[Index].GrenadePath, TargetVisualizer.GetTargetingFocusLocation());
		//}
		// END OF ALTERED

		//	=======================================================================================================================================
		
		Projectiles[Index].GrenadePath.bUseOverrideTargetLocation = false;
		Projectiles[Index].GrenadePath.bUseOverrideSourceLocation = false;
		Projectiles[Index].EndTime = Projectiles[Index].StartTime + Projectiles[Index].GrenadePath.GetEndTime();
		
		if (Projectiles[ Index ].GrenadePath.iNumKeyframes > 1)
		{
			// get the rough direction of travel at the end of the path.  TravelDirection is from the source to the target
			LastGrenadeFrame = Projectiles[ Index ].GrenadePath.ExtractInterpolatedKeyframe( Projectiles[ Index ].GrenadePath.GetEndTime( ) );
			LastGrenadeFrame2 = Projectiles[ Index ].GrenadePath.ExtractInterpolatedKeyframe( Projectiles[ Index ].GrenadePath.GetEndTime( ) - 0.05f );
			if (VSize( LastGrenadeFrame.vLoc - LastGrenadeFrame2.vLoc ) == 0)
			{
				`redscreen("Grenade path with EndTime and EndTime-.05 with the same point. ~RussellA");
			}

			GrenadeImpactDirection = Normal( LastGrenadeFrame.vLoc - LastGrenadeFrame2.vLoc );

			// don't use the projectile trace, because we don't want the usual minimal arming distance and other features of that trace.
			// really just trying to get the actual surface normal at the point of impact.  HitLocation and AimLocation should basically be the same.
			Trace( HitLocation, HitNormal, AimLocation + GrenadeImpactDirection * 5, AimLocation - GrenadeImpactDirection * 5, true, vect( 0, 0, 0 ), GrenadeTraceInfo );
			Projectiles[Index].ImpactInfo = GrenadeTraceInfo;
		}
		else
		{
			// Not enough keyframes to figure out a direction of travel... a straight up vector as a normal should be a reasonable fallback...
			HitNormal.X = 0.0f;
			HitNormal.Y = 0.0f;
			HitNormal.Z = 1.0f;
		}

		Projectiles[ Index ].InitialTargetNormal = HitNormal;
	}


	Projectiles[ Index ].SourceAttachActor.SetPhysics( PHYS_Projectile );
	Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_Projectile );

	switch( Projectiles[Index].ProjectileElement.UseProjectileType )
	{
	case eProjectileType_Traveling:
		if( Projectiles[Index].GrenadePath == none ) //If there is a grenade path, we move along that
		{
			Projectiles[Index].TargetAttachActor.Velocity = Projectiles[Index].InitialTravelDirection * Projectiles[Index].AdjustedTravelSpeed;
		}
		break;
	case eProjectileType_Ranged:
	case eProjectileType_RangedConstant:
		Projectiles[Index].SourceAttachActor.Velocity = vect(0, 0, 0);
		Projectiles[Index].TargetAttachActor.Velocity = Projectiles[Index].InitialTravelDirection * Projectiles[Index].AdjustedTravelSpeed;
		break;
	}

	if( Projectiles[Index].ProjectileElement.UseParticleSystem != none )
	{
		EmitterParameterSet = Projectiles[Index].ProjectileElement.DefaultParticleSystemInstanceParameterSet;
		if( bWasHit && Projectiles[Index].ProjectileElement.bPlayOnHit && Projectiles[Index].ProjectileElement.PlayOnHitOverrideInstanceParameterSet != none )
		{
			EmitterParameterSet = Projectiles[Index].ProjectileElement.PlayOnHitOverrideInstanceParameterSet;
		}
		else if( !bWasHit && Projectiles[Index].ProjectileElement.bPlayOnMiss && Projectiles[Index].ProjectileElement.PlayOnMissOverrideInstanceParameterSet != none )
		{
			EmitterParameterSet = Projectiles[Index].ProjectileElement.PlayOnMissOverrideInstanceParameterSet;
		}

		//Spawn the effect
		switch(Projectiles[Index].ProjectileElement.UseProjectileType)
		{
		case eProjectileType_Traveling:
			//For this style of projectile, the effect is attached to the moving point in space
			if( EmitterParameterSet != none )
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].TargetAttachActor,,,,
					EmitterParameterSet.InstanceParameters);
			}
			else
			{
				Projectiles[Index].ParticleEffectComponent = 
					WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].TargetAttachActor);
			}
			break;
		case eProjectileType_Ranged:
		case eProjectileType_RangedConstant:
			//For this style of projectile, the point in space is motionless
			if( EmitterParameterSet != none )
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].SourceAttachActor,,,,
					EmitterParameterSet.InstanceParameters);
			}
			else
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].SourceAttachActor);
			}
			break;
		}

		Projectiles[Index].ParticleEffectComponent.SetScale( Projectiles[Index].ProjectileElement.ParticleScale );
		Projectiles[Index].ParticleEffectComponent.OnSystemFinished = OnParticleSystemFinished;

		DistanceTravelled = Min( DistanceTravelled, Projectiles[ Index ].ProjectileElement.MaxTravelDistanceParam );
		//Tells the particle system how far the projectile must travel to reach its target
		ParticleParameterDistance.X = DistanceTravelled;
		ParticleParameterDistance.Y = DistanceTravelled;
		ParticleParameterDistance.Z = DistanceTravelled;
		Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Target_Distance', ParticleParameterDistance);
		Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Target_Distance', DistanceTravelled);

		ParticleParameterDistance.X = DistanceTravelled;
		ParticleParameterDistance.Y = DistanceTravelled;
		ParticleParameterDistance.Z = DistanceTravelled;
		Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Initial_Target_Distance', ParticleParameterDistance );
		Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Initial_Target_Distance', DistanceTravelled );

		//Tells the particle system how far we have moved
		ParticleParameterTravelledDistance.X = 0.0f;
		ParticleParameterTravelledDistance.Y = 0.0f;
		ParticleParameterTravelledDistance.Z = 0.0f;
		Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Traveled_Distance', ParticleParameterTravelledDistance);
		Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Traveled_Distance', 0.0f);

		if( Projectiles[Index].ProjectileElement.MaximumTrailLength > 0.0f )
		{
			ParticleParameterTrailDistance.X = 0.0f;
			ParticleParameterTrailDistance.Y = 0.0f;
			ParticleParameterTrailDistance.Z = 0.0f;
			Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Trail_Distance', ParticleParameterTrailDistance);
			Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Trail_Distance', 0.0f);
		}
	}

	`log("********************* PROJECTILE Element #"@self.Name@Index@"FIRED *********************************", , 'DevDestruction');
	`log("StartTime:"@Projectiles[Index].StartTime, , 'DevDestruction');
	`log("EndTime:"@Projectiles[Index].EndTime, , 'DevDestruction');
	`log("InitialSourceLocation:"@Projectiles[Index].InitialSourceLocation, , 'DevDestruction');
	`log("InitialTargetLocation:"@Projectiles[Index].InitialTargetLocation, , 'DevDestruction');
	`log("InitialTravelDirection:"@Projectiles[Index].InitialTravelDirection, , 'DevDestruction');
	`log("Projectile actor location is "@Projectiles[Index].SourceAttachActor.Location, , 'DevDestruction');
	`log("Projectile actor velocity is set to:"@Projectiles[Index].TargetAttachActor.Velocity, , 'DevDestruction');
	`log("******************************************************************************************", , 'DevDestruction');

	if( Projectiles[Index].ProjectileElement.bPlayWeaponAnim )
	{
		AnimParams.AnimName = 'FF_FireA';
		AnimParams.Looping = false;
		AnimParams.Additive = true;

		FoundAnimSeq = SkeletalMeshComponent(SourceWeapon.Mesh).FindAnimSequence(AnimParams.AnimName);
		if( FoundAnimSeq != None )
		{
			//Tell our weapon to play its fire animation
			if( SourceWeapon.AdditiveDynamicNode != None )
			{
				PlayingSequence = SourceWeapon.AdditiveDynamicNode.PlayDynamicAnim(AnimParams);
				PlayingSequences.AddItem(PlayingSequence);
				SetTimer(PlayingSequence.AnimSeq.SequenceLength, false, nameof(BlendOutAdditives), self);
			}
			
		}
	}

	if( Projectiles[Index].ProjectileElement.FireSound != none )
	{
		//Play a fire sound if specified
		// Start Issue #10 Trigger an event that allows to override the default projectile sound
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'ProjectilSoundOverride';
		Tuple.Data.Add(3);

		// The SoundCue to play instead of the AKEvent, used as reference
		Tuple.Data[0].kind = XComLWTVObject;
		Tuple.Data[0].o = none;

		// Projectile Element ObjectArchetype Pathname Parameter
		Tuple.Data[1].kind = XComLWTVString;
		Tuple.Data[1].s = PathName(Projectiles[Index].ProjectileElement.ObjectArchetype);

		// Ability Context Ref Parameter
		Tuple.Data[2].kind = XComLWTVInt;
		Tuple.Data[2].i = AbilityContextAbilityRefID;

		`XEVENTMGR.TriggerEvent('OnProjectileFireSound', Tuple, Projectiles[Index].ProjectileElement, none);
		if (Tuple.Data[0].o != none)
		{
			Projectiles[Index].SourceAttachActor.PlaySound(SoundCue(Tuple.Data[0].o));
		}
		else
		{
			Projectiles[Index].SourceAttachActor.PlayAkEvent(Projectiles[Index].ProjectileElement.FireSound);
		}
		// End Issue #10
	}
}

// This is slightly different from the similar function in X2TargetingMethod_RifleGrenade, since we need to adjust time and rotation of each point, which is irrelevant for the preview curve drawn for targeting.
private function AdjustGrenadePath(XComPrecomputedPath GrenadePath, vector PathEndLocation)
{
	local float		iKeyframes;
	local float		i;
	local float		Delta;
	local vector	KeyPosition;
	local float		VerticalShift;
	local float		MaxVerticalShift;
	local float		Distance;
	local vector	PathStartLocation;
	local float		fTravelTime;
	
	iKeyframes = GrenadePath.iNumKeyframes;

	PathStartLocation = GrenadePath.akKeyframes[0].vLoc;

	// These are probably unnecessary
	GrenadePath.bUseOverrideSourceLocation = true;
	GrenadePath.OverrideSourceLocation = PathStartLocation;
	GrenadePath.bUseOverrideTargetLocation = true;
	GrenadePath.OverrideTargetLocation = PathEndLocation;

	// This ignores trajectory's curvature. Nauseating. 
	Distance = VSize(PathEndLocation - PathStartLocation);

	fTravelTime = Distance / 1000;

	// 0.1f is an arbitrary "trajectory curvature coefficient". If I was smarter, I'd write an actual function that would calculate realistic trajectory curvature based on speed and free fall acceleration, but this is gewd enuff
	MaxVerticalShift = Distance * 0.1f; 

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		Delta = i /  iKeyframes;

		// Calculate horizontal movement - this is a straight line at this point
		KeyPosition = PathStartLocation * (1 - Delta) + PathEndLocation * Delta;
		
		// This creates a parabolic trajectory. The sin function scales from 0 to 1 at Pi/2 then back to 0 at Pi.
		VerticalShift = MaxVerticalShift * Sin(Delta * const.Pi);
		KeyPosition.Z += VerticalShift;

		GrenadePath.akKeyframes[i].vLoc = KeyPosition;

		// Get rid of the mid-flight rotation animation.
		GrenadePath.akKeyframes[i].rRot = rotator(GrenadePath.akKeyframes[i - 1].vLoc - GrenadePath.akKeyframes[i].vLoc);

		// Adjust time to make projectile travel time scale with distance so it has consistent speed.
		GrenadePath.akKeyframes[i].fTime = i * fTravelTime / iKeyframes;

		// Add some cosmetic roll to make it look nicer
		GrenadePath.akKeyframes[i].rRot.Roll += GrenadePath.akKeyframes[i].fTime * 210 * 182; // 210 degrees per second basically
	}
}

// For some reason just setting the mesh in the projectile didn't do the trick.
private function SkeletalMesh GetProjectileSkeletalMesh()
{
	return SkeletalMesh(`CONTENT.RequestGameArchetype("IRIRifleGrenadePerk.SM_RifleGrenade"));
}

private function MaybeUpdateTargetForUnitOnTile(out vector VectorLocation, const StateObjectReference ShooterRef, const StateObjectReference TargetRef)
{
	//local XComWorldData					World;
	//local TTile							TileLocation;
	local XComGameStateHistory			History;
	local XGUnit						GameUnit;

	//World = `XWORLD;

	//TileLocation = World.GetTileCoordinatesFromPosition(VectorLocation);

	`LOG("Original vector:" @ VectorLocation,, 'IRITEST');

	//	If there's a unit on the tile, or the tile contains a high cover object

	History = `XCOMHISTORY;
	GameUnit = XGUnit(History.GetVisualizer(TargetRef.ObjectID));

	`LOG("Target unit:" @ XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID)).GetFullName(),, 'IRITEST');

	if (GameUnit != none)
	{
		VectorLocation = GameUnit.GetShootAtLocation(eHit_Success, ShooterRef);

		`LOG("Adjusted vector:" @ VectorLocation,, 'IRITEST');
	}
	
}

// Was looking to remove the delay between projectile finishing the flight and exploding, but looks like the delay happens after the projectile hits according to this function.
/*
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

		local vector LocationThisTick;
		local vector LocationLastTick;
		local float DistanceTravelled;


		originalfDeltaT = fDeltaT;
		bAllProjectilesDone = true; //Set to false if any projectiles are 1. still to be created 2. being created 3. still in flight w. effects

		`LOG("========= Begin Tick ==========, Time:" @ fDeltaT,, 'IRITEST');
		

		for( Index = 0; Index < Projectiles.Length; ++Index )
		{

			//Update existing projectiles, fire any projectiles that are pending
			if( Projectiles[Index].bFired )
			{
				Projectiles[ Index ].ActiveTime += fDeltaT;

				`LOG(Index @ "Projectiles[ Index ].ActiveTime:" @ Projectiles[ Index ].ActiveTime @ "waiting to die:" @ Projectiles[ Index ].bWaitingToDie,, 'IRITEST');

				if (!Projectiles[ Index ].bWaitingToDie)
				{
					Projectiles[ Index ].AliveTime += fDeltaT;
				}

				`LOG(Index @ "Projectiles[ Index ].AliveTime:" @ Projectiles[ Index ].AliveTime,, 'IRITEST');

				`LOG("World Time:" @ WorldInfo.TimeSeconds @ "Projectile End time:" @ Projectiles[Index].EndTime @ "Trail Adjustment Time:" @ Projectiles[Index].TrailAdjustmentTime @ "Total:" @ (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime),, 'IRITEST');

				// Traveling projectiles should be forcibly deactivated once they've reaced their destination (and the trail has caught up).
				if(Projectiles[Index].ParticleEffectComponent != None && (Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_Traveling) && (WorldInfo.TimeSeconds >= (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime)))
				{
					`LOG("Killing particle effect component.",, 'IRITEST');

					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					Projectiles[ Index ].ParticleEffectComponent = none;
				}

				bStruckTarget = StruckTarget(Index, fDeltaT);
				bShouldEnd = (WorldInfo.TimeSeconds > Projectiles[Index].EndTime - 0.25) && !Projectiles[Index].bWaitingToDie;

				`LOG("bStruckTarget:" @ bStruckTarget @ "bShouldEnd:" @ bShouldEnd,, 'IRITEST');

				bShouldEnd = bShouldEnd || bStruckTarget;

				if (Index == 0 && Projectiles[Index].TargetAttachActor != none)
				{
					LocationThisTick = Projectiles[Index].TargetAttachActor.Location;
					DistanceTravelled = VSize(LocationThisTick - LocationLastTick);

					`LOG("DistanceTravelled:" @ DistanceTravelled,, 'IRITEST');

					if (DistanceTravelled == 0)
					{
						`LOG("Didn't travel, killing projectile.",, 'IRITEST');
						bShouldEnd = true;
					}

					LocationLastTick = LocationThisTick;
				}

				bShouldUpdate = Projectiles[Index].ProjectileElement.bAttachToSource || Projectiles[Index].ProjectileElement.bAttachToTarget ||
					((Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_RangedConstant) && (!Projectiles[Index].bConstantComplete));

				bProjectileEffectsComplete = (Projectiles[ Index ].ParticleEffectComponent == none || Projectiles[ Index ].ParticleEffectComponent.HasCompleted( ));

				`LOG("bShouldUpdate:" @ bShouldUpdate @ "bProjectileEffectsComplete:" @ bProjectileEffectsComplete,, 'IRITEST');

				if (bShouldEnd)
				{
					//The projectile has reached its destination / conclusion. Begin the destruction process.
					EndProjectileInstance( Index, fDeltaT );
					`LOG("Ending projectile instance.",, 'IRITEST');
				}

				if (ProjectileShouldImpact(Index))
				{
					`LOG("Projectile should impact. bShouldEnd:" @ bShouldEnd @ "Waiting to die:" @ Projectiles[Index].bWaitingToDie,, 'IRITEST');

					if(bShouldEnd)
					{
						`LOG("Doing main impact.",, 'IRITEST');

						DoMainImpact(Index, fDeltaT, bStruckTarget); //Impact(s) that should play when the shot "reaches the target"
					}
					else if (!Projectiles[Index].bWaitingToDie)
					{
						`LOG("Doing transit impact.",, 'IRITEST');

						DoTransitImpact(Index, fDeltaT); //Impact(s) that should play while the shot is in transit
					}					
				}

				ProcessReturn( Index );

				`LOG("bShouldEnd:" @ bShouldEnd @ "bShouldUpdate:" @ bShouldUpdate @ "bStruckTarget:" @ bStruckTarget,, 'IRITEST');

				if (!bShouldEnd || bShouldUpdate || bStruckTarget)
				{
					`LOG("Updating projectile instance",, 'IRITEST');

					//The projectile is in flight or a mode that wants continued position updates after ending
					UpdateProjectileDistances( Index, fDeltaT );
				}

				// always update the trail
				UpdateProjectileTrail( Index );

				bAllProjectilesDone = bAllProjectilesDone && bProjectileEffectsComplete && Projectiles[Index].bWaitingToDie;

				`LOG("bAllProjectilesDone:" @ bAllProjectilesDone @ "bProjectileEffectsComplete:" @ bProjectileEffectsComplete @ "Time exceeded:" @ (WorldInfo.TimeSeconds > (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime + 10.0)),, 'IRITEST');

				// A fallback to catch bad projectile effects that are lasting too long (except for the constants)
				if (!bProjectileEffectsComplete && (WorldInfo.TimeSeconds > (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime + 10.0)) && (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_RangedConstant))
				{
					`LOG("Killing projectile effects.",, 'IRITEST');
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
				`LOG("Firing projectile instance.",, 'IRITEST');
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
			`LOG("All projectiles done, processing destruction.",, 'IRITEST');
			for( Index = 0; Index < Projectiles.Length; ++Index )
			{
				Projectiles[ Index ].SourceAttachActor.Destroy( );
				Projectiles[ Index ].TargetAttachActor.Destroy( );
			}
			Destroy( );
		}

		`LOG("--------- End Tick ------------",, 'IRITEST');
	}

Begin:
}
*/