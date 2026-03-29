# Pennsylvania Education and Income Analysis

SAS analysis examining the relationship between college graduation rates and median household income across 1,690+ Pennsylvania zip codes.

## Key Findings

- **Exponential Relationship:** Higher graduation rates correlated with disproportionately higher income levels
- **Complete Coverage:** Successfully matched 1,690 PA zip codes between datasets
- **Quartile Progression:** Each graduation quartile showed measurable income increases (Low → Med-Low → Med-High → High)
- **Geographic Clustering:** High-education areas showed elevated income and population density

## Tools Used

**SAS:** PROC IMPORT, PROC MEANS, PROC UNIVARIATE, PROC SGPLOT, PROC TABULATE, Data Step Programming

## Project Structure
```
pa-education-income-analysis/
├── README.md
├── pa_education_analysis.sas
└── data/
    ├── pa_grad_zip_code.xlsx
    └── income_zip_code.xlsx
```

## How to Run

1. Place data files in `data/` folder
2. Open `pa_education_analysis.sas` in SAS (v9.4+)
3. Run the program 

## Analysis Overview

1. Import and clean PA graduation data and national income data
2. Merge datasets by standardized zip codes
3. Create quartile-based graduation groups
4. Calculate aggregate statistics by group
5. Visualize population vs income relationship

## Author

**Luke Hobbie**  
Villanova University | 3.92 GPA | Dean's List All Semesters  
[LinkedIn](https://www.linkedin.com/in/luke-hobbie/) | [Portfolio](https://lhobbie.github.io/portfolio/)

## Related Projects

- [Global Happiness Index Analysis (R)](https://github.com/lhobbs2023-wq/world-happiness-analysis)
