#!/bin/bash

NSXUSER='youruserhere'
#NSXPASS='yourpasswordhere'
NSXMAN='your nsx manager here'

read -s -p "Password: " NSXPASS

#txt files cleanup

rm -rf *.txt

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1/infra/domains/default/security-policies | grep '"id"' > section_id.txt
curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1/infra/domains/default/security-policies | grep '"display_name"' > section_display_name.txt
curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1/infra/domains/default/security-policies | grep '"path"' > path.txt

paste -d " " section_id.txt section_display_name.txt path.txt > section.list

sed -i 's/ //g' section.list
sed -i 's/:/,/g' section.list
sed -i 's/"//g' section.list


SECTION="section.list"

echo 'Do you want to update a specif section? Choose the line number or leave empty to full update.'
echo ''

echo `cat -n $SECTION`


echo ''
read -p "Answer: " ANSWER

if [[ "$ANSWER" -ge 1 ]]

then

echo "$ANSWER"
echo "Updating Section $ANSWER"


sed -n $ANSWER,999p section.list > section2.list
sed -n 1,1p section2.list > section.list

echo `cat section.list`

rm  section2.list

sleep 1

else

echo "Updating Everything"
echo `cat section.list`

fi


for SECTIONVAR in `cat $SECTION`

do

ID01=`echo $SECTIONVAR | cut -f2 -d","`
DISPLAYNAME01=`echo $SECTIONVAR | cut -f4 -d","`
PATH01=`echo $SECTIONVAR | cut -f6 -d","`


curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH01 >> rules-orig.txt


curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH01 | grep "/security-policies/$ID01/rules" > rules_path$ID01.txt
curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH01 | grep "relative_path" > rules_id$ID01.txt

paste -d " " rules_id$ID01.txt rules_path$ID01.txt > rules$ID01.list

sed -i 's/ //g' rules$ID01.list
sed -i 's/:/,/g' rules$ID01.list
sed -i 's/"//g' rules$ID01.list
sed -i '/tag\,/d' rules$ID01.list

RULESPATH=rules$ID01.list


for RULES in `cat $RULESPATH`

do

ID02=`echo $RULES | cut -f2 -d","`
PATH02=`echo $RULES | cut -f4 -d","`

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH02 > rule$ID01$ID02.txt

cat rule$ID01$ID02.txt | grep "source_group" >  sourcesg$ID01$ID02.txt
cat rule$ID01$ID02.txt | grep "destination_group" >  destinationsg$ID01$ID02.txt

sed -i 's/ //g' sourcesg$ID01$ID02.txt
sed -i 's/:/,/g' sourcesg$ID01$ID02.txt
sed -i 's/"//g' sourcesg$ID01$ID02.txt
sed -i 's/\[//g' sourcesg$ID01$ID02.txt
sed -i 's/\]//g' sourcesg$ID01$ID02.txt


SRCSGID=`cat sourcesg$ID01$ID02.txt | cut -f2 -d","`

sed -i 's/ //g' destinationsg$ID01$ID02.txt
sed -i 's/:/,/g' destinationsg$ID01$ID02.txt
sed -i 's/"//g' destinationsg$ID01$ID02.txt
sed -i 's/\[//g' destinationsg$ID01$ID02.txt
sed -i 's/\]//g' destinationsg$ID01$ID02.txt

DSTSGID=`cat destinationsg$ID01$ID02.txt | cut -f2 -d","`

SOURCECHECK=`cat sourcesg$ID01$ID02.txt | grep "ipaddress-group-"`

if [[ $SOURCECHECK == *"ipaddress-group"* ]]

then

echo $SOURCECHECK
echo $SRCSGID

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$SRCSGID | grep ip_addresses > srcipaddr$ID01$ID02.txt

sed -i 's/ip_addresses/source_groups/g' srcipaddr$ID01$ID02.txt
sed -i 's/\s\s\s\s/  /g' srcipaddr$ID01$ID02.txt

sed -n 1,16p  rule$ID01$ID02.txt >>  rulenew$ID01$ID02.txt
cat  srcipaddr$ID01$ID02.txt  >>  rulenew$ID01$ID02.txt
sed -n 18,50p  rule$ID01$ID02.txt >>  rulenew$ID01$ID02.txt

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH02 -X PATCH --data @rulenew$ID01$ID02.txt -H "Content-Type: application/json"

sleep 1

fi

DESTINATIONCHECK=`cat destinationsg$ID01$ID02.txt | grep "ipaddress-group-"`

if [[ $DESTINATIONCHECK == *"ipaddress-group"* ]]

then

echo $DESTINATIONCHECK
echo $DSTSGID

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH02 > rulenew2$ID01$ID02.txt

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$DSTSGID | grep ip_addresses > dstipaddr$ID01$ID02.txt


sed -i 's/ip_addresses/destination_groups/g' dstipaddr$ID01$ID02.txt
sed -i 's/\s\s\s\s/  /g' dstipaddr$ID01$ID02.txt



sed -n 1,17p  rulenew2$ID01$ID02.txt >>  rulenew3$ID01$ID02.txt
cat  dstipaddr$ID01$ID02.txt  >>  rulenew3$ID01$ID02.txt
sed -n 19,50p  rulenew2$ID01$ID02.txt >>  rulenew3$ID01$ID02.txt

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1$PATH02 -X PATCH --data @rulenew3$ID01$ID02.txt -H "Content-Type: application/json"


sleep 1


fi


done

done
