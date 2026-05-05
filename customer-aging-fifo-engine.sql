/*
====================================================================================================
Project: ERP Account Balance & Partial Invoice Closure Report
Description: 
    This query calculates the open balances of customer/vendor accounts up to a specified date.
    It uses Window Functions to calculate a running balance from the newest invoice to the oldest,
    and accurately identifies the remaining open amount of partially paid invoices.
====================================================================================================
*/

DECLARE @BalanceDate DATE = '20260101';

SELECT 
    *,
    -- Kısmi kapanan faturanın sadece açıkta kalan tutarını hesaplar
    -- Calculates the remaining open amount for partially closed invoices
    RemainingInvoiceBalance = CASE 
                                WHEN RunningBalance <= TotalBalance THEN CurrentBalance 
                                ELSE TotalBalance - (RunningBalance - CurrentBalance) 
                              END
FROM (
    SELECT 
        *,
        -- Müşteri/Hesap bazında, en yeni faturadan eskiye doğru kümülatif bakiye toplamı hesaplanır
        -- Calculates running balance partitioned by account, ordered from newest to oldest document
        RunningBalance = SUM(CurrentBalance) OVER (
            PARTITION BY CustomerCode 
            ORDER BY TransactionDate DESC, ReferenceNumber DESC
        )
    FROM (
        -- =========================================================================================
        -- BÖLÜM 1: STANDART CARİ HESAPLAR (AccountTypeCode = 3)
        -- SECTION 1: STANDARD CURRENT ACCOUNTS (AccountTypeCode = 3)
        -- =========================================================================================
        SELECT 
              CustomerCode                  = AccountTransactions.AccountID
            , CustomerDescription           = ISNULL((SELECT AccountName FROM AccountDescriptions WITH(NOLOCK) WHERE AccountDescriptions.AccountTypeCode = AccountMaster.AccountTypeCode AND AccountDescriptions.AccountID = AccountMaster.AccountID AND AccountDescriptions.LangCode = 'TR'), '')
            , CompanyCode                   = AccountTransactions.CompanyCode
            , OfficeCode                    = AccountTransactions.OfficeCode
            , TransactionDate               = AccountTransactions.TransactionDate
            , ReferenceNumber               = AccountTransactions.ReferenceNumber
            , RefNumber                     = AccountTransactions.RefNumber
            , PaymentDueDate                = AccountTransactions.PaymentDueDate
            , DaysOverdue                   = DATEDIFF(DAY, @BalanceDate, AccountTransactions.PaymentDueDate)
            
            -- Dinamik Açıklama Oluşturma (İşlem Tipi + Borç Nedeni + Satır Açıklaması)
            -- Dynamic Description Generation (Process Type + Debit Reason + Line Description)
            , Description                   = ISNULL((SELECT ProcessDefinitions.ProcessDescription FROM InvoiceHeaders WITH(NOLOCK) LEFT OUTER JOIN ProcessDefinitions ON ProcessDefinitions.ProcessCode = InvoiceHeaders.ProcessCode AND ProcessDefinitions.LangCode = 'TR' WHERE InvoiceHeaders.InvoiceHeaderID = AccountTransactions.ApplicationID AND AccountTransactions.ApplicationCode = 'Invoi'), '')
                                              + CASE WHEN AccountTransactions.ApplicationCode <> 'Invoi' OR AccountTransactions.DebitReasonCode = '' THEN '' ELSE ' - ' END 
                                              + ISNULL((SELECT DebitReasonDescription FROM DebitReasonDefinitions WITH(NOLOCK) WHERE DebitReasonDefinitions.DebitReasonCode = AccountTransactions.DebitReasonCode AND DebitReasonDefinitions.LangCode = 'TR'), '')
                                              + CASE WHEN AccountTransactions.LineDescription = '' THEN '' ELSE ' - ' END 
                                              + AccountTransactions.LineDescription
          
            , AmountDebit                   = AccountTransactions.AmountDebit
            , CurrentBalance                = AccountTransactions.CurrentBalance
            
            -- Toplam Bakiye (Genel Defterden Gelen Net Bakiye)
            -- Total Balance (Net Balance from General Ledger)
            , TotalBalance                  = ISNULL(Balance.AmountDebit, 0) - ISNULL(Balance.AmountCredit, 0)

            , PaymentTerm                   = AccountMaster.PaymentTerm
            , AverageDay_Debit              = ISNULL(AvgPaymentDays.AverageDay_Debit, '')
            , AverageDueDate_Debit          = ISNULL(AvgPaymentDays.AverageDueDate_Debit, '')
             
            , SalesChannelCode              = AccountMaster.SalesChannelCode 
            , SalespersonCode               = ISNULL(SalesPersonnel.RepresentativeID, '')
            , SalespersonFullName           = ISNULL(SalesPersonnel.FullName, '')
            , CustomerTypeCode              = AccountMaster.CustomerTypeCode
            , CustomerTypeDescription       = ISNULL((SELECT CustomerTypeDescription FROM CustomerTypeDefinitions WITH(NOLOCK) WHERE CustomerTypeDefinitions.CustomerTypeCode = AccountMaster.CustomerTypeCode AND CustomerTypeDefinitions.LangCode = 'TR'), '')
             
            , AddressTypeCode               = ISNULL(AccountAddresses.AddressTypeCode, '')
            , AddressTypeDescription        = ISNULL(AccountAddresses.AddressTypeDescription, '')
            , Address                       = ISNULL(AccountAddresses.Address, '')
            , ZipCode                       = ISNULL(AccountAddresses.ZipCode, '')
            , DistrictCode                  = ISNULL(AccountAddresses.DistrictCode, '')
            , DistrictDescription           = ISNULL(AccountAddresses.DistrictDescription, '')
            , CityCode                      = ISNULL(AccountAddresses.CityCode, '')
            , CityDescription               = ISNULL(AccountAddresses.CityDescription, '')
            , StateCode                     = ISNULL(AccountAddresses.StateCode, '')
            , StateDescription              = ISNULL(AccountAddresses.StateDescription, '')
            , CountryCode                   = ISNULL(AccountAddresses.CountryCode, '')
            , CountryDescription            = ISNULL(AccountAddresses.CountryDescription, '')
            , TaxOfficeCode                 = ISNULL(AccountAddresses.TaxOfficeCode, '')
            , TaxOfficeDescription          = ISNULL(AccountAddresses.TaxOfficeDescription, '')
            , TaxNumber                     = ISNULL(AccountAddresses.TaxNumber, '')

            , ATAtt01 = AccountAttributes.Attribute01
            , ATAtt02 = AccountAttributes.Attribute02
            , ATAtt03 = AccountAttributes.Attribute03
            , ATAtt04 = AccountAttributes.Attribute04
            , ATAtt05 = AccountAttributes.Attribute05

            , ApplicationCode               = AccountTransactions.ApplicationCode
            , ApplicationDescription        = ISNULL((SELECT ApplicationDescription FROM SourceDefinitions WITH(NOLOCK) WHERE SourceDefinitions.ApplicationCode = AccountTransactions.ApplicationCode AND SourceDefinitions.LangCode = 'TR'), '')
             
        FROM AccountTransactions 
        INNER JOIN AccountMaster WITH(NOLOCK) 
            ON AccountMaster.AccountTypeCode = 3 
            AND AccountTransactions.AccountID = AccountMaster.AccountID
        LEFT OUTER JOIN AccountAttributes WITH(NOLOCK)
            ON AccountAttributes.AccountTypeCode = AccountMaster.AccountTypeCode 
            AND AccountAttributes.AccountID = AccountMaster.AccountID
            
        -- Vade Tablosu Bağlantısı (Fonksiyondan Tabloya Çevrildi)
        -- Average Payment Days Table Join (Converted from Function to Table)
        LEFT OUTER JOIN AveragePaymentDays AS AvgPaymentDays WITH(NOLOCK)
            ON AccountMaster.AccountTypeCode = AvgPaymentDays.AccountTypeCode
            AND AccountMaster.AccountID = AvgPaymentDays.AccountID
            
        -- Adres Bağlantıları (Fonksiyondan Tabloya Çevrildi)
        -- Address Joins (Converted from Function to Table)
        LEFT OUTER JOIN AccountDefaults WITH(NOLOCK) 
            ON AccountDefaults.AccountTypeCode = AccountMaster.AccountTypeCode
            AND AccountDefaults.AccountID = AccountMaster.AccountID 
        LEFT OUTER JOIN AccountAddresses WITH(NOLOCK)
            ON AccountAddresses.AddressLinkID = AccountDefaults.AddressLinkID

        -- Satış Temsilcisi Bağlantısı (En son atanan temsilciyi alır)
        -- Sales Representative Join (Fetches the most recently assigned representative)
        LEFT OUTER JOIN (
            SELECT 
                AccountTypeCode, 
                AccountID, 
                SalespersonAssignments.RepresentativeID, 
                FullName, 
                SortOrder = ROW_NUMBER() OVER (PARTITION BY AccountTypeCode, AccountID ORDER BY StartDate DESC)
            FROM SalespersonAssignments WITH(NOLOCK)
            INNER JOIN SalesPersonnel WITH(NOLOCK) ON SalesPersonnel.RepresentativeID = SalespersonAssignments.RepresentativeID
        ) AS SalesPersonnel
            ON SalesPersonnel.AccountTypeCode = AccountMaster.AccountTypeCode
            AND SalesPersonnel.AccountID = AccountMaster.AccountID
            AND SalesPersonnel.SortOrder = 1
            
        -- Genel Defter Bakiye Hesaplaması
        -- General Ledger Balance Calculation
        LEFT OUTER JOIN (
            SELECT CustomerCode, AmountDebit = SUM(AmountDebit), AmountCredit = SUM(AmountCredit)
            FROM (
                SELECT CustomerCode = AccountID, AmountDebit, AmountCredit 
                FROM GeneralLedger WHERE AccountTypeCode = 3 
                UNION ALL
                SELECT CustomerCode = AccountRelations.AccountID, AmountDebit, AmountCredit 
                FROM GeneralLedger  
                INNER JOIN AccountRelations WITH(NOLOCK)
                    ON AccountRelations.VendorTypeCode = GeneralLedger.AccountTypeCode
                    AND AccountRelations.VendorCode = GeneralLedger.AccountID
                WHERE GeneralLedger.AccountTypeCode = 1 
            ) AS AccountBooks
            GROUP BY CustomerCode
        ) AS Balance ON Balance.CustomerCode = AccountMaster.AccountID
            
        WHERE AccountTransactions.AccountTypeCode = 3
          AND (ISNULL(Balance.AmountDebit, 0) - ISNULL(Balance.AmountCredit, 0)) > 0
          AND AccountMaster.AccountID <> ''
            
        UNION ALL

        -- =========================================================================================
        -- BÖLÜM 2: İLİŞKİLİ HESAPLAR / TEDARİKÇİ-MÜŞTERİ ORTAK HESAPLARI
        -- SECTION 2: RELATED ACCOUNTS / VENDOR-CUSTOMER MUTUAL ACCOUNTS
        -- =========================================================================================
        SELECT 
              CustomerCode                  = AccountRelations.AccountID
            , CustomerDescription           = ISNULL((SELECT AccountName FROM AccountDescriptions WITH(NOLOCK) WHERE AccountDescriptions.AccountTypeCode = AccountMaster.AccountTypeCode AND AccountDescriptions.AccountID = AccountMaster.AccountID AND AccountDescriptions.LangCode = 'TR'), '')
            , CompanyCode                   = AccountTransactions.CompanyCode
            , OfficeCode                    = AccountTransactions.OfficeCode
            , TransactionDate               = AccountTransactions.TransactionDate
            , ReferenceNumber               = AccountTransactions.ReferenceNumber
            , RefNumber                     = AccountTransactions.RefNumber
            , PaymentDueDate                = AccountTransactions.PaymentDueDate
            , DaysOverdue                   = DATEDIFF(DAY, @BalanceDate, AccountTransactions.PaymentDueDate)
            
            -- Dinamik Açıklama Oluşturma
            -- Dynamic Description Generation
            , Description                   = ISNULL((SELECT ProcessDefinitions.ProcessDescription FROM InvoiceHeaders WITH(NOLOCK) LEFT OUTER JOIN ProcessDefinitions ON ProcessDefinitions.ProcessCode = InvoiceHeaders.ProcessCode AND ProcessDefinitions.LangCode = 'TR' WHERE InvoiceHeaders.InvoiceHeaderID = AccountTransactions.ApplicationID AND AccountTransactions.ApplicationCode = 'Invoi'), '')
                                              + CASE WHEN AccountTransactions.ApplicationCode <> 'Invoi' OR AccountTransactions.DebitReasonCode = '' THEN '' ELSE ' - ' END 
                                              + ISNULL((SELECT DebitReasonDescription FROM DebitReasonDefinitions WITH(NOLOCK) WHERE DebitReasonDefinitions.DebitReasonCode = AccountTransactions.DebitReasonCode AND DebitReasonDefinitions.LangCode = 'TR'), '')
                                              + CASE WHEN AccountTransactions.LineDescription = '' THEN '' ELSE ' - ' END 
                                              + AccountTransactions.LineDescription
          
            , AmountDebit                   = AccountTransactions.AmountDebit
            , CurrentBalance                = AccountTransactions.CurrentBalance
            , TotalBalance                  = ISNULL(Balance.AmountDebit, 0) - ISNULL(Balance.AmountCredit, 0)
            
            , PaymentTerm                   = AccountMaster.PaymentTerm
            , AverageDay_Debit              = ISNULL(AvgPaymentDays.AverageDay_Debit, '')
            , AverageDueDate_Debit          = ISNULL(AvgPaymentDays.AverageDueDate_Debit, '')
             
            , SalesChannelCode              = AccountMaster.SalesChannelCode 
            , SalespersonCode               = ISNULL(SalesPersonnel.RepresentativeID, '')
            , SalespersonFullName           = ISNULL(SalesPersonnel.FullName, '')
            , CustomerTypeCode              = AccountMaster.CustomerTypeCode
            , CustomerTypeDescription       = ISNULL((SELECT CustomerTypeDescription FROM CustomerTypeDefinitions WITH(NOLOCK) WHERE CustomerTypeDefinitions.CustomerTypeCode = AccountMaster.CustomerTypeCode AND CustomerTypeDefinitions.LangCode = 'TR'), '')
             
            , AddressTypeCode               = ISNULL(AccountAddresses.AddressTypeCode, '')
            , AddressTypeDescription        = ISNULL(AccountAddresses.AddressTypeDescription, '')
            , Address                       = ISNULL(AccountAddresses.Address, '')
            , ZipCode                       = ISNULL(AccountAddresses.ZipCode, '')
            , DistrictCode                  = ISNULL(AccountAddresses.DistrictCode, '')
            , DistrictDescription           = ISNULL(AccountAddresses.DistrictDescription, '')
            , CityCode                      = ISNULL(AccountAddresses.CityCode, '')
            , CityDescription               = ISNULL(AccountAddresses.CityDescription, '')
            , StateCode                     = ISNULL(AccountAddresses.StateCode, '')
            , StateDescription              = ISNULL(AccountAddresses.StateDescription, '')
            , CountryCode                   = ISNULL(AccountAddresses.CountryCode, '')
            , CountryDescription            = ISNULL(AccountAddresses.CountryDescription, '')
            , TaxOfficeCode                 = ISNULL(AccountAddresses.TaxOfficeCode, '')
            , TaxOfficeDescription          = ISNULL(AccountAddresses.TaxOfficeDescription, '')
            , TaxNumber                     = ISNULL(AccountAddresses.TaxNumber, '')

            , ATAtt01 = AccountAttributes.Attribute01
            , ATAtt02 = AccountAttributes.Attribute02
            , ATAtt03 = AccountAttributes.Attribute03
            , ATAtt04 = AccountAttributes.Attribute04
            , ATAtt05 = AccountAttributes.Attribute05

            , ApplicationCode               = AccountTransactions.ApplicationCode
            , ApplicationDescription        = ISNULL((SELECT ApplicationDescription FROM SourceDefinitions WITH(NOLOCK) WHERE SourceDefinitions.ApplicationCode = AccountTransactions.ApplicationCode AND SourceDefinitions.LangCode = 'TR'), '')
             
        FROM AccountTransactions
        INNER JOIN AccountRelations WITH(NOLOCK)
            ON AccountRelations.VendorTypeCode = AccountTransactions.AccountTypeCode
            AND AccountRelations.VendorCode = AccountTransactions.AccountID
        INNER JOIN AccountMaster WITH(NOLOCK) 
            ON AccountMaster.AccountTypeCode = 1 
            AND AccountMaster.AccountID = AccountRelations.VendorCode
            
        LEFT OUTER JOIN AccountAttributes WITH(NOLOCK)
            ON AccountAttributes.AccountTypeCode = AccountMaster.AccountTypeCode 
            AND AccountAttributes.AccountID = AccountMaster.AccountID
            
        -- Vade Tablosu Bağlantısı (Fonksiyondan Tabloya Çevrildi)
        -- Average Payment Days Table Join (Converted from Function to Table)
        LEFT OUTER JOIN AveragePaymentDays AS AvgPaymentDays WITH(NOLOCK)
            ON AccountMaster.AccountTypeCode = AvgPaymentDays.AccountTypeCode
            AND AccountMaster.AccountID = AvgPaymentDays.AccountID
            
        -- Adres Bağlantıları (Fonksiyondan Tabloya Çevrildi)
        -- Address Joins (Converted from Function to Table)
        LEFT OUTER JOIN AccountDefaults WITH(NOLOCK) 
            ON AccountDefaults.AccountTypeCode = AccountMaster.AccountTypeCode
            AND AccountDefaults.AccountID = AccountMaster.AccountID 
        LEFT OUTER JOIN AccountAddresses WITH(NOLOCK)
            ON AccountAddresses.AddressLinkID = AccountDefaults.AddressLinkID

        -- Satış Temsilcisi Bağlantısı (En son atanan temsilciyi alır)
        -- Sales Representative Join (Fetches the most recently assigned representative)
        LEFT OUTER JOIN (
            SELECT 
                AccountTypeCode, 
                AccountID, 
                SalespersonAssignments.RepresentativeID, 
                FullName, 
                SortOrder = ROW_NUMBER() OVER (PARTITION BY AccountTypeCode, AccountID ORDER BY StartDate DESC)
            FROM SalespersonAssignments WITH(NOLOCK)
            INNER JOIN SalesPersonnel WITH(NOLOCK) ON SalesPersonnel.RepresentativeID = SalespersonAssignments.RepresentativeID
        ) AS SalesPersonnel
            ON SalesPersonnel.AccountTypeCode = AccountMaster.AccountTypeCode
            AND SalesPersonnel.AccountID = AccountMaster.AccountID
            AND SalesPersonnel.SortOrder = 1
            
        -- Genel Defter Bakiye Hesaplaması
        -- General Ledger Balance Calculation
        LEFT OUTER JOIN (
            SELECT CustomerCode, AmountDebit = SUM(AmountDebit), AmountCredit = SUM(AmountCredit)
            FROM (
                SELECT CustomerCode = AccountID, AmountDebit, AmountCredit 
                FROM GeneralLedger WHERE AccountTypeCode = 3 
                UNION ALL
                SELECT CustomerCode = AccountRelations.AccountID, AmountDebit, AmountCredit 
                FROM GeneralLedger  
                INNER JOIN AccountRelations WITH(NOLOCK)
                    ON AccountRelations.VendorTypeCode = GeneralLedger.AccountTypeCode
                    AND AccountRelations.VendorCode = GeneralLedger.AccountID
                WHERE GeneralLedger.AccountTypeCode = 1 
            ) AS AccountBooks
            GROUP BY CustomerCode
        ) AS Balance ON Balance.CustomerCode = AccountMaster.AccountID

        WHERE AccountMaster.AccountID <> ''
          AND (ISNULL(Balance.AmountDebit, 0) - ISNULL(Balance.AmountCredit, 0)) > 0

    ) AS BaseQuery
) AS FinalReport

-- Açıkta kalan bakiye kontrolü / Open balance condition
WHERE (RunningBalance - CurrentBalance) < TotalBalance;
