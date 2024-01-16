# NATS - Zig Client

This is a Zig client library for the [NATS messaging system](https://nats.io). It's currently a thin wrapper over [NATS.c](https://github.com/nats-io/nats.c), which is included and automatically built as part of the package.

There are three main goals:

  1. Provide a Zig package that can be used with the Zig package manager.
  2. Provide a native-feeling Zig client API.
  3. Support cross-compilation to the platforms that Zig supports.

`nats.c` is compiled against a copy of LibreSSL that has been wrapped with the zig build system. This appears to work, but it notably is not specifically OpenSSL, so there may be corner cases around encrypted connections. The `protobuf-c` runtime library is compiled directly in-tree.

# Status

All basic `nats.c` APIs are wrapped. The JetStream APIs are not currently wrapped, and the streaming API is not wrapped. It is unlikely I will wrap these as I do not require them for my primary use case. Contributions on this front are welcome. People who are brave or desperate can use these APIs unwrapped through the exposed `nats.nats_c` object.

In theory, all wrapped APIs are referenced in unit tests so that they are at least checked to compile correctly. The unit tests do not do much in the way of behavioral testing, under the assumption that the underlying C library is well tested. However, there may be some gaps in the test coverage around less-common APIs.

The standard workflows around publishing and subscribing to messages seem to work well and feel (in my opinion) sufficiently Zig-like. Some of the APIs use getter/setter functions more heavily than I think a native Zig implementation would, due to the fact that the underlying C library is designed with a very clean opaque handle API style.

Only tagged release versions of `nats.c` will be used. The current version of `nats.c` being used is `3.7.0`.

# Zig Version Support

Since the language is still under active development, any written Zig code is a moving target. The master branch targets zig 0.12 development versions (though it is not guaranteed to work with all versions. Check the commit history for specific version updates). The `zig-0.11.x` branch targets the current stable zig release, 0.11.

# Using

NATS.zig is ready-to-use with the Zig package manager. With Zig 0.11.x, this means you will need to create a `build.zig.zon` and modify your `build.zig` to use the dependency.

### Example `build.zig.zon`

```zig
.{
    .name = "my cool project",
    .version = "0.1.0",
    .dependencies = .{
        .nats = .{
            .url = "https://github.com/epicyclic-dev/nats.zig/archive/<git commit hash>.tar.gz",
            // on first run, `zig build` will prompt you to add the missing hash.
            // .hash = "",
        },
    },
}
```

### Example `build.zig`

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const my_program = b.addExecutable(.{
        .name="cool-project",
        .root_source_file = .{.path = "my_cool_project.zig"},
    });

    const nats_dep = b.dependency("nats", .{});

    my_program.addModule("nats", nats_dep.module("nats"));
    my_program.linkLibrary(nats_dep.artifact("nats-c"));

    b.installArtifact(my_program);
}
```

# Building

Some basic example executables can be built using `zig build examples`. These examples expect you to be running a copy of `nats-server` listening for unencrypted connections on `localhost:4222` (the default NATS port).

# Testing

Unit tests can be run using `zig build test`. The unit tests expect an executable named `nats-server` to be in your PATH in order to run properly.

# License

Unless noted otherwise (check file headers), all source code is licensed under the Apache License, Version 2.0 (which is also the `nats.c` license).

```
Licensed under the Apache License, Version 2.0 (the "License");
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
