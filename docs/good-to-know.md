# Useful Commands

## Convert .drawio to PNG

### Install draw.io CLI (no sudo required)

```bash
# Download the draw.io desktop .deb package
curl -sLo /tmp/drawio.deb "https://github.com/jgraph/drawio-desktop/releases/download/v26.0.9/drawio-amd64-26.0.9.deb"

# Extract without installing (no sudo needed)
mkdir -p /tmp/drawio-app
dpkg-deb -x /tmp/drawio.deb /tmp/drawio-app/

# Copy to a permanent location
mkdir -p ~/bin/drawio-app
cp -r /tmp/drawio-app/opt/drawio/* ~/bin/drawio-app/
```

> **Note:** `xvfb-run` must be available (`/usr/bin/xvfb-run`). If not installed:
> ```bash
> sudo apt install xvfb
> ```

### Usage

```bash
xvfb-run -a ~/bin/drawio-app/drawio -x -f png -o output.png input.drawio
```
