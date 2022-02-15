{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
	pname = "marka";
	version = "v0.1";

	src = ./.;

	buildInputs = [
    	pkgs.crystal
	];

	buildPhase = ''
		crystal build marka.cr
	'';

	installPhase = ''
		mkdir -p $out/bin
		mv marka $out/bin/
	'';
}
