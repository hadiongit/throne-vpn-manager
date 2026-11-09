# VPN Manager for Debian + Throne

**Version: 2.3.0**

VPN Manager automates a Throne VPN session on Debian/Linux. Each session is pinned to one static profile. Once a profile reaches `RUNNING`, the manager never connects another profile during that session. The Stop workflow disconnects the VPN, disables TUN and System Proxy, disables Kill Switch last, and restores the saved original system timezone.

All application-generated menus, prompts, status messages, warnings, and errors are in English. Profile names and subscription group names are supplied by the subscription provider and are displayed unchanged; a provider may therefore supply names in another language.

## Requirements

- Debian or another Linux distribution with Python 3
- Throne for Linux
- `thronectl` available in `PATH`
- `curl`, `ip`, `timedatectl`, `resolvectl` (optional), and `sudo`
- Throne running with its local API enabled
- ThroneCore permissions required for TUN and Kill Switch

## Enable the Throne API

In Throne:

1. Enable Advanced Mode if required by your build.
2. Open **Settings → Integration Settings → Throne API**.
3. Enable the Throne API.
4. Keep the listener bound to **This computer only** / `127.0.0.1`.
5. Use **Copy for scripts** to copy the API key.
6. Confirm that the API is listening on `127.0.0.1:9095` (or update the configured address accordingly).

On first launch, VPN Manager prompts for the API key and stores it with restrictive permissions at:

```text
~/.config/throne/api-key
```

Treat this key as a password. Do not publish it or commit it to a repository.

## Install or update

Extract the downloaded archive, then run:

```bash
chmod +x vpn-manager install-vpn-manager.sh
./install-vpn-manager.sh
```

The installer places the executable at:

```text
~/.local/bin/vpn-manager
```

It also creates a desktop entry named **VPN Manager**. If the command is not found in the current terminal, open a new terminal or run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

The installer replaces only the executable and desktop entry. It does not remove user configuration, the API key, saved timezone, session state, or logs.

## Usage

Run the interactive menu:

```bash
vpn-manager
```

Available commands:

```text
vpn-manager --start          Start a pinned single-profile VPN session
vpn-manager --stop           Disconnect and restore normal system state
vpn-manager --status         Show Throne and session status
vpn-manager --choose-group   Select the subscription group for the next session
vpn-manager --reset-timezone Restore only the original timezone
vpn-manager --version        Show the installed version
```

Run the program as your normal desktop user. Do not run it with `sudo`; it invokes `sudo` only for operations that require elevated privileges, such as changing the system timezone.

## Session behavior

- Auto Selector profiles are excluded because they can change exit servers automatically.
- Subscription groups are updated before profile selection.
- Latency and Throne's built-in IP tests are used to evaluate candidates.
- **Anthropic Supported Regions filtering is mandatory:** candidates are eligible only when the fresh result from the current Throne IP-test Job contains a valid public `ip_out` and a supported ISO 3166-1 alpha-2 country code. The server name, flag, hostname, and subscription label are never used to infer location.
- The region filter uses Anthropic's official Supported Regions Policy effective **2026-11-12**. It uses an allowlist, so countries/regions not listed by Anthropic are rejected. Missing, malformed, or unrecognized country codes are rejected (fail-closed). The supported country list and common ISO-coded territories/dependencies are embedded as a versioned snapshot; update this application if Anthropic changes its policy.
- Ukraine is conservatively excluded in full because Anthropic's policy has regional exclusions inside Ukraine, while Throne's profile result provides a country code rather than a sub-country region.
- A limited download speed test is run only for the configured number of top candidates, and only after unsupported/unknown egress regions have been removed.
- TUN Auto Redirect and Linux DNS/TUN readiness are checked before final verification.
- A candidate may be replaced only during startup when Throne confirms a stable `idle` state before any profile has reached `RUNNING`.
- As soon as a profile reaches `RUNNING`, its ID is pinned. No other profile is connected by VPN Manager after that point.
- Running Start again during a pinned session does not update subscriptions, rerun selection, reconnect, or switch profiles. It only rechecks the same pinned connection, network path, and timezone.
- If the API reports an ambiguous or inconsistent state, the manager stops rather than risking a second connection.

VPN Manager cannot prevent a user from manually selecting another profile in Throne, or another tool from changing Throne directly. It detects a profile ID mismatch and reports it; it does not initiate a replacement connection.

## Anthropic Supported Regions filter

Before a profile can enter the connection candidate list, VPN Manager runs Throne's native per-profile IP test and reads the finished Job's `results` array. It requires both:

- A valid public egress IP (`ip_out`).
- A valid ISO 3166-1 alpha-2 egress country code (`country`) reported by that same IP-test Job.

The filter uses an allowlist snapshot of Anthropic's Supported Regions Policy effective **2026-11-12**. Any country code not in the supported list is rejected. This includes, among others, Russia (`RU`), Iran (`IR`), China (`CN`), Belarus (`BY`), Afghanistan (`AF`), North Korea (`KP`), Syria (`SY`), Cuba (`CU`), Venezuela (`VE`), Hong Kong (`HK`), and Macao (`MO`). Common ISO-coded territories/dependencies of supported countries are included, consistent with Anthropic's policy.

Unknown, absent, malformed, or stale-only country data is not accepted: VPN Manager uses the results returned by the current IP-test Job and fails closed if they are missing. It never infers location from a profile's name, flag, hostname, or subscription label. Ukraine (`UA`) is conservatively excluded in full because Throne exposes country-level results only, while Anthropic's policy contains exclusions for five regions within Ukraine.

This policy list is a versioned local snapshot, not a live policy download. Review and update the embedded allowlist if Anthropic changes its Supported Regions Policy.

**Important policy boundary:** this filter only screens the VPN server's observed public IP country. It does not change or establish the user's physical location, an entity's place of incorporation/headquarters, or its ownership/control. A supported VPN exit IP alone does not make use compliant with Anthropic's policy.

## Stop and restore

The Stop operation uses a conservative order:

1. Disconnect the active Throne profile and wait for `idle`.
2. Disable TUN.
3. Disable System Proxy.
4. Verify that both are disabled.
5. Disable Kill Switch last and verify its runtime state.
6. Restore the original system timezone.
7. Remove the pinned session file only after network cleanup is confirmed.

If Throne cannot confirm a safe network state or the API is unavailable, the manager does not claim that cleanup succeeded and retains session state for recovery. Kill Switch is not disabled blindly.

The original timezone is saved on first use. The suggested initial value is `Asia/Tehran`, which can be edited before saving. The saved value is stored at:

```text
~/.local/state/vpn-timezone/original-timezone
```

## Configuration and logs

```text
~/.config/vpn-manager/config.json
~/.local/state/vpn-manager/session.json
~/.local/state/vpn-manager/logs/
```

The configuration includes the selected subscription group, TUN interface, local proxy URL, and bounded profile testing parameters. Logs may contain profile names, IP addresses, and diagnostic output; review them before sharing.

## Important notes

- The egress-country filter only screens the VPN server's observed public IP country. It does **not** change or establish the user's physical location, an entity's place of incorporation/headquarters, or its ownership/control. A supported VPN exit IP alone does not make use compliant with Anthropic's policy.
- The local Throne API should remain bound to localhost. Do not expose it to the LAN or public internet.
- A profile marked `RUNNING` is not sufficient by itself to prove working internet access; the manager also checks actual system/TUN egress.
- If the VPN is active but IP verification fails, the manager preserves the pinned profile and Kill Switch. It does not switch servers.
- If Throne exits or crashes, its own Kill Switch protection may no longer be active. Keep Throne running during a protected session.
