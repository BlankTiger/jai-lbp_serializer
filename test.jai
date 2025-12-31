//
// Compilation test command: jai -x64 -no_dce -quiet test.jai
//

main :: () {}

Version :: enum s32 {
    INVALID :: -1;

    INITIAL;

    LATEST :: INITIAL;
}

#load "module.jai";
