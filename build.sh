#!/bin/bash

SCRIPT_FILE=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT_FILE)

OUTDIR=$SCRIPT_DIR/Artifacts

NUGET_CMD="mono $SCRIPT_DIR/tools/NuGet.exe"
RETRY_CMD="$SCRIPT_DIR/tools/retry.sh"
TIMEOUT_CMD="$SCRIPT_DIR/tools/timeout.sh"
DOTNET_CMD="$RETRY_CMD $TIMEOUT_CMD 600 dotnet"

RUN_BUILD="$DOTNET_CMD msbuild $SCRIPT_DIR/build/build.proj"
RUN_BUILD_DUMMY="$DOTNET_CMD build $SCRIPT_DIR/build/build.dummy.csproj"

usage() {
  echo "Usage: %0 [command] [args]"
  echo "Commands:"
  echo "    build [module]     Build a specific module"
  echo "    full               Build all modules in src/ directory"
  echo "    dummy              Generate dummy assemblies of all modules"
  echo "    pack [version]     Make a NuGet package with build artifacts"
  echo "    clean              Clean all artifacts"
}

cmd_build() {
  if [ -z "$1" ]; then
    echo "No module specified."
    exit 1
  fi
  if [ -d /nuget ]; then
    NUGET_SOURCE_OPT="/p:RestoreSources=/nuget"
  fi
  $RUN_BUILD /t:build /p:Project=$1 $NUGET_SOURCE_OPT
}

cmd_full_build() {
  if [ -d /nuget ]; then
    NUGET_SOURCE_OPT="/p:RestoreSources=/nuget"
  fi
  $RUN_BUILD /t:build $NUGET_SOURCE_OPT
}

cmd_dummy_build() {
  if [ -d /nuget ]; then
    NUGET_SOURCE_OPT="/p:RestoreSources=/nuget"
  fi
  $RUN_BUILD_DUMMY $NUGET_SOURCE_OPT
}

cmd_pack() {
  if [ -n "$1" ]; then
    NUGET_VERSION_OPT="-Version $1"
  fi

  $NUGET_CMD pack $SCRIPT_DIR/pkg/Tizen.NET.Private.nuspec -Symbols -NoPackageAnalysis $NUGET_VERSION_OPT -BasePath $SCRIPT_DIR -OutputDirectory $OUTDIR
  $NUGET_CMD pack $SCRIPT_DIR/pkg/Tizen.NET.nuspec -Symbols -NoPackageAnalysis $NUGET_VERSION_OPT -BasePath $SCRIPT_DIR -OutputDirectory $OUTDIR
}

cmd_clean() {
  $RUN_BUILD /t:clean
}

cmd=$1; shift;
case "$cmd" in
  build|--build|-b) cmd_build $@ ;;
  full |--full |-f)  cmd_full_build $@ ;;
  dummy|--dummy|-d) cmd_dummy_build $@ ;;
  pack |--pack |-p)  cmd_pack $@ ;;
  clean|--clean|-c) cmd_clean $@ ;;
  *)     usage ;;
esac
