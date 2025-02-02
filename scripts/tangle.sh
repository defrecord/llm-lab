#!/bin/bash

# Check if any files are passed
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <org_file1> [<org_file2> ...]"
    exit 1
fi

echo "Processing org files: $*"

for file in "$@"; do
    echo "Processing file: $file"
    emacs --batch \
	  -l .emacs.d/init.el \
	  --eval "(with-current-buffer (find-file \"$file\") \
        (org-babel-tangle) \
        (org-babel-execute-buffer))" \
	  --kill
done
