#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  inputs,
  system,
  ...
}: let
  # Hash guard: build fails loudly if upstream Clock.tera changes instead of silently no-opping.
  upstreamClockTeraSha256 = "52c83dba5e74f9708d8103d2a91c729903091f1f499f1f9fe9a5145dd312a494";

  clockTera = pkgs.writeText "catppuccin-sddm-clock.tera" ''
    ---
    whiskers:
      version: "^2.5.1"
      matrix:
        - flavor
        - accent
      hex_format: "\"#{{R}}{{G}}{{B}}{{Z}}\""
      filename: "./themes/catppuccin-{{flavor.identifier}}-{{accent}}/Components/Clock.qml"
    ---
    import QtQuick 2.15

    Column {
      id: container
      property date dateTime: new Date()
      property color color: {{text.hex}}
      anchors {
        margins: 10
        top: parent.top
        right: parent.right
      }
      Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: container.dateTime = new Date()
      }
      Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        color: container.color
        text: Qt.formatTime(container.dateTime, "hh:mm")
        font.family: config.Font
        font.pointSize: 72
      }
      Text {
        id: dateText
        anchors.horizontalCenter: parent.horizontalCenter
        color: container.color
        text: Qt.formatDate(container.dateTime, "yyyy-MM-dd")
        font.family: config.Font
        font.pointSize: 24
      }
    }
  '';
in {
  catppuccin.sources.sddm = inputs.catppuccin.packages.${system}.sddm.overrideAttrs (_finalAttrs: prevAttrs: {
    postPatch =
      (prevAttrs.postPatch or "")
      + ''
        echo "${upstreamClockTeraSha256}  templates/Components/Clock.tera" | sha256sum -c -
        cp ${clockTera} templates/Components/Clock.tera
      '';
  });
}
