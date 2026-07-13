/*****************************************************************************
 * PART 1: DATA IMPORT
 *
 * The upstream script imports two workbooks via PROC IMPORT DBMS=XLSX:
 *   FILENAME REFFILE 'data/pa_grad_zip_code.xlsx';  -> WORK.IMPORT
 *   FILENAME REFFILE 'data/income_zip_code.xlsx';   -> WORK.IMPORT1 (SHEET="nation")
 * To keep this bundle self-contained (no external files), the two imports are
 * reproduced here as DATA steps carrying a small inline sample with the same
 * columns PROC IMPORT would have produced. Real PA zip codes, cities, and
 * graduation rates from pa_grad_zip_code.xlsx are used; column headers are
 * given the plain SAS names PROC IMPORT yields under VALIDVARNAME=V7
 * (grad_zip / City / pct_collgrad for graduation; Zip / mean / Median / Pop for
 * income). Everything from PART 2 onward is the upstream analysis, unchanged
 * except for referencing those plain column names.
 *****************************************************************************/

/* Pennsylvania Graduation Data by Zip Code (sample of WORK.IMPORT) */
DATA WORK.IMPORT;
    LENGTH City $32;
    INPUT grad_zip City $ pct_collgrad;
    DATALINES;
19345 Immaculata 1
19009 BrynAthyn 0.8235
19085 Villanova 0.7672
19066 MerionStation 0.7668
19421 Birchrunville 0.7580
16027 Connoquenessing 0.1972
19547 Oley 0.1416
15035 EastMcKeesport 0.1073
16833 Curwensville 0.0740
15469 Normalville 0.0621
16503 Erie 0.0435
15420 Cardale 0
15484 Uledi 0
15429 Denbo 0
;
RUN;

/* Examine structure of graduation data */
PROC CONTENTS DATA=WORK.IMPORT;
RUN;

/* National Income Data by Zip Code (sample of WORK.IMPORT1, SHEET="nation") */
DATA WORK.IMPORT1;
    INPUT Zip mean Median Pop;
    DATALINES;
19345 210500 198000 3200
19009 172400 165000 2600
19085 158900 149500 8100
19066 151200 142000 5400
19421 138700 130000 1900
16027 71200 66500 1600
19547 63800 60000 4200
15035 58100 55000 3100
16833 49500 47000 2400
15469 46200 44500 1200
16503 41800 39500 15600
15420 38900 37000 900
15484 37600 36000 700
;
RUN;

/* Examine structure of income data */
PROC CONTENTS DATA=WORK.IMPORT1;
RUN;

/*****************************************************************************
 * PART 2: DATA CLEANING AND PREPARATION
 *****************************************************************************/

/* Clean Pennsylvania Graduation Data - Standardize Zip Codes */
DATA WORK.IMPORT_c;
    SET WORK.IMPORT;
    LENGTH zip_clean $5;
    /* Format zip codes with leading zeros */
    zip_clean = PUT(grad_zip, z5.);
    DROP grad_zip;
RUN;

PROC PRINT DATA=WORK.IMPORT_c;
RUN;

/* Clean National Income Data - Standardize Zip Codes */
DATA WORK.IMPORT1_c;
    SET WORK.IMPORT1;
    LENGTH zip_clean $5;
    /* Format zip codes with leading zeros */
    zip_clean = PUT(Zip, z5.);
    DROP Zip;
RUN;

PROC PRINT DATA=WORK.IMPORT1_c;
RUN;

/* Sort datasets by zip code for merging */
PROC SORT DATA=WORK.IMPORT_c;
    BY zip_clean;
RUN;

PROC SORT DATA=WORK.IMPORT1_c;
    BY zip_clean;
RUN;

/*****************************************************************************
 * PART 3: DATA MERGING AND PARTITIONING
 *****************************************************************************/

/* Create merged dataset with all zip codes */
DATA merged;
    MERGE WORK.IMPORT_c WORK.IMPORT1_c;
    BY zip_clean;
RUN;

/* Create matched dataset - zip codes present in both datasets */
/* This represents Pennsylvania zip codes with complete data */
DATA match;
    MERGE WORK.IMPORT_c(in=a) WORK.IMPORT1_c(in=b);
    BY zip_clean;
    IF a AND b;  /* Keep only records present in both datasets */
RUN;

PROC PRINT DATA=match;
    TITLE "Matched Zip Codes (Complete Data)";
RUN;

/* Create dataset of zip codes with missing income data */
DATA noinc;
    SET merged;
    IF mean=.;  /* Missing income values */
RUN;

/* Create dataset of zip codes without graduation data */
DATA nograd;
    SET merged;
    IF pct_collgrad=.;  /* Missing graduation data */
RUN;

/*****************************************************************************
 * PART 4: EXPLORATORY DATA ANALYSIS
 *****************************************************************************/

/* Examine zip codes without graduation data */
PROC PRINT DATA=nograd;
    TITLE "Zip Codes Without Graduation Data";
RUN;

/* Examine zip codes without income data */
PROC PRINT DATA=noinc;
    TITLE "Zip Codes Without Income Data";
RUN;

/*****************************************************************************
 * PART 5: STATISTICAL ANALYSIS - GRADUATION RATE QUARTILES
 *****************************************************************************/

/* Calculate quartiles for college graduation rates */
PROC UNIVARIATE DATA=match;
    VAR pct_collgrad;
    TITLE "Distribution Statistics for College Graduation Rates";
RUN;

/*****************************************************************************
 * PART 6: CATEGORICAL ANALYSIS
 *****************************************************************************/

/* Define format for graduation quartile groups */
PROC FORMAT;
    VALUE $CollGradformat
        '1' = 'Low'
        '2' = 'Med-low'
        '3' = 'Med-high'
        '4' = 'High'
    ;
RUN;

/* Create quartile-based graduation groups */
DATA match1;
    SET match;

    /* Assign quartile groups based on graduation rate thresholds */
    IF pct_collgrad > .19150 THEN CollGradGroup='4';           /* Q4: High */
    ELSE IF pct_collgrad > .12375 THEN CollGradGroup='3';      /* Q3: Med-high */
    ELSE IF pct_collgrad > .08400 THEN CollGradGroup='2';      /* Q2: Med-low */
    ELSE IF pct_collgrad <= .08400 THEN CollGradGroup='1';     /* Q1: Low */
    ELSE CollGradGroup='';                                      /* Missing */

    LABEL CollGradGroup = "College Graduation Percentages";
    FORMAT CollGradGroup $CollGradformat.;
RUN;

/* Display categorized data */
PROC PRINT DATA=match1;
    TITLE "Zip Codes with Graduation Quartile Groups";
RUN;

/* Examine structure of categorized dataset */
PROC CONTENTS DATA=match1;
RUN;

/*****************************************************************************
 * PART 7: AGGREGATE STATISTICS BY GRADUATION GROUP
 *****************************************************************************/

/* Calculate mean income and population by graduation quartile */
PROC MEANS DATA=match1 MEAN NOPRINT;
    WHERE CollGradGroup IN ('1', '2', '3', '4');
    CLASS CollGradGroup;
    VAR Median Pop;
    OUTPUT OUT=mean1
        MEAN=meaninc meanpop;
RUN;

/* Display summary statistics */
PROC PRINT DATA=mean1;
    VAR CollGradGroup meaninc meanpop;
    TITLE "Mean Income and Population by Graduation Group";
RUN;

/* Create formatted table of statistics */
PROC TABULATE DATA=match1;
    CLASS CollGradGroup;
    VAR Median Pop;
    TABLE CollGradGroup, (Median Pop)*MEAN;
    TITLE "Summary Statistics: Income and Population by Graduation Group";
RUN;

/*****************************************************************************
 * PART 8: VISUALIZATION
 *****************************************************************************/

/* Scatter plot: Population vs Income by Graduation Group */
PROC SGPLOT DATA=mean1;
    SCATTER x=meanpop y=meaninc;
    XAXIS LABEL="Mean Population";
    YAXIS LABEL="Mean Income";
    TITLE "Relationship Between Population and Income by Graduation Group";
RUN;

/*****************************************************************************
 * END OF ANALYSIS
 *****************************************************************************/
