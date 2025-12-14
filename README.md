# vcpkg-deb

`vcpkg-deb` provides **`vcpkg-deb-sync`**, a lightweight integration tool that makes Debian system packages available as overlay ports in [vcpkg](https://github.com/microsoft/vcpkg).

To use the system-provided overlay ports, configure vcpkg to use the overlay directory at `/usr/share/vcpkg-deb` (see the official [overlay ports documentation](https://learn.microsoft.com/en-us/vcpkg/concepts/overlay-ports)).

Alternatively, `vcpkg-deb-sync` can be used directly to generate and maintain your own overlay ports directories.

---

## Using system-wide overlay ports

The system-wide overlay ports directory is located at:
```text
/usr/share/vcpkg-deb
```
It is automatically updated whenever `/usr/include` is modified by `dpkg`.

The mapping configuration is read from `/etc/vcpkg-deb`:
- `/etc/vcpkg-deb/mappings.json` is the main mapping file shipped with the package.
- JSON files found under `/etc/vcpkg-deb/mappings.d/` are intended for custom mappings and overrides.

An overlay port is generated if the corresponding Debian package is installed and its version is **greater than or equal to** the required minimum version.

---

## Using the synchronization script

```text
vcpkg-deb-sync <conf_dir> <overlay_dir> [<package_name> ...]
```

- `<conf_dir>` — directory containing mapping files.
- `<overlay_dir>` — directory where overlay ports will be generated or updated.
- `<package_name>` — optional list of Debian package names to update.

If no package names are provided, all packages defined in the mapping files are processed.

This allows maintaining custom overlay port directories independently of the system-wide installation.

---

## Mapping file schema

The following example defines the overlay port `gtest` from the Debian package `libgtest-dev (>= 1.10)`:

```json
{
  "libgtest-dev": {
    "vcpkg-port": "gtest",
    "min-version": "1.10"
  }
}
```
The following example defines the overlay ports boost-headers, boost-algorithm, and boost-iterator from the Debian package libboost-dev (>= 1.74):

```json
{
  "libboost-dev": {
    "vcpkg-port": [
      "boost-headers",
      "boost-algorithm",
      "boost-iterator"
    ],
    "min-version": "1.74"
  }
}
```

Each mapping entry specifies:
- The Debian package name
- One or more vcpkg port names
- A minimum required Debian package version

## Contributing
Contributions are welcome!
- To add new mappings, submit a pull request modifying mappings.json.
- For bug reports or feature requests, please open an issue.

Please keep mappings general (i.e. useful across most Debian systems with default APT repositories) and avoid adding highly project-specific configurations.

