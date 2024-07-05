package;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;

class PlayState extends FlxState
{
	private static final blendModes:Array<BlendMode> = [
		NORMAL, ADD, ALPHA, DARKEN, DIFFERENCE, ERASE, HARDLIGHT, INVERT, LAYER, LIGHTEN, MULTIPLY, OVERLAY, SCREEN, SHADER, SUBTRACT
	];
	private static final fadeColors:Array<FlxColor> = [
		FlxColor.WHITE, FlxColor.GRAY, FlxColor.BLACK, FlxColor.GREEN, FlxColor.LIME, FlxColor.YELLOW, FlxColor.ORANGE, FlxColor.RED, FlxColor.PURPLE,
		FlxColor.BLUE, FlxColor.BROWN, FlxColor.PINK, FlxColor.MAGENTA, FlxColor.CYAN
	];

	private var stage:FlxTypedGroup<FlxSprite>;
	private var light:FlxSprite;
	private var cameraHUD:FlxCamera;

	private var lightInfoText:FlxText;
	private var fadeInfoText:FlxText;

	private var curBlendMode:Int = 0;
	private var curFadeColor:Int = 0;

	var _resetTimer:Float = 0.0;

	override public function create():Void
	{
		super.create();

		/**	stage setup	**/

		FlxG.cameras.reset(new CameraWithFixedFill());
		FlxG.camera.zoom = 0.55;
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.26);

		stage = new FlxTypedGroup();
		add(stage);

		addToStage(new FlxSprite(-1091.45, -785.15, AssetPaths.wall__png));
		addToStage(new FlxSprite(-876.45, 705.15, AssetPaths.floor__png));
		addToStage(new FlxSprite(1166.45, 125.15, AssetPaths.sign_yesterday__png));
		addToStage(new FlxSprite(1516.45, 105.15, AssetPaths.drinks__png));
		addToStage(new FlxSprite(1916.45, 105.15, AssetPaths.drinks__png));
		addToStage(new FlxSprite(916.45, 316.15, AssetPaths.reg__png), 0.98);
		addToStage(new FlxSprite(-635.1, 29.6, AssetPaths.shelf_w_shit__png), 0.6);
		addToStage(new FlxSprite(1516.45, 348.15, AssetPaths.reg__png), 1.2);
		addToStage(new FlxSprite(1785.65, 362.5, AssetPaths.reg_skin__png), 1.13);
		addToStage(new FlxSprite(-795.1, 110.6, AssetPaths.shelf_w_shit_back__png), 0.95);
		addToStage(new FlxSprite(1316.45, -439.5, AssetPaths.reg_alco__png)).color = 0xBDAAAAAA;
		addToStage(new FlxSprite(1785.65, -389.5, AssetPaths.reg_alco__png));
		addToStage(new FlxSprite(-1075.1, -20.6, AssetPaths.shelf_w_shit__png));
		addToStage(new FlxSprite(-791.55 + FlxG.random.int(-50, 50), 552.55 + FlxG.random.int(-50, 50), AssetPaths.cleaning_stuff__png));
		addToStage(new FlxSprite(395, -480, AssetPaths.lamp__png));
		addToStage(new FlxSprite(300, -400, AssetPaths.lamp_bloom__png));
		light = addToStage(new FlxSprite(110, -300, AssetPaths.light__png));
		light.blend = ADD;
		curBlendMode = blendModes.indexOf(light.blend);

		sortStage();

		/**	end stage setup	**/
		/**	hud setup	**/

		cameraHUD = new FlxCamera();
		cameraHUD.bgColor.alpha = 0;
		FlxG.cameras.add(cameraHUD, false);

		final TEXT_PADDING = 10.0;
		var text = "Use \"WASD\" to move the camera (\"SHIFT\" to move 4 times faster)";
		text += "\nUse \"LEFT\" and \"RIGHT\" to change light sprite blend mode";
		text += "\nUse \"UP\" and \"DOWN\" to reorder light sprite";
		text += "\nUse \"Z\" to switch light sprite visibility";
		text += "\nUse \"Q\" and \"E\" to change fade fill color";
		text += "\nUse \"SPACE\" to start fade out";
		text += "\nUse \"X\" to try fill fix";
		text += "\nHold \"R\" to reset the state";
		text += "\n\nRender method: " + FlxG.renderMethod;
		addToHUD(createFormatedText(TEXT_PADDING, TEXT_PADDING, text));

		lightInfoText = createFormatedText(TEXT_PADDING);
		lightInfoText.y = FlxG.height - lightInfoText.height * 2 - TEXT_PADDING;
		addToHUD(lightInfoText);
		updateLightInfoText();

		fadeInfoText = createFormatedText(TEXT_PADDING, "Fade Status Text");
		fadeInfoText.y = FlxG.height - fadeInfoText.height - TEXT_PADDING;
		addToHUD(fadeInfoText);

		// accurate fade status information
		FlxG.signals.postUpdate.add(updateFadeInfoText);

		/**	end hud setup	**/
	}

	override public function update(elapsed:Float):Void
	{
		// state reset timer
		if (FlxG.keys.pressed.R)
		{
			_resetTimer += elapsed;
			if (_resetTimer >= 0.5)
			{
				FlxG.resetState();
				return;
			}
		}
		else
			_resetTimer = 0.0;

		super.update(elapsed);

		// camera movement control
		final LEFT = FlxG.keys.pressed.A;
		final RIGHT = FlxG.keys.pressed.D;
		final UP = FlxG.keys.pressed.W;
		final DOWN = FlxG.keys.pressed.S;

		final HORIZONTAL_MOVEMENT = (LEFT || RIGHT);
		final VERTICAL_MOVEMENT = (UP || DOWN);
		if (HORIZONTAL_MOVEMENT || VERTICAL_MOVEMENT)
		{
			var SPEED = 600.0;
			// speed up if shit is pressed
			if (FlxG.keys.pressed.SHIFT)
				SPEED *= 4.0;

			// do not move if both are pressed at the same time
			if (HORIZONTAL_MOVEMENT && !(LEFT && RIGHT))
				FlxG.camera.scroll.x += (LEFT ? -SPEED : SPEED) * elapsed;
			if (VERTICAL_MOVEMENT && !(UP && DOWN))
				FlxG.camera.scroll.y += (UP ? -SPEED : SPEED) * elapsed;
			// trace(FlxG.camera.scroll);
		}

		// change light sprite blend mode
		final ARROW_LEFT = FlxG.keys.justPressed.LEFT;
		final ARROW_RIGHT = FlxG.keys.justPressed.RIGHT;
		if (ARROW_LEFT || ARROW_RIGHT && !(ARROW_LEFT && ARROW_RIGHT))
		{
			if (ARROW_RIGHT)
				curBlendMode++;
			else
				curBlendMode--;

			curBlendMode = FlxMath.wrap(curBlendMode, 0, blendModes.length - 1);
			light.blend = blendModes[curBlendMode];
			updateLightInfoText();
		}

		// move light sprite around the stage
		final ARROW_UP = FlxG.keys.justPressed.UP;
		final ARROW_DOWN = FlxG.keys.justPressed.DOWN;
		if (ARROW_UP || ARROW_DOWN && !(ARROW_UP && ARROW_DOWN))
		{
			if (ARROW_UP)
				light.ID++;
			else
				light.ID--;

			// wrap new id around the stage length
			light.ID = FlxMath.wrap(light.ID, 0, stage.length - 1);
			sortStage();
			updateLightInfoText();
		}

		// switch light sprite visibility
		if (FlxG.keys.justPressed.Z)
			light.visible = !light.visible;

		// change fade fill color
		final COLOR_LEFT = FlxG.keys.justPressed.Q;
		final COLOR_RIGHT = FlxG.keys.justPressed.E;
		if (COLOR_LEFT || COLOR_RIGHT && !(COLOR_LEFT && COLOR_RIGHT))
		{
			if (COLOR_RIGHT)
				curFadeColor++;
			else
				curFadeColor--;

			curFadeColor = FlxMath.wrap(curFadeColor, 0, fadeColors.length - 1);
		}

		if (FlxG.keys.justPressed.X)
		{
			final camera = cast(FlxG.camera, CameraWithFixedFill);
			camera.fillFix = !camera.fillFix;
		}

		// start fade
		if (FlxG.keys.justPressed.SPACE)
		{
			final color = fadeColors[curFadeColor];
			FlxG.camera.fade(color, 1.0, false, () -> new FlxTimer().start(0.5, (_) -> FlxG.camera.fade(color, 0.0, true)));
		}
	}

	private function addToStage(spr:FlxSprite, scale = 1.0):FlxSprite
	{
		spr.ID = stage.length;
		// trace(spr.ID);
		spr.active = false;
		spr.scale.scale(scale * 1.3);
		// spr.updateHitbox();
		spr.antialiasing = true;
		return stage.add(spr);
	}

	private function addToHUD(basic:FlxBasic):FlxBasic
	{
		basic.cameras = [cameraHUD];
		return add(basic);
	}

	private function sortStage():Void
	{
		// trace([for (basic in stage.members) basic.ID]);
		stage.sort(sortByID);

		// for some reason sometimes array.sort() doesn't always work propertly
		// so i had to add this manual sorting in case of regular sorting failture
		final index = stage.members.indexOf(light);
		if (light.ID != index)
		{
			stage.members[index] = stage.members[light.ID];
			stage.members[light.ID] = light;
		}
		// trace([for (basic in stage.members) basic.ID]);
	}

	private function sortByID(order:Int, basic1:FlxBasic, basic2:FlxBasic):Int
	{
		// trace(basic1.ID, basic2.ID);
		return FlxSort.byValues(order, basic1.ID, basic2.ID);
	}

	private function createFormatedText(x = 0.0, ?y = 0.0, text = ""):FlxText
	{
		return new FlxText(x, y, 0.0, text, 16).setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
	}

	private function updateLightInfoText():Void
	{
		var text = "Index: " + stage.members.indexOf(light);
		// text += ", ID: " + light.ID;
		text += ", Blend: " + light.blend + ' [$curBlendMode]';
		lightInfoText.text = 'Light info: ($text)';
	}

	@:access(flixel.FlxCamera)
	private function updateFadeInfoText():Void
	{
		final isFadeActive = FlxG.camera._fxFadeAlpha > 0.0;
		var fadeProgress = FlxMath.roundDecimal(FlxG.camera._fxFadeAlpha, 4);
		if (FlxG.camera._fxFadeIn)
			fadeProgress = 1.0 - fadeProgress;

		final colorIndex = (isFadeActive ? fadeColors.indexOf(FlxG.camera._fxFadeColor) : curFadeColor);
		var text = "Color: " + getColorName(fadeColors[colorIndex]) + ' [$colorIndex]';
		text += ", Fill fix: " + cast(FlxG.camera, CameraWithFixedFill).fillFix;
		text += ", Status: " + (isFadeActive ? 'active [$fadeProgress]' : "inactive");
		fadeInfoText.text = 'Fade info: ($text)';
	}

	private function getColorName(color:FlxColor):String
	{
		return switch (color)
		{
			case FlxColor.WHITE: "white";
			case FlxColor.GRAY: "gray";
			case FlxColor.BLACK: "black";
			case FlxColor.GREEN: "green";
			case FlxColor.LIME: "lime";
			case FlxColor.YELLOW: "yellow";
			case FlxColor.ORANGE: "orange";
			case FlxColor.RED: "red";
			case FlxColor.PURPLE: "purple";
			case FlxColor.BLUE: "blue";
			case FlxColor.BROWN: "brown";
			case FlxColor.PINK: "pink";
			case FlxColor.MAGENTA: "magenta";
			case FlxColor.CYAN: "cyan";
			default: "unknown";
		}
	}
}
