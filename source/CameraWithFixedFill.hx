package;

import flixel.FlxCamera;

class CameraWithFixedFill extends FlxCamera
{
	#if (openfl > "8.7.0")
	public var fillFix:Bool = false;

	override function drawFX()
	{
		if (fillFix)
			canvas.graphics.overrideBlendMode(null);

		super.drawFX();
	}
	#end
}
