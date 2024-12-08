#!/bin/bash
# Версия скрипта 1.14.50
# Скрипт линейный = [1,2], количество функций = XX, версия сборки = XXX
echo -e "\nЭтот скрипт проверяет наличие обновлений и обновляет систему с помощью pamac, yay и paru."
echo -e "Скрипт сам установит необходимые пакеты, но вы можете сделать это самостоятельною "
echo -e "Для полноценной работы скрипта необходимо установить следующие пакеты: pacman-contrib, "
echo -e "rebuild-detector, timeshift, timeshift-autosnap-manjaro, yay, meld, needrestart, thunar, "
echo -e "libnotify, libcanberra, sound-theme-freedesktop. "
echo -e "Аурхелпер paru вы должны установить самостоятельно, но при наличии yay он не нужен. "
echo -e "Скрипт будет работать и без них, только с ограниченной функциональностью."
# ----------------------------------------------------------------------------------------------------
# Описание используемых функций в скрипте
pack () 
{
  # 1 Функция проверки наличия и установки пакета
  for i in "$@" ; do
    package="$i"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";  
    if [ -n "${check}" ] ; then echo -e "\nПакет $i уже установлен" ; else echo -e "\nУстанавливается пакет $i " ; pamac install "$i" ; fi
  done
}

check ()
{
  # Функция проверки наличия пакета
  for i in "$@" ; do 
    package="$i"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")"; 
    checks="$checks$check"; 
  done ; 
  echo "$checks";
}
enter ()
{
  # 2 Функция ожидания нажатия клавиши $1 = libnotify $2 = libcanberra $3 = sound-theme-freedesktop
  echo -e "\n"; echo "Нажмите клавишу Enter, чтобы продолжить"
  check=$(check libnotify libcanberra sound-theme-freedesktop )
  # shellcheck disable=SC2034
  while true; do read -r -t 1 -n 1 key <&1 ; 
    # shellcheck disable=SC2181
    if [ $? = 0 ] ; then break ; else 
      if [ -n "${check}" ] ; then 
        notify-send -t 600 -i face-plain "   ВНИМАНИЕ! Обновление  " "   Требует <b>Вмешательства</b>  " ; canberra-gtk-play -i dialog-warning ; 
      fi
    fi ;
  done
}

pacdiffmeld ()
{
  # 3 Функция Сравнить конфиги pacnew
  # Обработка черезстрочного массива
  # ifps="$(find /etc -name '*.pacsave' 2>/dev/null)"
  # for i in "${ifps[@]}"; do echo "$i"; done
  # Обработка однострочного масства
  # func () { for i in "$@" ; do echo "$i" ; done; }
  # вместо echo "$i" подставить запрос на просмотр и/или удаление файла *.pacsave
    echo -e "\nПроверка наличия резервных копий conf.pacsave и conf.pacnew"
    echo -e "Файлы conf.pacsave можно удалить, если эти настройки больше не нужны"
    ifpacn="$(sudo find /etc -name '*.pacnew')"
    ifpacs="$(sudo find /etc -name '*.pacsave')"
    if [ -n "${ifpacn}" ] ; 
      then 
        sudo find /etc -name '*.pacnew' ;
        echo -e "\n"; read -r -n 1 -p "Сравнить конфиги pacnew? [y/N]: " diff;
        if [[ "$diff" = [yYlLдД] ]]; then 
          package="meld"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
          if [ -n "${check}" ] ; 
            then
              echo -e "\n"; read -r -n 1 -p "Сравнить в meld(графика)? [Y/n]: " difft;
              if [[ "$difft" = "" || "$difft" = [yYlLдД] ]]; 
                then echo -e "\n"; sudo DIFFPROG=meld pacdiff; 
                else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff; 
              fi
            else echo -e "\n"; sudo DIFFPROG=vimdiff pacdiff;
          fi
        fi
      else echo -e "Резервных копий .pacnew нет" ; 
    fi 
    if [ -n "${ifpacs}" ] ;
      then
        sudo find /etc -name '*.pacsave'
        echo -e "\n"; read -r -n 1 -p "Просмотреть и/или удалить конфиги .pacsave ? [y/N]: " pacs ;
        if [[ "$pacs" = [yYlLдД] ]]; then
          for i in "${ifpacs[@]}"; do 
            echo -e "\n"; read -r -n 1 -p "Просмотреть файл $i ? [y/N]: " paci ; 
            if [[ "$paci" = [yYlLдД] ]]; then sudo nano "$i" ; fi
            echo -e "\n"; read -r -n 1 -p "Удалить файл $i ? [y/N]: " pacd ;
            if [[ "$pacd" = [yYlLдД] ]]; then sudo rm -i "$i" ; fi
          done
        fi
      else echo -e "Резервных копий .pacsave нет" ;
    fi
    #Конец условия Сравнить конфиги pacnew?
}

needrest ()
{ 
  # 4 Функция проверки сервисов для перезапуска
  package="needrestart"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; 
    then
      echo -e "\n"; read -r -n 1 -p "Проверить сервисы для перезапуска? [y/N]: " restart;
      # [Y/n] [[ "$restart" = "" || "$restart" = [yYlLдД]  ]]
      if [[ "$restart" = [yYlLдД] ]]; then
        echo -e "\n"; sudo systemctl daemon-reload; sudo needrestart -u NeedRestart::UI::stdio -r i;  
      fi
  fi
  # Конец Функции проверки сервисов для перезапуска
}

checkrebu ()
{
  # 5 Функция проверки пакетов для пересборки
    echo -e "\n"; read -r -n 1 -p "Проверить, пакеты для пересборки? [y/N]: " pac; 
    if [[ "$pac" = [yYlLдД] ]]; then echo -e "\n";
      if [[ -n "$(checkrebuild | grep -v zoom | head -n 1)" ]]; 
        then echo "Возможно необходимо пересобрать следующие пакеты из AUR:"; echo -e "\n"; checkrebuild | grep -v zoom ;
        else echo "Пакетов из AUR для пересборки нет."; 
      fi
    fi  
}

syrot ()
{ 
  # 6 Функция проверки и очистки пакетов-сирот
    echo -e "\n"; read -r -n 1 -p "Проверить пакеты сироты? [y/N]: " syro;  
    if [[ "$syro" = [yYlLдД] ]]; then echo -e "\n"; 
      if [ -n "$(pamac list -o | head -n 1)" ];
        then echo "Возможно следующие пакеты являются сиротами (ПРОВЕРЬТЕ перед удалением!): "; echo -e "\n"; 
          pamac list -o
          echo -e "\n"; read -r -n 1 -p "Удалить пакеты сироты? [y/N]: " syrd; 
          if [[ "$syrd" = [yYlLдД] ]]; then echo -e "\n"; pamac remove -o ; fi
        else echo "Пакеты сироты отсутствуют."; 
      fi
    fi  
}

reqt ()
{
  # 7 Функция пересборки пакетов Qt
  package="yay"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; then
    echo -e "\n"; read -r -n 1 -p "Пересобрать Qt пакеты из AUR? [y/N]: " uqtaq;
    # shellcheck disable=SC2046
    if [[ "$uqtaq" = [yYlLдД] ]]; then echo -e "\n"; ( yay -S --rebuild $(pacman -Qmt | grep ^qt) ) |& tee -i "$HOME/upgrade.yay" ; fi
  fi
}

updatep ()
{
  # 8 Функция обновления пакетов через pamac $1 = репозиториев $2 = --no-aur $3 = --repo $4 = --enable-downgrade 
  #                                          $1 = AUR          $2 = --aur    $3 = --aur  $4 = '' 
  echo -e "\n"; echo -e "Будет произведено обновление пакетов из $1 !"; 
  echo -e "\n"; read -r -n 1 -p "Обновить зеркала pacman? [y/N]: " mirr; echo -e "\n";
  if [[ "$mirr" = [yYlLдД] ]]; then sudo pacman-mirrors --fasttrack ; fi
  echo -e "\n"; echo -e "Если в процессе обновления пакетов терминал завис нужно нажать Ctrl+c"; echo -e "\n";
  ( stdbuf -e 0 -o 0 bash -c "pamac upgrade --no-confirm $4 $2 2> /dev/null && echo 'Запись EOF'" ) |& tee -i "$HOME/upgrade.pamac" ; 
  enter
  if [[ "$1" == "AUR" ]]; then adinsta ; fi
  echo -e "\n"; read -r -n 1 -p "Нет обновлений? Принудительно обновить базы? [y/N]: " update; echo -e "\n";
  if [[ "$update" = [yYlLдД] ]]; then
    #sudo pacman-mirrors --fasttrack 
    echo -e "\n"; read -r -n 1 -p "Обновить зеркала pacman? [y/N]: " mirr; echo -e "\n";
    if [[ "$mirr" = [yYlLдД] ]]; then sudo pacman-mirrors --fasttrack ; fi
    ( stdbuf -e 0 -o 0 bash -c "pamac upgrade --force-refresh $4 $2 2> /dev/null && echo 'Запись EOF' " ) |& tee -i "$HOME/upgrade.pamac" ;
  fi
  enter
  if [[ "$1" == "AUR" ]]; then adinsta ; fi
  package="yay"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; then
    echo -e "\n"; read -r -n 1 -p "Обновить пакеты из $1 через AURхелперы yay или paru? [y/N]: " upda; 
    if [[ "$upda" = [yYlLдД] ]]; then
      echo -e "\n"; read -r -n 1 -p "Обновить через yay? [y/N]: " yayupd;
      if [[ "$yayupd" = [yYlLдД] ]]; then echo -e "\n"; ( stdbuf -e 0 -o 0 bash -c "yay -Syyuu $3 " ) |& tee -i "$HOME/upgrade.yay" ; fi
      echo -e "\n"; read -r -n 1 -p "Обновить через paru? [y/N]: " parupd;
      if [[ "$parupd" = [yYlLдД] ]]; then echo -e "\n"; ( stdbuf -e 0 -o 0 bash -c "paru -Syyuu $3 " ) |& tee -i "$HOME/upgrade.paru" ; fi
    fi
    # Проверка необходимости пересборки Qt пакетов
    # Функция пересборки пакетов Qt
    #echo -e "\n"; read -n 1 -p "Пересобрать Qt пакеты из AUR? [y/N]: " uqtaq;
    ## shellcheck disable=SC2046
    #if [[ "$uqtaq" = [yYlLдД] ]]; then yay -S --rebuild $(pacman -Qmt | grep ^qt); fi
  fi
}

rkhunt ()
{
  # 9 Функция Создание исполняемого файла для запуска rkhunter
  if [ ! -f "$HOME/my_scripts/rkhunter.sh" ]; then 
    mkdir -p "$HOME/my_scripts"
    touch "$HOME/my_scripts/rkhunter.sh"
    echo "#!/bin/bash " >> "$HOME/my_scripts/rkhunter.sh"
    echo "sudo rkhunter --check --skip-keypress --update --report-warnings-only 2> /dev/null " >> "$HOME/my_scripts/rkhunter.sh"
    chmod +x "$HOME/my_scripts/rkhunter.sh"
  fi
  # запуск rkhunter --propupd после изменения конфигурационных файлов или обновления ОС
  package="rkhunter"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
  if [ -n "${check}" ] ; 
    then
      echo -e "\n"; read -r -n 1 -p "Выполнить проверку rkhunter? [y/N]: " rkh; 
      if [[ "$rkh" = [yYlLдД] ]]; then echo -e "\n";
        "$HOME/my_scripts/rkhunter.sh" ; 
        enter libnotify libcanberra sound-theme-freedesktop
        echo -e "\n"; read -r -n 1 -p "Все в порядке? Создать базу данных для rkhunter? [y/N]: " rkhb; 
        if [[ "$rkhb" = [yYlLдД] ]]; then echo -e "\n"; sudo rkhunter --propupd 2> /dev/null ; fi
      fi
  fi
}

postrunif () 
{
  # postrun "Ничего не нужно делать" "Nothing to do" "there is nothing to do" "делать больше нечего" "Нет заданий" "Ошибка авторизации"
  # $1 = "Ничего не нужно делать" $2 = "Nothing to do" $3 = "there is nothing to do" $4= "делать больше нечего" $5 = "Нет заданий" $6 = "Ошибка авторизации"
  # 10 Функция Проверки необходимости постдействий после обновлений ---------------------------------------
  for i in "$@" ; do  
    if grep -Rnw "$HOME/upgrade.pamac" -e "$i" &>/dev/null ; then rm "$HOME/upgrade.pamac" &>/dev/null ; fi
    if grep -Rnw "$HOME/upgrade.yay" -e "$i" &>/dev/null ; then rm "$HOME/upgrade.yay" &>/dev/null ; fi
    if grep -Rnw "$HOME/upgrade.paru" -e "$i" &>/dev/null ; then rm "$HOME/upgrade.paru" &>/dev/null ; fi
  done;
  # --------------------------------------------------------------------------------------------
}

postrun ()
{
  # 11 Функция выполнения пост действий после обновления
    # Пересборка пакетов Qt
    reqt
    # Сравнение конфигов pacnew
    pacdiffmeld
    # Рестарт сервисов 
    needrest
    # Пересборка необходимых пакетов
    checkrebu
    # Поиск и уаление сирот
    syrot
    #rkhunt
}

adinsta ()
{
  # 12 Функция доустановки отсутствующей зависимости
  # $1 = название пакета
  postrunif "Ничего не нужно делать" "Nothing to do" "there is nothing to do" "делать больше нечего" "Нет заданий" "Ошибка авторизации"
  if compgen -G "$HOME/upgrade.*" > /dev/null; then
    echo -e "\n"; read -r -n 1 -p "Установить отсутствующие зависимости? [y/N]: " adinst;
    if [[ "$adinst" = [yYlLдД] ]]; then
      echo -e "\n"; read -r -p "Введите название пакета и нажмите Enter? : " sai;
      #sai="$1"
      pamac search --aur "$sai"
      echo -e "\n"; read -r -n 1 -p "Установить из репозиториев? [y/N]: " adinstr;
      if [[ "$adinstr" = [yYlLдД] ]]; then pamac install "$sai" ; fi
      echo -e "\n"; read -r -n 1 -p "Установить из AUR? [y/N]: " adinsta;
      if [[ "$adinsta" = [yYlLдД] ]]; then pamac build "$sai" ; fi
    fi
  fi
}

delfile ()
{
  # 13 Функция удаления файла логов
  for i in "$@" ; do  
    if [[ -f $HOME/$i ]]; then rm "$HOME/$i" ; fi
  done;
  echo -e "\nЛоги скрипта удалены"
}

drweb ()
{
  # 14 Функция проверки установки антивируса drweb и отключения SpIDer Gate
  # $1 = Yes, No Показывает что надо сделать, вкл или выкл SpIDer Gate
  #Проверка наличия установки drweb
  if [ -f /opt/drweb.com/bin/drweb-ctl ]; then 
  # Показать настройку
    echo -e "\nDrWeb SpIDer Gate $1 "
    sg=$(drweb-ctl cfshow LinuxFirewall.OutputDivertEnable | awk '{ print $3 }')
    if [[ ! $sg == "$1" ]]; then sudo drweb-ctl cfset LinuxFirewall.OutputDivertEnable "$1" ; fi
  fi
  #drweb-ctl cfshow LinuxFirewall.OutputDivertEnable | awk '{ print $3 }'
  #drweb-ctl cfshow LinuxFirewall.OutputDivertEnable
  # включить
  #sudo drweb-ctl cfset LinuxFirewall.OutputDivertEnable Yes
  # выключить
  #sudo drweb-ctl cfset LinuxFirewall.OutputDivertEnable No
}
# Конец описания функций скрипта
# ----------------------------------------------------------------------------------------
drweb No
echo -e "\n"; read -r -n 1 -p "Установить отсутствующие пакеты и настроить бэкап timeshift? [y/N]: " inst;
if [[ "$inst" = [yYlLдД] ]]; then 
  pack pacman-contrib rebuild-detector timeshift timeshift-autosnap-manjaro yay meld needrestart thunar libnotify libcanberra sound-theme-freedesktop ;
  #pack paru-bin ;  
  #
  # Здесь будет возможность подключения и обновления антивируса
  # Запуск гуя timeshift для настройки
  echo -e "\n"; read -r -n 1 -p "Настроить timeshift? [y/N]: " tsh ;
  if [[ "$tsh" = [yYlLдД] ]]; then timeshift-launcher ; fi
fi
# Необходимые пакеты установлены и настроены
# ---------------------------------------------------------------------------------------------
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then echo -e "\n"; sudo rm /var/lib/pacman/db.lck; fi
# Этот скрипт проверяет наличие обновлений, обновляет и перезапускает сервисы при необходимости
echo -e "\n"; echo -e "Проверка наличия обновлений:"; echo -e "\n"; pamac checkupdates -a
# ---------------------------------------------------------------------------------------------
# Проверка состояни бэкапа timeshift
package="timeshift"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
if [ -n "${check}" ] ; then
  if ! pgrep 'timeshift'>null; 
    then
      echo -e "\n"; timesmount="$(df | grep "$(sudo timeshift --list | grep Device | awk '{ print $3 }')" | awk '{ print $6 }')"
      timesfile="$timesmount/timeshift/snapshots"
      bekaplast=$(find "$timesfile" -mindepth 1 -maxdepth 1 -printf '%P\n' | sort -r | head -n 1)
      echo -e "\n"; echo -e "Последний бэкап timeshift сделан: $bekaplast " ;
      package="timeshift-autosnap-manjaro"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; then
        echo -e "\n"; read -r -n 1 -p "Сделать бэкап timeshift перед обновлением? [y/N]: " bekap; 
        if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=true/skipAutosnap=false/g' /etc/timeshift-autosnap.conf; fi
      fi
    else echo -e "\n"; echo -e "Сейчас невозможно определить последний бэкап, так как работает timeshift"
  fi  
fi
# Если терминал завис нужно нажать Ctrl+c
echo -e "\n"; read -r -n 1 -p "Обновить пакеты из репозиториев? [y/N]: " updrep;
if [[ "$updrep" = [yYlLдД] ]]; then
  updatep репозиториев --no-aur --repo --enable-downgrade
  # ---------------------------------------------------------------------------------------------
  # echo -e "\n"; read -n 1 -p "Обновить flatpak?  [y/N]: " flat;
  # if [[ "$flat" = [yY] ]]; then echo -e "\n"; flatpak update; echo -e "\n"; fi
  # Проверка необходимости постдействий обновления из репозиториев ---------------------------
  postrunif "Ничего не нужно делать" "Nothing to do" "there is nothing to do" "делать больше нечего" "Нет заданий" "Ошибка авторизации"
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    echo -e "\n"; read -r -n 1 -p "Проверить, есть ли лишние модули ядра? [y/N]: " kerny; 
    if [[ "$kerny" = [yYlLдД] ]]; then
      echo -e "\n"; echo "В системе установлены следующие ядра:"
      pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]"
      echo -e "\n"; echo "Возможно необходимо почистить каталог /usr/lib/modules/"
      package="thunar"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
      if [ -n "${check}" ] ; 
        then
        cd /usr/lib/modules/ || exit; gksu dbus-run-session thunar /usr/lib/modules/ 2> /dev/null ;
      fi
    fi
    # Устранение недоразуменя загрузки старого ядра через rEFInd
    package="refind"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
    if [ -n "${check}" ] ; then
      echo -e "\n"; echo "В системе установлены следующие ядра (по умолчанию будет загружаться первое в списке ):"
      #pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]" | sort -n -r -t'x' -k2,2
      # shellcheck disable=SC2010
      ls -t /boot | grep vmlinuz    
      echo -e "\n"; read -r -n 1 -p "Сделать загружаемым по умолчанию новое ядро? [y/N]: " lynn; 
      if [[ "$lynn" = [yYlLдД] ]]; then
        lini=$(pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]" | sort -n -r -t'x' -k2,2 | head -n 1 | awk '{ print $2 }')
        echo -e "\n"; read -r -n 1 -p "По умолчанию rEFInd будет загружать $lini ? [y/N]: " lynin;
        if [[ "$lynin" = [yYlLдД] ]]; then 
          lin=$(pacman -Q | grep -E "linux[0-9]{2}(\s|[0-9])[^-]" | sort -n -r -t'x' -k2,2 | head -n 1 | awk '{ print $2 }' | awk -F. '{ print "/boot/vmlinuz-"$1"."$2"-x86_64" }')
          if [ -e "$lin" ]; then sudo touch -m "$lin" ; fi
        fi
      fi
    fi
    postrun
  fi
fi
# Конец условия Необходимости постобработки после обновления пакетов репозиториев --------------------------------
#  else echo -e "\n"; echo -e "Вы приняли решение не обновлять установленные пакеты"
#fi
# Удаление блокировки баз при ее наличии
if [[ -f /var/lib/pacman/db.lck ]]; then echo -e "\n"; sudo rm /var/lib/pacman/db.lck; fi
echo -e "\n"; read -r -n 1 -p "Обновить пакеты из AUR? [y/N]: " updaur;
if [[ "$updaur" = [yYlLдД] ]]; then
  updatep AUR --aur --aur
  postrunif "Ничего не нужно делать" "Nothing to do" "there is nothing to do" "делать больше нечего" "Нет заданий" "Ошибка авторизации"
  # --------------------------------------------------------------------------------------------
  # Проверка необходимости постдействий после обновлений AUR -----------------------------------
  if compgen -G "$HOME/upgrade.*" > /dev/null; then 
    postrun
  fi
fi
# Конец условия Необходимости постобработки после обновления AUR -------------------------------------------------
# Конец условия Обновить установленные пакеты?
package="timeshift-autosnap-manjaro"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
if [ -n "${check}" ] ; 
  then
    if [[ "$bekap" = [yYlLдД] ]]; then sudo sed -i 's/skipAutosnap=false/skipAutosnap=true/g' /etc/timeshift-autosnap.conf; fi
fi
echo -e "\n";
# Удаление логов ------------------------------------------------------------------------------
delfile upgrade.paru upgrade.yay upgrade.pamac
drweb Yes
# В разработке
# ---------------------------------------------------------------------------------------------
# Создание скрипта обновления антивирусных баз
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
# Скрипт обновления антивируса создан
# ----------------------------------------------------------------------------------------------
# Обновление баз антивируса
#package="clamav"; check="$(pacman -Qs --color always "${package}" | grep "local" | grep "${package}")";
#if [ -n "${check}" ] ; 
#  then
#    if [[ ! -z "$(find /var/lib/clamav/daily.cvd -type f -mtime +6)" ]]; then echo -e "\n"; 
#      echo -e "База clamav создана более недели назад!"; echo -e "\n"; stat /var/lib/clamav/daily.cvd | grep Модифицирован ; 
#      echo -e "\n"; read -n 1 -p "Обновить базы антивируса clamav? [y/N]: " clupdate;
#      if [[ "$clupdate" = [yYlLдД] ]]; then echo -e "\n"; sudo $HOME/my_scripts/update_clamav.sh; fi
#    fi
#fi
# Базы антивируса обновлены
# ---------------------------------------------------------------------------------------------
