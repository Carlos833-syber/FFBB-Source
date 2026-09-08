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
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var curSongPlaying:Int = -1;
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

		/*
			Load songs from Main.gameWeeks.
		*/
		for (i in 0...Main.gameWeeks.length)
		{
			addWeek(
				Main.gameWeeks[i][0],
				i,
				Main.gameWeeks[i][1],
				Main.gameWeeks[i][2]
			);

			for (j in cast(Main.gameWeeks[i][0], Array<Dynamic>))
			{
				existingSongs.push(
					Std.string(j).toLowerCase()
				);
			}
		}

		/*
			Discord RPC is desktop-only.
		*/
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

			if (goldenSpatulaCost[i] > FlxG.save.data.spat)
			{
				order.text = 'KRABBY SURPRISE.............................';
			}

			order.antialiasing = true;
			order.ID = i;

			if (i >= 3 && goldenSpatulaCost[2] <= FlxG.save.data.spat)
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

			if (i >= 3 && goldenSpatulaCost[2] <= FlxG.save.data.spat)
			{
				cost.y += 30;
			}

			add(cost);
		}

		var shinyText:FlxText = new FlxText(
			FlxG.width * 0.765,
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
			FlxG.width * 0.7,
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
			scoreText.getGraphicMidpoint().y - 30
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
			signs.y + 868,
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

		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";

		changeSelection();
		changeDiff();

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

			bubbleRise.lifespan.set(3, 5);

			var bubbleGraphic = Paths.image(
				'particles/BubbleHit' + i
			);

			if (bubbleGraphic != null)
			{
				bubbleRise.loadParticles(
					bubbleGraphic,
					500,
					16,
					true
				);
			}

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
				-10 + (35 * i),
				740 + (FlxG.random.int(10, 70) * i) + ((i >= 20) ? -100 : 0)
			);

			var bubbleGraphic = Paths.image(
				'particles/BubbleTransition'
			);

			if (bubbleGraphic != null)
			{
				bubble.loadGraphic(bubbleGraphic);
			}

			bubble.setGraphicSize(
				Std.int(
					bubble.width * FlxG.random.float(0.7, 1.1)
				)
			);

			bubble.antialiasing = true;
			bubbleEffect.add(bubble);
		}

		loading = new FlxText(
			FlxG.width * 0.868,
			FlxG.height - 42,
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
				||
				(
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
			addSong(
				song,
				weekNum,
				songCharacters[num[0]],
				songColor[num[1]]
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

		var lerpVal:Float = Main.framerateAdjust(0.1);

		lerpScore = Math.floor(
			FlxMath.lerp(
				lerpScore,
				intendedScore,
				lerpVal
			)
		);

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (squeakSound > 2)
			squeakSound = 1;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP && !selectedSong)
		{
			changeSelection(-1);

			FlxG.sound.play(
				Paths.sound('squeak' + squeakSound),
				0.7
			);

			squeakSound++;
		}
		else if (downP && !selectedSong)
		{
			changeSelection(1);

			FlxG.sound.play(
				Paths.sound('squeak' + squeakSound),
				0.7
			);

			squeakSound++;
		}

		if (controls.LEFT_P && !selectedSong)
			changeDiff(-1);

		if (controls.RIGHT_P && !selectedSong)
			changeDiff(1);

		if (controls.BACK && !selectedSong)
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
			&& curSelected >= 0
			&& curSelected < goldenSpatulaCost.length
			&& goldenSpatulaCost[curSelected] <= FlxG.save.data.spat
			&& !selectedSong
		)
		{
			selectedSong = true;
			transition();
		}

		if (scoreText != null)
		{
			scoreText.text = Std.string(lerpScore);
			scoreText.x = FlxG.width - scoreText.width - 5;
		}

		if (shinies != null && scoreText != null)
		{
			shinies.x =
				(FlxG.width * 0.930)
				- scoreText.width
				- 5;
		}

		if (diffText != null && signs != null)
		{
			diffText.x =
				(signs.x - 185)
				+ (signs.width / 2)
				- (diffText.width / 2);
		}

		if (mutex != null)
		{
			mutex.acquire();

			if (songToPlay != null)
			{
				FlxG.sound.playMusic(songToPlay);

				if (
					FlxG.sound.music != null
					&& FlxG.sound.music.fadeTween != null
				)
				{
					FlxG.sound.music.fadeTween.cancel();
				}

				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = 0.0;
					FlxG.sound.music.fadeIn(
						1.0,
						0.0,
						1.0
					);
				}

				songToPlay = null;
			}

			mutex.release();
		}
	}

	override function beatHit()
	{
		super.beatHit();
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0)
	{
		if (
			songs.length == 0
			|| existingDifficulties.length == 0
			|| curSelected < 0
			|| curSelected >= existingDifficulties.length
			|| existingDifficulties[curSelected].length == 0
		)
		{
			return;
		}

		curDifficulty += change;

		if (
			lastDifficulty != null
			&& change != 0
		)
		{
			while (
				curDifficulty >= 0
				&& curDifficulty < existingDifficulties[curSelected].length
				&& existingDifficulties[curSelected][curDifficulty] == lastDifficulty
			)
			{
				curDifficulty += change;
			}
		}

		if (curDifficulty < 0)
		{
			curDifficulty =
				existingDifficulties[curSelected].length - 1;
		}

		if (
			curDifficulty
			> existingDifficulties[curSelected].length - 1
		)
		{
			curDifficulty = 0;
		}

		intendedScore = Highscore.getScore(
			songs[curSelected].songName,
			curDifficulty
		);

		diffText.text =
			'< '
			+ existingDifficulties[curSelected][curDifficulty]
			+ ' >';

		lastDifficulty =
			existingDifficulties[curSelected][curDifficulty];
	}

	function changeSelection(change:Int = 0)
	{
		if (
			songs.length == 0
			|| existingDifficulties.length == 0
		)
		{
			return;
		}

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;

		if (curSelected >= songs.length)
			curSelected = 0;

		if (
			curSelected >= existingDifficulties.length
			|| existingDifficulties[curSelected].length == 0
		)
		{
			return;
		}

		if (
			curDifficulty >= existingDifficulties[curSelected].length
		)
		{
			curDifficulty = 0;
		}

		intendedScore = Highscore.getScore(
			songs[curSelected].songName,
			curDifficulty
		);

		mainColor =
			songs[curSelected].songColor;

		grpOrders.forEach(function(txt:FlxText)
		{
			if (curSelected == txt.ID)
				txt.alpha = 1;
			else
				txt.alpha = 0.5;
		});

		changeDiff();
	}

	var playingSongs:Array<FlxSound> = [];

	function transition()
	{
		if (selectedSong && transitionBG != null)
		{
			transitionBG.visible = true;
		}

		FlxG.sound.play(
			Paths.sound('transition'),
			0.4
		);

		if (bubbleEffect != null)
		{
			bubbleEffect.forEach(function(spr:FlxSprite)
			{
				FlxTween.tween(
					spr,
					{y: -100},
					FlxG.random.float(0.8, 1.4),
					{
						ease: FlxEase.sineIn
					}
				);
			});
		}

		new FlxTimer().start(
			1.6,
			function(tmr:FlxTimer)
			{
				if (loading != null)
					loading.visible = true;

				if (
					curSelected < 0
					|| curSelected >= songs.length
					|| curSelected >= existingDifficulties.length
					|| existingDifficulties[curSelected].length == 0
				)
				{
					selectedSong = false;
					return;
				}

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
						poop,
						songs[
							curSelected
						].songName.toLowerCase()
					);

				if (PlayState.SONG == null)
				{
					selectedSong = false;

					if (loading != null)
						loading.visible = false;

					return;
				}

				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				PlayState.storyWeek = songs[curSelected].week;

				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();

				threadActive = false;

				FlxG.save.data.speedStore = true;

				Main.switchState(
					this,
					new PlayState()
				);
			}
		);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var songColor:FlxColor = FlxColor.WHITE;

	public function new(
		song:String,
		week:Int,
		songCharacter:String,
		songColor:FlxColor
	)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.songColor = songColor;
	}
}
