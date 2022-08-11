#!/bin/sh

#
# Does the user have all the IETF published models.
#
if [ ! -d ../bin/yang-parameters ]; then
   rsync -avz --delete rsync.iana.org::assignments/yang-parameters ../bin/
fi

for i in ../bin/*\@$(date +%Y-%m-%d).yang
do
    name=$(echo $i | cut -f 1-3 -d '.')
    echo "Validating YANG module $name.yang using pyang"
    if test "${name#^example}" = "$name"; then
        response=`pyang --lint --strict --canonical -p ../../iana/yang-parameters -p ../bin -f tree --max-line-length=72 --tree-line-length=69 $name.yang > $name-tree.txt.tmp`
    else            
        response=`pyang --ietf --strict --canonical -p ../bin/yang-parameters -p ../bin -f tree --max-line-length=72 --tree-line-length=69 $name.yang > $name-tree.txt.tmp`
    fi
    if [ $? -ne 0 ]; then
        printf "$name.yang failed pyang validation\n"
        printf "$response\n\n"
        echo
	rm yang/*-tree.txt.tmp
        exit 1
    fi
    echo "Validation of YANG module $name.yang using pyang succeeded."
    fold -w 71 $name-tree.txt.tmp > $name-tree.txt
    echo "Validating YANG module $name.yang using yanglint"
    response=`yanglint -p ../src/yang $name.yang -i`
    if [ $? -ne 0 ]; then
       printf "$name.yang failed yanglint validation\n"
       printf "$response\n\n"
       echo
       exit 1
   fi
   echo "Validation of $name.yang using yanglint succeeded."
done
rm ../bin/*-tree.txt.tmp

for i in ../bin/ietf-*-notif-*\@$(date +%Y-%m-%d).yang
do
    name=$(echo $i | cut -f 1-3 -d '.')
    echo "Generating abridged tree diagram for $name.yang"
    if test "${name#^example}" = "$name"; then
       response=`pyang --lint --strict --canonical -p ../bin/yang-parameters/ -p ../bin -f tree --tree-depth=7 --max-line-length=69 --tree-line-length=69 $name.yang > $name-sub-tree.txt.tmp`
    else            
       response=`pyang --ietf --strict --canonical -p ../bin/yang-parameters/ -p ../bin -f tree --tree-depth=3 --max-line-length=69 --tree-line-length=69 $name.yang > $name-sub-tree.txt.tmp`
    fi
    if [ $? -ne 0 ]; then
        printf "$name.yang failed generation of sub-tree diagram\n"
        printf "$response\n\n"
        echo
	rm yang/*-sub-tree.txt.tmp
        exit 1
    fi
    fold -w 69 $name-sub-tree.txt.tmp > $name-sub-tree.txt
done
rm ../bin/*-sub-tree.txt.tmp

echo "Validating examples"

for i in yang/example-https-notif-*.xml
do
    name=$(echo $i | cut -f 1-2 -d '.')
    echo "Validating examples for $name.xml"
    response=`yanglint -ii -t config -p ../bin -p ../bin/yang-parameters ../bin/ietf-https-notif-transport\@$(date +%Y-%m-%d).yang $name.xml`
    if [ $? -ne 0 ]; then
       printf "failed (error code: $?)\n"
       printf "$response\n\n"
       echo
       exit 1
    fi
    echo "$name is VALID"
done

for i in yang/example-custom-https-notif.xml
do
    name=$(echo $i | cut -f 1 -d '.')
    echo "Validating examples for $name.xml"
    response=`yanglint -ii -t config -p ../bin -p ../bin/yang-parameters ../bin/example-custom-module\@$(date +%Y-%m-%d).yang $name.xml`
    if [ $? -ne 0 ]; then
       printf "failed (error code: $?)\n"
       printf "$response\n\n"
       echo
       exit 1
    fi
    echo "$name is VALID"
done
