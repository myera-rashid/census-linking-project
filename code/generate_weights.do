/****************************************************************************************
Project: 	Census Linking Project
Created by: 	Myera Rashid
Last modified: 	04/22/2020
Description: 	Example code to reweight data  
*****************************************************************************************/


cap clear all
set more off

*------------------------------------------------------------------------------------------------------------------------------------
* SET UP
*-----------------------------------------------------------------------------------------------------------------------------------
global names exact    								
global method standard 								
global Year1 1900		   							
global Year2 1910         							
local keepvar "lit age urban occscore "		

/* NOTE: Based on the choice of your variables to weight on, it must be noted that variables are coded differently 
		and must be dealt with accordingly as shown in Section 3 of code. For this reason please use this code as 
		example and ammend the code in a way that suits your research project and context.  */
*-----------------------------------------------------------------------------------------------------------------------------------
* DIRECTORIES
*-----------------------------------------------------------------------------------------------------------------------------------

global datadir "/home/data/census-ipums/v2019/dta/" 									// location of full count data (equivalent of data downloaded from IPUMS)
global full_count_data "/disk/bulkw/mrashid/matching_project/test/full_count_data"		// location of full count data ready to be merged
global master_crosswalk  "/disk/bulkw/mrashid/matching_project/test/master_crosswalks"	// location of matched crosswalk				
global mergedir "/disk/bulkw/mrashid/matching_project/test/final_merged"				// location of matched crosswalk with merged data
global weighting "/disk/bulkw/mrashid/matching_project/test/weighting"					// location of macthed crosswalk with weights

*-----------------------------------------------------------------------------------------------------------------------------------
* BODY
*-----------------------------------------------------------------------------------------------------------------------------------

*******************************************************************************
/* SECTION 1. Prep Year1 and Year2 full count data to be merged into matched data  
*******************************************************************************/
/* 1.1 - This section provides code for extracting and preparing full count data 
		 to be merged into the crosswalks */

local years "${Year1} ${Year2}"

foreach y in `years' {

	use "$datadir//`y'.dta", clear 	// data files from downloaded from IPUMS separately for each year
	keep if sex == 1				// keep only the men
	keep if histid != ""			// drop observations that have a missing hidtid
	duplicates drop histid, force 	// drop observations that are duplicates 
	isid histid 					// checks for uniqeness of histid
	save "$full_count_data/`y'_full_count", replace 	// full count data ready to be merged
}


*******************************************************************************
/* SECTION 2. Merge data into crosswalks
*******************************************************************************/
/* 2.1 - This section provides code for merging information into the crosswalks
		 Note: Here we are reweighting based on Year2 characteristics. 
		 This is a context specific choice. Sometimes it makes sense to reweight
		 based on starting year characteristics instead of later year. If possible,
		 we encourage first reweighting using Year2 characteristics and then Year1 
		 in order to compare results from both. */


use "$master_crosswalk/crosswalk_${Year1}_${Year2}.dta", clear 		// use matched crosswalk		

keep if link_abe_${names}_${method} == 1	// here we are keeping matches made from a specific method. You can skip this if you want to keep matches made using various methods						
keep link_abe_${names}_${method} histid_${Year1} histid_${Year2} 	// drop the extra variables

rename histid_${Year1} histid 	// rename Year1 histid to match that of full count data for Year1

merge 1:1 histid using "$full_count_data/${Year1}_full_count.dta", keepusing(`keepvar') keep(1 3) nogenerate  // merge in Year1 data only for matched obs

foreach v in `keepvar' {

	rename `v' `v'_${Year1}		// rename merged in variables to be identified as Year1 vars
}

rename histid histid_${Year1}

rename histid_${Year2} histid 	// rename Year2 histid to match that of full count data for Year2 

merge 1:1 histid using "$full_count_data/${Year2}_full_count.dta", keepusing(`keepvar')	 // merge in Year2 data for matched and non-matched observations

gen matched = 0
replace matched = 1 if _merge == 3		// flag the matched observations	
drop _merge

foreach v in `keepvar' {

	rename `v' `v'_${Year2}			// rename Year2 vars 
}
rename histid histid_${Year2}


*******************************************************************************
/* SECTION 3. Generate Weights
*******************************************************************************/

/* 3.1 - Create bins for continuous variables
		In this example continuous variables are: age occscore   */

* create bins for age variable
gen age_bins_${Year2} = 0 
replace age_bins_${Year2} = 1 if age_${Year2} >= 10 & age_${Year2} < 20
replace age_bins_${Year2} = 2 if age_${Year2} >= 20 & age_${Year2} < 30
replace age_bins_${Year2} = 3 if age_${Year2} >= 40 & age_${Year2} < 50
replace age_bins_${Year2} = 4 if age_${Year2} >= 50 & age_${Year2} < 60
replace age_bins_${Year2} = 5 if age_${Year2} >= 60 & age_${Year2} < 70
replace age_bins_${Year2} = 6 if age_${Year2} >= 70 & age_${Year2} < 80
replace age_bins_${Year2} = 7 if age_${Year2} >= 80 & age_${Year2} < 90
replace age_bins_${Year2} = 8 if age_${Year2} >= 90

* create bins for occscore variable
gen occscore_bins_${Year2} = 0
replace occscore_bins_${Year2} = 1 if occscore_${Year2} >= 10 & occscore_${Year2} < 20
replace occscore_bins_${Year2} = 2 if occscore_${Year2} >= 20 & occscore_${Year2} < 30
replace occscore_bins_${Year2} = 3 if occscore_${Year2} >= 30 & occscore_${Year2} < 40
replace occscore_bins_${Year2} = 4 if occscore_${Year2} >= 40 & occscore_${Year2} < 50
replace occscore_bins_${Year2} = 5 if occscore_${Year2} >= 50


/* 3.2 - Dummy the categorical variables
		In this example categorical variables are: lit urban */

gen lit_dummy_${Year2} = 0
replace lit_dummy_${Year2} = 1 if lit_${Year2} == 4  // lit = 4 refers to those who are literate 

gen urban_dummy_${Year2} = 0
replace urban_dummy_${Year2} = 1 if urban_${Year2} == 2 // urban = 2 refers to those who live in urban areas

/* 3.3 - Run probit and generate weights */

** Probit
probit matched i.age_bins_${Year2} i.occscore_bins_${Year2} i.lit_dummy_${Year2} i.urban_dummy_${Year2} 
predict phat
 

** generate weights
cap drop weight
gen weight = (1-phat)/phat
 
sum matched
local x = `r(mean)'
replace weight = weight*`x'/(1-`x')	//weight for matched observations
replace weight = 1 if matched==0	// unmatched observations are given a weight = 1


*******************************************************************************
/* SECTION 4. Create Balance Tables 
*******************************************************************************/

** create balance tables for the covariates that need balancing 

local balance_covars "age_${Year2} occscore_${Year2} lit_${Year2} urban_${Year2}" // these are not the dummies but the actual variables we want to balance

foreach v in `balance_covars' {             
	reg `v' matched
	outreg2 using "${weighting}/weighting_balance.xls", append
	reg `v' matched [pw=weight]
	outreg2 using "${weighting}/weighting_balance.xls", append
}


save "${weighting}/weighting_wbins.dta", replace 	// save dataset with weights 

*******************************************************************************
/* SECTION 5. Matched Sample with Weights

** The matched sample used here was created using merge_in_variables.do
*******************************************************************************/

** Merge weights into matched sample for analysis

keep if matched ==1		// keep only the matched observations using the flag created
keep histid_${Year2} phat weight 	// keep relevant variables
merge 1:1 histid_${Year2} using "$mergedir/${Year1}_${Year2}_abe_${names}_${method}_complete_matched.dta" 	// using dataset is the one created as the output of merge_in_variables.do. This is your analysis dataset.
 
/* if using dataset has matches using several methods, use the 1:m option for merge instead of 1:1 */

keep if _merge ==3 	
drop _merge
save "${weighting}/${Year1}_${Year2}_abe_${names}_${method}_weighted.dta", replace 		// dataset with weights ready for analysis 

/* At this point you can use [pw=weight] to run weighted regressions in the matched data */





