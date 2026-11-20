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

    // ---- notifications: shown one at a time inside the island ------------------
    property var current: null
    property var queue: []
    property bool dnd: false
    property bool holdNotif: false

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
            store.queue = store.queue.concat([n])
            if (!store.current) store.nextNotif()
        }
    }

    function notifTimeout(n) {
        if (n.urgency === NotificationUrgency.Critical) return 20000
        return n.expireTimeout > 0 ? Math.max(3000, Math.min(n.expireTimeout, 10000)) : 6000
    }
    function nextNotif() {
        const q = queue.filter(n => n && n.tracked)
        if (q.length === 0) { current = null; queue = []; notifLimit.stop(); return }
        current = q[0]
        queue = q.slice(1)
        notifTimer.interval = notifTimeout(current)
        notifTimer.restart()
        // hard limit: closes even if the hover pause got stuck
        notifLimit.interval = current.urgency === NotificationUrgency.Critical ? 60000 : 30000
        notifLimit.restart()
    }
    function closeCurrent() {
        if (current && current.tracked) current.expire()
        nextNotif()
    }
    function dismissAll() {
        for (const n of server.trackedNotifications.values) n.dismiss()
        queue = []
        current = null
    }
    function activateCurrent() {
        if (!current) return
        const def = current.actions.find(a => a.identifier === "default")
        if (def) def.invoke()
        else current.dismiss()
        nextNotif()
    }
    // hovering the shown notification pauses it; leaving restarts the countdown
    onHoldNotifChanged: if (!holdNotif && current) notifTimer.restart()
    Timer {
        id: notifTimer
        onTriggered: if (!store.holdNotif) store.closeCurrent()
    }
    Timer {
        id: notifLimit
        onTriggered: if (store.current) store.closeCurrent()
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
            const c = store.current
            return JSON.stringify({
                current: c ? { app: c.appName, summary: c.summary, tracked: c.tracked,
                               resident: c.resident, expireTimeout: c.expireTimeout } : null,
                queue: store.queue.length, hold: store.holdNotif, timerRunning: notifTimer.running,
                limitRunning: notifLimit.running,
                timerInterval: notifTimer.interval, dnd: store.dnd
            })
        }
        function sys(): void { store.sysOpen = !store.sysOpen }
        function power(): void { store.powerOpen = !store.powerOpen }
    }
}
