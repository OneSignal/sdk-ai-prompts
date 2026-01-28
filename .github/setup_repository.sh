#!/usr/bin/env bash
while getopts n: flag
do
    case "${flag}" in
        n) REPOSITORY_NAME=${OPTARG};;
    esac
done

DASHED_NAME=$(echo $REPOSITORY_NAME | tr '_' '-' | tr '[:upper:]' '[:lower:]');
PACKAGE_NAME=$(echo $DASHED_NAME | tr '-' '_');
SPACED_NAME=$(echo $DASHED_NAME | tr '-' ' ');

echo "Repository: $REPOSITORY_NAME";
echo "Dashed Name: $DASHED_NAME";
echo "Package Name: $PACKAGE_NAME";
echo "Spaced Name: $SPACED_NAME";

# Replace any template placeholder values with the proper values
echo "Replacing template variables..."
for filename in $(git ls-files); do
    sed -i \
        -e "s/{{repo_name}}/$REPOSITORY_NAME/g" \
        -e "s/{{dashed_name}}/$DASHED_NAME/g" \
        -e "s/{{package_name}}/$PACKAGE_NAME/g" \
        -e "s/{{spaced_name}}/$SPACED_NAME/g" \
        $filename
    echo "Replaced template variables in: $filename"
done

# Ensure this github action only runs on the initial setup.
echo "Cleaning up template files..."
rm -rf .github/template.yml
rm -rf .github/setup_repository.sh
rm -rf .github/workflows/setup_repository.yml

rm -f README.md
mv README_TEMPLATE.md README.md
mv TEMPLATE_catalog-info.yaml catalog-info.yaml
