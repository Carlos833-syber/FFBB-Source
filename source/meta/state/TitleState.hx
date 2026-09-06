package meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.effects.particles.FlxEmitter;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.userInterface.SpatulaHUD;
import lime.app.Application;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.dependency.Discord;
import meta.state.menus.*;
import meta.subState.GameOverSubstate;
import openfl.Assets;

using StringTools;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;
	static var isMainMenu:Bool = false;
	static var startRandom:Bool = false;

	var warningText:FlxSprite;
	var black:FlxSprite;
	var warningSkip:Bool = false;

	var heavy:FlxSprite;
	var logoBl:FlxSprite;
	var spongeDance:FlxSprite;
	var menuBFGF:FlxSprite;
	var island:FlxSprite;
	var pineapple:FlxSprite;
	var danceLeft:Bool = false;
	var enterText:FlxText;
	var foreverText:FlxSprite;
	var tribute:FlxSprite;
	var bubbles:FlxSprite;
	var spatulaHUD:SpatulaHUD;
	var transitionBG:FlxSprite;
	var loading:FlxText;
	var diffText:FlxText;

	var particles:FlxTypedGroup<FlxEmitter>;
	var bubbleEffect:FlxTypedGroup<FlxSprite>;

	public static var titleImage:String = "";

	var squeakSound:Int = 1;

	var reverseAnim:Bool = false;
	var notLoopIsland:Bool = true;
	var fading:Bool = false;
	var bubblesDone:Bool = false;

	var optionShit:Array<String> = ['story mode', 'freeplay', 'options', 'achievements', 'credits'];
	var existingDifficulties:Array<String> = [];
	var menuItems:FlxTypedGroup<FlxSprite>;
	static var curSelected:Float = 0;
	static var curDifficulty:Int = 1;

	override public function create():Void
	{
		FlxG.mouse.visible = false;
		FlxG.mouse.enabled = false;
		FlxG.mouse.useSystemCursor = false;

		controls.setKeyboardScheme(None, false);

		titleImage = "freaky";

		super.create();

		persistentUpdate = true;

		GameOverSubstate.fishHadEnough = 0;

		for (i in CoolUtil.difficultyArray)
			existingDifficulties.push(i);

		pineapple = new FlxSprite().loadGraphic(Paths.image('menus/base/titleandmainmenu/mainmenuBG'));
		pineapple.setGraphicSize(Std.int(pineapple.width * 1.05));
		pineapple.antialiasing = true;
		pineapple.screenCenter();
		pineapple.y += 712 * 1.5;
		add(pineapple);

		spongeDance = new FlxSprite();
		spongeDance.frames = Paths.getSparrowAtlas('menus/base/titleandmainmenu/SPONGEHANDS
