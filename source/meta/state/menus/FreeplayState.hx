package meta.state.menus;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.userInterface.HealthIcon;
import gameObjects.userInterface.SpatulaHUD;
import lime.utils.Assets;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Song.SwagSong;
import meta.data.dependency.Discord;
import meta.subState.*;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var selector:FlxText;

	public static var curSelected:Int = 0;
	public static var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var songThread:Thread;
	var threadActive:Bool = true;
	var mutex:Mutex;
	var songToPlay:Sound = null;

	var transitionBG:FlxSprite;
	var shinies:FlxSprite;
	var loading:FlxText;

	var selectedSong:Bool = false;

	var spatulaHUD:SpatulaHUD;

	var bubbles:FlxTypedGroup<FlxEmitter>;
	var bubbleEffect:FlxTypedGroup<FlxSprite>;

	private var curPlaying:Bool = false;
	private var labels:FlxText;

	private var galleyGrubOrders:Array<String> = [
		'UNSATISFIED CUSTOMER IN: on-ice.......',
		'A BREACHED POSEIDOME IN: nuts-and-bolts.......',
		'POORLY DRAWN SPONGEBOB IN: doodle-duel.......\nw/ secret sauce\n',
		'MIND-CONTROLLED SEA KING IN: plan-z.......',
		'PIMP MOB BOSS IN: pimpin.......',
		'METALLIC CLARINET PLAYER IN: scrapped-metal.......'
	];

	private var goldenSpatulaCost:Array<Int> = [
		1,
		1,
		1,
		2,
		3,
		4
	];

	private var grpOrders:FlxTypedGroup<FlxText>;
	private var mainColor:FlxColor = FlxColor.WHITE;

	private var bgBack:FlxSprite;
	private var thereIAm:FlxSprite;
	private var bg:FlxSprite;
	private var signs:FlxSprite;

	private var existingSongs:Array<String> = [];
	private var existingDifficulties:Array<Array<String>> = [];

	var squeakSound:Int = 1;

	override function create()
	{
		super.create();

		mutex = new Mutex();

		GameOverSubstate.fishHadEnough = 0;

		for (i in 0...Main.gameWeeks.length)
		{
			addWeek(
				Main.gameWeeks[i][0],
				i,
				Main.gameWeeks[i][1],
				Main.gameWeeks[i][2]
			);

			for (song in cast(Main.gameWeeks[i][0], Array<Dynamic>))
			{
				existingSongs.push(
					Std.string(song).toLowerCase()
				);
			}
		}

		#if !android
		Discord.changePresence(
			'Ordering A Battle',
			'Freeplay',
			" ",
			TitleState.titleImage
		);
		#end

		bgBack = new FlxSprite().loadGraphic(
			Paths.image('menus/base/freeplay/bgBack')
		);
		bgBack.antialiasing = true;
		add(bgBack);

		thereIAm = new FlxSprite(
			1120,
			305
		).loadGraphic(
			Paths.image('menus/base/freeplay/thereIAm')
		);
		thereIAm.antialiasing = true;
		add(thereIAm);

		bg = new FlxSprite().loadGraphic(
			Paths.image('menus/base/freeplay/bg')
		);
		bg.antialiasing = true;
		add(bg);

		signs = new FlxSprite(
			-50,
			-360
		).loadGraphic(
			Paths.image('menus/base/freeplay/signs')
		);
		signs.antialiasing = true;
		add(signs);

		labels = new FlxText(
			50,
			205,
			0,
			"Songs                                              Spatula Cost"
		);

		labels.setFormat(
			Paths.font("sponge.otf"),
			20,
			FlxColor.BLACK,
			LEFT
		);

		labels.antialiasing = true;
		add(labels);

		grpOrders = new FlxTypedGroup<FlxText>();
		add(grpOrders);

		for (i in 0...galleyGrubOrders.length)
		{
			var order:FlxText = new FlxText(
				50,
				240 + (i * 40),
				0,
				galleyGrubOrders[i]
			);

			order.setFormat(
				Paths.font("sponge.otf"),
				17,
				FlxColor.BLACK,
				LEFT
			);

			if (
				i < goldenSpatulaCost.length
				&& goldenSpatulaCost[i] > FlxG.save.data.spat
			)
			{
				order.text =
					'KRABBY SURPRISE.............................';
			}

			order.antialiasing = true;
			order.ID = i;

			if (
				i >= 3
				&& goldenSpatulaCost[2] <= FlxG.save.data.spat
			)
			{
				order.y += 30;
			}

			grpOrders.add(order);
		}

		for (i in 0...goldenSpatulaCost.length)
		{
			var cost:FlxText = new FlxText(
				565,
				238 + (i * 40),
				0,
				Std.string(goldenSpatulaCost[i])
			);

			cost.setFormat(
				Paths.font("sponge.otf"),
				20,
				FlxColor.BLACK,
				CENTER
			);

			cost.antialiasing = true;

			if (
				i >= 3
				&& goldenSpatulaCost[2] <= FlxG.save.data.spat
			)
			{
				cost.y += 30;
			}

			add(cost);
		}

		var shinyText:FlxText = new FlxText(
			Std.int(FlxG.width * 0.765),
			5,
			0,
			"Shiny Count"
		);

		shinyText.setFormat(
			Paths.font("sponge.otf"),
			40,
			FlxColor.YELLOW,
			RIGHT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		shinyText.antialiasing = true;
		add(shinyText);

		scoreText = new FlxText(
			Std.int(FlxG.width * 0.7),
			65,
			0,
			""
		);

		scoreText.setFormat(
			Paths.font("sponge.otf"),
			50,
			FlxColor.YELLOW,
			RIGHT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		scoreText.antialiasing = true;
		add(scoreText);

		shinies = new FlxSprite(
			0,
			Std.int(scoreText.getGraphicMidpoint().y - 30)
		).loadGraphic(
			Paths.image("UI/default/base/shinies")
		);

		shinies.setGraphicSize(
			Std.int(shinies.width * 0.55)
		);

		shinies.antialiasing = true;
		add(shinies);

		diffText = new FlxText(
			0,
			Std.int(signs.y + 868),
			0,
			""
		);

		diffText.alignment = CENTER;

		diffText.setFormat(
			Paths.font("sponge.otf"),
			24,
			FlxColor.YELLOW,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		diffText.antialiasing = true;
		add(diffText);

		changeSelection();
		changeDiff();

		selector = new FlxText(
			0,
			0,
			0,
			">"
		);

		selector.size = 40;
		add(selector);

		bubbles = new FlxTypedGroup<FlxEmitter>();

		for (i in 0...5)
		{
			var bubbleRise:FlxEmitter = new FlxEmitter(
				-1000,
				850
			);

			bubbleRise.launchMode = FlxEmitterMode.SQUARE;

			bubbleRise.velocity.set(
				-50,
				-150,
				50,
				-550,
				-100,
				0,
				100,
				-100
			);

			bubbleRise.scale.set(
				0.6,
				0.6,
				1.2,
				1,
				0.6,
				0.6,
				0.9,
				0.8
			);

			bubbleRise.drag.set(
				0,
				0,
				0,
				0,
				5,
				5,
				10,
				10
			);

			bubbleRise.width = 4000;

			bubbleRise.alpha.set(
				1,
				1,
				0,
				0
			);

			bubbleRise.lifespan.set(
				3,
				5
			);

			bubbleRise.loadParticles(
				Paths.image('particles/BubbleHit' + i),
				500,
				16,
				true
			);

			bubbleRise.start(
				false,
				FlxG.random.float(0.35, 0.4),
				1000000
			);

			bubbles.add(bubbleRise);
		}

		add(bubbles);

		spatulaHUD = new SpatulaHUD(0, 0);
		add(spatulaHUD);

		transitionBG = new FlxSprite(
			-85
		).loadGraphic(
			Paths.image('menus/base/transition/bgClouds')
		);

		transitionBG.setGraphicSize(
			Std.int(transitionBG.width * 2)
		);

		transitionBG.visible = false;
		transitionBG.antialiasing = true;
		transitionBG.scrollFactor.set();
		transitionBG.updateHitbox();
		transitionBG.screenCenter();

		add(transitionBG);

		bubbleEffect = new FlxTypedGroup<FlxSprite>();
		add(bubbleEffect);

		for (i in 0...40)
		{
			var bubble:FlxSprite = new FlxSprite(
				Std.int(-10 + (35 * i)),
				Std.int(
					740
					+ (FlxG.random.int(10, 70) * i)
					+ ((i >= 20) ? -100 : 0)
				)
			);

			bubble.loadGraphic(
				Paths.image('particles/BubbleTransition')
			);

			bubble.setGraphicSize(
				Std.int(
					bubble.width
					* FlxG.random.float(0.7, 1.1)
				)
			);

			bubble.antialiasing = true;
			bubbleEffect.add(bubble);
		}

		loading = new FlxText(
			Std.int(FlxG.width * 0.868),
			Std.int(FlxG.height - 42),
			0,
			"LOADING....."
		);

		loading.setFormat(
			Paths.font("sponge.ttf"),
			32,
			FlxColor.WHITE,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		loading.scrollFactor.set();
		loading.antialiasing = true;
		loading.visible = false;
		add(loading);

		#if android
		addVirtualPad(LEFT_FULL, A_B);
		#end
	}

	public function addSong(
		songName:String,
		weekNum:Int,
		songCharacter:String,
		songColor:FlxColor
	)
	{
		var coolDifficultyArray:Array<String> = [];

		for (i in CoolUtil.difficultyArray)
		{
			if (
				Assets.exists(
					Paths.songJson(
						songName,
						songName + '-' + i
					)
				)
				|| (
					Assets.exists(
						Paths.songJson(
							songName,
							songName
						)
					)
					&& i == "NORMAL"
				)
			)
			{
				coolDifficultyArray.push(i);
			}
		}

		if (coolDifficultyArray.length > 0)
		{
			songs.push(
				new SongMetadata(
					songName,
					weekNum,
					songCharacter,
					songColor
				)
			);

			existingDifficulties.push(
				coolDifficultyArray
			);
		}
	}

	public function addWeek(
		songs:Array<String>,
		weekNum:Int,
		?songCharacters:Array<String>,
		?songColor:Array<FlxColor>
	)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		if (songColor == null)
			songColor = [FlxColor.WHITE];

		var num:Array<Int> = [0, 0];

		for (song in songs)
		{
			var character:String =
				songCharacters[
					Math.min(
						num[0],
						songCharacters.length - 1
					)
				];

			var color:FlxColor =
				songColor[
					Math.min(
						num[1],
						songColor.length - 1
					)
				];

			addSong(
				song,
				weekNum,
				character,
				color
			);

			if (songCharacters.length != 1)
				num[0]++;

			if (songColor.length != 1)
				num[1]++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var lerpVal:Float =
			Main.framerateAdjust(0.1);

		var newScore:Float =
			FlxMath.lerp(
				lerpScore,
				intendedScore,
				lerpVal
			);

		lerpScore = Std.int(newScore);

		if (
			Math.abs(
				lerpScore - intendedScore
			) <= 10
		)
		{
			lerpScore = intendedScore;
		}

		if (squeakSound > 2)
			squeakSound = 1;

		var upP:Bool = controls.UP_P;
		var downP:Bool = controls.DOWN_P;
		var accepted:Bool = controls.ACCEPT;

		if (upP && !selectedSong)
		{
			changeSelection(-1);

			FlxG.sound.play(
				Paths.sound(
					'squeak' + squeakSound
				),
				0.7
			);

			squeakSound++;
		}
		else if (downP && !selectedSong)
		{
			changeSelection(1);

			FlxG.sound.play(
				Paths.sound(
					'squeak' + squeakSound
				),
				0.7
			);

			squeakSound++;
		}

		if (
			controls.LEFT_P
			&& !selectedSong
		)
		{
			changeDiff(-1);
		}

		if (
			controls.RIGHT_P
			&& !selectedSong
		)
		{
			changeDiff(1);
		}

		if (
			controls.BACK
			&& !selectedSong
		)
		{
			threadActive = false;

			Main.switchState(
				this,
				new TitleState()
			);

			return;
		}

		if (
			accepted
			&& !selectedSong
			&& curSelected >= 0
			&& curSelected < songs.length
			&& curSelected < goldenSpatulaCost.length
			&& goldenSpatulaCost[curSelected]
				<= FlxG.save.data.spat
		)
		{
			selectedSong = true;
			transition();
		}

		scoreText.text =
			Std.string(lerpScore);

		var scoreX:Int = Std.int(
			FlxG.width
			- scoreText.width
			- 5
		);

		var shiniesX:Int = Std.int(
			(FlxG.width * 0.930)
			- scoreText.width
			- 5
		);

		var diffX:Int = Std.int(
			(signs.x - 185)
			+ (signs.width / 2)
			- (diffText.width / 2)
		);

		scoreText.x = scoreX;
		shinies.x = shiniesX;
		diffText.x = diffX;
	}

	function changeDiff(change:Int = 0)
	{
		if (
			songs == null
			|| songs.length == 0
		)
			return;

		if (
			curSelected < 0
			|| curSelected >= songs.length
		)
			return;

		if (
			curSelected
			>= existingDifficulties.length
		)
			return;

		if (
			existingDifficulties[curSelected] == null
			|| existingDifficulties[curSelected].length == 0
		)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
		{
			curDifficulty =
				existingDifficulties[
					curSelected
				].length - 1;
		}

		if (
			curDifficulty
			>= existingDifficulties[
				curSelected
			].length
		)
		{
			curDifficulty = 0;
		}

		intendedScore =
			Highscore.getScore(
				songs[curSelected].songName,
				curDifficulty
			);

		diffText.text =
			'< '
			+ existingDifficulties[
				curSelected
			][
				curDifficulty
			]
			+ ' >';
	}

	function changeSelection(change:Int = 0)
	{
		if (
			songs == null
			|| songs.length == 0
		)
			return;

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;

		if (curSelected >= songs.length)
			curSelected = 0;

		if (
			curSelected < 0
			|| curSelected >= songs.length
		)
			return;

		if (songs[curSelected] == null)
			return;

		if (
			curSelected
			>= existingDifficulties.length
		)
			return;

		if (
			existingDifficulties[curSelected] == null
			|| existingDifficulties[curSelected].length == 0
		)
			return;

		intendedScore =
			Highscore.getScore(
				songs[curSelected].songName,
				curDifficulty
			);

		mainColor =
			songs[curSelected].songColor;

		grpOrders.forEach(
			function(txt:FlxText)
			{
				if (txt == null)
					return;

				if (curSelected == txt.ID)
					txt.alpha = 1;
				else
					txt.alpha = 0.5;
			}
		);

		changeDiff();
	}

	function transition()
	{
		if (
			songs == null
			|| songs.length == 0
		)
			return;

		if (
			curSelected < 0
			|| curSelected >= songs.length
		)
			return;

		if (
			curSelected
			>= existingDifficulties.length
		)
			return;

		if (
			existingDifficulties[curSelected] == null
			|| existingDifficulties[curSelected].length == 0
		)
			return;

		if (
			curDifficulty < 0
			|| curDifficulty
				>= existingDifficulties[
					curSelected
				].length
		)
			return;

		transitionBG.visible = true;

		FlxG.sound.play(
			Paths.sound('transition'),
			0.4
		);

		bubbleEffect.forEach(
			function(spr:FlxSprite)
			{
				FlxTween.tween(
					spr,
					{y: -100},
					1,
					{
						ease: FlxEase.sineIn
					}
				);
			}
		);

		new FlxTimer().start(
			1.6,
			function(tmr:FlxTimer)
			{
				loading.visible = true;

				var difficultyIndex:Int =
					CoolUtil.difficultyArray.indexOf(
						existingDifficulties[
							curSelected
						][
							curDifficulty
						]
					);

				var poop:String =
					Highscore.formatSong(
						songs[
							curSelected
						].songName.toLowerCase(),
						difficultyIndex
					);

				PlayState.SONG =
					Song.loadFromJson(
