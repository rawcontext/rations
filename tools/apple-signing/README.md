# Raw Context signing

Rations uses Raw Context LLC, team `U65DCW9TAK`:

- Development bundle: `com.rawcontext.rations.dev`
- Production bundle: `com.rawcontext.rations`

The checked-in Xcode project uses automatic signing with that team. Certificates
and profiles remain in the developer's Keychain and Xcode storage. The development
entitlements identify the application and signing team.

```sh
make build SIGNED=1
make build CONFIGURATION=Release SIGNED=1
make xcode
```

Debug and Release select their bundle IDs through `.xcconfig` files. A production
bundle ID with development signing is not a distributable release. Developer ID
signing and notarization use the [direct-release workflow](../../docs/releases.md).

Makefile builds default to ad-hoc signing without development entitlements, so CI
can build and test without private signing assets. `make archive` creates an
unsigned universal archive that the release workflow signs from the inside out.
