{
  stdenv,
  lib,
  fetchFromGitHub,
  coreutils,
  lazarus,
  fpc,
  libX11,

  # GTK2/3
  pango,
  cairo,
  glib,
  atk,
  gtk2,
  gtk3,
  gdk-pixbuf,
  python3,

  # Qt5
  libsForQt5,

  widgetset ? "qt5",
  # See https://github.com/Alexey-T/CudaText-lexers
  additionalLexers ? [ "Nix" ],
}:

assert builtins.elem widgetset [
  "gtk2"
  "gtk3"
  "qt5"
];

let
  deps = lib.mapAttrs (
    name: spec:
    fetchFromGitHub {
      repo = name;
      inherit (spec) owner rev hash;
    }
  ) (lib.importJSON ./deps.json);
in
stdenv.mkDerivation rec {
  pname = "cudatext";
  version = "1.202.1";

  src = fetchFromGitHub {
    owner = "Alexey-T";
    repo = "CudaText";
    rev = version;
    hash = "sha256-ZFMO986D4RtrTnLFdcL0a2BNjcsB+9pIolylblku7j4=";
  };

  patches = [ ./proc_globdata.patch ];

  postPatch = ''
    substituteInPlace app/proc_globdata.pas \
      --subst-var out \
      --subst-var-by python3 ${python3}
    substituteInPlace app/proc_editor_saving.pas \
      --replace-fail '/bin/cp' "${coreutils}/bin/cp"
  '';

  nativeBuildInputs = [
    lazarus
    fpc
  ]
  ++ lib.optional (widgetset == "qt5") libsForQt5.wrapQtAppsHook;

  buildInputs = [
    libX11
  ]
  ++ lib.optionals (lib.hasPrefix "gtk" widgetset) [
    pango
    cairo
    glib
    atk
    gdk-pixbuf
  ]
  ++ lib.optional (widgetset == "gtk2") gtk2
  ++ lib.optional (widgetset == "gtk3") gtk3
  ++ lib.optional (widgetset == "qt5") libsForQt5.libqtpas;

  NIX_LDFLAGS = "--as-needed -rpath ${lib.makeLibraryPath buildInputs}";

  buildPhase =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: dep: ''
        cp -r ${dep} ${name}
      '') deps
    )
    + ''
      # See https://wiki.freepascal.org/CudaText#How_to_compile_CudaText
      substituteInPlace ATSynEdit/atsynedit/atsynedit_package.lpk \
        --replace GTK2_IME_CODE _GTK2_IME_CODE

      lazbuild --lazarusdir=${lazarus}/share/lazarus --pcp=./lazarus --ws=${widgetset} \
        bgrabitmap/bgrabitmap/bgrabitmappack.lpk \
        EncConv/encconv/encconv_package.lpk \
        ATBinHex-Lazarus/atbinhex/atbinhex_package.lpk \
        ATFlatControls/atflatcontrols/atflatcontrols_package.lpk \
        ATSynEdit/atsynedit/atsynedit_package.lpk \
        ATSynEdit_Cmp/atsynedit_cmp/atsynedit_cmp_package.lpk \
        EControl/econtrol/econtrol_package.lpk \
        ATSynEdit_Ex/atsynedit_ex/atsynedit_ex_package.lpk \
        Python-for-Lazarus/python4lazarus/python4lazarus_package.lpk \
        Emmet-Pascal/emmet/emmet_package.lpk \
        app/cudatext.lpi
    '';

  installPhase = ''
    install -Dm755 app/cudatext -t $out/bin

    install -dm755 $out/share/cudatext
    cp -r app/{data,py,settings_default} $out/share/cudatext

    install -Dm644 setup/debfiles/cudatext-512.png -t $out/share/pixmaps
    install -Dm644 setup/debfiles/cudatext.desktop -t $out/share/applications
  ''
  + lib.concatMapStringsSep "\n" (lexer: ''
    if [ -d "CudaText-lexers/${lexer}" ]; then
      install -Dm644 CudaText-lexers/${lexer}/*.{cuda-lexmap,lcf} $out/share/cudatext/data/lexlib
    else
      echo "${lexer} lexer not found"
      exit 1
    fi
  '') additionalLexers;

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Cross-platform code editor";
    longDescription = ''
      Text/code editor with lite UI. Syntax highlighting for 200+ languages.
      Config system in JSON files. Multi-carets and multi-selections.
      Search and replace with RegEx. Extendable by Python plugins and themes.
    '';
    homepage = "https://cudatext.github.io/";
    changelog = "https://cudatext.github.io/history.txt";
    license = licenses.mpl20;
    maintainers = with maintainers; [ sikmir ];
    platforms = platforms.linux;
    mainProgram = "cudatext";
  };
}
