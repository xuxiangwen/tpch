# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

echo `date +%Y-%m-%d-%H:%M:%S`: clear cache：do nothing now
