#!/usr/bin/env bash
# Cobblemon (Pokemon) Minecraft server - automatyczna instalacja (Linux/macOS)
#
# Robi to samo co setup.ps1, patrz komentarze tam po szczegoly.
# Wymaga: java (17+), curl, jq.

set -euo pipefail

MC_VERSION="1.20.1"
FABRIC_INSTALLER_VERSION="1.0.1"
SERVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODS_DIR="$SERVER_DIR/mods"

echo "=== Cobblemon Server Setup ==="
echo "Docelowy folder: $SERVER_DIR"

command -v java >/dev/null || { echo "Zainstaluj Java 17+ (np. https://adoptium.net/) i uruchom ponownie."; exit 1; }
command -v curl >/dev/null || { echo "Zainstaluj curl."; exit 1; }
command -v jq   >/dev/null || { echo "Zainstaluj jq."; exit 1; }

mkdir -p "$MODS_DIR"
cd "$SERVER_DIR"

INSTALLER_JAR="fabric-installer-$FABRIC_INSTALLER_VERSION.jar"
if [ ! -f "$INSTALLER_JAR" ]; then
    echo "Pobieram Fabric installer..."
    curl -fL -o "$INSTALLER_JAR" \
        "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$FABRIC_INSTALLER_VERSION/fabric-installer-$FABRIC_INSTALLER_VERSION.jar"
fi

echo "Instaluje serwer Fabric $MC_VERSION (pobiera oryginalny server.jar od Mojanga)..."
java -jar "$INSTALLER_JAR" server -mcversion "$MC_VERSION" -downloadMinecraft -dir "$SERVER_DIR"

fetch_modrinth() {
    local slug="$1"
    local uri="https://api.modrinth.com/v2/project/${slug}/version?game_versions=[\"${MC_VERSION}\"]&loaders=[\"fabric\"]"
    local json
    json="$(curl -fsSL "$uri")"
    local url filename
    url="$(echo "$json" | jq -r '.[0].files[] | select(.primary) | .url' | head -n1)"
    filename="$(echo "$json" | jq -r '.[0].files[] | select(.primary) | .filename' | head -n1)"
    if [ -z "$url" ] || [ "$url" = "null" ]; then
        url="$(echo "$json" | jq -r '.[0].files[0].url')"
        filename="$(echo "$json" | jq -r '.[0].files[0].filename')"
    fi
    echo "Pobieram $slug ($filename)..."
    curl -fL -o "$MODS_DIR/$filename" "$url"
}

fetch_modrinth "fabric-api"
fetch_modrinth "cobblemon"

echo ""
echo "Uruchamiajac serwer akceptujesz EULA Minecrafta: https://aka.ms/MinecraftEULA"
read -rp "Akceptujesz EULA? (tak/nie): " AGREE
if [[ ! "$AGREE" =~ ^(t|tak|y|yes)$ ]]; then
    echo "Nie zaakceptowano EULA - przerywam."
    exit 1
fi
echo "eula=true" > eula.txt

PROPS="server.properties"
touch "$PROPS"
declare -A DESIRED=(
    ["online-mode"]="false"
    ["enforce-secure-profile"]="false"
    ["white-list"]="false"
    ["motd"]="Pokemon Server (Cobblemon) - non-premium OK"
    ["difficulty"]="normal"
    ["gamemode"]="survival"
    ["max-players"]="20"
    ["view-distance"]="10"
    ["server-port"]="25565"
    ["enable-command-block"]="true"
)
for key in "${!DESIRED[@]}"; do
    if grep -q "^${key}=" "$PROPS" 2>/dev/null; then
        sed -i.bak "s/^${key}=.*/${key}=${DESIRED[$key]}/" "$PROPS"
    else
        echo "${key}=${DESIRED[$key]}" >> "$PROPS"
    fi
done
rm -f "$PROPS.bak"

cat > start.sh <<'EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")"
java -Xms2G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar fabric-server-launch.jar nogui
EOF
chmod +x start.sh

echo ""
echo "=== GOTOWE ==="
echo "Uruchom serwer: ./start.sh"
echo "Zobacz README.md po instrukcje polaczenia z TLaunchera."
