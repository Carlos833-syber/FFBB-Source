package meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.userInterface.SpatulaHUD;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
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
	var bubbleEffect:FlxTypedGroup<Fl
