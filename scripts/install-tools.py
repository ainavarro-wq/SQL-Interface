"""Install pinned Roblox development tools with official release checksums."""

from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from io import BytesIO
from pathlib import Path
from urllib.request import urlopen
from zipfile import ZipFile
import argparse
import platform
import subprocess


if platform.system() != "Linux" or platform.machine() != "x86_64":
    raise SystemExit("These pinned binaries require Linux x86_64.")

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parents[1] / ".tools")
TOOLS = parser.parse_args().directory.resolve()
TOOLS.mkdir(parents=True, exist_ok=True)
ASSETS = [
    (
        "rojo",
        "https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip",
        "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4",
    ),
    (
        "lune",
        "https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip",
        "39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1",
    ),
]


def install(asset):
    name, url, expected_digest = asset
    archive = TOOLS / f"{name}.zip"
    if archive.exists():
        data = archive.read_bytes()
    else:
        with urlopen(url, timeout=60) as response:
            data = response.read()
    if sha256(data).hexdigest() != expected_digest:
        raise RuntimeError(f"Checksum mismatch for {name}; refusing to use this archive.")
    archive.write_bytes(data)
    with ZipFile(BytesIO(data)) as zipped:
        binary = zipped.read(name)
    executable = TOOLS / name
    executable.write_bytes(binary)
    executable.chmod(0o755)
    subprocess.run([str(executable), "--version"], check=True)


with ThreadPoolExecutor(max_workers=2) as executor:
    list(executor.map(install, ASSETS))
