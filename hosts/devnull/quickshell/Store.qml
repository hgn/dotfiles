pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

// Shared state: audio, system stats, weather, notifications, popups.
Singleton {
    id: store

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    readonly property string home: Quickshell.env("HOME")

    // ---- popups -------------------------------------------------------------
    property bool mixerOpen: false
    property bool launcherOpen: false
    property bool sysOpen: false
    property bool powerOpen: false
    property bool inhibitIdle: false

    // ---- audio --------------------------------------------------------------
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
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
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

    // the island shows an OSD whenever the volume changes; skip startup
    property int osdSerial: 0
    property bool audioReady: false
    Timer { interval: 2000; running: true; onTriggered: store.audioReady = true }
    onVolumeChanged: if (audioReady) osdSerial++
    onMutedChanged: if (audioReady) osdSerial++

    // ---- system stats ---------------------------------------------------------
    property real cpu: 0
    property var cpuHistory: []
    property var tempHistory: []
    property real memUsed: 0
    property real memTotal: 1
    property real temp: 0
    property string load: ""
    property real prevIdle: 0
    property real prevTotal: 0

    // one plain cat every 3 s; the coretemp hwmon index is resolved once
    property string tempPath: ""
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input | head -1"]
        stdout: StdioCollector { onStreamFinished: store.tempPath = text.trim() }
    }
    Process {
        id: statProc
        command: ["cat", "/proc/stat", "/proc/meminfo", "/proc/loadavg"].concat(store.tempPath ? [store.tempPath] : [])
        stdout: StdioCollector { onStreamFinished: store.parseStats(text) }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: statProc.running = true
    }
    function push(arr, v) { const a = arr.slice(-59); a.push(v); return a }
    function parseStats(t) {
        const l = t.trim().split("\n")
        const f = l[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + f[4]
        const total = f.reduce((a, b) => a + b, 0)
        if (prevTotal > 0 && total > prevTotal) {
            cpu = Math.max(0, Math.min(1, 1 - (idle - prevIdle) / (total - prevTotal)))
            cpuHistory = push(cpuHistory, cpu)
        }
        prevIdle = idle
        prevTotal = total
        const kb = key => {
            const line = l.find(x => x.startsWith(key + ":"))
            return line ? parseInt(line.split(/\s+/)[1]) : 0
        }
        const mt = kb("MemTotal")
        if (mt > 0) {
            memTotal = mt / 1048576
            memUsed = (mt - kb("MemAvailable")) / 1048576
        }
        const la = l.find(x => /^\d+\.\d+ \d+\.\d+ \d+\.\d+ /.test(x))
        if (la) load = la.split(" ").slice(0, 3).join("  ")
        const last = l[l.length - 1].trim()
        if (store.tempPath && /^\d+$/.test(last)) {
            temp = parseInt(last) / 1000
            tempHistory = push(tempHistory, temp / 100)
        }
    }

    // ---- weather (shared wttr.in helper) ---------------------------------------
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
            // volume/brightness OSD from wm-osd: the island draws its own
            if (n.appName === "wm-osd") return
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

    // ---- launcher usage counts (ranking), kept in the quickshell state dir --------
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

    // ---- ipc: qs ipc call shell <fn> ----------------------------------------------
    IpcHandler {
        target: "shell"
        function dismiss(): void { store.dismissAll() }
        function dnd(): void { store.dnd = !store.dnd }
        function mixer(): void { store.mixerOpen = !store.mixerOpen }
        function launcher(): void { store.launcherOpen = !store.launcherOpen }
        function status(): string {
            return JSON.stringify({
                notifications: store.notifications.length,
                dnd: store.dnd
            })
        }
        function sys(): void { store.sysOpen = !store.sysOpen }
        function power(): void { store.powerOpen = !store.powerOpen }
    }
}
