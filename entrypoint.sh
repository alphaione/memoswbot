#!/usr/bin/env sh

# --------- file_env 函数 ---------
file_env() {
   var="$1"
   fileVar="${var}_FILE"

   val_var="$(printenv "$var")"
   val_fileVar="$(printenv "$fileVar")"

   if [ -n "$val_var" ] && [ -n "$val_fileVar" ]; then
      echo "error: both $var and $fileVar are set (but are exclusive)" >&2
      exit 1
   fi

   if [ -n "$val_var" ]; then
      val="$val_var"
   elif [ -n "$val_fileVar" ]; then
      val="$(cat "$val_fileVar")"
   fi

   export "$var"="$val"
   unset "$fileVar"
}

# --------- 处理 MEMOS_DSN 的文件变量 ---------
file_env "MEMOS_DSN"

# ========= 新增：3 秒后条件启动 memogram =========
./memos &
MEMOS_PID=$!

sleep 3        # 固定 3 秒延迟

if [ -n "$BOT_TOKEN" ]; then
  echo "Starting memogram after 3s ..."
  ./memogram &
  MEMOGRAM_PID=$!
  trap 'kill -TERM $MEMOS_PID $MEMOGRAM_PID' EXIT
else
  cat <<WARN
=======================================================
memogram 未启动！
如需启用 memogram，请重新运行容器并添加环境变量：
   -e BOT_TOKEN=<your_bot_token>
=======================================================
WARN
  trap 'kill -TERM $MEMOS_PID' EXIT
fi

wait $MEMOS_PID
