#!/usr/bin/env bash
set -e

# Forward to public installer
curl -fsSL https://raw.githubusercontent.com/allanmaaz/sayn/main/apps/web/public/install.sh | bash
