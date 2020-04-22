This repository provides codes and documentation associated with the Census Linking Project that links each wave of the complete-count historical Census (1850-1940) to every other wave using a wide variety of frontier linking algorithms. 

Last modified: April 22, 2020

Users can download linked crosswalks at https://censuslinkingproject.netlify.app/data/. Data can then be merged into these crosswalks from https://usa.ipums.org/usa/ to provide the user with historical longitudinal data for analysis. 

Currently, there are three associated .do files that are found in the codes folder: 
	- 	create_matched_crosswalks.do: Code used to create the matched crosswalks.
	-	merge_in_variables.do: Example code to merge data into the crosswalks from IPUMS.
	- 	generate_weights.do: Example code outlining how to generate weights in order to reweight the matched data.

The respective documentation for each of the .do files can be found in the documentation folder: 
	-	create_matched_crosswalks_readme
	-	merge_in_variables_readme
	-	generate_weights_readme
