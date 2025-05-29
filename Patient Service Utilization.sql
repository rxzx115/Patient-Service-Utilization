-- Use database
USE projects


-- Create Patients Table
CREATE TABLE Patients (
    PatientID VARCHAR(10) PRIMARY KEY,
    Gender VARCHAR(10),
    AgeGroup VARCHAR(20),
    ZipCode VARCHAR(10),
    PrimaryDiagnosisGroup VARCHAR(50)
)


-- Drop table
-- DROP TABLE Patients


-- Load the data
BULK INSERT Patients
FROM 'C:\Users\Ryan Zheng\Downloads\patients.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
)


-- Select the data
SELECT *
FROM Patients


-- Create Services_Provided Table
CREATE TABLE Services_Provided (
    ServiceID VARCHAR(10) PRIMARY KEY,
    ServiceCode VARCHAR(20),
    ServiceDescription VARCHAR(100),
    ServiceType VARCHAR(50),
    IsElective BIT
)


-- Drop table
-- DROP TABLE Services_Provided


-- Load the data
BULK INSERT Services_Provided
FROM 'C:\Users\Ryan Zheng\Downloads\services_provided.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
)


-- Select the data
SELECT *
FROM Services_Provided


-- Create Payer_Claims Table
CREATE TABLE Payer_Claims (
    ClaimID VARCHAR(20),
    ClaimLineID INT,
    PatientID VARCHAR(10),
    ServiceID VARCHAR(10),
    ClaimDate DATE,
    Payer VARCHAR(50),
    BilledAmount DECIMAL(10, 2),
    AllowedAmount DECIMAL(10, 2),
    PaidAmount DECIMAL(10, 2),
    DeniedAmount DECIMAL(10, 2),
    ClaimStatus VARCHAR(50),
    ReasonForDenial VARCHAR(100),
    PRIMARY KEY (ClaimID, ClaimLineID)
)


-- Drop table
-- DROP TABLE Payer_Claims


-- Load the data
BULK INSERT Payer_Claims
FROM 'C:\Users\Ryan Zheng\Downloads\payer_claims.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
)


-- Select the data
SELECT *
FROM Payer_Claims


-- Create Service_Cost_Catalog Table
CREATE TABLE Service_Cost_Catalog (
    ServiceCode VARCHAR(20) PRIMARY KEY,
    InternalCost DECIMAL(10, 2)
)


-- Drop table
-- DROP TABLE Service_Cost_Catalog


-- Load the data
BULK INSERT Service_Cost_Catalog
FROM 'C:\Users\Ryan Zheng\Downloads\service_cost_catalog.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
)


-- Select the data
SELECT *
FROM Service_Cost_Catalog


-- Which specific services, when denied, result in the highest total financial loss (Denied Amount)? What are the most common reasons for these denials?
SELECT
    sp.ServiceDescription,
    pc.ReasonForDenial,
    SUM(pc.DeniedAmount) AS TotalFinancialLoss,
    COUNT(pc.ClaimLineID) AS NumberOfDeniedOccurrences
FROM Payer_Claims pc
JOIN Services_Provided sp ON pc.ServiceID = sp.ServiceID
WHERE pc.ClaimStatus = 'Denied'
GROUP BY sp.ServiceDescription, pc.ReasonForDenial
ORDER BY TotalFinancialLoss DESC


-- For high-volume services, which payers consistently provide the lowest average reimbursement (Paid Amount) relative to the hospital's internal cost (Internal Cost)?
WITH ServiceProfitMargins AS (
    SELECT
        sp.ServiceDescription,
        pc.Payer,
        COUNT(pc.ClaimLineID) AS ServiceOccurrences,
        SUM(pc.PaidAmount) AS TotalPaid,
        SUM(scc.InternalCost) AS TotalInternalCost,
        SUM(pc.PaidAmount - scc.InternalCost) AS TotalProfitMargin
    FROM Payer_Claims pc
    JOIN Services_Provided sp ON pc.ServiceID = sp.ServiceID
    JOIN Service_Cost_Catalog scc ON sp.ServiceCode = scc.ServiceCode
    WHERE pc.ClaimStatus = 'Approved' 
    GROUP BY sp.ServiceDescription, pc.Payer
    HAVING COUNT(pc.ClaimLineID) > 1
)
SELECT
    ServiceDescription,
    Payer,
    ServiceOccurrences,
    TotalPaid,
    TotalInternalCost,
    TotalProfitMargin,
    (TotalProfitMargin * 1.0 / ServiceOccurrences) AS AvgProfitMarginPerService
FROM ServiceProfitMargins
ORDER BY ServiceDescription, AvgProfitMarginPerService ASC


-- Which high-cost services (Billed Amount or Internal Cost) show unusually high utilization patterns within specific patient demographic groups (e.g., an age group or gender)?
SELECT
    p.AgeGroup,
    p.Gender,
    sp.ServiceDescription,
    COUNT(pc.ClaimLineID) AS TotalOccurrences,
    SUM(pc.BilledAmount) AS TotalBilledAmount,
    SUM(scc.InternalCost) AS TotalInternalCost_ForApprovedClaims
FROM Payer_Claims pc
JOIN Patients p ON pc.PatientID = p.PatientID
JOIN Services_Provided sp ON pc.ServiceID = sp.ServiceID
LEFT JOIN Service_Cost_Catalog scc ON sp.ServiceCode = scc.ServiceCode AND pc.ClaimStatus = 'Approved'
WHERE pc.BilledAmount > 500 OR scc.InternalCost > 200 
GROUP BY p.AgeGroup, p.Gender, sp.ServiceDescription
ORDER BY TotalBilledAmount DESC, TotalInternalCost_ForApprovedClaims DESC


-- What are the overall trends in service utilization (e.g., total volume, total billed amount, total denied amount) month-over-month?
SELECT
    FORMAT(pc.ClaimDate, 'yyyy-MM') AS ClaimMonth,
    COUNT(pc.ClaimLineID) AS TotalServiceVolume,
    SUM(pc.BilledAmount) AS TotalBilledAmount,
    SUM(pc.PaidAmount) AS TotalPaidAmount,
    SUM(pc.DeniedAmount) AS TotalDeniedAmount
FROM Payer_Claims pc
GROUP BY FORMAT(pc.ClaimDate, 'yyyy-MM')
ORDER BY ClaimMonth


-- Which services show the largest disparities between the Billed Amount and the Paid Amount (i.e., high write-offs or adjustments)?
SELECT
    sp.ServiceDescription,
    AVG(pc.BilledAmount) AS AvgBilledAmount,
    AVG(pc.PaidAmount) AS AvgPaidAmount,
    AVG(pc.BilledAmount - pc.PaidAmount) AS AvgDisparity,
    FORMAT(
        AVG(pc.BilledAmount - pc.PaidAmount) * 100.0 / AVG(pc.BilledAmount),
        'N2'
    ) + '%' AS AvgDisparityPercentage
FROM Payer_Claims pc
JOIN Services_Provided sp ON pc.ServiceID = sp.ServiceID
WHERE pc.ClaimStatus = 'Approved' 
GROUP BY sp.ServiceDescription
HAVING AVG(pc.BilledAmount) > 0
ORDER BY AvgDisparity DESC
