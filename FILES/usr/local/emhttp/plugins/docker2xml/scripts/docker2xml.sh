#!/bin/bash

DOCKERFILE="$1dockerfile/raw"

echo "Converting $DOCKERFILE"
echo ""
echo ""
if ! wget $DOCKERFILE -O /tmp/dockerfile
then
	echo ""
	echo ""
	echo "Could not download the dockerfile"
	echo ""
	echo "$DOCKERFILE"
	echo ""
	echo "Bad URL?"
	exit 1
fi



DOCKERNAME=$(basename $(echo "$DOCKERFILE" | sed -e "s/\/[^\/]*$//" | sed -e "s/\/[^\/]*$//"))
REGISTRY=$(echo "$DOCKERFILE" | sed -e "s/\/[^\/]*$//" | sed -e "s/\/[^\/]*$//")
REPOSITORY="$(echo "$REGISTRY" | grep -oP '(?<=https:\/\/registry.hub.docker.com\/u\/)\w+')"

OUTPUT="/tmp/$DOCKERNAME"

# Get the exposed ports.  Other ports are assumed to be TCP ** Not specified by docker file **

PORTLIST="$(cat /tmp/dockerfile | grep "EXPOSE")"
MYPORTS="$(echo "$PORTLIST" | sed 's/EXPOSE//')"
TCPPORTS="$(echo "$MYPORTS" | egrep -i "/tcp" | sed 's/^.//' | sed 's/.\{4\}$//')"
UDPPORTS="$(echo "$MYPORTS" | egrep -i "/udp" | sed 's/^.//' | sed 's/.\{4\}$//')"
OTHERPORTS="$(echo "$MYPORTS" | egrep -v -i "/tcp" | egrep -v -i "/udp" |sed 's/^.//')"

# Get the container's Volumes

VOLUMELIST="$(cat /tmp/dockerfile | egrep "VOLUME" | sed 's/VOLUME//g')"

# Replace messed characters []," with spaces since there are multiple ways of handling VOLUMES

VOLUMELIST="$(echo "$VOLUMELIST" | sed 's/\[/ /g' | sed 's/\]/ /g' | sed 's/\,/ /g' | sed 's/\"/ /g')"


echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $OUTPUT
echo "<Container>" >> $OUTPUT
echo "	<Name>$DOCKERNAME</Name>" >> $OUTPUT
echo "	<Description>Converted XML File from $DOCKERFILE.[br][br]Converted by Docker2XML.[br][br][span style=\'color: #E80000;\']Double check the entries via the Advanced View button.[br][br]You will need to manually add any required environment variables.[/span]" >> $OUTPUT
echo "	</Description>" >> $OUTPUT
echo "	<Registry>$REGISTRY</Registry>" >> $OUTPUT
echo "	<Repository>$REPOSITORY/$DOCKERNAME</Repository>" >> $OUTPUT
echo "	<BindTime>true</BindTime>" >> $OUTPUT
echo "	<Privileged>false</Privileged>" >> $OUTPUT
echo "	<Environment/>" >> $OUTPUT
echo "	<Networking>" >> $OUTPUT
echo "		<Mode>bridge</Mode>" >> $OUTPUT
echo "		<Publish>" >> $OUTPUT

for PORT in $TCPPORTS
do
	echo "		<Port>" >> $OUTPUT
	echo "			<HostPort>$PORT</HostPort>" >> $OUTPUT
	echo "			<ContainerPort>$PORT</ContainerPort>" >> $OUTPUT
	echo "			<Protocol>tcp</Protocol>" >> $OUTPUT
	echo "		</Port>" >> $OUTPUT
done

for PORT in $UDPPORTS
do
        echo "          <Port>" >> $OUTPUT
        echo "                  <HostPort>$PORT</HostPort>" >> $OUTPUT
        echo "                  <ContainerPort>$PORT</ContainerPort>" >> $OUTPUT
        echo "                  <Protocol>udp</Protocol>" >> $OUTPUT
        echo "          </Port>" >> $OUTPUT
done

for PORT in $OTHERPORTS
do
        echo "          <Port>" >> $OUTPUT
        echo "                  <HostPort>$PORT</HostPort>" >> $OUTPUT
        echo "                  <ContainerPort>$PORT</ContainerPort>" >> $OUTPUT
        echo "                  <Protocol>tcp</Protocol>" >> $OUTPUT
        echo "          </Port>" >> $OUTPUT
done
echo "		</Publish>" >> $OUTPUT
echo "	</Networking>" >> $OUTPUT
echo "	<Data>" >> $OUTPUT

for VOLUME in $VOLUMELIST
do
	echo "	<Volume>" >> $OUTPUT
	echo "		<HostDir>Change to suitable unRaid directory</HostDir>" >> $OUTPUT
	echo "		<ContainerDir>$VOLUME</ContainerDir>" >> $OUTPUT
	echo "		<Mode>rw</Mode>" >> $OUTPUT
	echo "	</Volume>" >> $OUTPUT
done

echo "	</Data>" >> $OUTPUT

if [ $(echo "$PORTLIST" | wc -l) -eq "1" ]
then
	echo "	<WebUI>http://[IP]:[PORT:$PORT]</WebUI>" >> $OUTPUT
fi

	echo "	<Icon>https://raw.githubusercontent.com/Squidly271/Docker2XML/master/docker.png</Icon>" >> $OUTPUT
	echo "	<Banner>https://raw.githubusercontent.com/Squidly271/Docker2XML/master/docker_banner.png</Banner>" >> $OUTPUT

echo "</Container>" >> $OUTPUT

CONVERTED="/boot/config/plugins/dockerMan/templates-user/Docker2XML-$DOCKERNAME.xml"

if [ ! -d /boot/config/plugins/dockerMan/templates-user/ ]
then
	mkdir -p /boot/config/plugins/dockerMan/templates-user/
fi


mv "$OUTPUT" "$CONVERTED"
echo "Converted file now available at $CONVERTED"
echo ""
echo "After loading the template, make sure you assign the Host Volume Paths and double-check the Host Port Assignments"
echo ""
rm /tmp/dockerfile



