package meta.data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets as OpenFlAssets;
import meta.data.Section.SwagSection;
import sys.io.File;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var stage:String;
	var noteSkin:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var realFolder:String = folder;
		var realJson:String = jsonInput;

		/*
		 * Nuts and Bolts usa nomes diferentes dos nomes
		 * usados originalmente pela playlist.
		 *
		 * Caminho real:
		 * assets/songs/Nuts-and-Bolts/
		 *
		 * Arquivos:
		 * nuts-and-bolts.json
		 * nuts-and-bolts-easy.json
		 * nuts-and-bolts-hard.json
		 */
		if (
			folder != null &&
			folder.toLowerCase() == 'nuts and bolts'
		)
		{
			realFolder = 'Nuts-and-Bolts';

			realJson =
				jsonInput
					.toLowerCase()
					.replace('nuts and bolts', 'nuts-and-bolts')
					.replace(' ', '-');
		}

		var assetPath:String =
			Paths.songJson(
				realFolder,
				realJson
			);

		var rawJson:String =
			OpenFlAssets.getText(assetPath).trim();

		while (
			rawJson.length > 0 &&
			!rawJson.endsWith("}")
		)
		{
			rawJson =
				rawJson.substr(
					0,
					rawJson.length - 1
				);
		}

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(
		rawJson:String
	):SwagSong
	{
		var swagShit:SwagSong =
			cast Json.parse(rawJson).song;

		swagShit.validScore = true;

		return swagShit;
	}
}
