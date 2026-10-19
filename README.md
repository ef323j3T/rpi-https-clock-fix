## Installation

### 1. Bootstrap the system clock (only if Git clone fails due to a certificate error)

If the Raspberry Pi's clock is significantly incorrect, GitHub's HTTPS certificate verification may fail. The following command retrieves HTTP `Date` headers from two independent sources, checks that they agree within 60 seconds, and temporarily corrects the system clock.

This is a bootstrap workaround only. HTTP does not authenticate the time source, so use it only on a network you trust.

```bash
sudo bash -c '
set -e
get_time() {
  curl -fsSI --max-time 10 "http://$1/" 2>/dev/null |
    tr -d "\r" |
    awk "BEGIN { IGNORECASE=1 } /^Date:/ { sub(/^[^:]*:[[:space:]]*/, \"\"); print; exit }"
}
A=$(get_time google.com)
B=$(get_time neverssl.com)
[ -n "$A" ] && [ -n "$B" ] || { echo "Could not get both HTTP dates"; exit 1; }
TA=$(date -u -d "$A" +%s)
TB=$(date -u -d "$B" +%s)
DIFF=$((TA-TB)); [ "$DIFF" -lt 0 ] && DIFF=$((-DIFF))
[ "$DIFF" -le 60 ] || { echo "HTTP time sources disagree by ${DIFF}s; clock unchanged"; exit 1; }
date -u -s "@$(((TA+TB)/2))"
'
```

If this command fails, do not bypass Git's certificate verification. Investigate the network connection or set the system clock using a trusted time source.

### 2. Alternatively, set the system clock manually

If you know the current local date and time, you can set it manually instead of using the HTTP bootstrap command.

First, check the configured time zone:

```bash
timedatectl
```

If necessary, set the correct time zone. For example, for Sydney:

```bash
sudo timedatectl set-timezone Australia/Sydney
```

Then set the local date and time, replacing the example with the actual current date and time:

```bash
sudo date -s "2026-10-19 14:30:00"
```

Use the 24-hour format `YYYY-MM-DD HH:MM:SS`.

Verify the result:

```bash
date
date -u
```

Once the clock is sufficiently accurate, proceed with cloning the repository. If the clock is already correct, skip this step.

### 3. Clone the repository and install

```bash
git clone https://github.com/ef323j3T/rpi-https-clock-fix.git
cd rpi-https-clock-fix
sudo bash install.sh
```

The installer configures the HTTPS-based clock correction service and its systemd timer.

If cloning succeeds without a certificate error, skip Step 1 and 2 and proceed directly to Step 3.
