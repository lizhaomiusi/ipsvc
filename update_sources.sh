#!/bin/bash
# 每天由 GitHub Actions 运行：按 upstream.txt 从原始出处拉最新频道列表，覆盖仓库里的同名 .m3u
# 拉取失败、返回的是网页、或者条数比旧文件少了七成以上（多半是上游出问题）时，保留旧文件。
# hubei.m3u 来自本地测速，不在这里更新。
set -u
cd "$(dirname "$0")"
PAT='^(https?|rtp|rtsp)://|,(https?|rtp|rtsp)://'
fail=0
while IFS='|' read -r file url; do
  case "$file" in ''|\#*) continue;; esac
  if ! curl -sfL --retry 2 -m 90 -o "${file}.tmp" "$url"; then
    echo "失败 ${file}  下载出错 ${url}（保留旧文件）"; rm -f "${file}.tmp"; fail=$((fail + 1)); continue
  fi
  if head -c 2048 "${file}.tmp" | grep -qiE '^[[:space:]]*<|<html|<!doctype'; then
    echo "失败 ${file}  返回的是网页（保留旧文件）"; rm -f "${file}.tmp"; fail=$((fail + 1)); continue
  fi
  new=$(grep -cE "$PAT" "${file}.tmp")
  old=0; [ -f "${file}.m3u" ] && old=$(grep -cE "$PAT" "${file}.m3u")
  if [ "$new" -eq 0 ] || [ $((new * 10)) -lt $((old * 3)) ]; then
    echo "失败 ${file}  只有 ${new} 条，旧文件 ${old} 条（保留旧文件）"; rm -f "${file}.tmp"; fail=$((fail + 1)); continue
  fi
  mv "${file}.tmp" "${file}.m3u"
  echo "成功 ${file}  ${old} -> ${new} 条"
done < upstream.txt
echo "失败 ${fail} 个"
