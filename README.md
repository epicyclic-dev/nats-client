# NATS - Zig Client

This is a Zig client library for the [NATS messaging system](https://nats.io). It's currently a thin wrapper over [NATS.c](https://github.com/nats-io/nats.c).

There are three main goals:

  1. Provide a Zig package that can be used with the Zig package manager.
  2. Provide a native-feeling Zig client API.
  3. Support cross-compilation to the platforms that Zig supports.

Right now, in service of goal 3, the underlying C library is built without certain features (notably, without TLS support and without streaming support) because those features require wrangling some complex transitive dependencies (OpenSSL and Protocol Buffers, respectively). Solving this limitation is somewhere on the roadmap, but it's not high priority.

# Zig Version Support

Since the language is still under active development, any written Zig code is a moving target. The plan is to support Zig `0.11.*` exclusively until the NATS library API has good coverage and is stabilized. At that point, if there are major breaking changes, a maintenance branch will be created, and master will probably move to track Zig master.

# Building

Currently, a demonstration executable can be built in the standard fashion, i.e. by running `zig build`.

# License

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
