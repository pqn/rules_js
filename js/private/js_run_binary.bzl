"""Runs a js_binary as a build action.

This macro wraps Aspect bazel-lib's run_binary (https://github.com/aspect-build/bazel-lib/blob/main/lib/run_binary.bzl)
and adds attributes and features specific to rules_js's js_binary.

Load this with,

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
```
"""

load("@aspect_bazel_lib//lib:run_binary.bzl", _run_binary = "run_binary")
load("@aspect_bazel_lib//lib:utils.bzl", "to_label")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", _copy_to_bin = "copy_to_bin")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//js/private:js_binary.bzl", _js_binary_envs_for_log_level = "envs_for_log_level")

def js_run_binary(
        name,
        tool,
        env = {},
        srcs = [],
        outs = [],
        out_dirs = [],
        args = [],
        chdir = None,
        stdout = None,
        stderr = None,
        exit_code_out = None,
        silent_on_success = True,
        copy_srcs_to_bin = True,
        log_level = None,
        mnemonic = "JsRunBinary",
        progress_message = None,
        execution_requirements = None,
        patch_node_fs = True,
        **kwargs):
    """Wrapper around @aspect_bazel_lib run_binary that adds convienence attributes for using a js_binary tool.

    This rule does not require Bash `native.genrule`.

    Args:
        name: Target name
        tool: The tool to run in the action.

            Should be a js_binary rule. Use Aspect bazel-lib's run_binary
            (https://github.com/aspect-build/bazel-lib/blob/main/lib/run_binary.bzl)
            for other *_binary rule types.

        env: Environment variables of the action.

            Subject to `$(location)` and make variable expansion.

        srcs: Additional inputs of the action.

            These labels are available for `$(location)` expansion in `args` and `env`.

        outs: Output files generated by the action.

            These labels are available for `$(location)` expansion in `args` and `env`.

        out_dirs: Output directories generated by the action.

            These labels are _not_ available for `$(location)` expansion in `args` and `env` since
            they are not pre-declared labels created via attr.output_list(). Output directories are
            declared instead by `ctx.actions.declare_directory`.

        args: Command line arguments of the binary.

            Subject to `$(location)` and make variable expansion.

        chdir: Working directory to run the binary or test in, relative to the workspace.

            This overrides the chdir value if set on the js_binary tool target.

            By default, Bazel always runs in the workspace root.

            To run in the directory containing the js_run_binary under the source tree, use
            `chdir = package_name()` (or if you're in a macro, use `native.package_name()`).

            To run in the output directory where the js_run_binary writes outputs, use
            `chdir = "$(RULEDIR)"`

            WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,
            which are workspace-relative.

            You may need `../../` segments to re-relativize such paths to the new working directory.

        stderr: set to capture the stderr of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`

        stdout: set to capture the stdout of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`

        exit_code_out: set to capture the exit code of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`. Note that setting this will force the binary to exit 0.

            If the binary creates outputs and these are declared, they must still be created

        silent_on_success: produce no output on stdout nor stderr when program exits with status code 0.

            This makes node binaries match the expected bazel paradigm.

        copy_srcs_to_bin: When True, all srcs files are copied to the output tree that are not already there.

        log_level: Set the logging level of the js_binary tool.

            This overrides the log level set on the js_binary tool target.

        mnemonic: A one-word description of the action, for example, CppCompile or GoLink.

        progress_message: Progress message to show to the user during the build, for example,
            "Compiling foo.cc to create foo.o". The message may contain %{label}, %{input}, or
            %{output} patterns, which are substituted with label string, first input, or output's
            path, respectively. Prefer to use patterns instead of static strings, because the former
            are more efficient.

        execution_requirements: Information for scheduling the action.

            For example,

            ```
            execution_requirements = {
                "no-cache": "1",
            },
            ```

            See https://docs.bazel.build/versions/main/be/common-definitions.html#common.tags for useful keys.

        patch_node_fs: Patch the to Node.js `fs` API (https://nodejs.org/api/fs.html) for this node program
            to prevent the program from following symlinks out of the execroot, runfiles and the sandbox.

            When enabled, `js_binary` patches the Node.js sync and async `fs` API functions `lstat`,
            `readlink`, `realpath`, `readdir` and `opendir` so that the node program being
            run cannot resolve symlinks out of the execroot and the runfiles tree. When in the sandbox,
            these patches prevent the program being run from resolving symlinks out of the sandbox.

            When disabled, node programs can leave the execroot, runfiles and sandbox by following symlinks
            which can lead to non-hermetic behavior.

        **kwargs: Additional arguments
    """

    # Friendly fail if user has specified data instead of srcs
    data = kwargs.pop("data", None)
    if data != None:
        fail("Use srcs instead of data in js_run_binary: https://github.com/aspect-build/rules_js/blob/main/docs/js_run_binary.md#js_run_binary-srcs.")

    # Copy srcs to bin
    extra_srcs = []
    if copy_srcs_to_bin:
        copy_to_bin_name = "%s_copy_srcs_to_bin" % name
        _copy_to_bin(
            name = copy_to_bin_name,
            srcs = srcs,
            tags = kwargs.get("tags"),
        )
        extra_srcs = [":%s" % copy_to_bin_name]

    # Automatically add common and useful make variables to the environment for js_run_binary build targets
    extra_env = {
        "BAZEL_BINDIR": "$(BINDIR)",
        "BAZEL_BUILD_FILE_PATH": "$(BUILD_FILE_PATH)",
        "BAZEL_COMPILATION_MODE": "$(COMPILATION_MODE)",
        "BAZEL_INFO_FILE": "$(INFO_FILE)",
        "BAZEL_TARGET_CPU": "$(TARGET_CPU)",
        "BAZEL_TARGET": "$(TARGET)",
        "BAZEL_VERSION_FILE": "$(VERSION_FILE)",
        "BAZEL_WORKSPACE": "$(WORKSPACE)",
    }

    # Configure working directory to `chdir` is set
    if chdir:
        extra_env["JS_BINARY__CHDIR"] = chdir

    # Configure capturing stdout, stderr and/or the exit code
    extra_outs = []
    if stdout:
        extra_env["JS_BINARY__STDOUT_OUTPUT_FILE"] = "$(execpath {})".format(stdout)
        extra_outs.append(stdout)
    if stderr:
        extra_env["JS_BINARY__STDERR_OUTPUT_FILE"] = "$(execpath {})".format(stderr)
        extra_outs.append(stderr)
    if exit_code_out:
        extra_env["JS_BINARY__EXIT_CODE_OUTPUT_FILE"] = "$(execpath {})".format(exit_code_out)
        extra_outs.append(exit_code_out)

    # Configure silent on success
    if silent_on_success:
        extra_env["JS_BINARY__SILENT_ON_SUCCESS"] = "1"

    # Disable node patches if requested
    if patch_node_fs:
        extra_env["JS_BINARY__PATCH_NODE_FS"] = "1"
    else:
        # Set explicitly to "0" so disable overrides any enable in the js_binary
        extra_env["JS_BINARY__PATCH_NODE_FS"] = "0"

    # Configure log_level if specified
    if log_level:
        for log_level_env in _js_binary_envs_for_log_level(log_level):
            extra_env[log_level_env] = "1"

    if not stdout and not stderr and not exit_code_out and (len(outs) + len(out_dirs) < 1):
        # run_binary will produce the actual error, but we want to give an additional JS-specific
        # warning message here. Note that as a macro, we can't tell the name of the rule provided
        # by the users BUILD file (e.g. for "typescript_bin.tsc(outs = [])" we'd wish to say
        # "try using tsc_binary instead")
        # buildifier: disable=print
        print("""\
WARNING: {name} is not configured to produce outputs.
        
If this is a generated bin from package_json.bzl, consider using the *_binary variant instead.
""".format(
            name = to_label(name),
        ))

    _run_binary(
        name = name,
        tool = tool,
        env = dicts.add(extra_env, env),
        srcs = srcs + extra_srcs,
        outs = outs + extra_outs,
        out_dirs = out_dirs,
        args = args,
        mnemonic = mnemonic,
        progress_message = progress_message,
        execution_requirements = execution_requirements,
        **kwargs
    )
