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

	doCheck = false;

	nativeBuildInputs = [
		pkgs.pandoc
	];
}
