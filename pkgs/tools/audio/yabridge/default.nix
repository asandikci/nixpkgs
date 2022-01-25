{ lib
, multiStdenv
, fetchFromGitHub
, substituteAll
, pkgsi686Linux
, libnotify
, meson
, ninja
, pkg-config
, wine
, boost
, libxcb
, nix-update-script
}:

let
  # Derived from subprojects/bitsery.wrap
  bitsery = fetchFromGitHub {
    owner = "fraillt";
    repo = "bitsery";
    rev = "c0fc083c9de805e5825d7553507569febf6a6f93";
    sha256 = "sha256-VwzVtxt+E/SVcxqIJw8BKPO2q7bu/hkhY+nB7FHrZpY=";
  };

  # Derived from subprojects/function2.wrap
  function2 = fetchFromGitHub {
    owner = "Naios";
    repo = "function2";
    rev = "02ca99831de59c7c3a4b834789260253cace0ced";
    sha256 = "sha256-wrt+fCcM6YD4ZRZYvqqB+fNakCNmltdPZKlNkPLtgMs=";
  };

  # Derived from subprojects/tomlplusplus.wrap
  tomlplusplus = fetchFromGitHub {
    owner = "marzer";
    repo = "tomlplusplus";
    rev = "47216c8a73d77e7431ec536fb3e251aed06cc420";
    sha256 = "sha256-cwAzWu5j3ch/56a6JmEoKCsxVNTk6tiZswNdNT6qzX0=";
  };

  # Derived from vst3.wrap
  vst3 = fetchFromGitHub {
    owner = "robbert-vdh";
    repo = "vst3sdk";
    rev = "v3.7.3_build_20-patched";
    fetchSubmodules = true;
    sha256 = "sha256-m2y7No7BNbIjLNgdAqIAEr6UuAZZ/wwM2+iPWKK17gQ=";
  };
in multiStdenv.mkDerivation rec {
  pname = "yabridge";
  version = "3.7.0";

  # NOTE: Also update yabridgectl's cargoHash when this is updated
  src = fetchFromGitHub {
    owner = "robbert-vdh";
    repo = pname;
    rev = version;
    sha256 = "sha256-dz7kScNrVUsjokJntzUCJzDIboqi3vQI+RpXl0UFmUQ=";
  };

  # Unpack subproject sources
  postUnpack = ''(
    cd "$sourceRoot/subprojects"
    cp -R --no-preserve=mode,ownership ${bitsery} bitsery
    cp packagefiles/bitsery/* bitsery
    cp -R --no-preserve=mode,ownership ${function2} function2
    cp packagefiles/function2/* function2
    cp -R --no-preserve=mode,ownership ${tomlplusplus} tomlplusplus
    cp -R --no-preserve=mode,ownership ${vst3} vst3
  )'';

  patches = [
    # Hard code bitbridge & runtime dependencies
    (substituteAll {
      src = ./hardcode-dependencies.patch;
      boost32 = pkgsi686Linux.boost;
      libxcb32 = pkgsi686Linux.xorg.libxcb;
      inherit libnotify wine;
    })
  ];

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wine
  ];

  buildInputs = [
    boost
    libxcb
  ];

  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

  mesonFlags = [
    "--cross-file" "cross-wine.conf"
    "-Dwith-bitbridge=true"

    # Requires CMake and is unnecessary
    "-Dtomlplusplus:generate_cmake_config=false"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/lib"
    cp yabridge-group*.exe{,.so} "$out/bin"
    cp yabridge-host*.exe{,.so} "$out/bin"
    cp libyabridge-vst2.so "$out/lib"
    cp libyabridge-vst3.so "$out/lib"
    runHook postInstall
  '';

  # Hard code wine path in wrapper scripts generated by winegcc
  postFixup = ''
    for exe in "$out"/bin/*.exe; do
      substituteInPlace "$exe" \
        --replace 'WINELOADER="wine"' 'WINELOADER="${wine}/bin/wine"'
    done
  '';

  passthru.updateScript = nix-update-script {
    attrPath = pname;
  };

  meta = with lib; {
    description = "Yet Another VST bridge, run Windows VST2 plugins under Linux";
    homepage = "https://github.com/robbert-vdh/yabridge";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ kira-bruneau ];
    platforms = [ "x86_64-linux" ];
  };
}
