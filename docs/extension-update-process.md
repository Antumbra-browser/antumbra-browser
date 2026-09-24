# Bundled extension baseline refresh process

Antumbra bundles extension XPIs in `third_party/extensions/` as an install baseline.
Once installed, extensions auto-update from AMO (D10 in DECISIONS.md). This process
updates the vendored XPI so that new Antumbra installs start at a recent version.

## Cadence

Per ROADMAP.md: every 4 weeks, and at every Antumbra release.
The goal is to keep the shipped baseline within one release cycle of AMO current.

## Extension registry

| Extension | Extension ID | AMO slug |
|-----------|-------------|----------|
| uBlock Origin | uBlock0@raymondhill.net | ublock-origin |
| Consent-O-Matic | gdpr@cavi.au.dk | consent-o-matic |
| Multi-Account Containers | @testpilot-containers | multi-account-containers |

## Steps

### 1. Check for new versions

For each extension, check the AMO version page:

- uBlock Origin: https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/versions/
- Consent-O-Matic: https://addons.mozilla.org/en-US/firefox/addon/consent-o-matic/versions/
- Multi-Account Containers: https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/versions/

Or use the AMO API to get the latest version programmatically:

```bash
for slug in ublock-origin consent-o-matic multi-account-containers; do
  echo "=== $slug ==="
  curl -s "https://addons.mozilla.org/api/v5/addons/addon/${slug}/versions/?ordering=-created&page_size=1" \
    | python3 -c "import json,sys; v=json.load(sys.stdin)['results'][0]; print('VERSION:', v['version']); print('URL:', v['file']['url'])"
done
```

Compare the current AMO release version against the version in
`third_party/extensions/{name}/VERSION`.

### 2. Review the changelog

For each extension with a newer version:

- Read the release notes or commit log between the pinned version and the new version.
- Flag any changes that affect privacy-relevant behavior: permissions changes,
  new network requests, filter list behavior changes.
- For uBlock Origin specifically: review the changelog for filter list changes
  that affect the protection baseline.

### 3. Download and verify the new XPI

```bash
# Get the download URL from the AMO API
SLUG=ublock-origin  # or consent-o-matic, multi-account-containers
curl -s "https://addons.mozilla.org/api/v5/addons/addon/${SLUG}/versions/?ordering=-created&page_size=1" \
  | python3 -c "import json,sys; v=json.load(sys.stdin)['results'][0]; print(v['file']['url'])"

# Download
curl -L -o new.xpi "<URL from above>"

# Verify the XPI is a valid ZIP and check ID and version
python3 -c "
import zipfile, json
with zipfile.ZipFile('new.xpi') as z:
    m = json.loads(z.read('manifest.json'))
    bss = m.get('browser_specific_settings', m.get('applications', {}))
    print('ID:', bss.get('gecko', {}).get('id'))
    print('Version:', m.get('version'))
    print('Name:', m.get('name'))
"
```

Verify the extension ID matches the expected value in the extension registry above.
A changed extension ID is a breaking change and must not be accepted silently.

### 4. Replace the vendored XPI

```bash
cd antumbra-browser/
EXT=ublock-origin   # or consent-o-matic, multi-account-containers
NEW_VERSION=1.76.0  # replace with actual new version

rm third_party/extensions/${EXT}/*.xpi
cp /path/to/new.xpi "third_party/extensions/${EXT}/${EXT//-/_}-${NEW_VERSION}.xpi"
echo "${NEW_VERSION}" > "third_party/extensions/${EXT}/VERSION"
```

Update `THIRD-PARTY.md`: change the version number and SHA-256 hash in the row
for the updated extension.

Get the SHA-256 hash:

```bash
sha256sum new.xpi  # Linux/macOS
# or on Windows:
certutil -hashfile new.xpi SHA256
```

### 5. Update policies.json if the extension ID changed

Extension IDs are stable for AMO-listed extensions, but verify after a major version.
If the ID changed, update the key in `prefs/policies.json` and the `EXT_IDS` mapping
in `scripts/package-extensions.sh`.

### 6. Regenerate the 0100-03-policies.patch if policies.json changed

If the extension ID changed and you updated `prefs/policies.json`, regenerate the patch:

```bash
cd /d/dev/antumbra/firefox
cp /d/dev/antumbra/antumbra-browser/prefs/policies.json browser/distribution/policies.json
git add -N browser/distribution/policies.json
git diff HEAD -- browser/distribution/policies.json > \
  /d/dev/antumbra/antumbra-browser/patches/0100-prefs/0100-03-policies.patch
rm browser/distribution/policies.json
```

### 7. Test

```bash
# Apply patches and run a faster build
./scripts/apply-patches.sh
./mach build faster
```

Verify the new version appears in `about:addons` in the built browser.
Check that the extension functions correctly:

- uBlock Origin: blocks an ad on a test page; toolbar icon appears.
- Consent-O-Matic: rejects a consent banner on a test site.
- Multi-Account Containers: containers still work (create a container tab).

### 8. Commit

Commit message format:

```
chore: update {extension name} to {NEW_VERSION}
```

Include the AMO changelog URL in the commit body for traceability.
Update `THIRD-PARTY.md` in the same commit.
