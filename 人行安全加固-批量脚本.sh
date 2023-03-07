#!/bin/bash

# 定义字体输出色彩变量
GREEN_COLOR='\E[1;32m'
BLUE_COLOR='\E[1;34m'


echo "========== 配置： 密码最小有效期为14天 ============"
if grep -q "PASS_MIN_DAYS 14" /etc/login.defs
then
echo -e "${BLUE_COLOR} 配置： 密码最小有效期为14天已存在/etc/login.defs文件中 ${BLUE_COLOR} "
else
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 14/g' /etc/login.defs

echo -e "${GREEN_COLOR} 配置项:(密码最小有效期为14天) =====> 配置完成 ${GREEN_COLOR}" 
sed -n '/^PASS_MIN_DAYS/p' /etc/login.defs
fi  
;;

echo "========== 配置： 密码最大有效期为90天 ============"
if grep -q "PASS_MAX_DAYS 90" /etc/login.defs
then
echo "${BLUE_COLOR} 配置： 密码最大有效期为90天已存在/etc/login.defs文件中 ${BLUE_COLOR} "
else
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
sed -n '/^PASS_MAX_DAYS/p' /etc/login.defs
echo -e "${GREEN_COLOR} 配置项:(密码最大有效期为90天) =====> 配置完成 ${GREEN_COLOR}"
fi  
;;


echo "========== 配置： 密码失效提前警告期限为10天 ============"
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 10/g' /etc/login.defs
sed -n '/^PASS_WARN_AGE/p' /etc/login.defs
if grep -q "PASS_MAX_DAYS 90" /etc/login.defs
then
echo "配置:密码失效提前警告期限为10天 已存在/etc/login.defs文件中"
else
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
sed -n '/^PASS_MAX_DAYS/p' /etc/login.defs
echo -e "${GREEN_COLOR} 配置项:(密码最大有效期为90天) =====> 配置完成 ${GREEN_COLOR}"
fi  
;;


echo "========== 配置： 密码口令最多失败次数设为5次,锁定时间为30s ============"
if grep -q "auth required pam_tally.so deny=5 unlock_time=30" /etc/pam.d/system-auth; 
then
echo "配置已存在/etc/pam.d/system-auth文件中"
else
# Get the line number of the last 'auth' string in /etc/pam.d/system-auth
last_auth_line=$(grep -n "auth " /etc/pam.d/system-auth | tail -1 | cut -d ':' -f 1)
# Add 'auth required pam_tally.so deny=5 unlock_time=30' on the next line after the last 'auth' string
sed -i "${last_auth_line}a auth required pam_tally.so deny=5 unlock_time=30" /etc/pam.d/system-auth
echo -e "${GREEN_COLOR} 配置已经添加 to /etc/pam.d/system-auth =====> 配置完成 ${GREEN_COLOR} "
fi
;;
5)
echo "========== 密码口令应在8位及以上 ============"
authconfig --passminlen=8 --update
grep "^minlen" /etc/security/pwquality.conf
;;
6)
echo "========== 密码包括数字、小写字母、大写字母和特殊符号4类中至少3类 ============"
authconfig --enablereqdigit --update		#最小数字长度s
authconfig --enablereqother --update		#特殊符号
authconfig --enablereqlower --update		#至少一个小写字母
authconfig --enablerequpper --update		#至少一个大写字母
grep "^dcredit" /etc/security/pwquality.conf
grep "^ocredit" /etc/security/pwquality.conf
grep "^dcredit" /etc/security/pwquality.conf
grep "^ocredit" /etc/security/pwquality.conf
;;
7)
echo "========== 不能使用前五次用过的密码 ============"
if grep -q "use_authtok remember=5" /etc/pam.d/system-auth; 
then
echo "配置已存在/etc/pam.d/system-auth文件中"
else

  sed -i 's/use_authtok/use_authtok remember=5/' /etc/pam.d/system-auth
echo -e "${GREEN_COLOR} 配置已经添加 to /etc/pam.d/system-auth =====> 配置完成 ${GREEN_COLOR} "
fi

;;

8)
# Check if protocol version 2 exists in sshd_config file
if grep -q "^Protocol" /etc/ssh/sshd_config; then
# If protocol version is not 2, then modify the configuration
if grep -qv "^Protocol\s\+2" /etc/ssh/sshd_config; then
    sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
    echo "修改Protocol version to 2 在sshd_config文件 =====> 配置完成"
else
    echo "SSH配置Protocol version 2已经存在于sshd_config文件中"
fi
else
# If protocol version 2 does not exist, then add it to the configuration
echo "Protocol 2" >> /etc/ssh/sshd_config
echo "添加rotocol version to 2 在sshd_config文件 =====> 配置完成"
fi

x)
echo "退出程序"
exit 0
;;
*)
echo "输入错误，请重新输入。"
;;
esac
done
done


