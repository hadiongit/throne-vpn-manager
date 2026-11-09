#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SOURCE_DIR/vpn-manager"
[[ -f "$SOURCE" ]] || { echo "Missing $SOURCE" >&2; exit 1; }

DEST_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
mkdir -p "$DEST_DIR" "$APP_DIR"
install -m 755 "$SOURCE" "$DEST_DIR/vpn-manager"

cat > "$APP_DIR/vpn-manager.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=VPN Manager
Comment=Start a pinned Throne VPN session or restore normal network state
Exec=$DEST_DIR/vpn-manager
Terminal=true
Categories=Network;Utility;
EOF
chmod 644 "$APP_DIR/vpn-manager.desktop"

case ":${PATH}:" in
  *":$DEST_DIR:"*) ;;
  *)
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
      if [[ -f "$rc" ]] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
        printf '\n# User-local executables\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
      fi
    done
    ;;
esac

echo "Installed: $DEST_DIR/vpn-manager"
echo "Desktop entry: $APP_DIR/vpn-manager.desktop"
echo "Run now: $DEST_DIR/vpn-manager"
echo "If the command is not found in the current terminal, run: export PATH=\"\$HOME/.local/bin:\$PATH\""
