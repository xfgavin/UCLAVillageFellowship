#!/usr/bin/env bash
function getEmail()
{
  local  __email_var=$1
  local  nickname=$2
  local  contact=''
  local  thisemail=
  if [ ${#nickname} -gt 0 ]
  then
    #5/12,廖珏Julie,,,orange.in.china@gmail.com,Julie,姐妹,,
    contact=`grep ",[^,]*@[^,]*,$nickname," contact.csv`
    [ ${#contact} -gt 0 ] && thisemail=`echo $contact|cut -d, -f5`
  fi
  eval $__email_var="'$thisemail'"
}
function getName(){
  local  __name_var=$1
  local  nickname=$2
  local  contact=''
  local  thisname=''
  if [ ${#nickname} -gt 0 ]
  then
    #5/12,廖珏Julie,,,orange.in.china@gmail.com,Julie,姐妹,,
    contact=`grep ",[^,]*@[^,]*,$nickname," contact.csv`
    [ ${#contact} -gt 0 ] && thisname=`echo $contact|cut -d, -f2,7|sed -e 's/,//g'`
  fi
  eval $__name_var="'$thisname'"
}
function sendErrMsg(){
  local msg=$1
  local admin=$2
  echo -e "$msg" |mail -s "Error when sending UCLA Fellowship notification email" $admin && exit -1
}

cd $(dirname $0)
[ `netstat -an|grep :25|wc -l` -eq 0 ] && sudo /etc/init.d/postfix restart
CC_list="Cien Shang<christian.sh@gmail.com>,Julie Liao<orange.in.china@gmail.com>,楊曜如<emailjulia72@yahoo.com>, Feng Xue <xfgavin@gmail.com>"
adminemail=xfgavin@gmail.com

####################################
#Grab all info from google drive
####################################

rm -f all.html
############################################
#Bitly short url: https://bit.ly/uclavillage
############################################
wget -q "https://docs.google.com/spreadsheets/d/e/2PACX-1vSSKQp8h-kMJO4FjOIKeISj4K_qYdPa2RQjusTroHdQpN0-yDKHgocBR89gUIQ99FeAgNMai7sPLnF8/pubhtml#" -O all.html
###Remove events with no leaders.
#e.g. Sunday,12/20,CBCWLA,圣诞节崇拜,-,-,-,,
./html2csv.py < all.html > all.csv
lastrec=`grep -n "1,,Date,Program,Content" all.csv|tail -n1|cut -d: -f1`
tail -n +$lastrec all.csv|cut -d, -f2- > schedule.csv
sed -e '/^\([^,]*,\)\{4\}\(-,\)\{2\}/d' -i schedule.csv

birthday_linenum=`grep -n "1,Birthday,Name" all.csv |cut -d: -f1`
tail -n +$birthday_linenum all.csv > contact_tmp.csv
birthday_linnum2=`grep -n '^1,' contact_tmp.csv |cut -d: -f1|head -n2|tail -n1`
((birthday_linnum2=birthday_linnum2-1))
head -n$birthday_linnum2 contact_tmp.csv>contact_tmp2.csv
cut -d, -f2- contact_tmp2.csv|sed '/^,*$/d' > contact.csv

rm -f contact_tmp*.csv
####################
#Solve date
####################

month=`date "+%m"`
day=`date "+%d"`
year=`date "+%Y"`
dow=`date '+%u'`
diff_nextsvc=$((7-dow+5))
[ ${month:0:1} -eq 0 ] && month=${month:1:1}
[ ${day:0:1} -eq 0 ] && day=${day:1:1}
[ $dow -eq 6 ] && dow_nextsvc_cn="一"
[ $dow -eq 7 ] && dow_nextsvc_cn="二"
[ $dow -eq 1 ] && dow_nextsvc_cn="三"
[ $dow -eq 2 ] && dow_nextsvc_cn="四"
[ $dow -eq 3 ] && dow_nextsvc_cn="五"
[ $dow -eq 4 ] && dow_nextsvc_cn="六"
[ $dow -eq 5 ] && dow_nextsvc_cn="日"
case $month in
  1 | 3 | 5 | 7 | 8 | 10 | 12)
    day_max=31
    ;;
  2)
    if [ $((year % 4)) -ne 0 ] ; then
      day_max=28
    elif [ $((yy % 400)) -eq 0 ] ; then
      day_max=29
    elif [ $((yy % 100)) -eq 0 ] ; then
      day_max=28
    else
      day_max=29
    fi
    ;;
  *)
    day_max=30
    ;;
esac
#day_nextsvc=$((day+diff_nextsvc))
day_nextsvc=$((day+9))
if [ $day_nextsvc -gt $day_max ]
then
  month_nextsvc=$((month+1))
  #day_nextsvc=$((diff_nextsvc+day-day_max))
  day_nextsvc=$((day_nextsvc-day_max))
else
  month_nextsvc=$month
fi
[ $month_nextsvc -gt 12 ] && month_nextsvc=1
schedule=`grep ",$month_nextsvc/$day_nextsvc," schedule.csv|sed '/\(C\|c\)\(a\|A\)\(n\|N\)\(C\|c\)\(e\|E\)\(l\|L\)/d'`
if [ ${#schedule} -eq 0 ]
then
  #[ $dow -eq 3 ] && echo -e "Can't find schedule for $month_nextsvc/$day_nextsvc" |mail -s "Error when sending UCLA Fellowship notification email" xfgavin@gmail.com && exit -1
  [ $dow -eq 3 ] && sendErrMsg "Can't find schedule for $month_nextsvc/$day_nextsvc" $adminemail
  exit 0
fi

###########################
#Parse content and leaders
###########################

#schedule='10/9,查经,馬可福音14:12-26,Feng,John/Jeff,-,,'
#8/28,特別聚會,見證分享,Jiayan/Julie,Julia,-,,
activity=`echo $schedule|cut -d, -f3`
content=`echo $schedule|cut -d, -f4`
if [ ${content:0:1} = '"' ]
then
  content=`echo $schedule|cut -d, -f4-5|sed -e 's/"//g'`
  leader_worship=`echo $schedule|cut -d, -f6|sed -e 's/"//g' -e 's/-//g'`
  leader_bible=`echo $schedule|cut -d, -f7|sed -e 's/"//g' -e 's/-//g'`
else
  leader_worship=`echo $schedule|cut -d, -f5|sed -e 's/"//g' -e 's/-//g'`
  leader_bible=`echo $schedule|cut -d, -f6|sed -e 's/"//g' -e 's/-//g'`
fi
tolist=""
leader_worship_name=""
leader_bible_name=""
if [[ $leader_worship =~ "/" ]]
then
  readarray -td/ leaderarray <<<"$leader_worship"; declare -p leaderarray >/dev/null;
  for leader in "${leaderarray[@]}"
  do
    leader=`echo $leader|sed -e 's/\n//g'`
    getEmail email $leader
    getName leadername $leader
    if [ ${#email} -eq 0 -o ${#leadername} -eq 0 ]
    then
      [ $dow -eq 3 ] && sendErrMsg "Can't find worship leader: $leader" $adminemail
    else
      if [ ${#tolist} -eq 0 ]
      then
        tolist=$email
        leader_worship_name=$leadername
      else
        tolist="$tolist,$email"
        leader_worship_name="$leader_worship_name,$leadername"
      fi
    fi
  done
else
  getEmail email $leader_worship
  getName leadername $leader_worship
  if [ ${#email} -eq 0 -o ${#leadername} -eq 0 ]
  then
    [ $dow -eq 3 ] && sendErrMsg "Can't find worship leader: $leader_worship" $adminemail
  else
    if [ ${#tolist} -eq 0 ]
    then
      tolist=$email
      leader_worship_name=$leadername
    else
      tolist="$tolist,$email"
      leader_worship_name="$leader_worship_name,$leadername"
    fi
  fi
fi
if [[ $leader_bible =~ "/" ]]
then
  readarray -td/ leaderarray <<<"$leader_bible"; declare -p leaderarray >/dev/null;
  for leader in "${leaderarray[@]}"
  do
    leader=`echo $leader|sed -e 's/\n//g'`
    getEmail email $leader
    getName leadername $leader
    [ ${#email} -eq 0 ] && sendErrMsg "Can't find email for bible leader: $leader" $adminemail
    [ ${#leadername} -eq 0 ] && sendErrMsg "Can't find name for bible leader: $leader" $adminemail
    if [ ${#tolist} -eq 0 ]
    then
      tolist=$email
      leader_bible_name=$leadername
    else
      tolist="$tolist,$email"
      leader_bible_name="$leader_bible_name,$leadername"
    fi
  done
else
  getEmail email $leader_bible
  getName leadername $leader_bible
  [ ${#email} -eq 0 ] && sendErrMsg "Can't find email for bible leader: $leader_bible" $adminemail
  [ ${#leadername} -eq 0 ] && sendErrMsg "Can't find name for bible leader: $leader_bible" $adminemail
  if [ ${#tolist} -eq 0 ]
  then
    tolist=$email
    leader_bible_name=$leadername
  else
    tolist="$tolist,$email"
    leader_bible_name="$leader_bible_name,$leadername"
  fi
fi

#####################
#Create Email body
#####################

body_1=$(cat <<HTMLEMAIL
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head><title>【UCLA大學村】服事提醒</title>
</head>
<body style="font-size:18px;font-family:arial">
亲爱的$leader_bible_name，
<br>
<br>
按照<a href="https://docs.google.com/spreadsheets/d/1Oo7Hpm-rpUFFc0QIQ9X2KVWt8Fg5wCT7SiEN-60PZvg/edit#gid=1287718392" target="_blank">同工服事表</a>上的安排，下周$dow_nextsvc_cn ($month_nextsvc/$day_nextsvc) 将由你带领<b><u>$content</u></b>的$activity。
HTMLEMAIL
)
if [ $activity = "查经" ]
then
body_2=$(cat <<HTMLEMAIL
<br>
<br>
如何使用归纳法+手稿预备查经请参考<a href="https://docs.google.com/document/d/1pNwrIMjB3fdwZ1nhoisY3x3FT5BvXdCxLurMixvrq3s/edit?usp=sharing" target="_blank">《团契带查经指南》</a>。此外，
<ul>
  <li>请使用<a href="https://drive.google.com/open?id=1RJApKlw9nEbjk2mun8ntSEFauWZaINR0" target="_blank">PPT template</a></li>
  <li>请在<b><u>周三</u></b>晚上将预备好的PPT发给所有同工：ucla-village-coworkers@googlegroups.com</li>
  <li>疫情期间，请在<b><u>周五</u></b>把预备好的手稿发给团契成员：ucla-village-fellowship@googlegroups.com</li>
</ul>
HTMLEMAIL
)
else
  body_2=""
fi
if [ ${#leader_worship_name} -gt 0 ]
then
body_3=$(cat <<HTMLEMAIL
<br>
<br>
---
<br>
<br>
亲爱的$leader_worship_name，
<br>
<br>
按照<a href="https://docs.google.com/spreadsheets/d/1Oo7Hpm-rpUFFc0QIQ9X2KVWt8Fg5wCT7SiEN-60PZvg/edit#gid=1287718392" target="_blank">同工服事表</a>上的安排  ，下周$dow_nextsvc_cn ($month_nextsvc/$day_nextsvc)将由你带领诗歌敬拜。
如何在团契带敬拜请参考<a href="https://docs.google.com/document/d/14VeG4sbUNshiBi9MZLN2WBzq-we_kykiID9iaGuaDCM/edit#heading=h.wq7feob99tk4" target="_blank">《团契带敬拜指南》</a>。诗歌敬拜环节全长是<b><u>10分钟</u></b>。
<br>
<br>
---
<br>
在准备过程中若有任何问题或需要帮助，请随时与我联系！愿主使用你们的服事，也继续祝福、带领我们团契！
<br>
<br>
主内平安，
</pre>
</body>
</html>
HTMLEMAIL
)
else
  body_3=''
fi
echo "$body_1 $body_2 $body_3" >msg.html

############
#Send email
############
/usr/bin/mutt \
-e "set content_type=text/html" \
-s "【UCLA大學村】服事提醒" \
-c "$CC_list" \
"$tolist" < msg.html
