# FIFO Receivables Aging (FIFO Yöntemiyle Alacak Yaşlandırma)

## Overview / Genel Bakış

[EN]

This project implements a FIFO-based accounts receivable aging analysis using SQL Server. It calculates open balances for customer/vendor accounts and accurately determines the remaining amounts of partially paid invoices. This project demonstrates real-world financial data modeling and invoice matching logic typically used in ERP systems.

[TR]

Bu proje, SQL Server kullanarak FIFO tabanlı bir alacak yaşlandırma analizi uygular. Müşteri/satıcı hesapları için açık bakiyeleri hesaplar ve kısmen ödenmiş faturaların kalan tutarlarını doğru bir şekilde belirler. Bu proje, ERP sistemlerinde tipik olarak kullanılan gerçek dünya finansal veri modelleme ve fatura eşleştirme mantığını gösterir.

## Problem / Problem

[EN] 

In financial systems, payments are not always matched directly to specific invoices. As a result:

[TR] 

Fnansal sistemlerde ödemeler her zaman belirli faturalarla doğrudan eşleştirilmez. Bunun sonucunda:

* Some invoices are partially paid / Bazı faturalar kısmen ödenir

* Some remain fully open / Bazıları tamamen açık kalır

* Accurate aging requires correct allocation logic / Doğru yaşlandırma raporları, doğru bir dağıtım mantığı gerektirir

[EN]

Traditional reporting methods often fail to correctly identify which invoices remain open.

[TR] 

Geleneksel raporlama yöntemleri genellikle hangi faturaların açık kaldığını doğru bir şekilde tespit etmekte başarısız olur.

## Solution / Çözüm

[EN] 

This project uses SQL window functions to:

[TR] 

Bu proje, aşağıdakileri gerçekleştirmek için SQL pencere (window) fonksiyonlarını kullanır:

* Calculate running balances per account / Hesap bazında kümülatif bakiyeleri hesaplamak

* Apply FIFO (First In, First Out) logic / FIFO (İlk Giren İlk Çıkar) mantığını uygulamak

* Identify partially closed invoices / Kısmen kapanmış faturaları tespit etmek

* Extract only the invoices contributing to the current outstanding balance / Sadece mevcut açık bakiyeye katkıda bulunan faturaları filtrelemek

## Key Concepts / Temel Kavramlar

* FIFO (First In, First Out) / FIFO (İlk Giren İlk Çıkar)

* Running Balance Calculation / Kümülatif Bakiye Hesaplama

* Window Functions (SUM OVER PARTITION) / Pencere Fonksiyonları

* Partial Invoice Matching Logic / Kısmi Fatura Eşleştirme Mantığı

## Features / Özellikler

* Accurate receivables aging calculation / Doğru alacak yaşlandırma hesaplaması

* Partial invoice closure detection / Kısmi fatura kapama tespiti

* Multi-account support (customer & vendor relationships) / Çoklu hesap desteği (müşteri & satıcı ilişkileri)

* Dynamic balance calculation based on reporting date / Raporlama tarihine göre dinamik bakiye hesaplama

* Financially consistent output aligned with general ledger totals / Genel defter toplamlarıyla uyumlu, finansal açıdan tutarlı çıktı

## Tech Stack / Teknolojiler

* SQL Server

* T-SQL (Window Functions, CTE-like nested queries / Pencere fonksiyonları ve iç içe sorgular)

## Query Logic (High-Level) / Sorgu Mantığı (Genel Bakış)

* Retrieve account transactions / Hesap hareketlerini getir

* Calculate total balance from general ledger / Genel defterden toplam bakiyeyi hesapla

* Compute running balance (newest → oldest) / Kümülatif bakiyeyi hesapla (en yeniden → en eskiye)

* Apply FIFO logic to determine: / Aşağıdakileri belirlemek için FIFO mantığını uygula:

* Fully open invoices / Tamamen açık faturalar

* Partially paid invoices / Kısmen ödenmiş faturalar

* Filter only relevant records contributing to the open balance / Sadece açık bakiyeye neden olan ilgili kayıtları filtrele

## Database & Data Source / Veritabanı ve Veri Kaynağı

[EN] 

This project is designed to work on a modular enterprise analytics database. The database schema and synthetic data used in this project can be generated using:

[TR] 

Bu proje, modüler bir kurumsal analitik veritabanında çalışacak şekilde tasarlanmıştır. Bu projede kullanılan veritabanı şeması ve sentetik veriler şu proje kullanılarak oluşturulabilir:

👉 [synthetic-data-generator project](https://github.com/iremDURGUN/Synthetic-Data-Generator)


---

[EN] 

Alternatively, you can create the empty database structure directly (without synthetic data) by running the [create_entrprise_analytics_database.sql](https://github.com/iremDURGUN/customer-aging-fifo-engine/blob/main/create_enterprise-analytics_database.sql) file included in this repository.

[TR] 

Alternatif olarak, veri girişi olmadan sadece veritabanı şemasını (boş tabloları) doğrudan SQL'de oluşturmak için bu projede bulunan [create_entrprise_analytics_database.sql](https://github.com/iremDURGUN/customer-aging-fifo-engine/blob/main/create_enterprise-analytics_database.sql) dosyasını çalıştırabilirsiniz.

 ```mermaid
erDiagram
    %% Core Entities
    AccountMaster {
        int AccountTypeCode PK
        string AccountID PK
        int PaymentTerm
        string SalesChannelCode
    }
    
    AccountTransactions {
        int TransactionID PK
        string AccountID FK
        date TransactionDate
        string ReferenceNumber
        decimal CurrentBalance
        int ApplicationID FK
    }
    
    GeneralLedger {
        int LedgerID PK
        string AccountID FK
        decimal AmountDebit
        decimal AmountCredit
    }
    
    %% Relational & Detail Entities
    AccountRelations {
        string VendorCode FK
        string AccountID FK
    }

    SalespersonAssignments {
        string AccountID FK
        string RepresentativeID FK
    }

    SalesPersonnel {
        string RepresentativeID PK
        string FullName
    }

    InvoiceHeaders {
        int InvoiceHeaderID PK
        string ProcessCode
    }

    %% Relationships
    AccountMaster ||--o{ AccountTransactions : "has transactions"
    AccountMaster ||--o{ GeneralLedger : "ledger balance"
    AccountMaster ||--o{ AccountRelations : "linked (Vendor/Customer)"
    AccountMaster ||--o{ SalespersonAssignments : "assigned to"
    AccountMaster ||--|| AccountDefaults : "has defaults"
    AccountMaster ||--|| AccountAttributes : "has attributes"
    AccountMaster ||--o{ AccountDescriptions : "described in"
    
    SalespersonAssignments }o--|| SalesPersonnel : "rep details"
    AccountTransactions }o--|| InvoiceHeaders : "invoiced via"
```
## This ensures: / Bu yapı şunları sağlar:

* No real company data is used / Gerçek şirket verisi kullanılmamasını

* Fully reproducible environment / Tamamen tekrarlanabilir bir çalışma ortamını

* Consistent testing scenarios / Tutarlı test senaryolarını

## How to Use / Nasıl Kullanılır?

### Set reporting date / Raporlama tarihini belirleyin:

SQL
'DECLARE @BalanceDate DATE = 'YYYYMMDD';'

### Run the query / Sorguyu çalıştırın.

## Output will include: / Çıktı şunları içerecektir:

* Open invoices / Açık faturalar

* Remaining balances / Kalan bakiyeler

* Aging-related fields / Yaşlandırma ile ilgili alanlar

## Output Description / Çıktı Açıklamaları

* CurrentBalance → Invoice amount / Fatura tutarı

* RunningBalance → Cumulative balance per account / Hesap bazında kümülatif bakiye

* TotalBalance → Net account balance / Net hesap bakiyesi

* RemainingInvoiceBalance → Actual open amount per invoice / Fatura başına kalan fiili açık tutar

## Use Cases / Kullanım Senaryoları

* Accounts receivable aging reports / Alacak yaşlandırma raporları

* Financial reconciliation / Finansal mutabakat

* ERP system analysis / ERP sistem analizleri

* Audit support / Denetim süreçlerine destek

* Credit risk evaluation / Kredi riski değerlendirmesi

## Notes / Notlar

* This implementation focuses on financial accuracy rather than simple aggregation. / Bu uygulama, basit bir veri toplamasından ziyade finansal doğruluğa odaklanır.

* Designed to simulate real ERP accounting scenarios. / Gerçek ERP muhasebe senaryolarını simüle etmek için tasarlanmıştır.

* Works best with transactional-level data. / En iyi işlem (hareket) düzeyindeki verilerle çalışır.

## Disclaimer / Yasal Uyarı

[EN]
All data used in this project can be generated synthetically. No real financial data is included.

[TR] 
Bu projede kullanılan tüm veriler sentetik olarak üretilebilir. Gerçek hiçbir finansal veri içermemektedir.
