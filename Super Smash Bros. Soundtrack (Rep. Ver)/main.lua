local SmashSoundtrack = RegisterMod("Super Smash Bros. Soundtrack", 1)function SmashSoundtrack:onStart()	if SoundtrackSongList then		AddSoundtrackToMenu("SuperSmashBros")	else		Isaac.ConsoleOutput("The Soundtrack Menu Mod is required for Super Smash Bros. Soundtrack")	endendSmashSoundtrack:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, SmashSoundtrack.onStart);