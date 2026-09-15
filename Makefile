SHELL := /bin/bash
.DEFAULT_GOAL := help
export DEVELOPER_DIR ?= /Applications/Xcode-beta.app/Contents/Developer

CONFIGURATION ?= Debug
export SIGNED ?= 0
ARGS ?=
XCODEBUILD = xcodebuild -project Rations.xcodeproj -scheme Rations \
	-derivedDataPath "$(CURDIR)/.build/Xcode" \
	-clonedSourcePackagesDirPath "$(CURDIR)/.build/SourcePackages"
ifeq ($(SIGNED),0)
SIGNING = CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
	CODE_SIGN_ENTITLEMENTS= ENABLE_HARDENED_RUNTIME=NO
endif

.PHONY: help bootstrap ci-tools build archive test test-app test-packages test-lint test-release \
	lint check dev verify debug logs telemetry xcode release-prepare release release-publish

help:
	@printf '%s\n' \
	  'make bootstrap       Install development checks and Git hooks' \
	  'make build           Build the native app (SIGNED=1 for team signing)' \
	  'make check           Lint, build, and run all tests' \
	  'make test            Run all tests' \
	  'make lint            Run Swift, shell, and duplicate-code checks' \
	  'make dev             Build and launch (ARGS=--settings to open Settings)' \
	  'make verify          Build, launch, and verify the app is running' \
	  'make debug           Build and launch under LLDB' \
	  'make logs            Build, launch, and stream process logs' \
	  'make telemetry       Build, launch, and stream development telemetry' \
	  'make xcode           Open the Xcode project' \
	  'make archive         Create an unsigned universal Release archive' \
	  'make release-prepare Build and validate the universal production app' \
	  'make release         Sign, notarize, and package the release' \
	  'make release-publish Publish the prepared release'

bootstrap:
	./scripts/bootstrap.sh

ci-tools:
	./scripts/install-ci-tools.sh

build:
	$(XCODEBUILD) -configuration $(CONFIGURATION) -destination 'platform=macOS' build $(SIGNING)

archive:
	$(XCODEBUILD) -configuration Release -destination 'generic/platform=macOS' \
	  -archivePath "$(CURDIR)/.build/Rations.xcarchive" archive \
	  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO CODE_SIGN_ENTITLEMENTS=

test: test-packages test-app test-lint test-release

test-packages:
	swift test --package-path packages

test-app:
	$(XCODEBUILD) -configuration Debug -destination 'platform=macOS' test $(SIGNING)

test-lint:
	swift test --package-path tools/cognitive-complexity

test-release:
	./tools/release/test.sh

lint:
	./scripts/lint.sh

check:
	$(MAKE) lint
	$(MAKE) build
	$(MAKE) test

dev verify debug logs telemetry:
	./scripts/build_and_run.sh --$(if $(filter dev,$@),run,$@) $(ARGS)

xcode:
	open Rations.xcodeproj

release-prepare release release-publish:
	python3 tools/release/release.py $(patsubst release-%,%,$@)
