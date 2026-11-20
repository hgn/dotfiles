import QtQuick
import Quickshell
import Quickshell.Widgets

// Application launcher living inside the dynamic island.
// Type to search (name, generic name, keywords, categories, fuzzy),
// Up/Down or Ctrl+J/K to move, Enter to start, Tab for the app's actions
// (e.g. "New private window"), Esc to close. Frequently used apps rank first.
Item {
    id: root

    readonly property int maxRows: 8
    readonly property int rowHeight: 58
    readonly property int rows: Math.max(1, Math.min(results.length, maxRows))
    implicitHeight: 64 + 12 + rows * rowHeight + 10

    property string query: ""
    property var actionsOf: null       // entry whose actions are listed
    property string savedQuery: ""     // search to restore when leaving the actions
    property int current: 0

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)

    readonly property var results: {
        if (actionsOf)
            return actionsOf.actions.map(a => ({ kind: "action", entry: actionsOf, action: a }))
        const q = query.trim().toLowerCase()
        const scored = []
        for (const e of apps) {
            const s = score(e, q)
            if (s >= 0) scored.push({ kind: "app", entry: e, s: s })
        }
        scored.sort((a, b) => b.s - a.s || a.entry.name.localeCompare(b.entry.name))
        return scored.slice(0, 50)
    }
    onResultsChanged: current = 0

    function text(x) { return x ? String(x).toLowerCase() : "" }

    function score(e, q) {
        const used = Store.usage[e.id] || 0
        const bonus = Math.min(250, 60 * Math.log2(1 + used))
        if (q === "") return bonus
        const name = text(e.name)
        let s = -1
        if (name === q) s = 1000
        else if (name.startsWith(q)) s = 800
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 650
        else if (name.includes(q)) s = 500
        else {
            const extra = [e.genericName, e.keywords, e.categories, e.comment, e.id].map(text).join(" ")
            if (extra.includes(q)) s = 300
            else {
                // fuzzy: all query characters in order inside the name
                let i = 0, gaps = 0, last = -1
                for (let k = 0; k < name.length && i < q.length; k++) {
                    if (name[k] === q[i]) { if (last >= 0) gaps += k - last - 1; last = k; i++ }
                }
                if (i === q.length) s = Math.max(50, 250 - gaps * 10)
            }
        }
        return s < 0 ? -1 : s + bonus
    }

    function iconFor(name) {
        if (!name) return ""
        if (name.startsWith("/")) return "file://" + name
        return Quickshell.hasThemeIcon(name) ? Quickshell.iconPath(name) : ""
    }

    function open() {
        query = ""
        input.text = ""
        actionsOf = null
        current = 0
        input.forceActiveFocus()
    }

    function launch(i) {
        const r = results[i]
        if (!r) return
        if (r.kind === "action") r.action.execute()
        else r.entry.execute()
        Store.bumpUsage(r.entry.id)
        Store.launcherOpen = false
    }

    function enterActions(entry) {
        savedQuery = input.text
        actionsOf = entry
        input.text = ""
    }
    function leaveActions() {
        actionsOf = null
        input.text = savedQuery
    }

    function move(d) {
        if (results.length === 0) return
        current = (current + d + results.length) % results.length
        list.positionViewAtIndex(current, ListView.Contain)
    }

    // ---- search field ---------------------------------------------------------
    Rectangle {
        id: field
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        height: 56
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(0.73, 0.60, 0.97, 0.45) : "transparent"

        Icon {
            id: lens
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            code: root.actionsOf ? 0xF0142 : 0xF0349
            size: 22
            color: Theme.purple
        }
        Txt {
            id: crumb
            anchors.left: lens.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: root.actionsOf !== null
            text: root.actionsOf ? root.actionsOf.name + "  ›" : ""
            color: Theme.purple
            size: 20
            font.weight: Font.Bold
        }
        TextInput {
            id: input
            anchors.left: crumb.visible ? crumb.right : lens.right
            anchors.leftMargin: 12
            anchors.right: hint.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.font
            font.pixelSize: 22
            color: "white"
            selectionColor: Theme.purple
            clip: true
            onTextChanged: root.query = text

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === "" && !root.actionsOf
                text: "Programm suchen …"
                color: Theme.dim
                size: 22
            }

            Keys.onPressed: e => {
                const ctrl = e.modifiers & Qt.ControlModifier
                if (e.key === Qt.Key_Escape) {
                    if (root.actionsOf) root.leaveActions()
                    else Store.launcherOpen = false
                } else if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                    root.move(1)
                } else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                    root.move(-1)
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    root.launch(root.current)
                } else if (e.key === Qt.Key_Tab) {
                    const r = root.results[root.current]
                    if (!root.actionsOf && r && r.entry.actions.length > 0) root.enterActions(r.entry)
                } else if (root.actionsOf && (e.key === Qt.Key_Backtab || (e.key === Qt.Key_Backspace && input.text === ""))) {
                    root.leaveActions()
                } else {
                    return
                }
                e.accepted = true
            }
        }
        Txt {
            id: hint
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            size: 13
            color: Theme.dim
            text: root.actionsOf ? "Esc zurück" : "↵ starten   ⇥ Aktionen"
        }
    }

    // ---- results ----------------------------------------------------------------
    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.topMargin: 12
        height: root.rows * root.rowHeight
        clip: true
        model: root.results
        currentIndex: root.current
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 140
        highlight: Rectangle {
            radius: 16
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0.48, 0.64, 0.97, 0.30) }
                GradientStop { position: 1; color: Qt.rgba(0.73, 0.60, 0.97, 0.22) }
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isAction: modelData.kind === "action"
            readonly property string iconSrc: root.iconFor(isAction && modelData.action.icon ? modelData.action.icon : modelData.entry.icon)
            width: ListView.view.width
            height: root.rowHeight

            Item {
                id: iconBox
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 38; height: 38
                IconImage {
                    anchors.fill: parent
                    source: row.iconSrc
                    asynchronous: true
                    visible: row.iconSrc !== ""
                }
                Icon {
                    anchors.centerIn: parent
                    visible: row.iconSrc === ""
                    code: 0xF08C6
                    size: 28
                    color: Theme.dim
                }
            }
            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 14
                anchors.right: badge.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Txt {
                    width: parent.width
                    text: row.isAction ? row.modelData.action.name : row.modelData.entry.name
                    color: row.index === root.current ? "white" : Theme.fg
                    size: 18
                    font.weight: row.index === root.current ? Font.Bold : Font.Medium
                }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: row.isAction ? row.modelData.entry.name
                          : (row.modelData.entry.genericName || row.modelData.entry.comment || "")
                    color: Theme.dim
                    size: 13
                }
            }
            Txt {
                id: badge
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.isAction && row.modelData.entry.actions.length > 0
                text: "⇥ " + (visible ? row.modelData.entry.actions.length : "")
                size: 12
                color: Theme.dim
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = row.index
                onClicked: root.launch(row.index)
            }
        }
    }

    Txt {
        anchors.centerIn: list
        visible: root.results.length === 0
        text: "Keine Treffer für „" + root.query + "“"
        color: Theme.dim
    }
}
