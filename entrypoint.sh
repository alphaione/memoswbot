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

# --------- memogram 启动逻辑 ---------
if [ -n "$BOT_TOKEN" ]; then
   echo "Starting memogram ..."
   ./memogram &
   MEMOGRAM_PID=$!
   trap 'kill -TERM $MEMOGRAM_PID' EXIT
else
   cat <<WARN
=======================================================
memogram 未启动！
如需启用 memogram，请重新运行容器并添加环境变量：
   -e BOT_TOKEN=<your_bot_token>
=======================================================
WARN
fi

# --------- 前台启动 memos，成为 PID 1 ---------
echo "Starting memos ..."
exec "$@"
