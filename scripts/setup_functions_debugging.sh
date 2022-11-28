#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#
# Set up infra/env.sh that can be sourced to load deployment token etc
#
mkdir -p $script_dir/../.vscode
cat <<EOF > $script_dir/../.vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "type": "func",
      "label": "func: host start (api)",
      "command": "host start",
      "problemMatcher": "$func-node-watch",
      "isBackground": true,
      "dependsOn": "npm install (functions)",
      "options": {
        "cwd": "${workspaceFolder}/api"
      }
    },
    {
      "type": "func",
      "label": "func: host start (back-end)",
      "command": "host start",
      "problemMatcher": "$func-node-watch",
      "isBackground": true,
      "dependsOn": "npm install (functions)",
      "options": {
        "cwd": "${workspaceFolder}/back-end"
      }
    },
    {
      "type": "shell",
      "label": "npm install (functions)",
      "command": "npm install",
      "options": {
        "cwd": "${workspaceFolder}/api"
      }
    },
    {
      "type": "shell",
      "label": "npm prune (functions)",
      "command": "npm prune --production",
      "problemMatcher": [],
      "options": {
        "cwd": "${workspaceFolder}/api"
      }
    }
  ]
}
EOF
cat <<EOF > $script_dir/../.vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Attach to Node Functions (api)",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "preLaunchTask": "func: host start (api)",
      
    },
    {
      "name": "Attach to Node Functions (back-end)",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "preLaunchTask": "func: host start (back-end)",
    }
  ]
}EOF
