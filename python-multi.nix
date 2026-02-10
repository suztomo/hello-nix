{ pkgs }:

let
  pythonVersions = [
    pkgs.python310
    pkgs.python311
    pkgs.python312
    pkgs.python313
    # pkgs.python314 # May need unstable or custom derivation if not in current nixpkgs
  ];

  # Helper to create a python with common tools
  pythonWithTools = py: py.withPackages (ps: with ps; [
    pip
    virtualenv
    setuptools
    wheel
  ]);

  py310 = pythonWithTools pkgs.python310;
  py311 = pythonWithTools pkgs.python311;
  py312 = pythonWithTools pkgs.python312;
  py313 = pythonWithTools pkgs.python313;

  # Combine all python versions into one environment
  # We want python3 to point to python3.12
  combinedPython = pkgs.symlinkJoin {
    name = "combined-python";
    paths = [
      py310
      py311
      py312
      py313
    ];
    postBuild = ''
      ln -sf ${py312}/bin/python3 $out/bin/python3
      ln -sf ${py312}/bin/pip3 $out/bin/pip3
    '';
  };

  # Define the system packages
  systemPackages = with pkgs; [
    bashInteractive
    coreutils
    curl
    wget
    git
    jq
    unzip
    zip
    gnupg
    cacert
    docker
    
    # Build tools
    stdenv.cc.cc
    binutils
    pkg-config
    gnumake
    
    # Libraries
    openssl
    zlib
    bzip2
    sqlite
    libffi
    postgresql
    libyaml
    snappy
    
    # GIS/Graph
    gdal
    graphviz
    
    # ODBC
    unixODBC
    unixODBCDrivers.msodbcsql17
    
    # Data Stores (binaries only)
    redis
    memcached
    
    # Cloud SDK
    google-cloud-sdk
    
    # Other tools from Dockerfile
    python312Packages.nox
    aspell
    aspellDicts.en
    enchant_2
    hunspell
    hunspellDicts.en_US
  ];

in
pkgs.dockerTools.buildLayeredImage {
  name = "python-multi";
  tag = "latest";

  contents = systemPackages ++ [
    combinedPython
  ];

  config = {
    Env = [
      "PATH=/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
      "LANG=C.UTF-8"
      "DEBIAN_FRONTEND=noninteractive"
      "CLOUDSDK_PYTHON=python3.12"
      "PYTHONUNBUFFERED=1"
    ];
    WorkingDir = "/workspace";
    Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];
    Labels = {
      "org.opencontainers.image.description" = "Multi-Python testing environment with Cloud SDK and system dependencies";
      "org.opencontainers.image.source" = "https://github.com/suztomo/hello-nix";
    };
  };
}
