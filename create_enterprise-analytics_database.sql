-- ==========================================
-- [EN] 1. Create Database
-- [TR] 1. Veri Tabanýný Oluþturma
-- ==========================================
CREATE DATABASE enterprise_analytics;
GO

USE enterprise_analytics;
GO

-- ==========================================
-- [EN] 2. MAIN LOOKUP TABLES
-- [TR] 2. ANA LUCKUP (TANIM) TABLOLARI
-- ==========================================

-- [EN] Process Type Definitions
-- [TR] Ýþlem Tipi Tanýmlarý
CREATE TABLE ProcessDefinitions (
    ProcessCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    ProcessDescription NVARCHAR(255)
);

-- [EN] Debit Reason Definitions
-- [TR] Borç Nedeni Tanýmlarý
CREATE TABLE DebitReasonDefinitions (
    DebitReasonCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    DebitReasonDescription NVARCHAR(255)
);

-- [EN] Customer/Account Type Definitions
-- [TR] Müþteri/Cari Tip Tanýmlarý
CREATE TABLE CustomerTypeDefinitions (
    CustomerTypeCode INT PRIMARY KEY,
    LangCode VARCHAR(10),
    CustomerTypeDescription NVARCHAR(255)
);

-- [EN] Source Application Definitions
-- [TR] Kaynak/Uygulama Tanýmlarý
CREATE TABLE SourceDefinitions (
    ApplicationCode VARCHAR(50) PRIMARY KEY,
    LangCode VARCHAR(10),
    ApplicationDescription NVARCHAR(255)
);

-- [EN] Sales Personnel Definitions
-- [TR] Satýþ Personeli Tanýmlarý
CREATE TABLE SalesPersonnel (
    RepresentativeID VARCHAR(50) PRIMARY KEY,
    FullName NVARCHAR(150)
);


-- ==========================================
-- [EN] 3. CURRENT ACCOUNT (ACCOUNT) MASTER TABLES
-- [TR] 3. CARÝ HESAP (ACCOUNT) ANA TABLOLARI
-- ==========================================

-- [EN] Account Master Records
-- [TR] Cari Hesap Ana Kayýtlarý
CREATE TABLE AccountMaster (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    PaymentTerm INT,
    SalesChannelCode VARCHAR(50),
    CustomerTypeCode INT,
    PRIMARY KEY (AccountTypeCode, AccountID)
);

-- [EN] Account Descriptions (Multi-language support)
-- [TR] Cari Hesap Açýklamalarý (Dil Destekli)
CREATE TABLE AccountDescriptions (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    LangCode VARCHAR(10),
    AccountName NVARCHAR(255),
    PRIMARY KEY (AccountTypeCode, AccountID, LangCode)
);

-- [EN] Account Defaults (Address links, etc.)
-- [TR] Cari Hesap Varsayýlanlarý (Adres Baðlantýsý vb.)
CREATE TABLE AccountDefaults (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    AddressLinkID INT,
    PRIMARY KEY (AccountTypeCode, AccountID)
);

-- [EN] Account Custom Attributes
-- [TR] Cari Hesap Özel Nitelikleri (Attributes)
CREATE TABLE AccountAttributes (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    Attribute01 VARCHAR(100),
    Attribute02 VARCHAR(100),
    Attribute03 VARCHAR(100),
    Attribute04 VARCHAR(100),
    Attribute05 VARCHAR(100),
    PRIMARY KEY (AccountTypeCode, AccountID)
);

-- [EN] Vendor - Customer Relations
-- [TR] Tedarikçi - Müþteri Ýliþkileri
CREATE TABLE AccountRelations (
    VendorTypeCode INT,
    VendorCode VARCHAR(50),
    AccountID VARCHAR(50),
    PRIMARY KEY (VendorTypeCode, VendorCode, AccountID)
);

-- [EN] Account - Sales Representative Assignments
-- [TR] Cari Hesap - Satýþ Temsilcisi Atamalarý
CREATE TABLE SalespersonAssignments (
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    RepresentativeID VARCHAR(50),
    StartDate DATE,
    PRIMARY KEY (AccountTypeCode, AccountID, RepresentativeID)
);


-- ==========================================
-- [EN] 4. TRANSACTION AND INVOICE TABLES
-- [TR] 4. HAREKET VE FÝÞ TABLOLARI
-- ==========================================

-- [EN] Account Transactions (Debit/Credit Details)
-- [TR] Cari Hesap Hareketleri (Borç/Alacak Detaylarý)
CREATE TABLE AccountTransactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    CompanyCode VARCHAR(10),
    OfficeCode VARCHAR(10),
    TransactionDate DATE,
    ReferenceNumber VARCHAR(50),
    RefNumber VARCHAR(50), -- [EN] Alternative reference / [TR] Alternatif referans
    PaymentDueDate DATE,
    ApplicationID INT,
    ApplicationCode VARCHAR(50),
    DebitReasonCode VARCHAR(50),
    LineDescription NVARCHAR(255),
    AmountDebit DECIMAL(18, 2),
    AmountCredit DECIMAL(18, 2),
    CurrentBalance DECIMAL(18, 2)
);

-- [EN] Invoice Headers
-- [TR] Fatura Üst Bilgileri
CREATE TABLE InvoiceHeaders (
    InvoiceHeaderID INT PRIMARY KEY,
    ProcessCode VARCHAR(50),
    ProcessDescription NVARCHAR(255)
);

-- [EN] General Ledger (Summary of all account transactions)
-- [TR] Genel Defter (Tüm Cari Hareket Özetleri)
CREATE TABLE GeneralLedger (
    LedgerID INT IDENTITY(1,1) PRIMARY KEY,
    AccountTypeCode INT,
    AccountID VARCHAR(50),
    AmountDebit DECIMAL(18, 2),
    AmountCredit DECIMAL(18, 2)
);
GO

-- ==========================================
-- [EN] 5. TABLE-VALUED FUNCTIONS
-- [TR] 5. FONKSÝYONLAR (TABLE-VALUED FUNCTIONS)
-- ==========================================
-- [EN] Note: Empty/mock schemas are created here so the code compiles without errors.
-- [TR] Not: Kodun hata vermeden derlenebilmesi için boþ/örnek þemalar oluþturulmuþtur.

-- [EN] Average Payment Days Calculation Function Mock
-- [TR] Ortalama Vade Hesaplama Fonksiyonu Mock'u
CREATE FUNCTION GetAveragePaymentDays (@BalanceDate DATE)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        CAST(3 AS INT) AS AccountTypeCode, 
        CAST('DUMMY' AS VARCHAR(50)) AS AccountID, 
        CAST(0 AS INT) AS AverageDay_Debit, 
        CAST('1900-01-01' AS DATE) AS AverageDueDate_Debit
    WHERE 1 = 0 -- [EN] Returns empty, used only for schema creation / [TR] Boþ döner, sadece þema yaratmak içindir
);
GO

-- [EN] Address Information Retrieval Function Mock
-- [TR] Adres Bilgilerini Getiren Fonksiyon Mock'u
CREATE FUNCTION GetAccountAddresses (@LangCode VARCHAR(10))
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        CAST(1 AS INT) AS AddressLinkID,
        CAST('1' AS VARCHAR(10)) AS AddressTypeCode,
        CAST('Mock Address Type' AS NVARCHAR(100)) AS AddressTypeDescription,
        CAST('Mock Address Detail' AS NVARCHAR(255)) AS Address,
        CAST('00000' AS VARCHAR(10)) AS ZipCode,
        CAST('Mock District' AS VARCHAR(50)) AS DistrictCode,
        CAST('Mock District Desc' AS NVARCHAR(100)) AS DistrictDescription,
        CAST('Mock City' AS VARCHAR(50)) AS CityCode,
        CAST('Mock City Desc' AS NVARCHAR(100)) AS CityDescription,
        CAST('Mock State' AS VARCHAR(50)) AS StateCode,
        CAST('Mock State Desc' AS NVARCHAR(100)) AS StateDescription,
        CAST('Mock Country' AS VARCHAR(50)) AS CountryCode,
        CAST('Mock Country Desc' AS NVARCHAR(100)) AS CountryDescription,
        CAST('Mock Tax Office' AS VARCHAR(50)) AS TaxOfficeCode,
        CAST('Mock Tax Office Desc' AS NVARCHAR(100)) AS TaxOfficeDescription,
        CAST('1234567890' AS VARCHAR(50)) AS TaxNumber
    WHERE 1 = 0 -- [EN] Returns empty, used only for schema creation / [TR] Boþ döner, sadece þema yaratmak içindir
);
GO