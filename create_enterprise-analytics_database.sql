-- ==========================================
-- [EN] 1. Create Database
-- [TR] 1. Veri Tabanını Oluşturma
-- ==========================================
CREATE DATABASE enterprise_analytics;
GO

USE enterprise_analytics;
GO

-- ==========================================
-- [EN] 2. MAIN LOOKUP TABLES (DICTIONARY)
-- [TR] 2. ANA LUCKUP (TANIM) TABLOLARI
-- ==========================================

-- [EN] Process Type Definitions
CREATE TABLE ProcessDefinitions (
    ProcessCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    ProcessDescription NVARCHAR(255)
);

-- [EN] Debit Reason Definitions
CREATE TABLE DebitReasonDefinitions (
    DebitReasonCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    DebitReasonDescription NVARCHAR(255)
);

-- [EN] Customer/Account Type Definitions
CREATE TABLE CustomerTypeDefinitions (
    CustomerTypeCode INT PRIMARY KEY,
    LangCode VARCHAR(10),
    CustomerTypeDescription NVARCHAR(255)
);

-- [EN] Source Application Definitions
CREATE TABLE SourceDefinitions (
    ApplicationCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    ApplicationDescription NVARCHAR(255)
);

-- [EN] Sales Personnel Definitions
CREATE TABLE SalesPersonnel (
    RepresentativeID VARCHAR(50) PRIMARY KEY,
    FullName NVARCHAR(150)
);


-- ==========================================
-- [EN] 3. CURRENT ACCOUNT (ACCOUNT) MASTER TABLES
-- [TR] 3. CARİ HESAP (ACCOUNT) ANA TABLOLARI
-- ==========================================

-- [EN] Account Master Records
CREATE TABLE AccountMaster (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    PaymentTerm INT,
    SalesChannelCode VARCHAR(50),
    CustomerTypeCode INT FOREIGN KEY REFERENCES CustomerTypeDefinitions(CustomerTypeCode),
    PRIMARY KEY (AccountTypeCode, AccountID)
);

-- [EN] Account Descriptions (Multi-language support)
CREATE TABLE AccountDescriptions (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    LangCode VARCHAR(10),
    AccountName NVARCHAR(255),
    PRIMARY KEY (AccountTypeCode, AccountID, LangCode),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] Account Addresses (Replaces the mock function)
CREATE TABLE AccountAddresses (
    AddressLinkID INT PRIMARY KEY,
    AddressTypeCode VARCHAR(10),
    AddressTypeDescription NVARCHAR(100),
    Address NVARCHAR(255),
    ZipCode VARCHAR(10),
    DistrictCode VARCHAR(50),
    DistrictDescription NVARCHAR(100),
    CityCode VARCHAR(50),
    CityDescription NVARCHAR(100),
    StateCode VARCHAR(50),
    StateDescription NVARCHAR(100),
    CountryCode VARCHAR(50),
    CountryDescription NVARCHAR(100),
    TaxOfficeCode VARCHAR(50),
    TaxOfficeDescription NVARCHAR(100),
    TaxNumber VARCHAR(50)
);

-- [EN] Account Defaults (Address links, etc.)
CREATE TABLE AccountDefaults (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    AddressLinkID INT FOREIGN KEY REFERENCES AccountAddresses(AddressLinkID),
    PRIMARY KEY (AccountTypeCode, AccountID),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] Account Custom Attributes
CREATE TABLE AccountAttributes (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    Attribute01 VARCHAR(100),
    Attribute02 VARCHAR(100),
    Attribute03 VARCHAR(100),
    Attribute04 VARCHAR(100),
    Attribute05 VARCHAR(100),
    PRIMARY KEY (AccountTypeCode, AccountID),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] Vendor - Customer Relations
CREATE TABLE AccountRelations (
    VendorTypeCode INT,
    VendorCode VARCHAR(50),
    AccountID VARCHAR(50),
    PRIMARY KEY (VendorTypeCode, VendorCode, AccountID)
);

-- [EN] Account - Sales Representative Assignments
CREATE TABLE SalespersonAssignments (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    RepresentativeID VARCHAR(50) FOREIGN KEY REFERENCES SalesPersonnel(RepresentativeID),
    StartDate DATE,
    PRIMARY KEY (AccountTypeCode, AccountID, RepresentativeID),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] Average Payment Days (Replaces the mock function)
CREATE TABLE AveragePaymentDays (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    AverageDay_Debit INT,
    AverageDueDate_Debit DATE,
    PRIMARY KEY (AccountTypeCode, AccountID),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);


-- ==========================================
-- [EN] 4. TRANSACTION AND INVOICE TABLES
-- [TR] 4. HAREKET VE FİŞ TABLOLARI
-- ==========================================

-- [EN] Invoice Headers
CREATE TABLE InvoiceHeaders (
    InvoiceHeaderID INT PRIMARY KEY,
    ProcessCode VARCHAR(50) FOREIGN KEY REFERENCES ProcessDefinitions(ProcessCode),
    InvoiceDate DATE,
    ProcessDescription NVARCHAR(255)
);

-- [EN] Account Transactions (Debit/Credit Details)
CREATE TABLE AccountTransactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    CompanyCode VARCHAR(10),
    OfficeCode VARCHAR(10),
    TransactionDate DATE,
    ReferenceNumber VARCHAR(50),
    RefNumber VARCHAR(50),
    PaymentDueDate DATE,
    ApplicationID INT FOREIGN KEY REFERENCES InvoiceHeaders(InvoiceHeaderID),
    ApplicationCode VARCHAR(50) FOREIGN KEY REFERENCES SourceDefinitions(ApplicationCode),
    DebitReasonCode VARCHAR(50) FOREIGN KEY REFERENCES DebitReasonDefinitions(DebitReasonCode),
    LineDescription NVARCHAR(255),
    AmountDebit DECIMAL(18, 2),
    AmountCredit DECIMAL(18, 2),
    CurrentBalance DECIMAL(18, 2),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] General Ledger (Summary of all account transactions)
CREATE TABLE GeneralLedger (
    LedgerID INT IDENTITY(1,1) PRIMARY KEY,
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    AmountDebit DECIMAL(18, 2),
    AmountCredit DECIMAL(18, 2),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);

-- [EN] Payments (Explicit payment records)
CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    PaymentDate DATE,
    Amount DECIMAL(18, 2),
    FOREIGN KEY (AccountTypeCode, AccountID) REFERENCES AccountMaster(AccountTypeCode, AccountID)
);
GO
