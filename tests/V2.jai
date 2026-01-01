main :: () {
    log("Testing V2.");

    game: Game; 
    game.list_of_names = .["Marie", "Stefan"];
    array_add(*game.number_collector, 67);
    array_add(*game.number_collector, 1337);

    save_file_path_V1 :: "tests/build/game_V1.dat";
    save_file_path_V2 :: "tests/build/game_V2.dat";

    ok := save_game(save_file_path_V2, *game);
    assert(ok);

    {
        ok, loaded_game_V1 := load_game(save_file_path_V1);
        assert(ok);

        compare_array(loaded_game_V1.list_of_names,    .["Alice", "Mark", "Greg"]);
        compare_array(loaded_game_V1.number_collector, .[]);
    }

    {
        ok, loaded_game_V2 := load_game(save_file_path_V2);
        assert(ok);

        compare_array(loaded_game_V2.list_of_names,    game.list_of_names);
        compare_array(loaded_game_V2.number_collector, game.number_collector);
    }

    log("V2 works fine.");
}

LBP_Version :: enum s32 {
    INVALID :: -1;
    INITIAL;
    ADDED_COLLECTOR;
    LATEST :: ADDED_COLLECTOR;
}

Game :: struct {
    list_of_names:    []string;
    number_collector: [..]s64;
}

serialize :: (s: *LBP_Serializer, game: *Game) {
    add(s, .INITIAL, *game.list_of_names);
    check_integrity(s, .INITIAL);

    add(s, .ADDED_COLLECTOR, *game.number_collector);
    check_integrity(s, .ADDED_COLLECTOR);
}

#scope_file

#load "utils.jai";
#load "../module.jai";
#import "Basic";
