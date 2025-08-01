{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  libnfc,
  xz,
}:

stdenv.mkDerivation {
  pname = "mfoc-hardnested";
  version = "0-unstable-2023-03-27";

  src = fetchFromGitHub {
    owner = "nfc-tools";
    repo = "mfoc-hardnested";
    rev = "a6007437405a0f18642a4bbca2eeba67c623d736";
    hash = "sha256-YcUMS4wx5ML4yYiARyfm7T7nLomgG9YCSFj+ZUg5XZk=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    libnfc
    xz
  ];

  meta = with lib; {
    description = "Fork of mfoc integrating hardnested code from the proxmark";
    mainProgram = "mfoc-hardnested";
    license = licenses.gpl2;
    homepage = "https://github.com/nfc-tools/mfoc-hardnested";
    changelog = "https://github.com/nfc-tools/mfoc-hardnested/blob/master/debian/changelog";
    maintainers = with maintainers; [ azuwis ];
    platforms = platforms.unix;
  };
}
