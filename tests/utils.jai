compare_array :: (a: []$T, b: []T) {
    count_a := a.count;
    count_b := b.count;
    assert(count_a == count_b, "% vs %", count_a, count_b);
    for value_a: a {
        value_b := b[it_index];
        assert(value_b == value_a, "% vs %", value_b, value_a);
    }
}

save_game :: (path_to_save: string, state: *Game) -> bool {
    err, s := lbp_init(path_to_save, .SERIALIZE);
    if err != .NONE {
        log("Failed to init LBP_Serializer with a reason: %", err);
        return false;
    }
    defer lbp_deinit(*s, clear_memory_before_dealloc = true);

    serialize(*s, state);

    ok := lbp_commit_to_disk(*s);
    if ok log("Saved '%'.", path_to_save);
    else  log("Couldn't save '%'.", path_to_save);

    return ok;
}

load_game :: (path_to_save: string) -> bool, Game {
    err, s := lbp_init(path_to_save, .DESERIALIZE);
    if err != .NONE {
        log("Failed to init LBP_Serializer with a reason: %", err);
        return false, .{};
    }
    defer lbp_deinit(*s, clear_memory_before_dealloc = true);

    state: Game;
    serialize(*s, *state);

    log("Loaded '%'.", path_to_save);
    return true, state;
}
