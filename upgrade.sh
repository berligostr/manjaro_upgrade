#!/bin/bash
echo -e "Этот скрипт проверяет наличие обновлений и обновляет систему с помощью pamac, yay и paru."
echo -e "Для полноценной работы скрипта необходимо установить следующие пакеты: pacman-contrib"
echo -e "rebuild-detector, timeshift, timeshift-autosnap-manjaro, yay, meld, needrestart и rkhunter."
echo -e "аурхелпер paru вы должны установить самостоятельно, при наличии yay он не нужен."
echo -e "Скрипт будет работать и без них, только с ограниченной функциональностью."

pack () 
{
  package="$1"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";  
  if [ -n "${check}" ] ; then echo -e "$1 установлен" ; else pamac install --no-confirm $1 ; fi
}

echo -e "\n"; read -n 1 -p "Установить отсутствующие пакеты и настроить бэкап timeshift? [y/N]: " inst;
if [[ "$inst" = [yYlLдД] ]]; then 
  pack pacman-contrib ; pack rebuild-detector ; pack timeshift ; pack timeshift-autosnap-manjaro 
  pack yay ; pack meld ; pack needrestart ; pack rkhunter ; 
  #pack paru-bin ;  
    if [ ! -f $HOME/my_scripts/rkhunter.sh ]; then 
    mkdir -p $HOME/my_scripts
    touch $HOME/my_scripts/rkhunter.sh
    echo "#!/bin/bash " >> $HOME/my_scripts/rkhunter.sh
    echo "sudo rkhunter --check --skip-keypress --update --report-warnings-only 2> /dev/null " >> $HOME/my_scripts/rkhunter.sh
    chmod +x $HOME/my_scripts/rkhunter.sh
  fi
#  if [ ! -f $HOME/my_scripts/update_clamav.sh ]; then
#    mkdir -p $HOME/my_scripts
#    touch $HOME/my_scripts/update_clamav.sh
#    echo "#!/bin/bash " >> $HOME/my_scripts/update_clamav.sh
#    echo "systemctl stop clamav-freshclam " >> $HOME/my_scripts/update_clamav.sh
#    echo "if [ -f /var/lib/clamav/freshclam.dat ]; then rm -f /var/lib/clamav/freshclam.dat; fi " >> $HOME/my_scripts/update_clamav.sh
#    echo "if [ -f /var/lib/clamav/main.cvd ]; then rm -f /var/lib/clamav/*.cvd; fi " >> $HOME/my_scripts/update_clamav.sh
#    echo "wget https://packages.microsoft.com/clamav/main.cvd -O /var/lib/clamav/main.cvd " >> $HOME/my_scripts/update_clamav.sh
#    echo "wget https://packages.microsoft.com/clamav/daily.cvd -O /var/lib/clamav/daily.cvd " >> $HOME/my_scripts/update_clamav.sh
#    echo "wget https://packages.microsoft.com/clamav/bytecode.cvd -O /var/lib/clamav/bytecode.cvd " >> $HOME/my_scripts/update_clamav.sh
#    echo "stat /var/lib/clamav/daily.cvd | grep Модифицирован " >> $HOME/my_scripts/update_clamav.sh
#    echo "systemctl start clamav-freshclam " >> $HOME/my_scripts/update_clamav.sh
#    echo "systemctl restart clamav-freshclam " >> $HOME/my_scripts/update_clamav.sh
#    chmod +x $HOME/my_scripts/update_clamav.sh
#  fi
  timeshift-launcher
fi
#package="clamav"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
#if [ -n "${check}" ] ; 
#  then
#    if [[ ! -z "$(find /var/lib/clamav/daily.cvd -type f -mtime +6)" ]]; then echo -e "\n"; 
#      echo -e "База clamav создана более недели назад!"; echo -e "\n"; stat /var/lib/clamav/daily.cvd | grep Модифицирован ; 
#      echo -e "\n"; read -n 1 -p "Обновить базы антивируса clamav? [y/N]: " clupdate;
#      if [[ "$clupdate" = [yYlLдД] ]]; then echo -e "\n"; sudo $HOME/my_scripts/update_clamav.sh; fi
#    fi
#fi
# ---------------------------------------------------------------------------------------------
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then echo -e "\n"; sudo rm /var/lib/pacman/db.lck; fi
# Этот скрипт проверяет наличие обновлений, обновляет и перезапускает сервисы при необходимости
#echo -e "\n"; read -n 1 -p "Проверить обновления? [y/N]: " cupdate; 
#if [[ "$cupdate" = [yYlLдД] ]]; then echo -e "\n"; pamac checkupdates -a; fi
echo -e "\n"; echo -e "Проверка наличия обновлений:"; echo -e "\n"; pamac checkupdates -a
# ---------------------------------------------------------------------------------------------
package="timeshift"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
if [ -n "${check}" ] ; then
  if ! pgrep 'timeshift'>null; 
    then
      echo -e "\n"; timesmount="$(df | grep "$(sudo timeshift --list | grep Device | awk '{ print $3 }')" | awk '{ print $6 }')"
      timesfile="$timesmount/timeshift/snapshots"
      bekaplast=$(find $timesfile -mindepth 1 -maxdepth 1 -printf '%P\n' | sort -r | head -n 1)
      echo -e "\n"; echo -e "Последний бэкап timeshift сделан: " $bekaplast ;
      package="timeshift-autosnap-manjaro"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; then
        echo -e "\n"; read -n 1 -p "Сделать бэкап timeshift перед обновлением? [y/N]: " bekap; 
        if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=true/skipAutosnap=false/g' /etc/timeshift-autosnap.conf; fi
      fi
    else echo -e "\n"; echo -e "Сейчас невозможно определить последний бэкап, так как работает timeshift"
  fi  
fi
# echo -e "\n"; read -n 1 -p "Обновить установленные пакеты? [Y/n]: " update; 
# if [[ "$update" = "" || "$update" = [yYlLдД] ]]; then 
# pamac upgrade --forse-refresh; 
# Если терминал завис нужно нажать Ctrl+c
echo -e "\n"; read -n 1 -p "Обновить пакеты из репозиториев? [y/N]: " updrep;
if [[ "$updrep" = [yYlLдД] ]]; then
  echo -e "\n"; echo -e "Будет произведено обновление пакетов репозиториев, сборка AUR не обновляется!"; 
  echo -e "\n"; echo -e "Если в процессе обновления пакетов терминал завис нужно нажать Ctrl+c"; echo -e "\n";
  ( pamac upgrade --no-confirm --enable-downgrade --no-aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac; 
  echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  echo -e "\n"; read -n 1 -p "Нет обновлений? Принудительно обновить базы? [y/N]: " update; echo -e "\n";
  if [[ "$update" = [yYlLдД] ]]; then 
    ( pamac upgrade --force-refresh --enable-downgrade --no-aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac;
  fi  
  # ---------------------------------------------------------------------------------------------
  echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  package="yay"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; 
    then
      echo -e "\n"; read -n 1 -p "Обновить пакеты из репозиториев через AURхелперы? [y/N]: " upda; 
      if [[ "$upda" = [yYlLдД] ]]; then
        echo -e "\n"; read -n 1 -p "Обновить через yay? [y/N]: " yayupd;
        if [[ "$yayupd" = [yYlLдД] ]]; then echo -e "\n"; yay -Syyuu --repo | tee $HOME/upgrade.yay; fi
        echo -e "\n"; read -n 1 -p "Обновить через paru? [y/N]: " parupd;
        if [[ "$parupd" = [yYlLдД] ]]; then echo -e "\n"; paru -Syyuu --repo | tee $HOME/upgrade.paru; fi
        # if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=false/skipAutosnap=true/g' /etc/timeshift-autosnap.conf; fi
      fi
      echo -e "\n"; read -n 1 -p "Пересобрать Qt пакеты из AUR? [y/N]: " uqta;
      if [[ "$uqta" = [yYlLдД] ]]; then yay -S --rebuild $(pacman -Qmt | grep ^qt); fi
  fi
  #if [[ ! "$update" = [yYlLдД] ]]; then pamac upgrade --force-refresh --enable-downgrade --no-aur ; fi
  # echo -e "\n";
  # ---------------------------------------------------------------------------------------------
  # echo -e "\n"; read -n 1 -p "Обновить flatpak?  [y/N]: " flat;
  # if [[ "$flat" = [yY] ]]; then echo -e "\n"; flatpak update; echo -e "\n"; fi
  # Проверка необходимости постдействий после обновлений ---------------------------------------
  if [[ -f $HOME/upgrade.pamac ]]; then if cat $HOME/upgrade.pamac | grep 'Нет заданий.'; then rm $HOME/upgrade.pamac; fi; fi
  if [[ -f $HOME/upgrade.yay ]]; then if cat $HOME/upgrade.yay | grep 'there is nothing to do'; then rm $HOME/upgrade.yay; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'делать больше нечего'; then rm $HOME/upgrade.paru; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'Нет заданий'; then rm $HOME/upgrade.paru; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'there is nothing to do'; then rm $HOME/upgrade.paru; fi; fi
  # --------------------------------------------------------------------------------------------
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    echo -e "\n"; read -n 1 -p "Сравнить конфиги pacnew? [Y/n]: " diff;
    if [[ "$diff" = "" || "$diff" = [yYlLдД] ]]; then 
      package="meld"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; 
        then
          echo -e "\n"; read -n 1 -p "Сравнить в meld(графика)? [Y/n]: " difft;
          if [[ "$difft" = "" || "$difft" = [yYlLдД] ]]; 
            then echo -e "\n"; sudo DIFFPROG=meld pacdiff; 
            else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff; 
          fi
        else
          echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff;
      fi
    fi
    # Конец условия Сравнить конфиги pacnew? 
    package="needrestart"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
    if [ -n "${check}" ] ; 
      then
        echo -e "\n"; read -n 1 -p "Проверить сервисы для перезапуска? [Y/n]: " restart;
        if [[ "$restart" = "" || "$restart" = [yYlLдД] ]]; then
          echo -e "\n"; sudo systemctl daemon-reload; sudo needrestart -u NeedRestart::UI::stdio -r i;  
        fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить, есть ли лишние модули ядра? [y/N]: " kerny; 
    if [[ "$kerny" = [yYlLдД] ]]; then
      echo -e "\n"; echo "В системе установлены следующие ядра:"
      pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]"
      echo -e "\n"; echo "Возможно необходимо почистить каталог /usr/lib/modules/"
      package="thunar"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; 
        then
        cd /usr/lib/modules/; gksu dbus-run-session thunar /usr/lib/modules/ 2> /dev/null ;
      fi
    fi
    echo -e "\n"; read -n 1 -p "Сделать загружаемым по умолчанию новое ядро? [y/N]: " lynn; 
    if [[ "$lynn" = [yYlLдД] ]]; then
      echo -e "\n"; echo "В системе установлены следующие ядра:"
      pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]"
      lini=$(pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]" | head -n 1 | awk '{ print $2 }')
      echo -e "\n"; read -n 1 -p "По умолчанию rEFInd будет загружать $lini ? [y/N]: " lynin;
      if [[ "$lynin" = [yYlLдД] ]]; then /home/kostya/my_scripts/refind-hook.sh ; fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить, пакеты для пересборки? [y/N]: " pac; 
    if [[ "$pac" = [yYlLдД] ]]; then echo -e "\n";
      if [[ -n "$(checkrebuild | grep -v zoom | head -n 1)" ]]; 
        then echo "Возможно необходимо пересобрать следующие пакеты из AUR:"; echo -e "\n"; checkrebuild | grep -v zoom ;
        else echo "Пакетов из AUR для пересборки нет."; 
      fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить пакеты сироты? [y/N]: " syr;  
    if [[ "$syr" = [yYlLдД] ]]; then echo -e "\n"; 
      if [[ -n "$(pamac list -o | head -n 1)" ]];
        then echo "Возможно следующие пакеты являются сиротами (ПРОВЕРЬТЕ перед удалением!): "; echo -e "\n"; 
          pamac list -o
          echo -e "\n"; read -n 1 -p "Удалить пакеты сироты? [y/N]: " syrd; 
          if [[ "$syrd" = [yYlLдД] ]]; then echo -e "\n"; pamac remove -o ; fi
        else echo -e "\n"; echo "Пакеты сироты отсутствуют."; echo -e "\n";
      fi
    fi
    # запуск rkhunter --propupd после изменения конфигурационных файлов или обновления ОС
    package="rkhunter"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
    if [ -n "${check}" ] ; 
      then
        echo -e "\n"; read -n 1 -p "Выполнить проверку rkhunter? [y/N]: " rkh; 
        if [[ "$rkh" = [yYlLдД] ]]; then echo -e "\n";
          $HOME/my_scripts/rkhunter.sh ; 
          echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
          while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
          echo -e "\n"; read -n 1 -p "Все в порядке? Создать базу данных для rkhunter? [y/N]: " rkhb; 
          if [[ "$rkhb" = [yYlLдД] ]]; then echo -e "\n"; sudo rkhunter --propupd 2> /dev/null ; fi
        fi
    fi
  fi
fi
# Конец условия Необходимости постобработки после обновления пакетов репозиториев ----------------------------------------------
#  else echo -e "\n"; echo -e "Вы приняли решение не обновлять установленные пакеты"
#fi
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then echo -e "\n"; sudo rm /var/lib/pacman/db.lck; fi
echo -e "\n"; read -n 1 -p "Обновить пакеты из AUR? [y/N]: " updaur;
if [[ "$updaur" = [yYlLдД] ]]; then
  echo -e "\n"; echo -e "Будет произведено обновление пакетов из AUR."; 
  echo -e "\n"; echo -e "Если в процессе обновления пакетов терминал завис нужно нажать Ctrl+c"; echo -e "\n";
  ( pamac upgrade --aur --no-confirm && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac;
  echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  echo -e "\n"; read -n 1 -p "Нет обновлений? Принудительно обновить базы? [y/N]: " update; echo -e "\n";
  if [[ "$update" = [yYlLдД] ]]; then 
    ( pamac upgrade --force-refresh --aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac;
  fi  
  echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  package="yay"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; 
    then
      echo -e "\n"; read -n 1 -p "Обновить пакеты из AUR через AURхелперы? [y/N]: " upda; 
      if [[ "$upda" = [yYlLдД] ]]; then  
        echo -e "\n"; read -n 1 -p "Обновить через yay? [y/N]: " yayupd;
        if [[ "$yayupd" = [yYlLдД] ]]; then echo -e "\n"; yay -Syyu --aur | tee $HOME/upgrade.yay; fi
        echo -e "\n"; read -n 1 -p "Обновить через paru? [y/N]: " parupd;
        if [[ "$parupd" = [yYlLдД] ]]; then echo -e "\n"; paru -Syyu --aur | tee $HOME/upgrade.paru; fi
      fi
      echo -e "\n"; read -n 1 -p "Пересобрать Qt пакеты из AUR? [y/N]: " uqta;
      if [[ "$uqta" = [yYlLдД] ]]; then yay -S --rebuild $(pacman -Qmt | grep ^qt); fi
  fi
  #if [[ ! "$update" = [yYlLдД] ]]; then pamac upgrade --force-refresh --aur ; fi
  if [[ -f $HOME/upgrade.pamac ]]; then if cat $HOME/upgrade.pamac | grep 'Нет заданий.'; then rm $HOME/upgrade.pamac; fi; fi
  if [[ -f $HOME/upgrade.yay ]]; then if cat $HOME/upgrade.yay | grep 'there is nothing to do'; then rm $HOME/upgrade.yay; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'делать больше нечего'; then rm $HOME/upgrade.paru; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'Нет заданий'; then rm $HOME/upgrade.paru; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'there is nothing to do'; then rm $HOME/upgrade.paru; fi; fi
  # --------------------------------------------------------------------------------------------
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    echo -e "\n"; read -n 1 -p "Сравнить конфиги pacnew? [y/N]: " diff;
    if [[ "$diff" = [yYlLдД] ]]; then 
      package="meld"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; 
        then
          echo -e "\n"; read -n 1 -p "Сравнить в meld(графика)? [Y/n]: " difft;
          if [[ "$difft" = "" || "$difft" = [yYlLдД] ]]; 
            then echo -e "\n"; sudo DIFFPROG=meld pacdiff; 
            else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff; 
          fi
        else
          echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff;
      fi
    fi
    # Конец условия Сравнить конфиги pacnew? 
    package="needrestart"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
    if [ -n "${check}" ] ; 
      then
        echo -e "\n"; read -n 1 -p "Проверить сервисы для перезапуска? [y/N]: " restart;
        if [[ "$restart" = [yYlLдД] ]]; then
          echo -e "\n"; sudo systemctl daemon-reload; sudo needrestart -u NeedRestart::UI::stdio -r i;  
        fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить, пакеты для пересборки? [y/N]: " pac; 
    if [[ "$pac" = [yYlLдД] ]]; then echo -e "\n";
      if [ -n "$(checkrebuild | grep -v zoom | head -n 1)" ]; 
        then echo "Возможно необходимо пересобрать следующие пакеты из AUR:"; echo -e "\n"; 
          checkrebuild | grep -v zoom
        else echo "Пакетов из AUR для пересборки нет."; echo -e "\n";
      fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить пакеты сироты? [y/N]: " syro;  
    if [[ "$syro" = [yYlLдД] ]]; then echo -e "\n"; 
      if [ -n "$(pamac list -o | head -n 1)" ];
        then echo "Возможно следующие пакеты являются сиротами (ПРОВЕРЬТЕ перед удалением!): "; echo -e "\n"; 
          pamac list -o
          echo -e "\n"; read -n 1 -p "Удалить пакеты сироты? [y/N]: " syrd; 
          if [[ "$syrd" = [yYlLдД] ]]; then echo -e "\n"; pamac remove -o ; fi
        else echo "Пакеты сироты отсутствуют."; 
      fi
    fi
    # запуск rkhunter --propupd после изменения конфигурационных файлов или обновления ОС
    package="rkhunter"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
    if [ -n "${check}" ] ; 
      then
        echo -e "\n"; read -n 1 -p "Выполнить проверку rkhunter? [y/N]: " rkh; 
        if [[ "$rkh" = [yYlLдД] ]]; then echo -e "\n";
          $HOME/my_scripts/rkhunter.sh ; 
          echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
          while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
          echo -e "\n"; read -n 1 -p "Все в порядке? Создать базу данных для rkhunter? [y/N]: " rkhb; 
          if [[ "$rkhb" = [yYlLдД] ]]; then echo -e "\n"; sudo rkhunter --propupd 2> /dev/null ; fi
        fi
    fi
  fi
fi
#if [[ ! "$update" = [yYlLдД] ]]; then echo -e "\n"; pamac upgrade --force-refresh --enable-downgrade --aur ; fi
# Конец условия Необходимости постобработки после обновления AUR -------------------------------------------------
# Конец условия Обновить установленные пакеты?
package="timeshift-autosnap-manjaro"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
if [ -n "${check}" ] ; 
  then
    if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=false/skipAutosnap=true/g' /etc/timeshift-autosnap.conf; fi
fi
echo -e "\n";
# Удаление логов ------------------------------------------------------------------------------
if [[ -f $HOME/upgrade.paru ]]; then rm $HOME/upgrade.paru; fi
if [[ -f $HOME/upgrade.yay ]]; then rm $HOME/upgrade.yay; fi
if [[ -f $HOME/upgrade.pamac ]]; then rm $HOME/upgrade.pamac; fi 

