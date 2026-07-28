# validate-prompt-body.awk — validate *.prompt.md body (after YAML front matter).
# Usage: awk -v apath="<abs path>" -f validate-prompt-body.awk "<file>"
# Prints one line per violation: path<TAB>reason (UTF-8 file recommended).

BEGIN {
  if (apath == "") {
    print "validate-prompt-body.awk: missing -v apath=" > "/dev/stderr"
    exit 2
  }
  n = 0
  state = 0
}
/^---$/ {
  if (state == 0) { state = 1; next }
  if (state == 1) { state = 2; next }
}
state == 1 { next }
{
  line = $0
  sub(/\r$/, "", line)
  if (state == 0) {
    n++
    lines[n] = line
  } else if (state >= 2) {
    n++
    lines[n] = line
  }
}
END {
  path = apath
  req[1] = "## 适用场景"
  req[2] = "## 输入要求"
  req[3] = "## Prompt 正文"
  req[4] = "## 验收标准"
  last = -1
  for (i = 1; i <= 4; i++) {
    h = req[i]
    c = 0
    pos = 0
    for (j = 1; j <= n; j++) {
      t = lines[j]
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      if (t == h) {
        c++
        pos = j
      }
    }
    if (c == 0) {
      print path "\tmissing heading: " h
    } else if (c != 1) {
      print path "\theading must appear exactly once: " h
    } else {
      if (pos <= last) {
        print path "\theadings out of order: required sequence is ## 适用场景 → ## 输入要求 → ## Prompt 正文 → ## 验收标准"
      }
      last = pos
    }
  }
  pp = 0
  aa = 0
  for (j = 1; j <= n; j++) {
    t = lines[j]
    gsub(/^[ \t]+|[ \t]+$/, "", t)
    if (t == "## Prompt 正文") {
      pp = j
    }
    if (t == "## 验收标准") {
      aa = j
    }
  }
  if (pp > 0) {
    pb = ""
    for (j = pp + 1; j <= n; j++) {
      t = lines[j]
      sub(/\r$/, "", t)
      st = t
      gsub(/^[ \t]+|[ \t]+$/, "", st)
      if (st ~ /^## /) {
        break
      }
      pb = pb t "\n"
    }
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", pb)
    if (length(pb) == 0) {
      print path "\t## Prompt 正文 不能为空（须有可执行指令）"
    }
  }
  if (aa > 0) {
    ac = ""
    for (j = aa + 1; j <= n; j++) {
      t = lines[j]
      sub(/\r$/, "", t)
      st = t
      gsub(/^[ \t]+|[ \t]+$/, "", st)
      if (st ~ /^## /) {
        break
      }
      ac = ac t "\n"
    }
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", ac)
    if (length(ac) == 0) {
      print path "\t## 验收标准 不能为空（须有可判定口径或 eval 表）"
    }
  }
}
