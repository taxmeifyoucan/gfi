#!/bin/bash

REPO_FILE="repos.txt"

if [[ ! -f "$REPO_FILE" ]]; then
    echo "File $REPO_FILE does not exist."
    exit 1
fi

# HTML head and base content
html_content="<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>GitHub Issues</title>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        h1 {
            color: #333;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            margin: 10px 0;
        }
        a {
            text-decoration: none;
            color: #007bff;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
<h1>Good first issues in Ethereum core repos</h1>
"
#api uses gh tool now, reading should work without a key
while IFS= read -r REPO; do

    if [[ $REPO == \#* ]]; then
        category=${REPO#\# }
        html_content="$html_content
    <h2>$category</h2>"
        continue
    fi
    

    if [[ -z "$REPO" ]]; then
        continue
    fi
    
    html_content="$html_content
    <h3>GFIs in $REPO</h3>
    <ul id=\"issues-list-$REPO\">"
    #api call with list of labels to pull
    issues=$(gh issue list --repo $REPO --search 'label:"good first issue","D-good-first-issue","E-easy"' --json title --json url)

    # pulls title and link from json, there is more fields to add
    while IFS= read -r line; do
        title=$(echo "$line" | jq -r '.title')
        link=$(echo "$line" | jq -r '.url')
        html_content="$html_content
        <li><a href=\"$link\" target=\"_blank\">$title</a></li>"
    done <<< "$(echo "$issues" | jq -c '.[]')"

    html_content="$html_content
    </ul>"
done < "$REPO_FILE"

html_content="$html_content
</body>
</html>"

echo "$html_content" > issues.html

echo "issues.html generated."
