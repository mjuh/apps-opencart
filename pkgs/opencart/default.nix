{ stdenv, fetchurl, lib }:

stdenv.mkDerivation rec {
  pname = "opencart";
  version = "3.0.3.8";

  src = fetchurl {
    url = "https://github.com/opencart/opencart/releases/download/${version}/opencart-${version}.zip";
    sha256 = "sha256-AncLp534atq+GeaDpofGoxsTFieu1TzFf7SlUpwSXbU=";
  };

  sourceRoot = ".";


  unpackPhase = " ";
  installPhase = ''
    cp -r $src $out
  '';
}
