arch="$(detect_arch)"

log "扫描 GitHub app 目录获取版本..."

API="https://api.github.com/repos/${REPO}/contents/app"
json="${TMP_DIR}/list.json"

download_to "${API}" "${json}"

# 提取版本号 vX.Y.Z
versions="$(grep -oE 'vohive_v[0-9]+\.[0-9]+\.[0-9]+' "${json}" | \
  sed 's/vohive_\(v[0-9.]*\).*/\1/' | sort -V | uniq)"

if [ -z "${versions}" ]; then
  err "未发现任何版本"
  exit 1
fi

latest_version="$(echo "${versions}" | tail -n 1)"

case "${arch}" in
  amd64|x86_64) file_arch="amd64" ;;
  arm64|aarch64) file_arch="arm64" ;;
  armv7|armv7l) file_arch="armv7" ;;
esac

asset="vohive_${latest_version}_linux_${file_arch}"
url="https://raw.githubusercontent.com/${REPO}/master/app/${asset}"

downloaded="${TMP_DIR}/vohive"

log "检测到最新版本: ${latest_version}"
log "架构: ${file_arch}"
log "下载: ${url}"

if ! download_to "${url}" "${downloaded}"; then
  err "下载失败: ${url}"
  exit 1
fi

# 防止 HTML
if head -c 4 "${downloaded}" | grep -q "<!DO"; then
  err "下载失败（返回 HTML）"
  exit 1
fi

# ELF 校验
if ! file "${downloaded}" | grep -q "ELF"; then
  err "不是有效二进制"
  file "${downloaded}" || true
  exit 1
fi

chmod +x "${downloaded}"
