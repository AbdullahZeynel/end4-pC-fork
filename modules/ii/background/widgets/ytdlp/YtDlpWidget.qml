pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

/**
 * Downloader widget driving yt-dlp.
 *
 * Paste a URL, the title is fetched and pre-filled but stays editable, pick a
 * container, download. Deliberately mirrors ImageConverterWidget's shape:
 * a Process per job, an idle/working/done/error state machine, and a combo box
 * for the output format.
 */
AbstractBackgroundWidget {
    id: root

    configEntryName: "ytdlp"

    readonly property var cfg: Config.options.background.widgets.ytdlp

    property list<var> formatOptions: [
        { displayName: "MP3",  icon: "music_note",   value: "mp3",  audio: true  },
        { displayName: "OGG",  icon: "music_note",   value: "vorbis", audio: true },
        { displayName: "OPUS", icon: "music_note",   value: "opus", audio: true  },
        { displayName: "M4A",  icon: "music_note",   value: "m4a",  audio: true  },
        { displayName: "WAV",  icon: "graphic_eq",   value: "wav",  audio: true  },
        { displayName: "FLAC", icon: "graphic_eq",   value: "flac", audio: true  },
        { displayName: "MP4",  icon: "movie",        value: "mp4",  audio: false },
        { displayName: "WEBM", icon: "movie",        value: "webm", audio: false },
        { displayName: "MKV",  icon: "movie",        value: "mkv",  audio: false },
    ]

    property string selectedFormat: "mp3"
    property string status: "idle" // idle | fetching | working | done | error
    property string statusMessage: ""
    property bool titleEdited: false

    implicitWidth: 300
    implicitHeight: 316

    readonly property var selectedOption: {
        for (let i = 0; i < formatOptions.length; i++) {
            if (formatOptions[i].value === root.selectedFormat) return formatOptions[i];
        }
        return formatOptions[0];
    }

    function sanitize(name) {
        return name.replace(/[\/\\:*?"<>|]/g, "_").trim();
    }

    function downloadDir() {
        const d = root.cfg.downloadDir;
        return d !== "" ? d : Quickshell.env("HOME") + "/Downloads";
    }

    function startDownload() {
        if (urlField.text.trim() === "") return;
        if (root.status === "working") return;

        const name = root.sanitize(nameField.text) || "%(title)s";
        const out = root.downloadDir() + "/" + name + ".%(ext)s";
        const url = urlField.text.trim();

        downloader.command = root.selectedOption.audio
            ? ["yt-dlp", "--no-playlist", "-x", "--audio-format", root.selectedFormat, "-o", out, url]
            : ["yt-dlp", "--no-playlist", "-f", "bv*+ba/b", "--merge-output-format", root.selectedFormat, "-o", out, url];

        root.status = "working";
        root.statusMessage = "Downloading...";
        downloader.running = true;
    }

    Timer {
        id: titleDebounce
        interval: 600
        onTriggered: {
            if (urlField.text.trim() === "") return;
            titleFetcher.running = false;
            titleFetcher.running = true;
        }
    }

    Process {
        id: titleFetcher
        command: ["yt-dlp", "--no-playlist", "--skip-download", "--print", "%(title)s", urlField.text.trim()]

        stdout: StdioCollector {
            id: titleOutput
        }

        onExited: (exitCode) => {
            if (root.status === "fetching") root.status = "idle";
            if (exitCode !== 0) return;
            const title = titleOutput.text.trim().split("\n")[0] ?? "";
            if (title === "") return;
            if (root.titleEdited) return; // never clobber a name the user typed
            nameField.text = root.sanitize(title);
        }
    }

    Process {
        id: downloader

        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.status = "done";
                root.statusMessage = "Saved to " + root.downloadDir().replace(/.*\//, "");
            } else {
                root.status = "error";
                root.statusMessage = "Download failed (code " + exitCode + ")";
            }
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer
        interval: 4000
        onTriggered: root.status = "idle"
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding?.verylarge ?? 30
        color: Appearance.colors.colWidgetPanel

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 16
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "download"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Download")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            MaterialTextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Paste a link")
                onTextChanged: {
                    root.titleEdited = false;
                    titleDebounce.restart();
                }
            }

            MaterialTextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: Translation.tr("File name")
                onTextEdited: root.titleEdited = true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledComboBox {
                    Layout.fillWidth: true
                    model: root.formatOptions
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colSurfaceContainerLow
                    colBackgroundActive: Appearance.colors.colSurfaceContainerLow
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        for (let i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedFormat) return i;
                        }
                        return 0;
                    }
                    onActivated: (index) => {
                        root.selectedFormat = model[index].value;
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: "download"
                    mainText: Translation.tr("Get")
                    enabled: root.status !== "working" && urlField.text.trim() !== ""
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    releaseAction: () => root.startDownload()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 6

                MaterialLoadingIndicator {
                    visible: root.status === "working"
                    loading: root.status === "working"
                    colBg: Appearance.colors.colPrimary
                    colShape: Appearance.colors.colOnPrimary
                    implicitSize: 18
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                    opacity: root.status === "idle" ? 0.5 : 1
                    color: {
                        switch (root.status) {
                            case "done":  return Appearance.colors.colTertiary;
                            case "error": return Appearance.colors.colError;
                            default:      return Appearance.colors.colOnPrimaryContainer;
                        }
                    }
                    text: root.status === "idle"
                        ? root.downloadDir()
                        : root.statusMessage
                }
            }
        }
    }
}
