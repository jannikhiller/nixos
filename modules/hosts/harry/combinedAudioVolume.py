#!/usr/bin/env python3
import curses
import json
import re
import subprocess


COMBINED_SINK = "combined_audio"


def sinks():
    graph = json.loads(subprocess.check_output(["pw-dump"], text=True))
    nodes = [item for item in graph if item.get("type") == "PipeWire:Interface:Node"]
    group = None
    physical = {}
    for item in nodes:
        props = item.get("info", {}).get("props", {})
        if props.get("node.name") == COMBINED_SINK:
            group = props.get("node.group")
        elif props.get("media.class") == "Audio/Sink":
            physical[props.get("node.name")] = (
                item["id"],
                props.get("node.description") or props.get("node.name"),
            )

    if not group:
        raise RuntimeError(f"Combined sink {COMBINED_SINK} not found")

    found = {}
    for item in nodes:
        props = item.get("info", {}).get("props", {})
        if props.get("node.group") == group and props.get("media.class") == "Stream/Output/Audio":
            target = props.get("target.object")
            if target in physical:
                found[target] = physical[target]
    return sorted(((name, *device) for name, device in found.items()), key=lambda item: item[2].casefold())


def volume(node_id):
    result = subprocess.check_output(["wpctl", "get-volume", str(node_id)], text=True)
    match = re.search(r"Volume:\s+([0-9.]+)", result)
    return (round(float(match.group(1)) * 100), "[MUTED]" in result)


def draw(screen, row, message):
    height, width = screen.getmaxyx()
    if row < height and width > 1:
        screen.addnstr(row, 0, message, width - 1)


def main(screen):
    curses.curs_set(0)
    screen.timeout(1000)
    selected_name = None
    while True:
        screen.erase()
        draw(screen, 0, "Combined audio volume")
        draw(screen, 1, "1-9 or ↑/↓ select   ←/→ or h/l change 5%   m mute   q quit")
        try:
            connected = sinks()
            error = None
        except (OSError, subprocess.CalledProcessError, json.JSONDecodeError, RuntimeError) as exc:
            connected = []
            error = str(exc)

        names = [name for name, _, _ in connected]
        if selected_name not in names:
            selected_name = names[0] if names else None
        selected = names.index(selected_name) if selected_name else 0

        for index, (name, node_id, description) in enumerate(connected):
            row = 3 + index * 3
            prefix = "> " if selected == index else "  "
            draw(screen, row, prefix + description)
            try:
                percent, muted = volume(node_id)
                width = min(30, max(1, screen.getmaxyx()[1] - 12))
                filled = min(width, max(0, round(percent * width / 100)))
                bar = "#" * filled + "-" * (width - filled)
                if percent > 100:
                    bar += "+"
                draw(screen, row + 1, f"  [{bar}] {percent}%" + (" muted" if muted else ""))
            except (OSError, subprocess.CalledProcessError, AttributeError, ValueError):
                draw(screen, row + 1, "  volume unavailable")
        if not connected and not error:
            draw(screen, 3, "No devices connected to the combined sink")
        if error:
            draw(screen, 3, f"Audio graph unavailable: {error}")
        screen.refresh()

        key = screen.getch()
        if key in (ord("q"), 27):
            break
        if ord("1") <= key <= ord("9") and key - ord("1") < len(connected):
            selected_name = names[key - ord("1")]
        elif key in (curses.KEY_UP, curses.KEY_DOWN) and connected:
            selected_name = names[(selected + (1 if key == curses.KEY_DOWN else -1)) % len(connected)]
        elif connected:
            node_id = str(connected[selected][1])
            if key in (curses.KEY_LEFT, ord("h")):
                subprocess.run(["wpctl", "set-volume", node_id, "5%-"], check=False)
            elif key in (curses.KEY_RIGHT, ord("l")):
                subprocess.run(["wpctl", "set-volume", node_id, "5%+"], check=False)
            elif key == ord("m"):
                subprocess.run(["wpctl", "set-mute", node_id, "toggle"], check=False)


if __name__ == "__main__":
    curses.wrapper(main)
