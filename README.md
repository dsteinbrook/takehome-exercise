# nextgen takehome

## setup instructions
--create a data folder in the root directory and add the unzipped html file `huge_chat_export.html` to the data folder

--run `python parse_authors.py` (or `python3 parse_authors.py`) to get a list of authors in the desired output format in `output.txt`

The script has an optional command line argument -n <max_lines> (e.g. python3 -n 1000) to parse the first 1000 lines only of the data file. If omitted it will parse the entire file.

Note: some of the author names in the data file were commented out (e.g. `<!--Author: Emily Chen (Facebook: 777777777777777)-->`) and I chose to omit these from the output result.
