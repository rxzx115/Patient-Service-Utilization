# Patient-Service-Utilization

## Objective
- To understand the demographic factors (e.g., age group, gender) and healthcare claims data (e.g., billed amount, paid amount, denied amount, claim status) that are related to service utilization to identify opportunities for cost savings

## Guiding Questions
- Which specific services, when denied, result in the highest total financial loss (Denied Amount)? What are the most common reasons for these denials?
- For high-volume services, which payers consistently provide the lowest average reimbursement (Paid Amount) relative to the hospital's internal cost (Internal Cost)?
- Which high-cost services (Billed Amount or Internal Cost) show unusually high utilization patterns within specific patient demographic groups (e.g., an age group or gender)?
- What are the overall trends in service utilization (e.g., total volume, total billed amount, total denied amount) month-over-month?
- Which services show the largest disparities between the Billed Amount and the Paid Amount (i.e., high write-offs or adjustments)?

## Data Collection
To retrieve data from Kaggle

## Data Cleaning
- Investigated different date data formats for data quality
- Standardized incomplete data for consistent categorical fields
- Reviewed outliers to avoid errors or unusual events

## Data Exploration
- Exploratory data analysis was performed in SQL to answer the guiding questions
- Refer to the separate .sql file for further details

## Insights and Recommendations
1. High Financial Loss from "MissingAuth" Denials.
    - Implement a mandatory pre-authorization verification step in the scheduling process for all high-cost procedures before service delivery.
2. "Comprehensive Metabolic Panel" yields the lowest profit margin per service.
    - Review the internal costs associated with the "Comprehensive Metabolic Panel" (e.g., reagents, labor, equipment depreciation) to identify opportunities for efficiency improvements and cost reduction.
3. Declining Total Paid Amount Despite Stable Service Volume and Billed Amount. 
    - Implement an aggressive denial management and appeals process, including proactively tracking denied claims, assigning clear responsibilities for appeals, and dedicating resources to efficiently appeal claims.
