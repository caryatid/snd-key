#!/bin/sh
# determine diff
# 1  2  3  4  5  6  7  8  9  10 11 12
# a. b_ b. c. d_ d. e_ e. f. f^ g. g^ a.
# r  2_ 2. 3_ 3. 4. 5_ 5. 6_ 6. 7_ 7. r
#       w     w  h     w     w     w  h

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

cat <<'EOF' >$TMP/notes
a.
b_
b.
c.
d_
d.
e_
e.
f.
f^
g.
g^
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
    

_get_note () {
    local data="${2:-$TMP/notes}"
    sed -n "$1 p" $data
}

_get_note_offset () {
    local off=$1; local note=$2
    _get_note $(( ($off + $note) % 12 + 1 ))
}

_get_pattern () {
    local root=$1; local pattern=${2:-major}
    _get_note_offset $root -1
    while read off
    do
        _get_note_offset $root $off
    done <$TMP/$pattern
}

_get_chord () {
    local key=$1; shift
    local intervals="$@"
    for i in $intervals
    do
        i=$(( $i % $(wc -l $TMP/major | awk '{print $1}') + 1 ))
        local i_v=$(_get_note $i $TMP/major)
        _get_note_offset $key $i_v 
    done 
}

_print_string () {
    local start=$(_get_idx $1)
    local fret=0
    local normal_fmt='%5.5s-|'
    local first_fmt='%5.5s]]'
    local dot_fmt='%5.5s-)'
    local oct_fmt='%5.5s))'
    for p in $(_get_pattern $start chromatic) $(_get_pattern $start chromatic)
    do
        echo $p
#        local fmt_=$(printf '"%s" == $2'  "$p")
#        local active=$(awk "$fmt_" $TMP/chord)
#        if test -n "$active"
#        then
#            local fmt__=$(printf '"%s" == $2 { print $1 }'  "$p")
#            local interval=$(awk "$fmt__" $TMP/chord)
#            p="$interval$p"
#        else
#            p="      "
#        fi
#        case $fret in
#        0) printf "$first_fmt" "$p" ;;
#        3|5|7|9) printf "$dot_fmt" "$p" ;;
#        12) printf "$oct_fmt" "$p" ;;
#        *) printf "$normal_fmt" "$p" ;;
#        esac
#        fret=$(( $fret + 1 ))
    done
    echo 
}
            
#_get_chord "$@"
#k_=$(_get_idx $2)
#for x in $(awk '{print $2}' $TMP/chord) 
#do
#    printf "$x "
#    _get_relation $k_ $(_get_idx $x)
#done
#echo
_get_chord  $@ >$TMP/chord
_print_string e.
#_print_string b.
#_print_string g.
#_print_string d.
#_print_string a.
#_print_string e.


# _get_note_offset $1 $2
# _get_pattern $1 $2
