load("@rules_apple//apple:apple.bzl", "apple_dynamic_framework_import")

apple_dynamic_framework_import(
    name = "framework",
    framework_imports = glob(["Sparkle.framework/**"]),
    visibility = ["//visibility:public"],
)

exports_files([
    "LICENSE",
    "bin/generate_appcast",
    "bin/generate_keys",
    "bin/sign_update",
])
