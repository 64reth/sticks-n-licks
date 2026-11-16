#!/usr/bin/env python3
"""Summarise executed CPU match results; no game simulation or invented targets."""
import argparse
import json
import statistics
from pathlib import Path


def summarize(report):
    result = {"checks": report["checks"], "failures": report["failures"],
              "matches": len(report["matches"]), "seed_range": [min(m["seed"] for m in report["matches"]), max(m["seed"] for m in report["matches"])],
              "definitions": {
                  "valid_timing": "Actual shared validator result; excludes race, hesitation and skipped actions. Not damage or win probability.",
                  "defence_frequency": "CPU blocks/parries divided by in-range successful player attacks (HIT/BLOCK/PARRY) against CPU.",
                  "duration": "Measured simulated musical clock through the deciding result, including current transition delays; excludes human Enter waits.",
                  "stall": "60 seconds with no clean hit; timeout is 360 seconds.",
                  "strategies": "rush_high: high attacks/low blocks; balanced: cycling heights, 8% spacing retreats; guard_high: high attacks/blocks and perfect-capable timing. All use 88% combat timing, rhythmic approach and 230ms race reaction."
              }, "difficulties": {}}
    for level in ("easy", "normal", "hard"):
        matches = [m for m in report["matches"] if m["difficulty"] == level]
        timing = {key: sum(m["timing"][key] for m in matches) for key in matches[0]["timing"]}
        heights = [sum(m["attack_heights"][i] for m in matches) for i in range(3)]
        opportunities = sum(m["cpu_defense_opportunities"] for m in matches)
        blocks = sum(m["cpu_blocks"] for m in matches)
        parries = sum(m["cpu_parries"] for m in matches)
        by_strategy = {}
        for strategy in ("rush_high", "balanced", "guard_high"):
            group = [m for m in matches if m["strategy"] == strategy]
            by_strategy[strategy] = {"matches": len(group), "cpu_wins": sum(m["winner"] == 1 for m in group),
                                     "player_wins": sum(m["winner"] == 0 for m in group)}
        result["difficulties"][level] = {
            "matches": len(matches), "timing": timing,
            "movement_valid_percent": timing["valid_move"] / timing["move"] * 100,
            "combat_valid_percent": timing["valid_combat"] / timing["combat"] * 100,
            "combined_valid_percent": (timing["valid_move"] + timing["valid_combat"]) / (timing["move"] + timing["combat"]) * 100,
            "height_counts_high_mid_low": heights,
            "height_percent_high_mid_low": [n / sum(heights) * 100 for n in heights],
            "defence_opportunities": opportunities, "blocks": blocks, "parries": parries,
            "block_percent": blocks / opportunities * 100, "parry_percent": parries / opportunities * 100,
            "average_match_seconds": statistics.mean(m["duration"] for m in matches),
            "maximum_match_seconds": max(m["duration"] for m in matches),
            "stalls": sum(m["stalls"] for m in matches), "timeouts": sum(m["timed_out"] for m in matches),
            "wins_by_strategy": by_strategy,
        }
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    summary = summarize(json.loads(args.source.read_text()))
    args.output.write_text(json.dumps(summary, indent=2) + "\n")
    for level, item in summary["difficulties"].items():
        print(f"{level}: movement {item['movement_valid_percent']:.1f}%, combat {item['combat_valid_percent']:.1f}%, "
              f"match {item['average_match_seconds']:.1f}s, stalls {item['stalls']}, "
              f"heights {[round(n, 1) for n in item['height_percent_high_mid_low']]}, "
              f"blocks/parries {item['block_percent']:.1f}%/{item['parry_percent']:.1f}%")
