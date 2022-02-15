{ pkgs ? import <nixpkgs> {} }:
let
    shard = builtins.readFile ./shard.yml;
    version = builtins.head (builtins.match ".*\nversion: ([0-9.]+).*" shard);
in
pkgs.crystal.buildCrystalPackage {
	pname = "marka";
	inherit version;

	src = ./.;

	format = "shards";
	lockFile = ./shard.lock;
	shardsFile = ./shards.nix;

	docCheck = false;

	nativeBuildInputs = [
		pkgs.pandoc
	];

	buildPhase = ''
		crystal build --release --progress --verbose marka.cr
		crystal build --release --progress --verbose marka-combiner.cr
	'';

	installPhase = ''
		mkdir -p $out/bin
		mv marka $out/bin/
		mv marka-combiner $out/bin/
	'';
}
