#!/bin/bash
# 定义字体输出色彩变量
GREEN_COLOR='\E[1;32m'
BLUE_COLOR='\E[1;34m'

echo -e "/t/t/t========== 配置: 密码最小有效期为14天 ============"
if grep -q "PASS_MIN_DAYS 14" /etc/login.defs; then
  echo -e "${BLUE_COLOR} 配置: 密码最小有效期为14天已存在/etc/login.defs文件中 ${BLUE_COLOR} "
else
  sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 14/g' /etc/login.defs
  echo -e "${GREEN_COLOR} 配置:(密码最小有效期为14天) =====> 配置完成 ${GREEN_COLOR}"
fi

echo -e "/t/t/t========== 配置: 密码最大有效期为90天 ============"
if grep -q "PASS_MAX_DAYS 90" /etc/login.defs; then
  echo "${BLUE_COLOR} 配置: 密码最大有效期为90天已存在/etc/login.defs文件中 ${BLUE_COLOR} "
else
  sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
  echo -e "${GREEN_COLOR} 配置:(密码最大有效期为90天) =====> 配置完成 ${GREEN_COLOR}"
fi

echo -e "/t/t/t========== 配置: 密码失效提前警告期限为10天 ============"
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 10/g' /etc/login.defs
sed -n '/^PASS_WARN_AGE/p' /etc/login.defs
if grep -q "PASS_MAX_DAYS 90" /etc/login.defs; then
  echo "配置:密码失效提前警告期限为10天 已存在/etc/login.defs文件中"
else
  sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
  echo -e "${GREEN_COLOR} 配置:密码失效提前警告期限为10天 =====> 配置完成 ${GREEN_COLOR}"
fi

echo -e "/t/t/t========== 配置: 密码口令最多失败次数设为5次,锁定时间为30s ============"
if grep -q "auth required pam_tally.so deny=5 unlock_time=30" /etc/pam.d/system-auth; then
  echo "配置已存在/etc/pam.d/system-auth文件中"
else
  # 在/etc/pam.d/system-auth中获取最后一个 'auth' 字符串的行号
  last_auth_line=$(grep -n "auth " /etc/pam.d/system-auth | tail -1 | cut -d ':' -f 1)
  # 在最后一个 'auth' 字符串之后的下一行添加 'auth required pam_tally.so deny = 5 unlock_time = 30'
  sed -i "${last_auth_line}a auth required pam_tally.so deny=5 unlock_time=30" /etc/pam.d/system-auth
  echo -e "${GREEN_COLOR} 配置已经添加 to /etc/pam.d/system-auth =====> 配置完成 ${GREEN_COLOR}"
fi

echo -e "/t/t/t========== 密码口令应在8位及以上 ============"
if grep -q "^minlen" /etc/security/pwquality.conf; then
  echo "配置已存在/etc/security/pwquality.conf文件中"
else
  authconfig --passminlen=8 --update
  echo -e "${GREEN_COLOR} 配置已经添加 to /etc/security/pwquality.conf =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 密码包括数字、小写字母、大写字母和特殊符号4类中至少3类 ============"
# 配置:最小数字长度
if grep -q "^dcredit" /etc/security/pwquality.conf; then
  echo "配置:最小数字长度 已存在/etc/security/pwquality.conf文件中"
else
  authconfig --enablereqdigit --update
  echo -e "${GREEN_COLOR} 配置:最小数字长度 已经添加 to /etc/security/pwquality.conf =====> 配置完成 ${GREEN_COLOR} "
fi
# 配置:特殊符号
if grep -q "^ocredit" /etc/security/pwquality.conf; then
  echo "配置:特殊符号 已存在/etc/security/pwquality.conf文件中"
else
  authconfig --enablereqother --update
  echo -e "${GREEN_COLOR} 配置:特殊符号 已经添加 to /etc/security/pwquality.conf =====> 配置完成 ${GREEN_COLOR} "
fi
# 配置:至少一个小写字母
if grep -q "^lcredit" /etc/security/pwquality.conf; then
  echo "配置:至少一个小写字母 已存在/etc/security/pwquality.conf文件中"
else
  authconfig --enablereqlowerr --update
  echo -e "${GREEN_COLOR} 配置:至少一个小写字母 已经添加 to /etc/security/pwquality.conf =====> 配置完成 ${GREEN_COLOR} "
fi
# 配置: 至少一个大写字母
if grep -q "^ucredit" /etc/security/pwquality.conf; then
  echo "配置:至少一个大写字母 已存在/etc/security/pwquality.conf文件中"
else
  authconfig --enablerequpper --update
  echo -e "${GREEN_COLOR} 配置:至少一个大写字母 已经添加 to /etc/security/pwquality.conf =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 不能使用前五次用过的密码 ============"
if grep -q "use_authtok remember=5" /etc/pam.d/system-auth; then
  echo "配置:不能使用前五次用过的密码 已存在/etc/pam.d/system-auth文件中"
else
  sed -i 's/use_authtok/use_authtok remember=5/' /etc/pam.d/system-auth
  echo -e "${GREEN_COLOR} 配置:不能使用前五次用过的密码 已经添加 to /etc/pam.d/system-auth =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 禁止root用户直接登陆 ============"
if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
  echo "配置:禁止root用户直接登陆 已存在/etc/ssh/sshd_config文件中"
else
  sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
  echo -e "${GREEN_COLOR} 配置:禁止root用户直接登陆 已经添加 to /etc/ssh/sshd_config =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 用户登陆无操作时,超过300秒需重新登陆 ============"
if grep -q "TMOUT=300" /etc/profile; then
  echo "配置:用户登陆无操作时,超过300秒需重新登陆 已存在/etc/profile文件中"
else
  sed -i '$a TMOUT=300\nreadonly TMOUT\nexport TMOUT' /etc/profile
  echo -e "${GREEN_COLOR} 配置:用户登陆无操作时,超过300秒需重新登陆 已经添加 to /etc/profile =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 设置umask值设置为027  ============"
if grep -q "umask 027" /etc/profile; then
  echo "配置:设置umask值设置为027  已存在/etc/profile文件中"
else
  sed -i 's/umask.*22/umask 027/g' /etc/profile
  echo -e "${GREEN_COLOR} 配置:设置umask值设置为027  已经添加 to /etc/profile =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 对监控用户打开文件数目上限设为2000  ============"
if grep -q "monitor - nofiles 2000" /etc/security/limits.conf; then
  echo "配置:对监控用户打开文件数目上限设为2000  已存在/etc/profile文件中"
else
  echo "monitor - nofiles 2000" >>/etc/security/limits.conf
  echo -e "${GREEN_COLOR} 配置:对监控用户打开文件数目上限设为2000  已经添加 to /etc/profile =====> 配置完成 ${GREEN_COLOR} "
fi

echo -e "/t/t/t========== 确保路径环境变量中不包含当前目录 ============"
# 检查/etc/profile文件中的PATH变量
if grep -q "^export\s\+PATH\s\+=" /etc/profile; then
  sed -i '/^export\s\+PATH\s\+=/ s/\.[^:]*\(:\|$\)/\1/g' /etc/profile
else
  echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >>/etc/profile
fi

# 检查/etc/bashrc文件中的PATH变量
if grep -q "^export\s\+PATH\s\+=" /etc/bashrc; then
  sed -i '/^export\s\+PATH\s\+=/ s/\.[^:]*\(:\|$\)/\1/g' /etc/bashrc
else
  echo 'export PATH=$PATH' >>/etc/bashrc
fi

# 更新当前shell的PATH变量
source /etc/profile

# 检查输出值中是否包含'.'
if echo $PATH | grep -q '\.'; then
  echo '路径环境变量包含 "."'
else
  echo '路径环境变量不包含 "."'
fi

echo -e "/t/t/t========== sshd_config文件中设置protocol版本2  ============"
# 检查sshd_config文件中是否存在协议版本2
if grep -q "^Protocol" /etc/ssh/sshd_config; then
  # 如果协议版本不是2,则修改配置
  if grep -qv "^Protocol\s\+2" /etc/ssh/sshd_config; then
    sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
    echo "修改Protocol version to 2 在sshd_config文件 =====> 配置完成"
  else
    echo "配置:SSH配置Protocol version 2已经存在于sshd_config文件中"
  fi
else
  # 如果协议版本2不存在,则将其添加到配置中
  echo "Protocol 2" >>/etc/ssh/sshd_config
  echo "配置:添加rotocol version to 2 在sshd_config文件 =====> 配置完成"
fi

echo -e "/t/t/t========== 配置某些关键目录其所需的最小权限;  ============"
echo -e "/t/t/t========== 重点要求passwd、group、crontabs、xhost文件权限  ============"
#检查/etc/passwd 最小权限 
if [ $(stat -c %!a(MISSING) /etc/passwd) = "644" ] 
then 
  echo "/etc/passwd permissions are correct" 
else 
  echo "Setting permissions to 644 for /etc/passwd" 
  chmod 644 /etc/passwd 
fi
