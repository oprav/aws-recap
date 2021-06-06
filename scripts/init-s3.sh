if [ $# -eq 0 ]; then
  echo "usage: $(basename $0) your-bucket-name"
  exit 1
fi

bucket=$1

: '
# https://gist.github.com/weavenet/f40b09847ac17dd99d16
bucket=$1

echo "Removing all versions from $bucket"

versions=`aws s3api list-object-versions --bucket $bucket |jq '.Versions'`
markers=`aws s3api list-object-versions --bucket $bucket |jq '.DeleteMarkers'`
let count=`echo $versions |jq 'length'`-1

if [ $count -gt -1 ]; then
        echo "removing files"
        for i in $(seq 0 $count); do
                key=`echo $versions | jq .[$i].Key |sed -e 's/\"//g'`
                versionId=`echo $versions | jq .[$i].VersionId |sed -e 's/\"//g'`
                cmd="aws s3api delete-object --quiet  --bucket $bucket --key $key --version-id $versionId"
                echo $cmd
                $cmd
        done
fi

let count=`echo $markers |jq 'length'`-1

if [ $count -gt -1 ]; then
        echo "removing delete markers"

        for i in $(seq 0 $count); do
                key=`echo $markers | jq .[$i].Key |sed -e 's/\"//g'`
                versionId=`echo $markers | jq .[$i].VersionId |sed -e 's/\"//g'`
                cmd="aws s3api delete-object --quiet  --bucket $bucket --key $key --version-id $versionId"
                echo $cmd
                $cmd
        done
fi

aws s3api delete-bucket --bucket $bucket
'

aws s3api create-bucket --acl private --bucket $bucket --create-bucket-configuration LocationConstraint=$(aws configure get region) | echo
aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

touch file.dat
aws s3 cp file.dat s3://$bucket/file.dat
rm file.dat

response=$(curl "http://$bucket.s3.amazonaws.com/file.dat")
status=$(echo "$response" | grep -o "<Code>.*</Code>")
if [ "$status" != "<Code>AccessDenied</Code>" ]; then
  echo "Error: Bucket items are accessible for public"
  exit 1
fi
