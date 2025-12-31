//
// To run tests: jai -x64 -quiet -no_dce tests/main.jai && tests/build/main
//

Program_Version :: enum #complete { V1; V2; V3; }

compile :: (program_version: Program_Version) {
    version_name := tprint("%", program_version);
    exe_file     := tprint("%.jai", version_name);

    build_opts := get_build_options();
    build_opts.output_executable_name = tprint("%", version_name);

    workspace := compiler_create_workspace(version_name);
    defer compiler_destroy_workspace(workspace);
    set_build_options(build_opts, workspace);

    add_build_file(exe_file, workspace);
}

build_dir :: "build";

build :: () {
    make_directory_if_it_does_not_exist(build_dir);
    set_build_options_dc(.{ output_path = build_dir });
    compile(.V1);
    compile(.V2);
    compile(.V3);
}

#run build();

main :: () {
    log("Running test scenarios..");

    run(.V1);
    run(.V2);
    run(.V3);

    log("Everything working as expected!");
}

run :: (program_version: Program_Version) {
    path_to_exe := tprint("tests/build/%", program_version);
    result, output, err_output := run_command(path_to_exe);
    assert(result.exit_code == 0);
}

#scope_file

#import "Basic";
#import "Compiler";
#import "Process";
#import "File";
