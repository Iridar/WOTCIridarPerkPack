class X2TargetingMethod_TopDown_NoCameraLock extends X2TargetingMethod_TopDown;

function Canceled()
{
	super(X2TargetingMethod).Canceled();
	if (LookatCamera != none)
	{
		`CAMERASTACK.RemoveCamera(LookatCamera);
	}
	ClearTargetedActors();
}

function Update(float DeltaTime)
{
	if (LookatCamera.HasArrived)
	{
		`CAMERASTACK.RemoveCamera(LookatCamera);
		LookatCamera = none;
	}
}
