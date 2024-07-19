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
    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">
</head>
<body>
<div class=\"content\">
<h1>Good first issues in Ethereum core repos</h1>
"

# Create a menu for anchor links
menu_content="<div class=\"menu\">
<h2>Repositories</h2>"

# Loop through repositories in repos.txt
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

    repo_name=$(echo "$REPO" | awk -F '/' '{print $2}')
    menu_content="$menu_content
    <div class=\"menu-item\"><a href=\"#$repo_name\">$REPO</a></div>"

    html_content="$html_content
    <h3 id=\"$repo_name\">GFIs in <a href=\"https://github.com/$REPO\" target=\"_blank\">$REPO</a></h3>
    <div id=\"issues-list-$repo_name\">"
    
    # API call with list of labels to pull
    issues=$(gh issue list --repo $REPO --search 'label:"good first issue","D-good-first-issue","E-easy"' --json title,url,state,assignees 2>&1)

    # Log raw JSON for debugging
    echo "Repository: $REPO" >> issues_debug.log
    echo "$issues" >> issues_debug.log

    # Check if 'issues' contains valid JSON
    if ! echo "$issues" | jq empty 2>/dev/null; then
        echo "Error fetching issues for repository $REPO. See issues_debug.log for details." >> issues.html
        continue
    fi

    # Process each issue and append to HTML content
    while IFS= read -r line; do
        title=$(echo "$line" | jq -r '.title')
        link=$(echo "$line" | jq -r '.url')
        state=$(echo "$line" | jq -r '.state')
        assignees=$(echo "$line" | jq -r '[.assignees[].login] | join(", ")')

        # Generate HTML for assignees with links
        assignees_html=$(echo "$line" | jq -r '[.assignees[] | "<a href=\"https://github.com/" + .login + "\" target=\"_blank\">" + .login + "</a>"] | join(", ")')

        html_content="$html_content
        <div class=\"item\">
            <a class=\"item-link\" href=\"$link\" target=\"_blank\">$title</a>
            <div class=\"item-state\">State: $state</div>
            <div class=\"item-assign\">Assignees: $assignees_html</div>
        </div>"
    done <<< "$(echo "$issues" | jq -c '.[]')"

    html_content="$html_content
    </div>"
done < "$REPO_FILE"

menu_content="$menu_content
</div>"

html_content="$html_content
</div>
$menu_content
</body>
</html>"

echo "$html_content" > issues.html

echo "issues.html generated."