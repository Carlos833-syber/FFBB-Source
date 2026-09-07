function changeDiff(change:Int = 0)
{
	// Proteções contra listas vazias ou índices inválidos
	if (songs == null || songs.length == 0)
		return;

	if (curSelected < 0 || curSelected >= songs.length)
		return;

	if (existingDifficulties == null || curSelected >= existingDifficulties.length)
		return;

	if (existingDifficulties[curSelected] == null
		|| existingDifficulties[curSelected].length == 0)
		return;

	curDifficulty += change;

	// Corrige o índice da dificuldade
	if (curDifficulty < 0)
		curDifficulty = existingDifficulties[curSelected].length - 1;

	if (curDifficulty >= existingDifficulties[curSelected].length)
		curDifficulty = 0;

	// Evita ficar preso na mesma dificuldade
	if (lastDifficulty != null && change != 0)
	{
		var safety:Int = 0;

		while (existingDifficulties[curSelected][curDifficulty] == lastDifficulty
			&& safety < existingDifficulties[curSelected].length)
		{
			curDifficulty += change;

			if (curDifficulty < 0)
				curDifficulty = existingDifficulties[curSelected].length - 1;

			if (curDifficulty >= existingDifficulties[curSelected].length)
				curDifficulty = 0;

			safety++;
		}
	}

	// Segurança adicional
	if (curDifficulty < 0
		|| curDifficulty >= existingDifficulties[curSelected].length)
		return;

	intendedScore = Highscore.getScore(
		songs[curSelected].songName,
		curDifficulty
	);

	diffText.text =
		'< ' + existingDifficulties[curSelected][curDifficulty] + ' >';

	lastDifficulty =
		existingDifficulties[curSelected][curDifficulty];
}


function changeSelection(change:Int = 0)
{
	// Não há músicas
	if (songs == null || songs.length == 0)
	{
		trace('ERRO: nenhuma música foi carregada no Freeplay!');
		return;
	}

	// DEBUG: mostra todas as músicas carregadas
	trace('================================');
	trace('MUSICAS CARREGADAS: ' + songs.length);

	for (i in 0...songs.length)
	{
		if (songs[i] != null)
			trace('SONG [' + i + ']: ' + songs[i].songName);
		else
			trace('SONG [' + i + ']: NULL');
	}

	trace('================================');

	// Altera seleção
	curSelected += change;

	// Volta para a última música
	if (curSelected < 0)
		curSelected = songs.length - 1;

	// Volta para a primeira música
	if (curSelected >= songs.length)
		curSelected = 0;

	// Segurança
	if (curSelected < 0 || curSelected >= songs.length)
		return;

	if (songs[curSelected] == null)
	{
		trace('ERRO: songs[' + curSelected + '] está NULL!');
		return;
	}

	// Verifica dificuldades
	if (existingDifficulties == null
		|| curSelected >= existingDifficulties.length)
	{
		trace('ERRO: não existem dificuldades para a música '
			+ songs[curSelected].songName);
		return;
	}

	if (existingDifficulties[curSelected] == null
		|| existingDifficulties[curSelected].length == 0)
	{
		trace('ERRO: lista de dificuldades vazia para '
			+ songs[curSelected].songName);
		return;
	}

	// Score
	intendedScore = Highscore.getScore(
		songs[curSelected].songName,
		curDifficulty
	);

	// Cor
	mainColor = songs[curSelected].songColor;

	// Seleciona o texto correspondente
	grpOrders.forEach(function(txt:FlxText)
	{
		if (txt == null)
			return;

		if (curSelected == txt.ID)
			txt.alpha = 1;
		else
			txt.alpha = 0.5;
	});

	// Atualiza dificuldade
	changeDiff();
} 
