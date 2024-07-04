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

class PlayState extends FlxState
{
	private var stage:FlxTypedGroup<FlxSprite>;
	private var light:FlxSprite;
	private var cameraHUD:FlxCamera;

	private var lightIndexText:FlxText;
	private var fadeStatusText:FlxText;

	override public function create():Void
	{
		super.create();

		/**	stage setup	**/

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

		sortStage();

		/**	end stage setup	**/
		/**	hud setup	**/

		cameraHUD = new FlxCamera();
		cameraHUD.bgColor.alpha = 0;
		FlxG.cameras.add(cameraHUD, false);

		final TEXT_PADDING = 10.0;
		var text = "Use \"WASD\" to move the camera (\"SHIFT\" to move 4 times faster)";
		text += "\nUse \"UP\" and \"DOWN\" to reorder light sprite";
		text += "\nUse \"Z\" to switch light sprite visibility";
		text += "\nUse \"SPACE\" to start fade out";
		text += "\nHold \"R\" to reset the state";
		text += "\n\nRender method: " + FlxG.renderMethod;
		addToHUD(createFormatedText(TEXT_PADDING, TEXT_PADDING, text));

		lightIndexText = createFormatedText(TEXT_PADDING);
		lightIndexText.y = FlxG.height - lightIndexText.height * 2 - TEXT_PADDING;
		addToHUD(lightIndexText);
		updateLightIndexText();

		fadeStatusText = createFormatedText(TEXT_PADDING, "Fade Status Text");
		fadeStatusText.y = FlxG.height - fadeStatusText.height - TEXT_PADDING;
		addToHUD(fadeStatusText);

		// accurate fade status information
		FlxG.signals.postUpdate.add(updateFadeStatusText);

		/**	end hud setup	**/
	}

	var _resetTimer = 0.0;

	override public function update(elapsed:Float):Void
	{
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

		// start fade after pressing SPACE
		if (FlxG.keys.justPressed.SPACE)
			FlxG.camera.fade(FlxColor.BLACK, 1.0, false, () -> new FlxTimer().start(0.5, (_) -> FlxG.camera.fade(FlxColor.BLACK, 0.0, true)));

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
			updateLightIndexText();
		}

		if (FlxG.keys.justPressed.Z)
			light.visible = !light.visible;
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

	private function updateLightIndexText():Void
	{
		lightIndexText.text = "Light index: " + stage.members.indexOf(light) + ", Light ID: " + light.ID;
	}

	@:access(flixel.FlxCamera)
	private function updateFadeStatusText():Void
	{
		final isFadeActive = FlxG.camera._fxFadeAlpha > 0.0;
		var fadeProgress = FlxMath.roundDecimal(FlxG.camera._fxFadeAlpha, 4);
		if (FlxG.camera._fxFadeIn)
			fadeProgress = 1.0 - fadeProgress;
		fadeStatusText.text = "Fade status: " + (isFadeActive ? 'ACTIVE [$fadeProgress]' : "INACTIVE");
	}
}
