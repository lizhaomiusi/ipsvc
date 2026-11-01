#!/bin/bash
# 每天由 GitHub Actions 运行：按 upstream.txt 从原始出处拉最新频道列表，覆盖仓库里的同名 .m3u
# 某个源拉取失败或内容无效时保留旧文件。hubei.m3u 来自本地测速，不在这里更新。
set -u
cd "$(dirname "$0")"
PAT='^(https?|rtp|rtsp)://|,https?://'
fail=0
while IFS='|' read -r file url; do
  case "$file" in ''|\#*) continue;; esac
  if curl -sfL --retry 2 -m 90 -o "$file.tmp" "$url" && grep -qE "$PAT" "$file.tmp"; then
    mv "$file.tmp" "$file.m3u"
    echo "成功 ${file}  $(grep -cE "$PAT" "$file.m3u") 条"
  else
    rm -f "$file.tmp"
    echo "失败 ${file}  ${url}（保留旧文件）"
    fail=$((fail + 1))
  fi
done < upstream.txt
echo "失败 ${fail} 个"
