# Changelog

## 2.3.0

- Added strict Anthropic Supported Regions egress-country filtering using the current Throne IP-test result.
- Rejects candidates with missing, malformed, stale, or unsupported country data.
- Conservatively excludes Ukraine because Throne reports country-level rather than sub-country egress location.
- Preserves single-profile session pinning: after a profile reaches `RUNNING`, VPN Manager does not connect another profile during that session.
- Keeps the Stop workflow ordered to disconnect, disable TUN and System Proxy, disable Kill Switch last, and restore the original timezone.
- Includes Linux TUN Auto Redirect and DNS readiness checks, staged egress verification, retry handling, and English application messages.
