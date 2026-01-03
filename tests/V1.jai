main :: () {
    log("Testing V1.");

    game: Game = .{ .["Alice", "Mark", "Greg"] };

    save_file_path :: "tests/build/game_V1.dat";

    ok := save_game(save_file_path, *game);
    assert(ok);

    ok=, loaded_game := load_game(save_file_path);
    assert(ok);

    compare_array(loaded_game.list_of_names, game.list_of_names);

    log("V1 works fine.");
}

Game :: struct {
    list_of_names: []string;
}

Serializer_Info :: struct {
    Version :: enum s32 {
        INVALID :: -1;
        INITIAL;
        LATEST :: INITIAL;
    }

    serialize :: (s: *LBP_Serializer, game: *Game) {
        add(s, .INITIAL, *game.list_of_names);
        ok := check_integrity(s, .INITIAL);
        assert(ok);
    }
}

#scope_file

#load "utils.jai";
#import,file "../module.jai"(Serializer_Info);
#import "Basic";
