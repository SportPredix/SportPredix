import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

BASE_URL = "https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/scoreboard"
OUTPUT_PATH = Path("data/serie_a_scoreboard.json")


def fetch_json(url: str) -> dict:
    try:
        with urlopen(url, timeout=30) as response:
            payload = response.read().decode("utf-8")
            return json.loads(payload)
    except HTTPError as exc:
        raise RuntimeError(f"HTTP error {exc.code} while fetching {url}") from exc
    except URLError as exc:
        raise RuntimeError(f"Network error while fetching {url}: {exc.reason}") from exc


def main() -> int:
    today_utc = datetime.now(timezone.utc).date()
    start_date = today_utc - timedelta(days=1)
    end_date = today_utc + timedelta(days=1)

    dates_query = f"{start_date:%Y%m%d}-{end_date:%Y%m%d}"
    url = f"{BASE_URL}?dates={dates_query}"

    data = fetch_json(url)

    if not isinstance(data, dict):
        raise RuntimeError("Unexpected payload format: root is not an object")

    events = data.get("events")
    leagues = data.get("leagues")
    if not isinstance(events, list) or not isinstance(leagues, list):
        raise RuntimeError("Unexpected payload format: missing 'events' or 'leagues' array")

    data["cacheGeneratedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    data["cacheWindow"] = {
        "start": f"{start_date:%Y-%m-%d}",
        "end": f"{end_date:%Y-%m-%d}",
    }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(data, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")

    print(f"Cache updated: {OUTPUT_PATH} (events={len(events)}, range={dates_query})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
