#!/bin/sh
find ./ -type d -name obj | xargs rm -fr && find ./ -type d -name bin | xargs rm -fr
NEWNAME=$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version| grep -v "\[")
nuget restore
xbuild ShowView.csproj /t:Build /p:Configuration=Release /p:Platform="AnyCPU"

LAST_RELEASE=$(git log --pretty=oneline | grep '\[maven-release-plugin\] prepare for next development iteration'|head -n1| awk '{ print $1; }'|sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
if [[ "$LAST_RELEASE" == "" ]]; then
	LAST_RELEASE=$(git log --pretty=oneline|tail -n1| awk '{ print $1; }'|sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
fi
NOTES=$(git log HEAD...$LAST_RELEASE --pretty=oneline | awk '{for (i=2;i<=NF;i++) { printf (i == 2 ? "- %s " : "%s "),$i};printf "\n"}')

NUSPEC_FILE=/tmp/nuget_droid_proxy.nuspec
echo '<?xml version="1.0"?> 
<package xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> 
<metadata xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd"> 
    <id>ShowcaseView</id> 
    <version>' > $NUSPEC_FILE
echo $NEWNAME >> $NUSPEC_FILE
echo    '</version>
    <authors>Alex Curran</authors>
    <owners>Alex Curran, Wolfgang Reithmeier</owners>
    <licenseUrl>https://github.com/amlcurran/ShowcaseView</licenseUrl>
    <projectUrl>https://github.com/W-R-SKY-DE/ShowView</projectUrl>
    <iconUrl>https://raw.githubusercontent.com/amlcurran/ShowcaseView/master/library/src/main/res/drawable-hdpi/cling.png</iconUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Showcase View Lib</description>
    <summary>Showcase View Lib</summary>
    <releaseNotes><![CDATA[' >> $NUSPEC_FILE
echo $NOTES >> $NUSPEC_FILE
echo '    ]]></releaseNotes>
    <language>en-US</language>
    <tags>Showcase View</tags>
</metadata>
<files>
    <file src="bin/Release/ShowView.dll" target="lib\MonoAndroid10\ShowView.dll" />
</files>
</package>' >> $NUSPEC_FILE
if [ ! -d "$DIRECTORY" ]; then
mkdir target
fi
nuget pack $NUSPEC_FILE -BasePath ./ -OutputDirectory ./target
# rm $NUSPEC_FILE