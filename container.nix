{ nixpkgs, system, php }:

with import nixpkgs { inherit system; };
let
  opencart = callPackage ./pkgs/opencart { };

  entrypoint = (stdenv.mkDerivation rec {
    name = "opencart-install";
    builder = writeScript "builder.sh" (
      ''
        source $stdenv/setup
        mkdir -p $out/bin

        cat > $out/bin/${name}.sh <<'EOF'
        #!${bash}/bin/bash
        set -ex
        export PATH=${coreutils}/bin:${unzip}/bin:${php}/bin:${gnused}/bin


        echo "Extract installer archive."
        unzip ${opencart} upload/*
        shopt -s dotglob
        mv upload/* .
        rm -r upload

        echo "Run installer"
        php install/cli_install.php install \
        --db_hostname $DB_HOST \
        --db_username $DB_USER \
        --db_password $DB_PASSWORD \
        --db_database $DB_NAME \
        --db_driver mysqli \
        --username $ADMIN_USERNAME \
        --password $ADMIN_PASSWORD \
        --email $ADMIN_EMAIL \
        --http_server $PROTOCOL://$DOMAIN_NAME/

        echo "Clean up installation"
        rm -rf install
        rm php.ini config-dist.php admin/config-dist.php
        echo "Finish installation"

        for c in config.php admin/config.php; do
          sed -i "s#/workdir#$DOCUMENT_ROOT#g" $c
        done
        mv .htaccess.txt .htaccess

        EOF

        chmod 555 $out/bin/${name}.sh
      ''
    );
  });

in
pkgs.dockerTools.buildLayeredImage rec {
  name = "docker-registry.intr/apps/opencart";

  contents = [ bashInteractive coreutils unzip php entrypoint ];
  config = {
    Entrypoint = "${entrypoint}/bin/opencart-install.sh";
    Env = [
      "TZ=Europe/Moscow"
      "TZDIR=${tzdata}/share/zoneinfo"
      "LOCALE_ARCHIVE_2_27=${glibcLocales}/lib/locale/locale-archive"
      "LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive"
      "LC_ALL=en_US.UTF-8"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    ];
    WorkingDir = "/workdir";
  };
  extraCommands = ''
    mkdir -p usr/bin etc tmp
    chmod 777 tmp
    ln -s ${coreutils}/bin/ln usr/bin/env

    cat > etc/passwd << 'EOF'
    root:!:0:0:System administrator:/root:/bin/sh
    alice:!:1000:997:Alice:/home/alice:/bin/sh
    EOF

    cat > etc/group << 'EOF'
    root:!:0:
    users:!:997:
    EOF

    cat > etc/nsswitch.conf << 'EOF'
    hosts: files dns
    EOF
  '';

}
