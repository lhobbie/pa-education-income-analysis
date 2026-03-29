
/*****************************************************************************
 * PART 1: DATA IMPORT
 *****************************************************************************/

/* Import Pennsylvania Graduation Data by Zip Code */
FILENAME REFFILE 'data/pa_grad_zip_code.xlsx';
PROC IMPORT DATAFILE=REFFILE
    DBMS=XLSX
    OUT=WORK.IMPORT
    REPLACE;
    GETNAMES=YES;
RUN;

/* Examine structure of graduation data */
PROC CONTENTS DATA=WORK.IMPORT; 
RUN;

/* Import National Income Data by Zip Code */
FILENAME REFFILE 'data/income_zip_code.xlsx';
PROC IMPORT DATAFILE=REFFILE
    DBMS=XLSX
    OUT=WORK.IMPORT1
    REPLACE;
    SHEET="nation";
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
    zip_clean = PUT('Zip Code'n, z5.);
    DROP 'Zip Code'n;
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
    IF percent_collgrad='';  /* Missing graduation data */
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
    VAR '% College Grad.'n;
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
    IF '% College Grad.'n > .19150 THEN CollGradGroup='4';           /* Q4: High */
    ELSE IF '% College Grad.'n > .12375 THEN CollGradGroup='3';      /* Q3: Med-high */
    ELSE IF '% College Grad.'n > .08400 THEN CollGradGroup='2';      /* Q2: Med-low */
    ELSE IF '% College Grad.'n <= .08400 THEN CollGradGroup='1';     /* Q1: Low */
    ELSE CollGradGroup='';                                            /* Missing */
    
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
