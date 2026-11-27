pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

// Shared state for laptop "ic1101": audio, backlight, battery, power profile,
// system telemetry, network/VPN, weather, OSD, notification stack, IPC.
Singleton {
    id: store

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    readonly property string home: Quickshell.env("HOME")

    // ---- popups & bar state ---------------------------------------------------
    property bool barHidden: false
    property bool mixerOpen: false
    property bool briOpen: false
    property bool launcherOpen: false
    property bool sysOpen: false
    property bool clipOpen: false
    property bool powerOpen: false
    property bool inhibitIdle: false

    function toggleIdleInhibit() {
        inhibitIdle = !inhibitIdle
        if (inhibitIdle) {
            pushToast(
                "idle-inhibit",
                "Wachmodus",
                "Wachmodus aktiviert",
                "Bildschirm bleibt an · kein automatisches Abdunkeln, Sperren oder Standby",
                0xF0176,
                Theme.yellow,
                4000
            )
        } else {
            pushToast(
                "idle-inhibit",
                "Wachmodus",
                "Wachmodus deaktiviert",
                "Automatische Bildschirmsperre und Standby sind wieder aktiv",
                0xF0FAA,
                Theme.dim,
                3500
            )
        }
    }

    // ---- audio (PipeWire) -----------------------------------------------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink)

    function setVolume(v) {
        if (!sink || !sink.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }
    function volumeIcon(vol, mute) {
        if (mute) return 0xF075F
        return vol < 0.34 ? 0xF057F : vol < 0.67 ? 0xF0580 : 0xF057E
    }
    function nodeName(n) {
        if (!n) return ""
        const p = n.properties || {}
        return p["application.name"] || n.nickname || n.description || n.name
    }

    PwObjectTracker {
        objects: [store.sink].concat(store.sinks).concat(store.streams).filter(o => o)
    }

    // ---- OSD (volume, brightness, mic) ----------------------------------------
    property string osdKind: "volume"   // "volume" | "brightness" | "mic"
    property string osdLabel: ""
    property real osdValue: 0
    property bool osdMuted: false
    property int osdSerial: 0
    property bool audioReady: false

    Timer { interval: 2000; running: true; onTriggered: store.audioReady = true }

    function triggerOsd(kind, label, val, mutedFlag) {
        osdKind = kind
        osdLabel = label
        osdValue = Math.max(0, Math.min(1, val))
        osdMuted = !!mutedFlag
        osdSerial++
    }

    onVolumeChanged: if (audioReady) triggerOsd("volume", "Lautstärke", volume, muted)
    onMutedChanged:  if (audioReady) triggerOsd("volume", "Lautstärke", volume, muted)

    // ---- backlight ------------------------------------------------------------
    property real brightness: 0.5
    property bool brightnessAvailable: false

    function brightnessIcon(v) {
        if (v < 0.25) return 0xF00DE
        if (v < 0.55) return 0xF00DF
        if (v < 0.80) return 0xF00DD
        return 0xF00E0
    }
    function setBrightness(v) {
        const clamped = Math.max(0.02, Math.min(1, v))
        brightness = clamped
        const pct = Math.round(clamped * 100)
        // linear set matches /sys/class/backlight/brightness / max_brightness 1:1
        run("brightnessctl -q -n2 set " + pct + "%")
        if (!briOpen) triggerOsd("brightness", "Helligkeit", clamped, false)
    }
    function stepBrightness(delta) {
        setBrightness(brightness + delta)
    }

    // ---- battery --------------------------------------------------------------
    property int batPercent: 100
    property string batStatus: "Unknown"
    property real batWatts: 0
    property string batTime: ""
    property bool batPresent: false

    function batteryIcon(pct, status) {
        if (status === "Charging") return 0xF0084
        if (status === "Full" || status === "Not charging") return 0xF06A5
        const icons = [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
        const idx = Math.max(0, Math.min(icons.length - 1, Math.round(pct / 10)))
        return icons[idx]
    }

    // ---- power profile --------------------------------------------------------
    property string powerProfile: "balanced"

    function powerProfileIcon(p) {
        if (p === "performance") return 0xF04C5
        if (p === "power-saver") return 0xF0F86
        return 0xF0F85
    }
    function powerProfileColor(p) {
        if (p === "performance") return Theme.red
        if (p === "power-saver") return Theme.green
        return Theme.blue
    }
    function powerProfileLabel(p) {
        if (p === "performance") return "Leistung"
        if (p === "power-saver") return "Energiesparen"
        return "Ausgewogen"
    }
    function powerProfileDesc(p) {
        if (p === "performance") return "Maximale CPU-Leistung · höherer Stromverbrauch & Lüfter"
        if (p === "power-saver") return "Reduziert CPU-Takt & Verbrauch für längere Akkulaufzeit"
        return "Standard-Balance zwischen Leistung und Akkulaufzeit"
    }
    function cyclePowerProfile() {
        const order = ["power-saver", "balanced", "performance"]
        const next = order[(order.indexOf(powerProfile) + 1) % order.length]
        powerProfile = next
        run("powerprofilesctl set " + next)
        pushToast(
            "power-profile",
            "Energieprofil",
            powerProfileLabel(next),
            powerProfileDesc(next),
            powerProfileIcon(next),
            powerProfileColor(next),
            3800
        )
    }

    // ---- system telemetry (CPU, RAM, temp, battery, backlight) ----------------
    property real cpu: 0
    property var cpuHistory: []
    property var tempHistory: []
    property real memUsed: 0
    property real memTotal: 1
    property real temp: 0
    property string load: ""
    property real prevIdle: 0
    property real prevTotal: 0

    Process {
        id: statProc
        command: ["sh", "-c",
            "head -n1 /proc/stat; " +
            "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
            "echo \"LOAD $(cat /proc/loadavg)\"; " +
            "t=$(ls /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1); " +
            "[ -n \"$t\" ] && echo \"TEMP $(cat \"$t\")\"; " +
            "bl=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1); " +
            "[ -n \"$bl\" ] && echo \"BL $(cat \"$bl/brightness\") $(cat \"$bl/max_brightness\")\"; " +
            "bat=/sys/class/power_supply/BAT0; " +
            "if [ -d \"$bat\" ]; then " +
            "  echo \"BAT_CAP $(cat \"$bat/capacity\" 2>/dev/null || echo 0)\"; " +
            "  echo \"BAT_STAT $(cat \"$bat/status\" 2>/dev/null || echo Unknown)\"; " +
            "  echo \"BAT_PWR $(cat \"$bat/power_now\" 2>/dev/null || echo 0)\"; " +
            "  echo \"BAT_NOW $(cat \"$bat/energy_now\" 2>/dev/null || echo 0)\"; " +
            "  echo \"BAT_FULL $(cat \"$bat/energy_full\" 2>/dev/null || echo 0)\"; " +
            "fi"
        ]
        stdout: StdioCollector { onStreamFinished: store.parseStats(text) }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    function pushHist(arr, v) { const a = arr.slice(-59); a.push(v); return a }
    function parseStats(t) {
        const lines = t.trim().split("\n")
        let memTot = 0, memAvail = 0
        let bPwr = 0, bNow = 0, bFull = 0, bStat = ""

        for (const raw of lines) {
            const line = raw.trim()
            if (line.startsWith("cpu ")) {
                const f = line.split(/\s+/).slice(1).map(Number)
                const idle = (f[3] || 0) + (f[4] || 0)
                const total = f.reduce((a, b) => a + b, 0)
                if (prevTotal > 0 && total > prevTotal) {
                    cpu = Math.max(0, Math.min(1, 1 - (idle - prevIdle) / (total - prevTotal)))
                    cpuHistory = pushHist(cpuHistory, cpu)
                }
                prevIdle = idle
                prevTotal = total
            } else if (line.startsWith("MemTotal:")) {
                memTot = parseInt(line.split(/\s+/)[1]) || 0
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = parseInt(line.split(/\s+/)[1]) || 0
            } else if (line.startsWith("LOAD ")) {
                load = line.slice(5).split(/\s+/).slice(0, 3).join("  ")
            } else if (line.startsWith("TEMP ")) {
                const tv = parseInt(line.slice(5))
                if (!isNaN(tv)) {
                    temp = tv / 1000
                    tempHistory = pushHist(tempHistory, temp / 100)
                }
            } else if (line.startsWith("BL ")) {
                const p = line.split(/\s+/)
                const cur = parseFloat(p[1]), mx = parseFloat(p[2])
                if (mx > 0) {
                    brightnessAvailable = true
                    brightness = cur / mx
                }
            } else if (line.startsWith("BAT_CAP ")) {
                batPresent = true
                batPercent = parseInt(line.slice(8)) || 0
            } else if (line.startsWith("BAT_STAT ")) {
                bStat = line.slice(9).trim()
                batStatus = bStat
            } else if (line.startsWith("BAT_PWR ")) {
                bPwr = parseFloat(line.slice(8)) || 0
            } else if (line.startsWith("BAT_NOW ")) {
                bNow = parseFloat(line.slice(8)) || 0
            } else if (line.startsWith("BAT_FULL ")) {
                bFull = parseFloat(line.slice(9)) || 0
            }
        }

        if (memTot > 0) {
            memTotal = memTot / 1048576
            memUsed = (memTot - memAvail) / 1048576
        }
        batWatts = bPwr / 1000000
        if (bPwr > 100000) {
            let hrs = 0
            if (bStat === "Discharging") hrs = bNow / bPwr
            else if (bStat === "Charging" && bFull > bNow) hrs = (bFull - bNow) / bPwr
            if (hrs > 0 && hrs < 100) {
                const h = Math.floor(hrs)
                const m = Math.round((hrs - h) * 60)
                batTime = (h > 0 ? h + "h " : "") + m + "m"
            } else {
                batTime = ""
            }
        } else {
            batTime = ""
        }
    }

    // ---- network, VPN & power profile -----------------------------------------
    property string netType: "offline"   // "wifi" | "ethernet" | "offline"
    property string netLabel: "offline"
    property string netIp: ""
    property int wifiSignal: 0
    property bool vpnActive: false

    function wifiIcon(sig) {
        if (sig >= 75) return 0xF0928
        if (sig >= 50) return 0xF0925
        if (sig >= 25) return 0xF0922
        return 0xF091F
    }

    Process {
        id: netProc
        command: ["sh", "-c",
            "nmcli -t -f NAME connection show --active 2>/dev/null | grep -qxF fritz-wg && echo 'VPN 1' || echo 'VPN 0'; " +
            "devline=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE dev 2>/dev/null | awk -F: '$2==\"connected\" && ($1==\"wifi\" || $1==\"ethernet\") {print $1 \"|\" $3 \"|\" $4; exit}'); " +
            "iface=${devline##*|}; " +
            "echo \"NET ${devline:-offline||}\"; " +
            "ip=$([ -n \"$iface\" ] && ip -4 -br addr show dev \"$iface\" 2>/dev/null | awk '{print $3}' | cut -d/ -f1); " +
            "echo \"IP ${ip}\"; " +
            "sig=$(nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}'); " +
            "echo \"SIG ${sig:-0}\"; " +
            "pp=$(powerprofilesctl get 2>/dev/null); " +
            "[ -n \"$pp\" ] && echo \"PP $pp\""
        ]
        stdout: StdioCollector { onStreamFinished: store.parseNet(text) }
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    function parseNet(t) {
        for (const raw of t.trim().split("\n")) {
            const line = raw.trim()
            if (line.startsWith("VPN ")) {
                vpnActive = line.slice(4).trim() === "1"
            } else if (line.startsWith("NET ")) {
                const parts = line.slice(4).split("|")
                const typ = parts[0] || "offline"
                const name = parts[1] || ""
                netType = typ
                netLabel = name || (typ === "offline" ? "offline" : typ)
            } else if (line.startsWith("IP ")) {
                netIp = line.slice(3).trim()
            } else if (line.startsWith("SIG ")) {
                const s = parseInt(line.slice(4))
                wifiSignal = isNaN(s) ? 0 : Math.max(0, Math.min(100, s))
            } else if (line.startsWith("PP ")) {
                powerProfile = line.slice(3).trim()
            }
        }
    }

    function refreshNet() { netProc.running = true }
    function toggleVpn() {
        run(home + "/.local/share/wm/bin/wm-vpn toggle")
        vpnRefreshTimer.restart()
    }
    Timer { id: vpnRefreshTimer; interval: 1500; onTriggered: store.refreshNet() }

    // ---- unread mail count (IMAP INBOX, fallback notmuch) ---------------------
    property int mailUnread: 0
    Process {
        id: mailProc
        command: [store.home + "/.local/share/wm/bin/wm-mail-count"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim())
                if (!isNaN(n) && n >= 0) store.mailUnread = n
            }
        }
    }
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: mailProc.running = true
    }
    function refreshMail() { mailProc.running = true }

    // ---- weather (shared wttr.in helper) --------------------------------------
    property string weather: ""
    property string weatherLong: ""
    Process {
        id: weatherProc
        command: [store.home + "/.local/share/wm/bin/wm-weather"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    store.weather = j.text || ""
                    store.weatherLong = j.tooltip || ""
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 15 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // ---- notifications (concave right-docked toasts at bottom-right) ----------
    property var notifications: []    // [{ id, notif, paused, closing, closeMs, totalMs, remainingMs }]
    property bool dnd: false
    property int notifSeq: 0
    property int notifTick: 0

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: n => {
            // Intercept wm-osd notifications and render them in our crisp OSD bar
            if (n.appName === "wm-osd") {
                if (n.summary === "Helligkeit") {
                    const m = String(n.body || "").match(/(\d+)/)
                    if (m) {
                        const v = Math.max(0, Math.min(100, parseInt(m[1]))) / 100
                        store.brightness = v
                        store.brightnessAvailable = true
                        store.triggerOsd("brightness", "Helligkeit", v, false)
                    }
                } else if (n.summary === "Mikrofon") {
                    const isMuted = String(n.body || "").indexOf("stumm") >= 0
                    store.triggerOsd("mic", "Mikrofon", isMuted ? 0 : 1, isMuted)
                }
                return
            }

            n.tracked = true
            if (store.dnd && n.urgency !== NotificationUrgency.Critical) return

            const ms = n.urgency === NotificationUrgency.Critical
                       ? 15000
                       : (n.expireTimeout > 0 ? Math.max(3000, Math.min(n.expireTimeout, 10000)) : 6500)
            const entry = {
                id: ++store.notifSeq,
                notif: n,
                paused: false,
                closing: false,
                closeMs: 240,
                totalMs: ms,
                remainingMs: ms
            }
            store.notifications = [entry].concat(store.notifications).slice(0, 5)
        }
    }

    function pushToast(tag, appName, summary, body, iconCode, accent, ms) {
        const dur = ms || 4200
        const entry = {
            id: ++store.notifSeq,
            local: true,
            tag: tag || "",
            appName: appName || "System",
            summary: summary || "",
            body: body || "",
            iconCode: iconCode || 0xF009A,
            accent: accent || Theme.purple,
            notif: null,
            paused: false,
            closing: false,
            closeMs: 240,
            totalMs: dur,
            remainingMs: dur
        }
        const filtered = tag ? store.notifications.filter(i => i.tag !== tag) : store.notifications
        store.notifications = [entry].concat(filtered).slice(0, 5)
    }

    Timer {
        interval: 60
        repeat: true
        running: store.notifications.length > 0
        onTriggered: {
            let structuralChange = false
            const next = []
            for (const item of store.notifications) {
                if (!item.local && (!item.notif || !item.notif.tracked) && !item.closing) {
                    item.closing = true
                    item.closeMs = 220
                }
                if (item.closing) {
                    item.closeMs -= 60
                    if (item.closeMs <= 0) {
                        structuralChange = true
                        continue
                    }
                    next.push(item)
                    continue
                }
                if (!item.paused) {
                    item.remainingMs = Math.max(0, item.remainingMs - 60)
                    if (item.remainingMs <= 0) {
                        if (item.notif && item.notif.tracked) item.notif.expire()
                        item.closing = true
                        item.closeMs = 240
                    }
                }
                next.push(item)
            }
            store.notifTick++
            if (structuralChange) store.notifications = next
        }
    }

    function setNotifPaused(id, paused) {
        for (const item of store.notifications) {
            if (item.id === id) {
                item.paused = paused
                if (!paused && !item.closing) item.remainingMs = Math.max(item.remainingMs, 2200)
                store.notifTick++
                return
            }
        }
    }
    function dismissNotif(id) {
        for (const item of store.notifications) {
            if (item.id === id && !item.closing) {
                if (item.notif && item.notif.tracked) item.notif.dismiss()
                item.closing = true
                item.closeMs = 220
                store.notifTick++
                return
            }
        }
    }
    function activateNotif(id) {
        for (const item of store.notifications) {
            if (item.id === id && !item.closing) {
                if (item.notif && item.notif.tracked) {
                    const def = item.notif.actions.find(a => a.identifier === "default")
                    if (def) def.invoke()
                    else item.notif.dismiss()
                }
                item.closing = true
                item.closeMs = 220
                store.notifTick++
                return
            }
        }
    }
    function dismissAll() {
        for (const n of server.trackedNotifications.values) n.dismiss()
        for (const item of store.notifications) {
            item.closing = true
            item.closeMs = 200
        }
        store.notifTick++
    }

    // ---- launcher usage counts ------------------------------------------------
    property var usage: ({})
    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        printErrors: false
        onLoaded: { try { store.usage = JSON.parse(text()) } catch (e) {} }
    }
    function bumpUsage(id) {
        const u = Object.assign({}, usage)
        u[id] = (u[id] || 0) + 1
        usage = u
        usageFile.setText(JSON.stringify(u))
    }

    // ---- IPC: qs ipc call shell <fn> ------------------------------------------
    IpcHandler {
        target: "shell"
        function launcher(): void { store.launcherOpen = !store.launcherOpen }
        function power(): void    { store.powerOpen = !store.powerOpen }
        function mixer(): void      { store.mixerOpen = !store.mixerOpen }
        function brightness(): void { store.briOpen = !store.briOpen }
        function sys(): void        { store.sysOpen = !store.sysOpen }
        function clip(): void       { store.clipOpen = !store.clipOpen }
        function refreshMail(): void { store.refreshMail() }
        function dismiss(): void    { store.dismissAll() }
        function dnd(): void      { store.dnd = !store.dnd }
        function refreshVpn(): void { store.refreshNet() }
        function barShow(): void    { store.barHidden = false }
        function barHide(): void    { store.barHidden = true }
        function barToggle(): void  { store.barHidden = !store.barHidden }
        function status(): string {
            return JSON.stringify({
                barHidden: store.barHidden,
                dnd: store.dnd,
                notifications: store.notifications.length,
                vpn: store.vpnActive,
                bat: store.batPercent,
                profile: store.powerProfile
            })
        }
    }
}
