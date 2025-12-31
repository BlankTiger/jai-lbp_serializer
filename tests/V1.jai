main :: () {
    log("Testing V1.");

    game: Game = .{ .["Alice", "Mark", "Greg"] };

    save_file_path :: "tests/build/game_V1.dat";

    ok: bool;
    ok = save_game(save_file_path, *game);
    assert(ok);

    loaded_game: Game;
    ok, loaded_game = load_game(save_file_path);
    assert(ok);

    compare_array(loaded_game.list_of_names, game.list_of_names);

    log("V1 works fine.");
}

Version :: enum s32 {
    INVALID :: -1;
    INITIAL;
    LATEST :: INITIAL;
}

Game :: struct {
    list_of_names: []string;
}

serialize :: (s: *LBP_Serializer, game: *Game) {
    add(s, .INITIAL, *game.list_of_names);
    check_integrity(s, .INITIAL);
}

#scope_file

#load "utils.jai";
#load "../module.jai";
#import "Basic";
