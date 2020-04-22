
/****************************************************************************************
Project: 	Census Linking Project
Created by: 	Myera Rashid
Last modified: 	04/22/2020
Description: 	Makes matched crosswalks 
Notes:   	This code uses US Census data from the NBER server. 
		Code uses the ABE algorithm on exact and nysiis names to make linked data. 
*****************************************************************************************/


cap clear all
set more off

*------------------------------------------------------------------------------------------------------------------------------------
* SET UP
*-----------------------------------------------------------------------------------------------------------------------------------
global names exact nysiis   // Pick between nysiis or exact for this macro. Matches will be made either on exact or nysiis names 
global Year1 1850		   // Starting year for matched crosswalk
global Year2 1860         // Ending year for matched crosswalk
global timediff = 10	 // timediff = year2 - year1

*-----------------------------------------------------------------------------------------------------------------------------------
* DIRECTORIES
*-----------------------------------------------------------------------------------------------------------------------------------

*location of complete count census data on nber server 
global datadir "/home/data/census-ipums/v2019/dta/"		

* location of extracted data 
global rawdir_${Year1} "/disk/bulkw/mrashid/matching_project/test/raw_data/${Year1}"	
global rawdir_${Year2} "/disk/bulkw/mrashid/matching_project/test/raw_data/${Year2}"	

*location of cleaned data
global cleandir_${Year1} "/disk/bulkw/mrashid/matching_project/test/abeclean_data/${Year1}"
global cleandir_${Year2} "/disk/bulkw/mrashid/matching_project/test/abeclean_data/${Year2}"

*location of matched data
global matchdir_${Year1}_${Year2}_standard "/disk/bulkw/mrashid/matching_project/test/abe_${names}_standard/${Year1}-${Year2}"
global matchdir_${Year1}_${Year2}_conservative  "/disk/bulkw/mrashid/matching_project/test/abe_${names}_conservative/${Year1}-${Year2}"

*location of crosswalks by birthplace
global crosswalk_${Year1}_${Year2}_standard "/disk/bulkw/mrashid/matching_project/test/crosswalks_by_bpl/abe_${names}_standard_crosswalks/${Year1}-${Year2}"
global crosswalk_${Year1}_${Year2}_conservative "/disk/bulkw/mrashid/matching_project/test/crosswalks_by_bpl/abe_${names}_conservative_crosswalks/${Year1}-${Year2}"

*location of final crosswalks for each year for each method
global final_cross_standard "/disk/bulkw/mrashid/matching_project/test/final_crosswalks/abe_${names}_standard_crosswalks"
global final_cross_conservative "/disk/bulkw/mrashid/matching_project/test/final_crosswalks/abe_${names}_conservative_crosswalks"

*location of master crosswalks for each year for all methods
global master_crosswalk  "/disk/bulkw/mrashid/matching_project/test/master_crosswalks"


*------------------------------------------------------------------------------------------------------------------------------------
* BODY
*-----------------------------------------------------------------------------------------------------------------------------------

*******************************************************************************
/* SECTION 1. Extract by Birthplace
*******************************************************************************/

/* 1.1 - Extract data. This section provides the code used to extract data to be matched
 for each birthplace for each of the two years . */

if 1 == 1 {

	* all possible birthplaces in Census data
	local bpls " 1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54  55 56 90 99 100 105 110 115  120 150 155 160 199 200 210 250 260 299 300 400 401 402 403 404 405 410 411 412 413 414 419 420 421 422 423 424 425 426 429 430 431 432 433 434 435 436 437 438 439 440 450 451 452 453 454 455 456 457 458 459 460 461 462 463 465 499 500 501 502 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 599 600 700 710 800 900 950 999"

	
	local years "${Year1} ${Year2}"

	foreach y in `years' {
		foreach b in `bpls'{
			use if floor(bpl/100)==`b' using $datadir//`y'.dta                // in the original dataset birthplaces are saved as longer detailed codes and we define bpls as the shortened version  
			keep if sex == 1												  // women cannot be linked over decades because historically they change their last names after marriage, so we restrict the sample to men 
			save "${rawdir_`y'}/`b'_bpl_`y'.dta", replace					  // save files by birthplaces in your raw data directory */	
		}
	}

}

*******************************************************************************
/* SECTION 2. STANDARDIZE AND CLEAN DATA
*******************************************************************************/

/* 2.1 - Cleans and standardizes the extracted data using abeclean.ado
         Creates nysiis names or exact names to be used in matching. */

if 1 == 1 {

	/* directory where abe .ado files are kept; required to use the abematch and abeclean commands.
	 Can be found at https://ranabr.people.stanford.edu/matching-codes */

	global MatchingDoFiles "/homes/nber/mrashid/cens1930.work/matching/matching_codes/ABE_algorithm_code/codes"       
	global main = "$MatchingDoFiles"
		cap program drop _all
		adopath+"global" 
	cap ssc install nysiis
	cd $MatchingDoFiles



	local bpls " 1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54  55 56 90 99 100 105 110 115  120 150 155 160 199 200 210 250 260 299 300 400 401 402 403 404 405 410 411 412 413 414 419 420 421 422 423 424 425 426 429 430 431 432 433 434 435 436 437 438 439 440 450 451 452 453 454 455 456 457 458 459 460 461 462 463 465 499 500 501 502 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 599 600 700 710 800 900 950 999"

	
	local years "${Year1} ${Year2}"


	foreach y in `years' {
		foreach b in `bpls'{
			
			capture confirm file "${rawdir_`y'}/`b'_bpl_`y'.dta"

				if !_rc {

				use "${rawdir_`y'}/`b'_bpl_`y'.dta", clear                         // uses the extracted by birthplace 
				
				if _N > 1 {                          							   // some files might only contain one observation with a missing firstname and lastname, restricting to files with more than one obs deals with the error 
					drop if serial == .											   // because we use serial and pernum to identify individuals through the matching process, drop individuals that have a missing serial and pernum 	
					drop if pernum == .

					duplicates report serial pernum								   // there are occasional duplicates in terms of serial and pernum, we drop those duplicates 
					duplicates drop serial pernum, force 
					
					abeclean namefrst namelast, sex(sex) nicknames initial(I)	   // uses abeclean.ado 
					
					gen birthyear = `y' - age									   // creates birthyear by substracting age from census year

					rename namefrst_cleaned namefrst_exact						   //abeclean names cleaned names namefrst_cleaned and namelast_cleaned.
					rename namelast_cleaned namelast_exact
					
					save "${cleandir_`y'}//`b'_abeclean_`y'.dta", replace		   //save cleaned and standardized data by birthplace, ready to be matched
				}
				clear
			}

			else {

				di "`b' does not exist"
			}
		}

	}



}

*******************************************************************************
/* SECTION 3. ABE Matching 
*******************************************************************************/

/* 3.1 - Matches the cleaned data using abematch.ado */

if 1 == 1 {

	/* directory where abe .ado files are kept; required to use the abematch and abeclean commands.
	 Can be found at https://ranabr.people.stanford.edu/matching-codes */

	global MatchingDoFiles "/homes/nber/mrashid/cens1930.work/matching/matching_codes/ABE_algorithm_code/codes"
	global main = "$MatchingDoFiles"
		cap program drop _all
		adopath+"global" 
	cap ssc install nysiis


	cd $MatchingDoFiles



	local bpls " 1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54  55 56 90 99 100 105 110 115  120 150 155 160 199 200 210 250 260 299 300 400 401 402 403 404 405 410 411 412 413 414 419 420 421 422 423 424 425 426 429 430 431 432 433 434 435 436 437 438 439 440 450 451 452 453 454 455 456 457 458 459 460 461 462 463 465 499 500 501 502 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 599 600 700 710 800 900 950 999"


	foreach b in `bpls'{
		di "${Year1}-${Year2}"
		global A "${cleandir_${Year1}}/`b'_abeclean_${Year1}.dta"
		global B "${cleandir_${Year2}}/`b'_abeclean_${Year2}.dta"

		capture confirm file $A
		if !_rc {

			di in red "file A exists"

			capture confirm file $B

			if !_rc {

				di in red "file B exists"

				/* 3.1.1 - Finds ABE Matches, Standard version */

				abematch namefrst_${names} namelast_${names}, file_A($A) file_B($B) timediff($timediff) timevar(age) save("${matchdir_${Year1}_${Year2}_standard}/`b'_abe_${names}_standard_${Year1}_${Year2}.dta") replace id_A(serial pernum) id_B(serial pernum) unique_m(2) unique_f(2) keep_A(namefrst namelast age) keep_B(namefrst namelast age) 

				/* 3.1.2 - Keeps only conservative matches */

				use "${matchdir_${Year1}_${Year2}_standard}/`b'_abe_${names}_standard_${Year1}_${Year2}.dta", clear

				keep if unique_file2 == 1  // keep only names unique within +- 2 years in own data sets
				keep if unique_match2 == 1 // drop people that have another potential match within +-2 years of birth

				save "${matchdir_${Year1}_${Year2}_conservative}/`b'_abe_${names}_conservative_${Year1}_${Year2}.dta", replace	

				cap clear

			}

			else {

				di in red "file B does not exist"
			}

		}

		else {

			di in red "file A does not exist"
		}

	}

}

*******************************************************************************
/* SECTION 4. Making HISTID Crosswalks for each method
*******************************************************************************/

if 1 == 1 {

	/* 4.1 - Merges in histid variable  */

	local methods "standard conservative"

	

	local bpls " 1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54  55 56 90 99 100 105 110 115  120 150 155 160 199 200 210 250 260 299 300 400 401 402 403 404 405 410 411 412 413 414 419 420 421 422 423 424 425 426 429 430 431 432 433 434 435 436 437 438 439 440 450 451 452 453 454 455 456 457 458 459 460 461 462 463 465 499 500 501 502 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 599 600 700 710 800 900 950 999"

	foreach m in `methods' {
		local keepvar "histid"
		foreach b in `bpls'{
			capture confirm file "${matchdir_${Year1}_${Year2}_`m'}/`b'_abe_${names}_`m'_${Year1}_${Year2}.dta"
			if !_rc {
				di in red "`b' file exists"
				use "${matchdir_${Year1}_${Year2}_`m'}/`b'_abe_${names}_`m'_${Year1}_${Year2}.dta", clear
				capture confirm variable serial_A pernum_A serial_B pernum_B
				if !_rc {
			                
			    	di in red "serial pernum exist"
			    	keep serial_A serial_B pernum_A pernum_B 		// drop the other variables
			    	rename serial_A serial 							// _A refers to variables from Year1, _B from Year2
					rename pernum_A pernum

					if _N >= 1 {				//some birthplaces have no matches, avoids those files


						* merge in histid from Year1 clean file using serial and pernum
						merge 1:1 serial pernum using "${cleandir_${Year1}}/`b'_abeclean_${Year1}.dta", keep(1 3) keepusing(`keepvar') nogenerate
						

						foreach var of varlist _all {

								rename `var' `var'_${Year1}		// rename Year1 vars 

						}

						rename serial_B_${Year1} serial 		//use serial_B and pernum_B to merge in histid from Year2
						rename pernum_B_${Year1} pernum
						
						* merge in histid from Year2 clean file using serial and pernum
						merge 1:1 serial pernum using "${cleandir_${Year2}}/`b'_abeclean_${Year2}.dta", keep(1 3) keepusing(`keepvar') nogenerate force

						foreach v of varlist _all {

								if regexm("`v'", "_${Year1}$") == 1 {
								

									di "${Year1} variables"			// do not rename Year1 vars
								}

								else{
									rename `v' `v'_${Year2}			// only rename Year2 vars
								}
							}


						
						keep histid_${Year1} histid_${Year2}		// drop the extra variables

			
						duplicates report histid_${Year1} 	 
						duplicates drop histid_${Year1}, force 	// drop duplicates for histid_year1

						duplicates report histid_${Year2}
						duplicates drop histid_${Year2}, force  // drop duplicates for histid_year2
						
						save "${crosswalk_${Year1}_${Year2}_`m'}/`b'_crosswalk_abe_${names}_`m'_${Year1}_${Year2}.dta", replace
					}
			    }
			    else {
			    	di in red "serial pernum do not exist"
			    }
			}

			else {

				di in red "`b' file does not exist"
			}


		}

		/* 4.2 - Appends the birthplace files */

		cap clear
		foreach b in `bpls'{
			capture confirm file "${crosswalk_${Year1}_${Year2}_`m'}/`b'_crosswalk_abe_${names}_`m'_${Year1}_${Year2}.dta"
			if !_rc {
				di in red "`b' file exits"

				append using "${crosswalk_${Year1}_${Year2}_`m'}/`b'_crosswalk_abe_${names}_`m'_${Year1}_${Year2}.dta"
			}

			else{

				di in red "`b' file does not exist"

			}
		}

		gen link_abe_${names}_`m' = 1		// to tag matches from a certain method
		save "${final_cross_`m'}/crosswalk_abe_${names}_`m'_${Year1}_${Year2}.dta", replace

	}


}

**********************************************************************************
/* SECTION 5. Making Master Crosswalks for each pair of years

** run this section only when all the final crosswalks from all methods are ready
**********************************************************************************/

if 1 == 0 {

** merge on histid_${Year1} and histid_${Year2} (currently 4 files to merge)
	
	* abe_exact_standard file
	use "/disk/bulkw/mrashid/matching_project/final_crosswalks/abe_exact_standard_crosswalks/crosswalk_abe_exact_standard_${Year1}_${Year2}.dta", clear
	* merge in matches from abe_nysiis_standard
	merge 1:1 histid_${Year1} histid_${Year2} using "/disk/bulkw/mrashid/matching_project/test/final_crosswalks/abe_nysiis_standard_crosswalks/crosswalk_abe_nysiis_standard_${Year1}_${Year2}.dta", keep (1 2 3) nogenerate
	* merge in matches from abe_exact_conservative
	merge 1:1 histid_${Year1} histid_${Year2} using "/disk/bulkw/mrashid/matching_project/test/final_crosswalks/abe_exact_conservative_crosswalks/crosswalk_abe_exact_conservative_${Year1}_${Year2}.dta", keep (1 2 3) nogenerate
	* merge in matches from abe_nysiis_consrvative
	merge 1:1 histid_${Year1} histid_${Year2} using "/disk/bulkw/mrashid/matching_project/test/final_crosswalks/abe_nysiis_conservative_crosswalks/crosswalk_abe_nysiis_conservative_${Year1}_${Year2}.dta", keep (1 2 3) nogenerate

	local link_vars "link_abe_nysiis_standard link_abe_nysiis_conservative link_abe_exact_standard link_abe_exact_conservative"

	* label variables that tag matches from different methods

	foreach v in `link_vars' {

		replace `v' = 0 if `v' == .

		if regexm("`v'", "link_abe_nysiis_standard") == 1 {

			label variable `v' "= 1 if match made using ABE on nysiis names"

		}

		if regexm("`v'", "link_abe_nysiis_conservative") == 1 {

			label variable `v' "= 1 if match made using ABE on nysiis names unique +- 2 years"
		}

		if regexm("`v'", "link_abe_exact_standard") == 1 {

			label variable `v' "= 1 if match made using ABE on exact names"

		}

		if regexm("`v'", "link_abe_exact_conservative") == 1 {

			label variable `v' "= 1 if match made using ABE on exact names unique +- 2 years"
		}

	}


	save "$master_crosswalk/crosswalk_${Year1}_${Year2}.dta", replace 		// save master crosswalk in dta format

	export delimited using "$master_crosswalk/crosswalk_${Year1}_${Year2}.csv", replace 	// save in csv format


}




