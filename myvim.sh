# !/bin/bash
input=""
input=$2
arrVar=()
func=$1
case $func in
    $'-v') 
        echo "version         0.0.1"
        echo "author          wjj"
        echo "Date            2022/8/14" 
        exit;;
    $'-h') 
        ./help.sh 
        exit;;
    *) 
        ;;
esac

# main function

file=$1
# hide the cursor 
tput civis 

# array to store the text
text=()

# if file exist
if [ -f $file ]
then
    # read the file line by line and store it in text array
    while IFS= read -r; do
        text+=("$REPLY\n")
    done < "$file"
# else the file doesn't exist, create a new file
else
    touch $file
fi

text_lines=${#text[@]}


# 所有的模式列表
COMMAND=0
INSERT=1
BOTTOM=2

# show status on the bottom
# to print information on the bottom of the window

print_status(){
    # get the lines and columns of the present shell
    local nl=$(tput lines)

    # save the position of the cursor
    tput cup $nl 0
    case $1 in
        $COMMAND) echo "--COMMAND--";;
        $INSERT) echo "--INSERT--";;
        $BOTTOM) echo "--BOTTOM--"
            tput cup $(($nl+1)) 0
            echo ":"
        ;;
        *)
        ;;
    esac
    # echo "--HELLO WORLD--"
}

l=0
c=0
mode=0

# output the text
print_text(){
    # every time output text, first need to flush the screen
    clear
    print_status $1
    print_curpos $2
    tput cup 0 0
    # then print text line by line
	for index in $(seq 0 $((${#text[@]}-1)));
    do
        # considering the \n, deal with it specially
        echo -ne "${text[$index]}" 
    done
    
    tput cup $l $c
}

print_curpos(){
    local nl=$(tput lines)
    local nc=$(tput cols)
    # save present cursor position
    tput sc
    # move cursor to the bottom
    tput cup $nl `expr $nc / 2`
    echo "$1/$nl"
    # restore the position of the cursor
    tput rc
}

# 初始界面的处理

clear
print_text $mode $l
tput cnorm
tput cup $l $c
# while true
# do
#     mode=0
# done

# save the file
savefile(){
    # save text into file line by line
    > $file
	for i in $(seq 0 $((${#text[@]}-1))) ; do
        line="${text[$i]}"
        echo -e "${line:0:$((${#line}-2))}" >> $file
    done
}

# # Black|Red|Green|Yellow|Blue|Magenta|Cyan|White
# # 40   |41 |42   |43    |44  |45     |46  |47


# [ Note ]
# 处理非单一键值的按键响应
# 参考stackoverflow: https://stackoverflow.com/questions/10679188/casing-arrow-keys-in-bash#11759139
# catch multi-char special key sequences

# echo -e "$c $l\n"
# 从键盘读入输入的1个字符 进行功能的转换
while read -sN1 key
do
    read -sN1 -t 0.0001 k1
    read -sN1 -t 0.0001 k2
    read -sN1 -t 0.0001 k3
    key+=${k1}${k2}${k3}
    case $mode in
    # 命令模式
    $COMMAND)
        case $key in
            # 光标右移，列数加一
            'l') if [[ $(($c)) -lt $((${#text[$l]}-3)) ]]
                then
                    c=`expr $c + 1 `
                fi
            ;;
            # 光标左移，列数减一
            'k') if [[ "$c" -ge 1 ]]
                then
                     c=`expr $c - 1`
                fi
            ;;
            # 光标上移，行数减一
            $'j') if [[ "$l" -ge 1 ]]
                then
                    l=`expr $l - 1` 
                fi
                if [[ $(($c)) -ge $((${#text[$l]}-1)) ]]
                then
                    c=`expr ${#text[$l]} - 3`
                fi
            ;;
            # 光标下移，行数加一
            $'h') if [[ "$l" -lt "$((${#text[@]}-1))" ]] 
                then
                    l=`expr $l + 1`
                fi 
                if [[ $(($c)) -ge $((${#text[$l]}-1)) ]]
                then
                    c=`expr ${#text[$l]} - 3`
                fi
            ;;
            # 进入插入模式
            $'i') mode=$INSERT 
            print_text $mode $l
            continue
            ;;
            # 进入底部命令行模式
            $':') mode=$BOTTOM
                # 隐藏光标
                print_text $mode $l
                tput civis
                continue
                ;;
            *) 
            ;;
        esac
    ;;
    # 插入模式
    $INSERT)
        case $key in
            # ESC 退出插入模式回到命令模式
            $'\x1b') mode=$COMMAND
                print_text $mode $l
                continue
                ;;
            # 回车键
            $'\x7f')
                if [[ "$c" -gt 0 ]]
                then
                    text[$l]="${line:0:$(($c-1))}""${line:$(($c))}"
                fi
                c=`expr $c - 1`
                print_text $mode $l
                continue
            ;;
            # 换行键
            $'\n') line="${text[$l]}"
                # 将输入的字符插入这一行
                i=${#text[@]}
                while true
                do
                    if [[ "$i" -gt "$(($l+1))" ]]
                    then
                        text[$i]=${text[$i-1]}
                        i=`expr $i-1`
                    else
                        break
                    fi
                done
                text[$l+1]="${line:$(($c+1))}"
                text[$l]="${line:0:$(($c+1))}""\n"
                # 光标向右移动
                l=`expr $l + 1 `
                c=0
                print_text $mode $l
                continue
            ;;

            # 输入一般字符，只需要将其直接加入队列
            *)  # 当前光标所指向的一行字符
                line="${text[$l]}"
                # 将输入的字符插入这一行
                line="${line:0:$(($c))}$key${line:$(($c))}"
                text[$l]="$line"
                # 光标向右移动
                c=`expr $c + 1 `
                print_text $mode $l
                continue
            ;;
        esac
    ;;

    # 底部命令模式
    $BOTTOM)
        case $key in
            $'w')
                # 退出程序，存储文件
                savefile 
                tput sc
                tput cup $(($(tput lines)+1)) 1
                echo "file successfully saved!"
                tput rc
                continue
                ;;
            $'q')
                # 恢复光标的正常显示
                tput clear
                tput cnorm
                exit ;;
            $'i')
                # 进入插入模式 重置光标属性
                tput tput cup $(($(tput lines)+1)) 0
                echo " "
                tput cup 0 0
                tput cnorm
                l=0
                c=0
                mode=$INSERT
                print_text $mode $l
                continue
            ;;
            $'\x1b') 
                # 进入命令模式 重置光标状态
                tput tput cup $(($(tput lines)+1)) 0
                echo " "
                tput cup 0 0
                tput cnorm
                l=0
                c=0
                mode=$COMMAND
                print_text $mode $l
                continue
        esac
    ;;
    *)
    ;;
    esac

    # 移动光标到(l,c)
    tput cup $l $c
    
done


# text=("aa\n" "abcdefs\n" 'cc\n')
# c=3
# l=1
# line="${text[$l]}"
# # 将输入的字符插入这一行
# if [[ "$c" -gt 0 ]]
# then
#     text[$l]="${line:0:$(($c-1))}""${line:$(($c))}"
# fi
# echo -ne ${text[$l]}