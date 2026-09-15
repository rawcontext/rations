# Raw Context signing

Rations uses Raw Context LLC, team `U65DCW9TAK`:

- Development bundle: `com.rawcontext.rations.dev`
- Production bundle: `com.rawcontext.rations`

The profile rules follow the existing Eudoxus 3 setup. Xcode-managed development
builds resolve the local `Mac Team Provisioning Profile: *` for that team.
Certificates and profiles remain in the developer's Keychain/Xcode storage.
The only development entitlements identify the application and signing team.

```sh
bazel build --config=signed //apps/macos:app
bazel build --config=release --config=signed //apps/macos:app
npm run xcode
```

Generated Xcode Debug/Release configurations select the appropriate bundle ID
and the Raw Context profile automatically. The production bundle ID alone does
not make a development-signed build a distributable release. Developer ID signing
and notarization use the [direct-release workflow](../../docs/releases.md).

CI can generate the Xcode project and build ad-hoc without private signing assets.
