//
// All credit for the methodology goes to https://handmade.network/p/29/swedish-cubes-for-unity/blog/p/2723-how_media_molecule_does_serialization
//
// If you deserialize arrays, then stuff will be allocated by the context.allocator
// to make that happen.
//

//
// You are expected to provide a type with a Version enum and all the serialize
// overloads you need the LBP_Serializer procedures to see. If you need more
// examples try to look into how the tests work.
//
//     Example_Serializer_Info :: struct {
//         Version :: enum s32 {
//             INVALID :: -1;
//             INITIAL;
//             LATEST :: INITIAL;
//         }
//
//         serialize :: (s: *LBP_Serializer, something_bespoke: *Something_Bespoke) {
//             // ...
//         }
//     }
//
#module_parameters(Serializer_Info: Type);

using Serializer_Info;

#assert(#exists(Version));
#assert(is_an_enum(Version));
#assert(get_internal_enum_type(Version) == s32);
#assert(enum_has_names(Version, .["INVALID", "INITIAL", "LATEST"]));

// @TODO: A generic serialize that could be used when the user doesn't need to
// guarantee forwards compatibility.

LBP_Serializer :: struct {
    data_version:       Version = .INVALID;
    integrity_counter:  s32;
    bytes:              [..]u8;
    offset_into_bytes:  s64;
    path_to_save_file:  string;
    mode:               Mode;
    initted_with_bytes: bool;

    Mode :: enum #complete { SERIALIZE; DESERIALIZE; }
}

LBP_Init_Error :: enum #complete {
    NONE :: 0;
    COULDNT_READ_FILE;
    DATA_IS_NEWER_THAN_THE_SERIALIZATION_CODE;
    READ_AN_INVALID_VERSION_FROM_THE_DATA;
    INITIALIZING_WITH_BYTES_IS_ONLY_SUPPORTED_FOR_DESERIALIZING;
}

lbp_init :: (bytes: []u8, mode: LBP_Serializer.Mode) -> LBP_Init_Error, LBP_Serializer {
    if mode != .DESERIALIZE {
        return .INITIALIZING_WITH_BYTES_IS_ONLY_SUPPORTED_FOR_DESERIALIZING, .{};
    }

    _bytes: [..]u8;
    _bytes.data      = bytes.data;
    _bytes.count     = bytes.count;
    _bytes.allocator = null_allocator;

    ser: LBP_Serializer = .{ .LATEST, 0, _bytes, 0, "", mode, true };
    serialize(*ser, *ser.data_version);

    if ser.data_version > .LATEST {
        return .DATA_IS_NEWER_THAN_THE_SERIALIZATION_CODE, .{};
    }

    if ser.data_version == .INVALID {
        return .READ_AN_INVALID_VERSION_FROM_THE_DATA, .{};
    }

    return .NONE, ser;
}

lbp_init :: (file_path: string, mode: LBP_Serializer.Mode) -> LBP_Init_Error, LBP_Serializer {
    bytes: [..]u8;

    if mode == .DESERIALIZE {
        bytes_as_str, ok := read_entire_file(file_path);
        if !ok return .COULDNT_READ_FILE, .{};

        bytes.data      = bytes_as_str.data;
        bytes.count     = bytes_as_str.count;
        bytes.allocator = null_allocator;
    }

    ser: LBP_Serializer = .{ .LATEST, 0, bytes, 0, file_path, mode, false };
    serialize(*ser, *ser.data_version);

    if mode == .DESERIALIZE && ser.data_version > .LATEST {
        return .DATA_IS_NEWER_THAN_THE_SERIALIZATION_CODE, .{};
    }

    if ser.data_version == .INVALID {
        return .READ_AN_INVALID_VERSION_FROM_THE_DATA, .{};
    }

    return .NONE, ser;
}

lbp_reserve :: inline (s: *LBP_Serializer, count: s64) {
    array_reserve(*s.bytes, count);
}

lbp_reset_integrity_counter :: inline (s: *LBP_Serializer) {
    s.integrity_counter = 0;
}

lbp_commit_to_disk :: (s: *LBP_Serializer) -> bool {
    bytes_as_str := cast(string) s.bytes;
    ok := write_entire_file(s.path_to_save_file, bytes_as_str);
    return ok;
}


lbp_deinit :: (s: *LBP_Serializer, clear_memory_before_dealloc := false) {
    if s.initted_with_bytes {
        //
        // When initting with bytes the whole idea is that we don't own them,
        // so don't try to deallocate anything here..
        //
        assert(s.mode == .DESERIALIZE);
        return;
    }
    //
    // For the duration of deserializing there is a null allocator on s.bytes
    // to disallow manipulating what was the original memory, but when freeing
    // we want to actually free the loaded bytes.
    //
    // There is also an option to clear memory before deallocating it. This is
    // potentially helpful for finding things that reference bytes in loaded
    // memory.
    //
    s.bytes.allocator = context.allocator;
    if clear_memory_before_dealloc memset(s.bytes.data, 0xAA, s.bytes.count);
    array_free(s.bytes);
}

read_bytes :: (s: *LBP_Serializer, byte_count: s64) -> []u8 {
    assert(s.offset_into_bytes + byte_count <= s.bytes.count, "Read overflow.");
    bytes: []u8;
    bytes.data  = s.bytes.data + s.offset_into_bytes;
    bytes.count = byte_count;
    s.offset_into_bytes += byte_count;
    return bytes;
}

read_type :: (s: *LBP_Serializer, $T: Type) -> T {
    bytes := read_bytes(s, size_of(T));
    type := bytes.data.(*T).*;
    return type;
}

write_bytes :: inline (s: *LBP_Serializer, bytes: []u8) {
    array_add(*s.bytes, ..bytes);
}

write_type :: (s: *LBP_Serializer, value: *$T) {
    bytes: []u8;
    bytes.data  = xx value;
    bytes.count = size_of(T);
    write_bytes(s, bytes);
}

serialize :: (s: *LBP_Serializer, number: *$T) #modify { return is_a_number_type(T); } {
    if s.mode == {
        case .SERIALIZE;
            write_type(s, number);

        case .DESERIALIZE;
            number.* = read_type(s, T);
    }
}

serialize :: (s: *LBP_Serializer, big_int: *S128) {
    if s.mode == {
        case .SERIALIZE;
            write_type(s, big_int);

        case .DESERIALIZE;
            big_int.* = read_type(s, S128);
    }
}

serialize :: (s: *LBP_Serializer, text: *string) {
    serialize(s, cast(*[]u8) text);
}

serialize :: (s: *LBP_Serializer, _bool: *bool) {
    if s.mode == {
        case .SERIALIZE;
            write_type(s, _bool);

        case .DESERIALIZE;
            _bool.* = read_type(s, bool);
    }
}

serialize :: (s: *LBP_Serializer, vec2: *Vector2) {
    serialize(s, *vec2.x);
    serialize(s, *vec2.y);
}

serialize :: (s: *LBP_Serializer, vec3: *Vector3) {
    serialize(s, *vec3.x);
    serialize(s, *vec3.y);
    serialize(s, *vec3.z);
}

serialize :: (s: *LBP_Serializer, vec4: *Vector4) {
    serialize(s, *vec4.x);
    serialize(s, *vec4.y);
    serialize(s, *vec4.z);
    serialize(s, *vec4.w);
}

serialize :: (s: *LBP_Serializer, _enum: *$T) #modify { return is_an_enum(T); } {
    Int_Type :: #run get_internal_enum_type(T);
    serialize(s, cast(*Int_Type) _enum);
}

serialize :: (s: *LBP_Serializer, apollo_time: *Apollo_Time) {
    Variant_Type :: #run get_type_of_variant(Apollo_Time);
    serialize(s, cast(*Variant_Type) apollo_time);
}

serialize :: (s: *LBP_Serializer, resizable_array: *[..]$T) {
    count := resizable_array.count;
    serialize(s, *count);

    if s.mode == .DESERIALIZE {
        assert(resizable_array.count == 0, ARRAY_DESERIALIZATION_MISUSE_ERROR_MSG);
        array_resize(resizable_array, count);
    }

    for * resizable_array.* {
        serialize(s, it);
    }
}

serialize :: (s: *LBP_Serializer, array: *[]$T) {
    count := array.count;
    serialize(s, *count);

    if s.mode == .DESERIALIZE {
        //
        // Probably should be allowed, but reported back somehow. For now
        // disallowing it as I do not see a real use-case.
        //
        assert(array.count == 0, ARRAY_DESERIALIZATION_MISUSE_ERROR_MSG);

        if count > 0 {
            array.* = NewArray(count, T);
        }
    }

    for * array.* {
        serialize(s, it);
    }
}

serialize :: (s: *LBP_Serializer, array: *[$N]$T) {
    for * array.* {
        serialize(s, it);
    }
}

add :: (s: *LBP_Serializer, $added_in_version: Version, datum: *$T) {
    if s.data_version >= added_in_version {
        serialize(s, datum);
    }
}

rem :: (s: *LBP_Serializer, $added_in_version: Version, $removed_in_version: Version, $T: Type) -> T {
    value: T;

    if s.data_version >= added_in_version && s.data_version < removed_in_version {
        serialize(s, *value);
    }

    return value;
}

check_integrity :: (s: *LBP_Serializer, $added_in_version: Version) -> bool {
    if s.data_version >= added_in_version {
        check := s.integrity_counter;
        serialize(s, *check);

        if check != s.integrity_counter {
            log("Integrity check failed at version %. File counter: %, code counter: %.", added_in_version, check, s.integrity_counter, flags = .ERROR);
            return false;
        }

        s.integrity_counter += 1;
    }

    return true;
}

#scope_file

ARRAY_DESERIALIZATION_MISUSE_ERROR_MSG :: "Deserialize into fresh memory only. If you hit this with a legitimate use-case, then I might reconsider.";

null_allocator: Allocator = .{
    data = null,
    proc = null_allocator_proc,
};

null_allocator_proc :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    assert(false, "This allocator is explicitly for disallowing allocations entirely.");
    return null;
}

is_an_enum :: ($$type: Type) -> bool {
    return is_an_enum(cast(*Type_Info) type);
}

is_an_enum :: ($$ti: *Type_Info) -> bool {
    return ti.type == .ENUM;
}

enum_has_name :: ($E: Type, name: string) -> bool {
    #assert(is_an_enum(E));

    ti := cast(*Type_Info_Enum) E;
    for ti.names {
        if it == name return true;
    }

    return false;
}

enum_has_names :: ($E: Type, names: []string) -> bool {
    for names {
        if !enum_has_name(E, it) return false;
    }

    return true;
}

is_a_number_type :: (type: Type) -> bool {
    return is_a_number_type(cast(*Type_Info) type);
}

is_a_number_type :: (ti: *Type_Info) -> bool {
    type := ti.type;
    if type == .VARIANT && is_a_number_type(cast(*Type_Info_Variant, ti).variant_of.type) {
        return true;
    }
    return is_a_number_type(type);
}

is_a_number_type :: (type: Type_Info_Tag) -> bool {
    return type == .FLOAT || type == .INTEGER;
}

get_internal_enum_type :: ($E: Type) -> Type {
    ti :: type_info(E);
    #assert(is_an_enum(ti));
    ti_e :: cast(*Type_Info_Enum) ti;

    return get_type(ti_e.internal_type);
}

is_a_variant_type :: ($T: Type) -> bool {
    ti := cast(*Type_Info) T;
    return ti.type == .VARIANT;
}

get_type_of_variant :: ($T: Type) -> Type {
    #assert(is_a_variant_type(T));
    ti := cast(*Type_Info_Variant) T;
    Variant_Type := get_type(ti.variant_of);
    return Variant_Type;
}

#import "Compiler";
#import "Basic";
#import "File";
#import "File_Utilities";
#import "Math";
