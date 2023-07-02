#!/bin/bash
if [[ ! -z "$(find /var/lib/clamav/daily.cvd -type f -mtime +6)" ]]; then echo -e "\n"; echo -e "База clamav создана более недели назад!"; fi
# echo -e "\n"; read -n 1 -p "Обновить базы антивируса clamav? [y/N]: " clupdate;
# if [[ "$clupdate" = [yYlLдД] ]]; then echo -e "\n"; sudo /home/kostya/my_scripts/update_clamav.sh; fi
# ---------------------------------------------------------------------------------------------
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then sudo rm /var/lib/pacman/db.lck; fi
# Этот скрипт проверяет наличие обновлений, обновляет и перезапускает сервисы при необходимости
echo -e "\n"; read -n 1 -p "Проверить обновления? [y/N]: " cupdate; 
if [[ "$cupdate" = [yYlLдД] ]]; then echo -e "\n"; pamac checkupdates -a; fi
# ---------------------------------------------------------------------------------------------
bekaplast=$(find /mnt/sdb/sdb6/timeshift/snapshots -mindepth 1 -maxdepth 1 -printf '%P\n' | sort -r | head -n 1)
echo -e "\n"; echo -e "Последний бэкап timeshift сделан: " $bekaplast ;
echo -e "\n"; read -n 1 -p "Сделать бэкап timeshift перед обновлением? [y/N]: " bekap; 
if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=true/skipAutosnap=false/g' /etc/timeshift-autosnap.conf; fi
# echo -e "\n"; read -n 1 -p "Обновить установленные пакеты? [Y/n]: " update; 
# if [[ "$update" = "" || "$update" = [yYlLдД] ]]; then 
# pamac upgrade --forse-refresh; 
# Если терминал завис нужно нажать Ctrl+c
echo -e "\n"; read -n 1 -p "Обновить пакеты из репозиториев? [y/N]: " updrep;
if [[ "$updrep" = [yYlLдД] ]]; then
  echo -e "\n"; echo -e "Будет произведено обновление пакетов репозиториев, сборка AUR не обновляется!!!."; 
  echo -e "\n"; echo -e "Если в процессе обновления пакетов терминал завис нужно нажать Ctrl+c"; echo -e "\n";
  ( pamac upgrade --enable-downgrade --no-aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac; 
  echo -e "\n"; read -n 1 -p "Нет обновлений? Принудительно обновить базы? [y/N]: " update; echo -e "\n";
  if [[ "$update" = [yYlLдД] ]]; then 
    ( pamac upgrade --force-refresh --enable-downgrade --no-aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac;
  fi  
  # ---------------------------------------------------------------------------------------------
  echo -e "\n"; echo "Нажмите любую клавишу, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  echo -e "\n"; read -n 1 -p "Обновить через AURхелперы? [y/N]: " upda; 
  if [[ "$upda" = [yYlLдД] ]]; then
    echo -e "\n"; read -n 1 -p "Обновить через yay? [y/N]: " yayupd;
    if [[ "$yayupd" = [yYlLдД] ]]; then echo -e "\n"; yay -Syyuu --repo | tee $HOME/upgrade.yay; fi
    echo -e "\n"; read -n 1 -p "Обновить через paru? [y/N]: " parupd;
    if [[ "$parupd" = [yYlLдД] ]]; then echo -e "\n"; paru -Syyuu --repo | tee $HOME/upgrade.paru; fi
    # if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=false/skipAutosnap=true/g' /etc/timeshift-autosnap.conf; fi
  fi
  # echo -e "\n";
  # ---------------------------------------------------------------------------------------------
  # echo -e "\n"; read -n 1 -p "Обновить flatpak?  [y/N]: " flat;
  # if [[ "$flat" = [yY] ]]; then echo -e "\n"; flatpak update; echo -e "\n"; fi
  # Проверка необходимости постдействий после обновлений ---------------------------------------
  if [[ -f $HOME/upgrade.pamac ]]; then if cat $HOME/upgrade.pamac | grep 'Нет заданий.'; then rm $HOME/upgrade.pamac; fi; fi
  if [[ -f $HOME/upgrade.yay ]]; then if cat $HOME/upgrade.yay | grep 'there is nothing to do'; then rm $HOME/upgrade.yay; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'делать больше нечего'; then rm $HOME/upgrade.paru; fi; fi
  # --------------------------------------------------------------------------------------------
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    echo -e "\n"; read -n 1 -p "Сравнить конфиги pacnew? [Y/n]: " diff;
    if [[ "$diff" = "" || "$diff" = [yYlLдД] ]]; then 
      echo -e "\n"; read -n 1 -p "Сравнить в meld(графика)? [Y/n]: " difft;
      if [[ "$difft" = "" || "$difft" = [yYlLдД] ]]; 
        then echo -e "\n"; sudo DIFFPROG=meld pacdiff; 
        else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff; 
      fi
    fi
    # Конец условия Сравнить конфиги pacnew? 
    echo -e "\n"; read -n 1 -p "Проверить сервисы для перезапуска? [Y/n]: " restart;
    if [[ "$restart" = "" || "$restart" = [yYlLдД] ]]; then
      echo -e "\n"; sudo systemctl daemon-reload; sudo needrestart -u NeedRestart::UI::stdio -r i;  
    fi
    echo -e "\n"; read -n 1 -p "Проверить, есть ли лишние модули ядра? [y/N]: " kerny; 
    if [[ "$kerny" = [yYlLдД] ]]; then
      echo -e "\n"; echo "В системе установлены следующие ядра:"
      pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]"
      echo -e "\n"; echo "Возможно необходимо почистить каталог /usr/lib/modules/"
      cd /usr/lib/modules/; gksu dbus-run-session thunar /usr/lib/modules/ 2> /dev/null ;
    fi
    echo -e "\n"; read -n 1 -p "Проверить, пакеты для пересборки? [y/N]: " pac; 
    if [[ "$pac" = [yYlLдД] ]]; then 
      if [ -n "$(checkrebuild | grep -v zoom | head -n 1)" ]; 
        then echo -e "\n"; echo "Возможно необходимо пересобрать следующие пакеты из AUR:"; echo -e "\n"; 
          checkrebuild | grep -v zoom
        else echo -e "\n"; echo "Пакетов из AUR для пересборки нет."; echo -e "\n";
      fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить пакеты сироты? [y/N]: " syr;  
    if [[ "$syr" = [yYlLдД] ]]; then  
      if [ -n "$(pamac list -o | head -n 1)" ];
        then echo -e "\n"; echo "Возможно следующие пакеты являются сиротами (ПРОВЕРЬТЕ перед удалением!!!): "; echo -e "\n"; 
          pamac list -o
          echo -e "\n"; read -n 1 -p "Удалить пакеты сироты? [y/N]: " syrd; 
          if [[ "$syrd" = [yYlLдД] ]]; then pamac remove -o ; fi
        else echo -e "\n"; echo "Пакеты сироты отсутствуют."; echo -e "\n";
      fi
    fi
    # запуск rkhunter --propupd после изменения конфигурационных файлов или обновления ОС
    echo -e "\n"; read -n 1 -p "Создать базу данных для rkhunter и выполнить проверку? [y/N]: " rkh; echo -e "\n";
    if [[ "$rkh" = [yYlLдД] ]]; then 
      sudo rkhunter --propupd 2> /dev/null
      /home/kostya/my_scripts/rkhunter.sh ; 
      echo -e "\n"; echo "Нажмите любую клавишу, чтобы продолжить"
      while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
    fi
  fi
fi
# Конец условия Необходимости постобработки после обновления пакетов репозиториев ----------------------------------------------
#  else echo -e "\n"; echo -e "Вы приняли решение не обновлять установленные пакеты"
#fi
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then sudo rm /var/lib/pacman/db.lck; fi
echo -e "\n"; read -n 1 -p "Обновить пакеты из AUR? [y/N]: " updaur;
if [[ "$updaur" = [yYlLдД] ]]; then
  echo -e "\n"; echo -e "Будет произведено обновление пакетов из AUR."; 
  echo -e "\n"; echo -e "Если в процессе обновления пакетов терминал завис нужно нажать Ctrl+c"; echo -e "\n";
  ( pamac upgrade --aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac; 
  echo -e "\n"; read -n 1 -p "Нет обновлений? Принудительно обновить базы? [y/N]: " update; echo -e "\n";
  if [[ "$update" = [yYlLдД] ]]; then 
    ( pamac upgrade --force-refresh --aur && echo "Запись EOF" ) | tee -i $HOME/upgrade.pamac;
  fi  
  echo -e "\n"; echo "Нажмите любую клавишу, чтобы продолжить"
  while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
  echo -e "\n"; read -n 1 -p "Обновить через AURхелперы? [y/N]: " upda; 
  if [[ "$upda" = [yYlLдД] ]]; then  
    echo -e "\n"; read -n 1 -p "Обновить через yay? [y/N]: " yayupd;
    if [[ "$yayupd" = [yYlLдД] ]]; then echo -e "\n"; yay -Syyu --aur | tee $HOME/upgrade.yay; fi
    echo -e "\n"; read -n 1 -p "Обновить через paru? [y/N]: " parupd;
    if [[ "$parupd" = [yYlLдД] ]]; then echo -e "\n"; paru -Syyu --aur | tee $HOME/upgrade.paru; fi
  fi
  if [[ -f $HOME/upgrade.pamac ]]; then if cat $HOME/upgrade.pamac | grep 'Нет заданий.'; then rm $HOME/upgrade.pamac; fi; fi
  if [[ -f $HOME/upgrade.yay ]]; then if cat $HOME/upgrade.yay | grep 'there is nothing to do'; then rm $HOME/upgrade.yay; fi; fi
  if [[ -f $HOME/upgrade.paru ]]; then if cat $HOME/upgrade.paru | grep 'делать больше нечего'; then rm $HOME/upgrade.paru; fi; fi
  # --------------------------------------------------------------------------------------------
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    echo -e "\n"; read -n 1 -p "Сравнить конфиги pacnew? [Y/n]: " diff;
    if [[ "$diff" = "" || "$diff" = [yYlLдД] ]]; then 
      echo -e "\n"; read -n 1 -p "Сравнить в meld(графика)? [Y/n]: " difft;
      if [[ "$difft" = "" || "$difft" = [yYlLдД] ]]; 
        then echo -e "\n"; sudo DIFFPROG=meld pacdiff; 
        else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff; 
      fi
    fi
    # Конец условия Сравнить конфиги pacnew? 
    echo -e "\n"; read -n 1 -p "Проверить сервисы для перезапуска? [Y/n]: " restart;
    if [[ "$restart" = "" || "$restart" = [yYlLдД] ]]; then
      echo -e "\n"; sudo systemctl daemon-reload; sudo needrestart -u NeedRestart::UI::stdio -r i;  
    fi
    echo -e "\n"; read -n 1 -p "Проверить, пакеты для пересборки? [y/N]: " pac; 
    if [[ "$pac" = [yYlLдД] ]]; then 
      if [ -n "$(checkrebuild | grep -v zoom | head -n 1)" ]; 
        then echo -e "\n"; echo "Возможно необходимо пересобрать следующие пакеты из AUR:"; echo -e "\n"; 
          checkrebuild | grep -v zoom
        else echo -e "\n"; echo "Пакетов из AUR для пересборки нет."; echo -e "\n";
      fi
    fi
    echo -e "\n"; read -n 1 -p "Проверить пакеты сироты? [y/N]: " syr;  
    if [[ "$syr" = [yYlLдД] ]]; then  
      if [ -n "$(pamac list -o | head -n 1)" ];
        then echo -e "\n"; echo "Возможно следующие пакеты являются сиротами (ПРОВЕРЬТЕ перед удалением!!!): "; echo -e "\n"; 
          pamac list -o
          echo -e "\n"; read -n 1 -p "Удалить пакеты сироты? [y/N]: " syrd; 
          if [[ "$syrd" = [yYlLдД] ]]; then pamac remove -o ; fi
        else echo -e "\n"; echo "Пакеты сироты отсутствуют."; echo -e "\n";
      fi
    fi
    # запуск rkhunter --propupd после изменения конфигурационных файлов или обновления ОС
    echo -e "\n"; read -n 1 -p "Создать базу данных для rkhunter и выполнить проверку? [y/N]: " rkh; echo -e "\n";
    if [[ "$rkh" = [yYlLдД] ]]; then 
      sudo rkhunter --propupd 2> /dev/null
      /home/kostya/my_scripts/rkhunter.sh ; 
      echo -e "\n"; echo "Нажмите любую клавишу, чтобы продолжить"
      while true; do read -t 1 variable <&1 ; if [ $? = 0 ] ; then break ; else notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; fi ;  done
    fi
  fi
fi
# Конец условия Необходимости постобработки после обновления AUR -------------------------------------------------
# Конец условия Обновить установленные пакеты?
if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=false/skipAutosnap=true/g' /etc/timeshift-autosnap.conf; fi
echo -e "\n";
# Удаление логов ------------------------------------------------------------------------------
if [[ -f $HOME/upgrade.paru ]]; then rm $HOME/upgrade.paru; fi
if [[ -f $HOME/upgrade.yay ]]; then rm $HOME/upgrade.yay; fi
if [[ -f $HOME/upgrade.pamac ]]; then rm $HOME/upgrade.pamac; fi

