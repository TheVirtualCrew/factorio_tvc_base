#!/bin/bash

dirname="$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
ignores="build.sh modportal/ .DS_Store README.md .git/ .gitignore"
version=$(grep '"version"' info.json| cut -d ":" -f2 | sed 's/[", ]//g')
new_version=$(echo "$version" | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
version_escaped=`echo $version| sed "s/\./\\\\\\\./g"`
new_version_escaped=`echo $new_version| sed "s/\./\\\\\\\./g"`
sed_cmd="sed -i -e 's/${version_escaped}/${new_version_escaped}/g' \"${dirname}info.json\""
$(eval $sed_cmd)
modname=$(grep '"name"' info.json| cut -d ":" -f2 | sed 's/[", ]//g')
release="${modname}_${new_version}"

git=`which git`
count=$($git status -su . | wc -l)
if [ $count -gt 1 ]
then
    echo "Found uncommited files stopping"
    exit 1;
fi

echo "Commiting version ${new_version} to tag"
$(git commit -m "Updated mod to version ${new_version} for ${modname}" -- "${dirname}info.json")
echo "Pushing version ${new_version} to origin"
$(git tag -a "${modname}_${new_version}" -m "Build version ${modname} ${new_version}")
gitres=$(git push origin "${modname}_${new_version}" 2>&1)
gitres=gitres/$'\n'/' '
#
if [[ $gitres == *"tag already exists"* ]]
then
    echo "Tag for ${new_version} already exists, stopping now"
    exit 1;
fi

cmd="rsync -a \"${dirname}\" \"${dirname}/../${release}/\""
for ignore in $ignores
do
    cmd+=" --exclude ${ignore}"
done

$(eval $cmd)
cd "${dirname}../"
zip -r "${release}.zip" "${release}/"
rm -rf "${release}/"
cd "${dirname}"
