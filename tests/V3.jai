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

Game :: struct {
    list_of_names: []string;
    timestamp:     Apollo_Time;
}

Serializer_Info :: struct {
    Version :: enum s32 {
        INVALID :: -1;
        INITIAL;
        ADDED_COLLECTOR;
        REMOVED_COLLECTOR_ADDED_TIMESTAMP;
        LATEST :: REMOVED_COLLECTOR_ADDED_TIMESTAMP;
    }

    serialize :: (s: *LBP_Serializer, game: *Game) {
        add(s, .INITIAL, *game.list_of_names);
        ok := check_integrity(s, .INITIAL);
        assert(ok);

        rem(s, .ADDED_COLLECTOR, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, [..]s64);
        ok = check_integrity(s, .ADDED_COLLECTOR);
        assert(ok);

        add(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, *game.timestamp);
        ok = check_integrity(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP);
        assert(ok);
    }
}

#scope_file

#load "utils.jai";
#import,file "../module.jai"(Serializer_Info);
#import "Basic";
