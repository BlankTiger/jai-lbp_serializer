main :: () {
    log("Testing V3.");

    game: Game; 
    game.list_of_names = .["Eliza", "Paul"];
    game.timestamp     = current_time_monotonic();

    save_file_path_V1 :: "tests/build/game_V1.dat";
    save_file_path_V2 :: "tests/build/game_V2.dat";
    save_file_path_V3 :: "tests/build/game_V3.dat";

    ok := save_game(save_file_path_V3, *game);
    assert(ok);

    default_timestamp: Apollo_Time;

    {
        ok, loaded_game_V1 := load_game(save_file_path_V1);
        assert(ok);

        compare_array(loaded_game_V1.list_of_names, .["Alice", "Mark", "Greg"]);
        assert(loaded_game_V1.timestamp == default_timestamp);
    }

    {
        ok, loaded_game_V2 := load_game(save_file_path_V2);
        assert(ok);

        compare_array(loaded_game_V2.list_of_names, .["Marie", "Stefan"]);
        assert(loaded_game_V2.timestamp == default_timestamp);
    }

    {
        ok, loaded_game_V3 := load_game(save_file_path_V3);
        assert(ok);

        compare_array(loaded_game_V3.list_of_names, game.list_of_names);
        assert(loaded_game_V3.timestamp == game.timestamp);
    }

    log("V3 works fine.");
}

LBP_Version :: enum s32 {
    INVALID :: -1;
    INITIAL;
    ADDED_COLLECTOR;
    REMOVED_COLLECTOR_ADDED_TIMESTAMP;
    LATEST :: REMOVED_COLLECTOR_ADDED_TIMESTAMP;
}

Game :: struct {
    list_of_names: []string;
    timestamp:     Apollo_Time;
}

serialize :: (s: *LBP_Serializer, game: *Game) {
    add(s, .INITIAL, *game.list_of_names);
    check_integrity(s, .INITIAL);

    rem(s, .ADDED_COLLECTOR, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, [..]s64);
    check_integrity(s, .ADDED_COLLECTOR);

    add(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, *game.timestamp);
    check_integrity(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP);
}

#scope_file

#load "utils.jai";
#load "../module.jai";
#import "Basic";
