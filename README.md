# 🧩 vcpkg-deb
`vcpkg-deb` is a lightweight integration tool that makes Debian system packages available as overlay ports in [vcpkg](https://github.com/microsoft/vcpkg). It enables vcpkg to recognize system-installed libraries, reducing redundant builds and improving integration with the system package manager.

# 📦 What it does
This package installs:
- `/usr/local/bin/vcpkg-deb-sync.sh` – A synchronization script that:
  - Reads mappings between Debian packages and vcpkg ports (`/etc/vcpkg-deb/mappings.json` and `/etc/vcpkg-deb/mappings.d/*.json`).
  - Checks which system packages are currently installed.
  - Creates or removes overlay ports in a target directory (`/opt/vcpkg-deb`).
- `/etc/apt/apt.conf.d/99-vcpkg-deb-sync` – An APT hook that:
  - Runs the sync script automatically after every `apt install`, `apt remove`, or `apt upgrade`.
This ensures that your overlay registry is always in sync with the actual system packages available on your machine.

# 🛠 How it works
The sync script uses a set of JSON files describing mappings between Debian package names and vcpkg port names. These mappings allow it to determine which overlay ports to generate or delete, depending on what is currently installed.

Each overlay port contains:
- A minimal `vcpkg.json` file with the version and name.
- A `portfile.cmake` that enables an empty placeholder (sufficient for satisfying dependencies when building with vcpkg).

# 📁 Configuration
The configuration directory is: `/etc/vcpkg-deb/`

## Main mapping file
- `/etc/vcpkg-deb/mappings.json` – Primary mapping of Debian package names to vcpkg port names. Supports single values or arrays.

Example:
```json
{
  "libgtest-dev": "gtest",
  "libboost-dev": ["boost-headers", "boost-iterator"]
}
```
## User-defined mappings:
- `/etc/vcpkg-deb/mappings.d/*.json` – Drop-in override files for additional or user-specific mappings.

You can place custom mappings here without modifying the system-provided mappings.json.

# 🚀 Getting Started
1. Install the [latest .deb package](https://github.com/yobeonline/vcpkg-deb/releases/latest) (e.g. `sudo dpkg -i vcpkg-deb_*_all.deb`).
2. APT will automatically call `vcpkg-deb-sync.sh` after package changes.
3. Use `/opt/vcpkg-deb` as a [vcpkg overlay port](https://learn.microsoft.com/en-us/vcpkg/users/overlay-triplets#overlay-ports) path:
```sh
./vcpkg install your-lib --overlay-ports=/opt/vcpkg-deb
```
# ✍️ Contributing
Contributions are welcome!
- To add new mappings or suggest improvements, submit a **pull request** with changes to `mappings.json`.
- For bug reports or feature requests, please open an **issue**.

Please keep mappings general (i.e., useful across most Debian systems) and avoid adding highly project-specific configurations.

# 🧪 Requirements
- `jq` (used for parsing JSON)
- `dpkg`, `apt` (standard on Debian/Ubuntu)

# 🔒 Permissions & Safety
- The script is read-only with respect to APT — it never installs or removes packages.
- It only writes into `/opt/vcpkg-deb` and reads from `/etc/vcpkg-deb`.
