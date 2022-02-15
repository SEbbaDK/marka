{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
	pname = "marka";
	version = "v0.1";

	src = ./.;

	buildInputs = [
    	pkgs.crystal
	];

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
