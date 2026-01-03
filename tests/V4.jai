main :: () {
    log("Testing V4.");

    name := "George";

    game: Game;
    game.list_of_names = .["Ginnie", "Mickey"];
    game.timestamp     = current_time_monotonic();
    game.bytes         = .[#char "H", #char "E", #char "L", #char "L", #char "O"];
    game.name_ptr      = *name;
    game.toggle        = true;

    save_file_path_V1 :: "tests/build/game_V1.dat";
    save_file_path_V2 :: "tests/build/game_V2.dat";
    save_file_path_V3 :: "tests/build/game_V3.dat";
    save_file_path_V4 :: "tests/build/game_V4.dat";

    ok := save_game(save_file_path_V4, *game);
    assert(ok);

    default_timestamp: Apollo_Time;

    {
        ok, loaded_game_V1 := load_game(save_file_path_V1);
        assert(ok);

        compare_array(loaded_game_V1.list_of_names, .["Alice", "Mark", "Greg"]);
        assert(loaded_game_V1.timestamp == default_timestamp);
        compare_array(loaded_game_V1.bytes, .[]);
        assert(loaded_game_V1.name_ptr == null);
        assert(loaded_game_V1.toggle == false);
    }

    {
        ok, loaded_game_V2 := load_game(save_file_path_V2);
        assert(ok);

        compare_array(loaded_game_V2.list_of_names, .["Marie", "Stefan"]);
        assert(loaded_game_V2.timestamp == default_timestamp);
        compare_array(loaded_game_V2.bytes, .[]);
        assert(loaded_game_V2.name_ptr == null);
        assert(loaded_game_V2.toggle == false);
    }

    {
        ok, loaded_game_V3 := load_game(save_file_path_V3);
        assert(ok);

        compare_array(loaded_game_V3.list_of_names, .["Eliza", "Paul"]);
        assert(loaded_game_V3.timestamp != default_timestamp);
        compare_array(loaded_game_V3.bytes, .[]);
        assert(loaded_game_V3.name_ptr == null);
        assert(loaded_game_V3.toggle == false);
    }

    {
        ok, loaded_game_V4 := load_game(save_file_path_V4);
        assert(ok);

        compare_array(loaded_game_V4.list_of_names, game.list_of_names);
        assert(loaded_game_V4.timestamp == game.timestamp);
        compare_array(loaded_game_V4.bytes, game.bytes);
        assert(loaded_game_V4.name_ptr.* == game.name_ptr.*);
        assert(loaded_game_V4.toggle == true);
    }

    log("V4 works fine.");
}

LBP_Version :: enum s32 {
    INVALID :: -1;
    INITIAL;
    ADDED_COLLECTOR;
    REMOVED_COLLECTOR_ADDED_TIMESTAMP;
    ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL;
    LATEST :: ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL;
}

Game :: struct {
    list_of_names: []string;
    timestamp:     Apollo_Time;
    bytes:         []u8;
    name_ptr:      *string;
    toggle:        bool;
}

serialize :: (s: *LBP_Serializer, game: *Game) {
    add(s, .INITIAL, *game.list_of_names);
    check_integrity(s, .INITIAL);

    rem(s, .ADDED_COLLECTOR, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, [..]s64);
    check_integrity(s, .ADDED_COLLECTOR);

    add(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP, *game.timestamp);
    check_integrity(s, .REMOVED_COLLECTOR_ADDED_TIMESTAMP);

    add(s, .ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL, *game.bytes);
    add(s, .ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL, *game.name_ptr);
    add(s, .ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL, *game.toggle);
    check_integrity(s, .ADDED_AN_ARRAY_OF_BYTES_A_POINTER_AND_A_BOOL);
}

// An example of custom serializing behavior. Serializing a double pointer is not handled by default.
serialize :: (s: *LBP_Serializer, str_ptr: **string) {
    if s.mode == {
        case .SERIALIZE;
            serialize(s, str_ptr.*);

        case .DESERIALIZE;
            new_str_ptr := New(string);
            serialize(s, new_str_ptr);
            str_ptr.* = new_str_ptr;
    }
}

#scope_file

#load "utils.jai";
#load "../module.jai";
#import "Basic";
