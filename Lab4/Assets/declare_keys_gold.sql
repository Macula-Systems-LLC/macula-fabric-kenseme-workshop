-- Declare primary and foreign keys on the AdventureWorksGold SQL analytics endpoint.
-- The keys are informational (NOT ENFORCED). Kenseme reads them to build relationships and bindings.
-- Run this once, after the gold notebook has finished and the 8 tables show on the SQL analytics endpoint.
-- If a key already exists, its statement fails with "already exists". That is harmless.
-- Check the result with:
--   SELECT OBJECT_NAME(parent_object_id) AS tbl, name FROM sys.key_constraints
--   UNION ALL SELECT OBJECT_NAME(parent_object_id), name FROM sys.foreign_keys;   -- expect 17 rows

ALTER TABLE dbo.DimCustomer        ADD CONSTRAINT PK_DimCustomer        PRIMARY KEY NONCLUSTERED (CustomerKey)        NOT ENFORCED;
ALTER TABLE dbo.DimProduct         ADD CONSTRAINT PK_DimProduct         PRIMARY KEY NONCLUSTERED (ProductKey)         NOT ENFORCED;
ALTER TABLE dbo.DimProductCategory ADD CONSTRAINT PK_DimProductCategory PRIMARY KEY NONCLUSTERED (ProductCategoryKey) NOT ENFORCED;
ALTER TABLE dbo.DimSalesChannel    ADD CONSTRAINT PK_DimSalesChannel    PRIMARY KEY NONCLUSTERED (SalesChannelKey)    NOT ENFORCED;
ALTER TABLE dbo.DimDate            ADD CONSTRAINT PK_DimDate            PRIMARY KEY NONCLUSTERED (DateKey)            NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrder     ADD CONSTRAINT PK_FactSalesOrder     PRIMARY KEY NONCLUSTERED (SalesOrderKey)      NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLine ADD CONSTRAINT PK_FactSalesOrderLine PRIMARY KEY NONCLUSTERED (SalesOrderLineKey)  NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLineDetail ADD CONSTRAINT PK_FactSalesOrderLineDetail PRIMARY KEY NONCLUSTERED (SalesOrderNumber, LineNumber) NOT ENFORCED;

ALTER TABLE dbo.DimProduct         ADD CONSTRAINT FK_DimProduct_DimProductCategory  FOREIGN KEY (ProductCategoryKey) REFERENCES dbo.DimProductCategory (ProductCategoryKey) NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrder     ADD CONSTRAINT FK_FactSalesOrder_DimCustomer      FOREIGN KEY (CustomerKey)        REFERENCES dbo.DimCustomer (CustomerKey)               NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrder     ADD CONSTRAINT FK_FactSalesOrder_DimSalesChannel  FOREIGN KEY (SalesChannelKey)    REFERENCES dbo.DimSalesChannel (SalesChannelKey)       NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrder     ADD CONSTRAINT FK_FactSalesOrder_DimDate          FOREIGN KEY (OrderDateKey)       REFERENCES dbo.DimDate (DateKey)                       NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLine ADD CONSTRAINT FK_FactSalesOrderLine_FactSalesOrder FOREIGN KEY (SalesOrderKey)    REFERENCES dbo.FactSalesOrder (SalesOrderKey)          NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLine ADD CONSTRAINT FK_FactSalesOrderLine_DimProduct   FOREIGN KEY (ProductKey)         REFERENCES dbo.DimProduct (ProductKey)                 NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLineDetail ADD CONSTRAINT FK_FactSalesOrderLineDetail_FactSalesOrder FOREIGN KEY (SalesOrderKey) REFERENCES dbo.FactSalesOrder (SalesOrderKey) NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLineDetail ADD CONSTRAINT FK_FactSalesOrderLineDetail_DimProduct     FOREIGN KEY (ProductKey)    REFERENCES dbo.DimProduct (ProductKey)         NOT ENFORCED;
ALTER TABLE dbo.FactSalesOrderLineDetail ADD CONSTRAINT FK_FactSalesOrderLineDetail_DimCustomer    FOREIGN KEY (CustomerKey)   REFERENCES dbo.DimCustomer (CustomerKey)       NOT ENFORCED;
