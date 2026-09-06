package;

/*
	Aw hell yeah! something I can actually work on!
 */
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import meta.CoolUtil;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

class Paths
{
	inline public static var SOUND_EXT = "ogg";

	static var currentLevel:String;

	public static function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [];

	public static function clearUnusedMemory()
	{
		var counter:Int = 0;

		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);

				if (obj != null)
				{
					var isTexture:Bool = currentTrackedTextures.exists(key);

					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);

						if (texture != null)
						{
							texture.dispose();
						}

						texture = null;
						currentTrackedTextures.remove(key);
					}

					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key))
					{
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}

					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}

		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);

			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)
				&& key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
	}

	/*
		Android/OpenFL-safe graphic loader.

		The old version used:

			FileSystem.exists(path)
			BitmapData.fromFile(path)

		That works for normal filesystem assets, but Android assets are
		packaged inside the APK. We therefore use OpenFL's asset system.
	*/
	public static function returnGraphic(
		key:String,
		?library:String,
		?textureCompression:Bool = false
	)
	{
		var path:String = getPath('images/$key.png', IMAGE, library);

		/*
			Important:
			OpenFlAssets knows how to access assets packed into the APK.
		*/
		if (!OpenFlAssets.exists(path, IMAGE))
		{
			trace('ERROR: Asset not found: ' + path);
			return null;
		}

		if (!currentTrackedAssets.exists(key))
		{
			var bitmap:BitmapData = null;

			try
			{
				bitmap = OpenFlAssets.getBitmapData(path);
			}
			catch (e:Dynamic)
			{
				trace('ERROR loading bitmap: ' + path);
				trace(e);
				return null;
			}

			if (bitmap == null)
			{
				trace('ERROR: BitmapData is null: ' + path);
				return null;
			}

			var newGraphic:FlxGraphic;

			if (textureCompression
				&& FlxG.stage != null
				&& FlxG.stage.context3D != null)
			{
				var texture = FlxG.stage.context3D.createTexture(
					bitmap.width,
					bitmap.height,
					BGRA,
					true,
					0
				);

				texture.uploadFromBitmapData(bitmap);

				currentTrackedTextures.set(key, texture);

				var textureBitmap:BitmapData = BitmapData.fromTexture(texture);

				newGraphic = FlxGraphic.fromBitmapData(
					textureBitmap,
					false,
					key,
					false
				);
			}
			else
			{
				newGraphic = FlxGraphic.fromBitmapData(
					bitmap,
					false,
					key,
					false
				);
			}

			if (newGraphic == null)
			{
				trace('ERROR: FlxGraphic creation failed: ' + path);
				return null;
			}

			currentTrackedAssets.set(key, newGraphic);
		}

		localTrackedAssets.push(key);

		return currentTrackedAssets.get(key);
	}

	public static function returnSound(
		path:String,
		key:String,
		?library:String
	)
	{
		var gottenPath:String =
			getPath('$path/$key.$SOUND_EXT', SOUND, library);

		/*
			Keep the original sound-loading behavior because it was
			already working correctly on the Android build.
		*/
		gottenPath = gottenPath.substring(
			gottenPath.indexOf(':') + 1,
			gottenPath.length
		);

		if (!currentTrackedSounds.exists(gottenPath))
		{
			currentTrackedSounds.set(
				gottenPath,
				Sound.fromFile(gottenPath)
			);
		}

		localTrackedAssets.push(key);

		return currentTrackedSounds.get(gottenPath);
	}

	inline public static function getPath(
		file:String,
		type:AssetType,
		?library:Null<String>
	)
	{
		if (library != null)
			return getLibraryPath(file, library);

		/*
			Check mods first.
		*/
		var levelPath = getLibraryPathForce(file, "mods");

		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		/*
			Otherwise use the normal assets folder.
		*/
		return getPreloadPath(file);
	}

	static public function getLibraryPath(
		file:String,
		library = "preload"
	)
	{
		return if (
			library == "preload"
			|| library == "default"
		)
			getPreloadPath(file);
		else
			getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(
		file:String,
		library:String
	)
	{
		return '$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		var returnPath:String = 'assets/$file';

		if (!OpenFlAssets.exists(returnPath))
			returnPath = CoolUtil.swapSpaceDash(returnPath);

		return returnPath;
	}

	inline static public function file(
		file:String,
		type:AssetType = TEXT,
		?library:String
	)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(
		key:String,
		?library:String
	)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(
		key:String,
		?library:String
	)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function offsetTxt(
		key:String,
		?library:String
	)
	{
		return getPath(
			'images/characters/$key.txt',
			TEXT,
			library
		);
	}

	inline static public function json(
		key:String,
		?library:String
	)
	{
		return getPath(
			'songs/$key.json',
			TEXT,
			library
		);
	}

	inline static public function songJson(
		song:String,
		secondSong:String,
		?library:String
	)
		return getPath(
			'songs/${song.toLowerCase()}/${secondSong.toLowerCase()}.json',
			TEXT,
			library
		);

	static public function sound(
		key:String,
		?library:String
	):Dynamic
	{
		var sound:Sound = returnSound(
			'sounds',
			key,
			library
		);

		return sound;
	}

	inline static public function soundRandom(
		key:String,
		min:Int,
		max:Int,
		?library:String
	)
	{
		return sound(
			key + FlxG.random.int(min, max),
			library
		);
	}

	inline static public function music(
		key:String,
		?library:String
	):Dynamic
	{
		var file:Sound = returnSound(
			'music',
			key,
			library
		);

		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String =
			'${CoolUtil.swapSpaceDash(song.toLowerCase())}/Voices';

		var voices = returnSound(
			'songs',
			songKey
		);

		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String =
			'${CoolUtil.swapSpaceDash(song.toLowerCase())}/Inst';

		var inst = returnSound(
			'songs',
			songKey
		);

		return inst;
	}

	inline static public function image(
		key:String,
		?library:String,
		?textureCompression:Bool = false
	)
	{
		var returnAsset:FlxGraphic =
			returnGraphic(
				key,
				library,
				textureCompression
			);

		return returnAsset;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(
		key:String,
		?library:String
	)
	{
		var graphic:FlxGraphic =
			returnGraphic(key, library);

		if (graphic == null)
		{
			trace('ERROR: Cannot create Sparrow atlas: ' + key);
			return null;
		}

		var xmlPath:String =
			file(
				'images/$key.xml',
				library
			);

		if (!OpenFlAssets.exists(xmlPath, TEXT))
		{
			trace('ERROR: Sparrow XML not found: ' + xmlPath);
			return null;
		}

		return FlxAtlasFrames.fromSparrow(
			graphic,
			OpenFlAssets.getText(xmlPath)
		);
	}

	inline static public function getPackerAtlas(
		key:String,
		?library:String
	)
	{
		var graphic:FlxGraphic =
			image(key, library);

		if (graphic == null)
		{
			trace('ERROR: Cannot create Packer atlas: ' + key);
			return null;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker(
			graphic,
			file(
				'images/$key.txt',
				library
			)
		);
	}
}
