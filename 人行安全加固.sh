#!/bin/bash

# 定义字体输出色彩变量
GREEN_COLOR='\E[1;32m'
BLUE_COLOR='\E[1;34m'

# 显示菜单选项
echo -e "\t\t\t ========== 请选择要设置的密码策略 ========== "
echo -e "\t1. 密码最小有效期为14天"
echo -e "\t2. 密码最大有效期为90天"
echo -e "\t3. 密码失效提前警告期限为10天"
echo -e "\t4. 密码口令最多失败次数设为5次,锁定时间为30s"
echo -e "\t5. 密码口令应在8位及以上"
echo -e "\t6. 密码包括数字、小写字母、大写字母和特殊符号4类中至少3类"
echo -e "\t7. 不能使用前五次用过的密码"
echo -e "\t\t\t ========== 用户登录安全策略 ========== "
echo -e "\t8. 禁止root用户直接登陆"
echo -e "\t9. 在sshd_config文件中设置protocol版本2"
echo -e "\t10. 用户登陆无操作时,超过300秒需重新登陆"
echo -e "\t11. 设置umask值设置为027 "
echo -e "\t12. 确保路径环境变量中不包含当前目录"
echo -e "\t13. 禁止在控制台直接按ctl-alt-del重新启动计算机"
echo -e "\t\t\t ========== SSH安全策略 ========== "
echo -e "\t14. 配置某些关键目录其所需的最小权限；"
echo -e "\t15. 系统应合理配置日志文件权限，控制对日志文件读取、修改和删除等操作"
echo -e "\t16. 配置ntp,保证时间同步 "
echo -e "\t17. 设置登录前后警告信息"
echo -e "\t18. 关闭系统防火墙"
echo -e "\t19. 配置系统增强安全功能，防止运行的程序出现堆栈缓冲溢出问题 "
echo -e "\t20. 确认操作系统用户和数据库用户均具有口令"
echo -e "\t21. 使用ssh关闭telnet"
echo -e "\t22. 使用telnet时不显示系统的信息和版本"
echo -e "x. 退出"

# 循环读取用户选择并执行相应操作
while true; do
  read -p "请输入选项(多选用逗号隔开,如1,2):" choices
  IFS=',' read -ra selections <<< "$choices"  # 将用户输入用逗号分隔成数组

  for choice in "${selections[@]}"; do
    case $choice in
      1)
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
      2)
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
      3)
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
      4)
        echo "========== 配置： 密码口令最多失败次数设为5次,锁定时间为30s ============"
        #!/bin/bash
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


