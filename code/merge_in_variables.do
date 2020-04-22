
/****************************************************************************************
Project: 	Census Linking Project
Created by: 	Myera Rashid
Last modified: 	04/22/2020
Description: 	Example code to merge data into crosswalks 
*****************************************************************************************/

cap clear all
set more off

*------------------------------------------------------------------------------------------------------------------------------------
* SET UP
*-----------------------------------------------------------------------------------------------------------------------------------

global names exact nysiis   				// Pick between nysiis or exact for this macro
global method standard conservative			// Pick between standard and conservative for this macro
global Year1 1850		   					// Starting year for matched crosswalk
global Year2 1860         					// Ending year for matched crosswalk
local keepvar "age bpl occscore"			// Variables to be merged in 
*-----------------------------------------------------------------------------------------------------------------------------------
* DIRECTORIES
*-----------------------------------------------------------------------------------------------------------------------------------

global master_crosswalk  "/disk/bulkw/mrashid/matching_project/test/master_crosswalks"	  // directory where crosswalk is stored 
global IPUMSdir "/disk/bulkw/mrashid/matching_project/IPUMS_data"  						  // directory where downloaded full count data from IPUMS is stored 
global mergedir "/disk/bulkw/mrashid/matching_project/test/final_merged"				  // directory where merged dataset will be stored 


*-----------------------------------------------------------------------------------------------------------------------------------
* BODY
*-----------------------------------------------------------------------------------------------------------------------------------


*******************************************************************************
/* SECTION 1. Extract Data by Year for Year1 and Year2 from IPUMS Downloaded data
*******************************************************************************/
/* 1.1 - Extract data from IPUMS. This section provides the code used to extract data 
		 for Year1 and Year2 in case data was downloaded together from IPUMS.  */

local years "${Year1} ${Year2}"

foreach y in `years' {
	use "$IPUMSdir/${Year1}_${Year2}_full.dta" , clear			// use the downloaded data from IPUMS
	keep if year == `y'											// only keeps obs from Year1 or Year2
	keep if sex == 1											// only keeps men as women cannot be matched		
	rename histid histid_`y'									// rename histid to match crosswalk data 
	keep if histid_`y' != ""									// identifying variable cannot be missing
	duplicates report histid_`y'								// identifying variable cannot have duplicates
	isid histid_`y'												// check to make sure histid uniquely identifies obs
	save "$IPUMSdir/`y'_full.dta" , replace 					// save a file for each year
}

*******************************************************************************
/* SECTION 2. Merge Year1 and Year2 Data into Matched Crosswalk
*******************************************************************************/
/* 2.1 - This section provides code to merge in data from IPUMS dataset into the
		 matched crosswalk to have a longitudinal dataset*/


use "$master_crosswalk/crosswalk_${Year1}_${Year2}.dta", clear 		// use the crosswalk downloaded from the Census Linking Project


keep if link_abe_${names}_${method} == 1		// keeps only matches made using the chosen method using the appropriate flag. 

/* If you want to keep matches made using all the methods, you do not have to use the keep if option above.
Then use a m:1 merge instead of a 1:1 merge in the code below */

merge 1:1 histid_${Year1} using "$IPUMSdir/${Year1}_full.dta", keepusing(`keepvar') keep(1 3) nogenerate		// merge in vars from Year1

** rename $Year1 variables to end in _${Year1}
foreach var of varlist _all {
	rename `var' `var'_${Year1}
}

rename histid_${Year2}_${Year1} histid_${Year2}

merge 1:1 histid_${Year2} using "$IPUMSdir/${Year2}_full.dta", keepusing(`keepvar') keep(1 3) nogenerate		// merge in vars Year2

** rename $Year2 variables to end in _${Year2}
foreach v of varlist _all {

	if regexm("`v'", "_${Year1}$") == 1 {
		di in red "${Year1} variables"		// don't rename Year1 vars
	}
	else{
		rename `v' `v'_${Year2}				// only rename Year2 vars
	}
}

rename histid_${Year1}_${Year1} histid_${Year1}
rename histid_${Year2}_${Year2} histid_${Year2} 

save "$mergedir/${Year1}_${Year2}_abe_${names}_${method}_complete_matched.dta", replace



** last updated: March 23, 2020 
** please contact ranabr@stanford.edu (Ran Abramitzky), lboustan@princeton.edu (Leah Boustan), and/or myerar@princeton.edu (Myera Rashid) 
** with any questions or feedback about this code. 


