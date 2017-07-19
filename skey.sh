#!/bin/sh
# determine diff
# 1  2  3  4  5  6  7  8  9  10 11 12
# a. b_ b. c. d_ d. e_ e. f. f^ g. g^ a.
# r  2_ 2. 3_ 3. 4. 5_ 5. 6_ 6. 7_ 7. r
#       w     w  h     w     w     w  h
# TODO output abc spec
# http://abcnotation.com/wiki/abc:standard:v2.1

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

cat <<'EOF' >$TMP/notes
=a
_b
=b
=c
_d
=d
_e
=e
=f
^f
=g
^g
EOF

cat <<'EOF' >$TMP/intervals
1=
2_
2=
3_
3=
4=
5_
5=
6_
6=
7_
7=
EOF

cat <<'EOF' >$TMP/major
0
2
4
5
7
9
11
EOF

cat <<'EOF' >$TMP/minor
0
2
3
5
7
8
10
EOF

seq 0 11 >$TMP/chromatic

_get_idx () {
    local data="${2:-$TMP/notes}"
    local fmt=$(printf '"%s" == $1 { print NR }' "$1")
    awk "$fmt" $data
}

_get_note () {
    local data="${2:-$TMP/notes}"
    sed -n "$1 p" $data
}

_stream_to_idx () {
    local data="${2:-$TMP/notes}"
    while read note
    do
        _get_idx $note $data
    done
}

_stream_to_note () {
    local data="${2:-$TMP/notes}"
    while read idx
    do
        _get_note $idx $data
    done
}

_get_distance () {
    local from=$1; local to=$2
    test $to -lt $from && to=$(( $to + 12 ))
    local distance=$(( ($to - $from + 1) % 12 ))
    test $distance -eq 0 && echo 12 || echo $distance
}

_get_offset () {
    local off=$1; local note=$2
    local nnum=$(( ($off + $note) % 12 ))
    test $nnum -eq 0 && nnum=12
    echo $nnum
}
    
_get_note_offset () {
    _get_note $(_get_offset $1 $2)
}

_get_pattern () {
    local root=$1; local pattern=${2:-major}
    while read off
    do
        _get_note_offset $root $off
    done <$TMP/$pattern
}

_get_chord () {
    local key=$1; shift
    local intervals="$@"
    local mod=$(wc -l $TMP/major | awk '{print $1}')
    for i in $intervals
    do
        i=$(( $i % $mod ))
        test $i -eq 0 && i=$mod
        local i_v=$(_get_note $i $TMP/major)
        _get_note_offset $key $i_v 
    done 
}

_take () {
    local count=0
    local take=${1:-10}; shift
    while true
    do
        for i in $($1)
        do
            count=$(( count + 1 ))
            test $count -gt $take && break 99
            echo $i
        done
    done
}
_print_interval () {
    local interval=$(_get_note $(_get_distance $1 $2) $TMP/intervals)
    case $interval in
    1=) echo $(_get_note $2) root ;;
    2_) echo $(_get_note $2) lowered second ;;
    2=) echo $(_get_note $2) second ;;
    3_) echo $(_get_note $2) lowered third ;;
    3=) echo $(_get_note $2) third ;;
    4=) echo $(_get_note $2) fourth ;;
    5_) echo $(_get_note $2) lowered fifth ;;
    5=) echo $(_get_note $2) fifth ;;
    6_) echo $(_get_note $2) lowered sixth ;;
    6=) echo $(_get_note $2) sixth ;;
    7_) echo $(_get_note $2) lowered seventh ;;
    7=) echo $(_get_note $2) seventh ;;
    esac
}
    
_print_string () {
    local key=$(_get_idx $1); shift
    local start=$(_get_idx $1); shift
    local marks=${1:-$TMP/notes}
    local fret=0
    local fret_fmt='%5.5s|'
    for p in $(_take 17 "_get_pattern $start chromatic")
    do
        pnum=$(_get_idx $p)
        if test -z "$(_get_idx $p $marks)"
        then
            p="----"
        else
            p="$p"
        fi
        case $fret in
        0|12) printf "$fret_fmt" "$p|" ;;
        3|5|7|9) printf "$fret_fmt" "$p)" ;;
        *) printf "$fret_fmt" "$p-" ;;
        esac
        fret=$(( $fret + 1 ))
        test $fret -eq 13 && fret=1
    done
    echo 
}
            
key_id=$1
key_name=$(_get_note $1)
shift;
_get_chord $key_id "$@" >$TMP/chord
for x in $(cat $TMP/notes)
do
    _print_interval $key_id $(_get_idx $x)
done

for string in e b g d a e
do
    _print_string "$key_name" "=$string" $TMP/chord
done



# _get_note_offset $1 $2
# _get_pattern $1 $2
