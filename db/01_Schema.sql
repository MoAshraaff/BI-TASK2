/*
  =====================================================================
  SalesBuzz SDK - Minimal Database Initialization Script
  Generated: 2026-08-20
  Purpose: Creates ALL objects needed for SalesBuzzDbContextBase
  Safe to re-run (IF NOT EXISTS guards throughout)
  =====================================================================
*/

USE [MO_ASHRAF]; -- ← CHANGE THIS to your actual database name
GO

-- =================================================================
-- SECTION 1: AUTH / SECURITY
-- =================================================================

-- HH_SA_SecurityKeys
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_SA_SecurityKeys' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_SA_SecurityKeys]
    (
        [KeyID]                    NVARCHAR(50)    NOT NULL,
        [Description]              NVARCHAR(50)    NULL,
        [DescriptionA]             NVARCHAR(50)    NULL,
        [ParentKeyID]              NVARCHAR(50)    NULL,
        [RedirectURI]              NVARCHAR(100)   NULL,
        [Type]                     TINYINT         NULL,
        [ModuleID]                 NVARCHAR(20)    NULL,
        [ModuleDesc]               NVARCHAR(150)   NULL,
        [IsErpAware]               TINYINT         NOT NULL DEFAULT 0,
        [EnableEditOnERPIntegration] TINYINT       NOT NULL DEFAULT 0,
        [CreatedOn]                DATETIME        NULL,
        [Createdby]                NVARCHAR(15)    NULL,
        [ModifiedOn]               DATETIME        NULL,
        [ModifiedBy]               NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_SA_SecurityKeys] PRIMARY KEY CLUSTERED ([KeyID])
    );
END
GO

-- HH_SA_Roles
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_SA_Roles' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_SA_Roles]
    (
        [RoleID]                    NVARCHAR(15)    NOT NULL,
        [Description]               NVARCHAR(200)   NULL,
        [DescriptionA]              NVARCHAR(200)   NULL,
        [NeedExplicitUpdatePermission] TINYINT      NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_SA_Roles] PRIMARY KEY CLUSTERED ([RoleID])
    );
END
GO

-- HH_SA_BU
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_SA_BU' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_SA_BU]
    (
        [BUID]                      NVARCHAR(15)    NOT NULL,
        [Description]               NVARCHAR(200)   NULL,
        [DescriptionA]              NVARCHAR(200)   NULL,
        [ParentBU]                  NVARCHAR(15)    NULL,
        [Level]                     TINYINT         NOT NULL DEFAULT 0,
        [HasChildren]               TINYINT         NULL,
        [ShortCode]                 NVARCHAR(5)     NULL,
        [OrganizationType]          TINYINT         NULL,
        [ERPOrganizationID]         NVARCHAR(50)    NULL,
        [MemoLineId]                NVARCHAR(50)    NULL,
        [ERPDistChannelID]          NVARCHAR(50)    NULL,
        [ERPSalesDivisonID]         NVARCHAR(50)    NULL,
        [TypeOfPayment]             TINYINT         NULL,
        [CompanyGlAccount]          NVARCHAR(50)    NULL,
        [CurrencyID]                NVARCHAR(15)    NULL,
        [SAPGovernorate]            NVARCHAR(50)    NULL,
        [SAPplant]                  NVARCHAR(50)    NULL,
        [SalesTypeID]               NVARCHAR(50)    NULL,
        [SAPSalesOffice]            NVARCHAR(50)    NULL,
        [SAPSalesdistrict]          NVARCHAR(50)    NULL,
        [SAPCompanyCode]            NVARCHAR(50)    NULL,
        [SAPCreditControlArea]      NVARCHAR(50)    NULL,
        [SAPCreditSegment]          NVARCHAR(50)    NULL,
        [SAPSalesOrg]               NVARCHAR(50)    NULL,
        [UserName]                  NVARCHAR(50)    NULL,
        [DefaultWarehouse]          NVARCHAR(50)    NULL,
        [TemporaryCredit]           DECIMAL(18,2)   NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_SA_BU] PRIMARY KEY CLUSTERED ([BUID])
    );
END
GO

-- HH_SA_RolePermissions
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_SA_RolePermissions' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_SA_RolePermissions]
    (
        [RoleID]                    NVARCHAR(15)    NOT NULL,
        [KeyID]                     NVARCHAR(50)    NOT NULL,
        [CanRead]                   TINYINT         NOT NULL DEFAULT 0,
        [CanInsert]                 TINYINT         NOT NULL DEFAULT 0,
        [CanUpdate]                 TINYINT         NOT NULL DEFAULT 0,
        [CanDelete]                 TINYINT         NOT NULL DEFAULT 0,
        [CanExecute]                TINYINT         NOT NULL DEFAULT 0,
        [CanViewAttachments]        TINYINT         NULL,
        [CanAddAttachments]         TINYINT         NULL,
        [CanDeleteAttachments]      TINYINT         NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_SA_RolePermissions] PRIMARY KEY CLUSTERED ([RoleID], [KeyID]),
        CONSTRAINT [FK_HH_SA_RolePermissions_Roles] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[HH_SA_Roles]([RoleID])
    );
END
GO

-- HH_SA_UserBUPermissions
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_SA_UserBUPermissions' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_SA_UserBUPermissions]
    (
        [UserID]                    NVARCHAR(15)    NOT NULL,
        [BUID]                      NVARCHAR(15)    NOT NULL DEFAULT '1',
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_SA_UserBUPermissions] PRIMARY KEY CLUSTERED ([UserID], [BUID])
    );
END
GO

-- HH_EntityBUControl
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_EntityBUControl' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_EntityBUControl]
    (
        [TableName]                 NVARCHAR(200)   NOT NULL,
        [BUControl]                 TINYINT         NOT NULL DEFAULT 0,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_EntityBUControl] PRIMARY KEY CLUSTERED ([TableName])
    );
END
GO

-- loginusers
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'loginusers' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[loginusers]
    (
        [userName]                  NVARCHAR(15)    NOT NULL,
        [role]                      INT             NULL,
        [password]                  NVARCHAR(15)    NULL,
        [userCode]                  NVARCHAR(50)    NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [branchNo]                  NVARCHAR(15)    NULL,
        [RoleID]                    NVARCHAR(15)    NOT NULL,
        [EncPassword]               NVARCHAR(15)    NULL,
        [FullName]                  NVARCHAR(200)   NULL,
        [JobTitle]                  NVARCHAR(200)   NULL,
        [InActive]                  TINYINT         NOT NULL DEFAULT 0,
        [ADAuthentication]          TINYINT         NOT NULL DEFAULT 0,
        [WindowsLogin]              NVARCHAR(200)   NULL,
        [Domain]                    NVARCHAR(200)   NULL,
        [ADUserName]                NVARCHAR(200)   NULL,
        [ForceLogin]                TINYINT         NULL,
        [AdvancedWFUser]            TINYINT         NULL,
        [Email]                     NVARCHAR(200)   NULL,
        [SupervisorModuleUser]      TINYINT         NULL,
        [WillNotExpired]            BIT             NOT NULL DEFAULT 0,
        [EnableMFA]                 TINYINT         NULL,
        [StartDate]                 DATETIME        NULL,
        [EndDate]                   DATETIME        NULL,
        [LastPasswordRenew]         DATETIME        NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_loginusers] PRIMARY KEY CLUSTERED ([userName])
    );
END
GO

-- RecordLevelSecurity
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'RecordLevelSecurity' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[RecordLevelSecurity]
    (
        [ID]                        INT IDENTITY(1,1) NOT NULL,
        [UserOrRoleID]              NVARCHAR(25)    NOT NULL,
        [RecType]                   TINYINT         NOT NULL,
        [EntityName]                NVARCHAR(128)   NOT NULL,
        [FieldName]                 NVARCHAR(128)   NOT NULL,
        [Criteria]                  NVARCHAR(1000)  NOT NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_RecordLevelSecurity] PRIMARY KEY CLUSTERED ([ID]),
        CONSTRAINT [UQ_RecordLevelSecurity] UNIQUE NONCLUSTERED ([UserOrRoleID], [RecType], [EntityName], [FieldName])
    );
END
GO

-- =================================================================
-- SECTION 2: AUDIT / LICENSE / SESSION
-- =================================================================

-- SA_AuditCriteria
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SA_AuditCriteria' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[SA_AuditCriteria]
    (
        [Serial]                    INT IDENTITY(1,1) NOT NULL,
        [UserName]                  NVARCHAR(15)    NULL,
        [TableName]                 NVARCHAR(200)   NULL,
        [OperationType]             TINYINT         NULL,
        [TableFields]               NVARCHAR(MAX)   NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_SA_AuditCriteria] PRIMARY KEY CLUSTERED ([Serial])
    );
END
GO

-- SA_AuditLogs
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SA_AuditLogs' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[SA_AuditLogs]
    (
        [Serial]                    BIGINT IDENTITY(1,1) NOT NULL,
        [UserName]                  NVARCHAR(15)    NOT NULL DEFAULT '',
        [Operationtype]             TINYINT         NULL,
        [TableName]                 NVARCHAR(200)   NOT NULL DEFAULT '',
        [Olddata]                   NVARCHAR(MAX)   NULL,
        [NewData]                   NVARCHAR(MAX)   NULL,
        [Date]                      DATE            NULL,
        [TableKeys]                 NVARCHAR(MAX)   NULL,

        CONSTRAINT [PK_SA_AuditLogs] PRIMARY KEY CLUSTERED ([Serial])
    );
END
GO

-- SA_License
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SA_License' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[SA_License]
    (
        [Id]                        INT             NOT NULL,
        [EncryptedXmlData]          NVARCHAR(MAX)   NOT NULL,
        [UploadedAt]                DATETIME        NOT NULL,

        CONSTRAINT [PK_SA_License] PRIMARY KEY CLUSTERED ([Id])
    );
END
GO

-- SA_Session
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SA_Session' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[SA_Session]
    (
        [JTI]                       UNIQUEIDENTIFIER NOT NULL,
        [UserName]                  NVARCHAR(15)    NULL,
        [ExpiryDate]                DATETIME        NULL,
        [S]                         TINYINT         NULL,
        [MachineIP]                 NVARCHAR(255)   NULL,
        [LastAccess]                DATETIME        NULL,
        [Status]                    INT             NULL,

        CONSTRAINT [PK_SA_Session] PRIMARY KEY CLUSTERED ([JTI])
    );
END
GO

-- =================================================================
-- SECTION 3: NUMBER SEQUENCES
-- =================================================================

-- hh_ST_NumberSequance
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hh_ST_NumberSequance' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[hh_ST_NumberSequance]
    (
        [NumberSequanceID]          NVARCHAR(50)    NOT NULL,
        [Description]               NVARCHAR(50)    NULL,
        [DescriptionAR]             NVARCHAR(50)    NULL,
        [Format]                    NVARCHAR(50)    NULL,
        [SerialStart]               TINYINT         NULL,
        [SerialLength]              TINYINT         NULL,
        [IncrementBy]               INT             NOT NULL DEFAULT 1,
        [ForceFormat]               TINYINT         NOT NULL DEFAULT 1,
        [MinValue]                  BIGINT          NOT NULL DEFAULT 1,
        [MaxValue]                  BIGINT          NULL,
        [NextValue]                 BIGINT          NOT NULL DEFAULT 1,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,

        CONSTRAINT [PK_hh_ST_NumberSequance] PRIMARY KEY CLUSTERED ([NumberSequanceID])
    );
END
GO

-- hh_ST_NumberSequenceBU
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hh_ST_NumberSequenceBU' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[hh_ST_NumberSequenceBU]
    (
        [NumberSequanceID]          NVARCHAR(50)    NOT NULL,
        [ShortCode]                 NVARCHAR(5)     NOT NULL,
        [NextValue]                 BIGINT          NOT NULL DEFAULT 1,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,

        CONSTRAINT [PK_hh_ST_NumberSequenceBU] PRIMARY KEY CLUSTERED ([NumberSequanceID], [ShortCode]),
        CONSTRAINT [FK_hh_ST_NumberSequenceBU_Seq] FOREIGN KEY ([NumberSequanceID]) REFERENCES [dbo].[hh_ST_NumberSequance]([NumberSequanceID])
    );
END
GO

-- hh_ST_NumberSequanceCanceledSerials
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hh_ST_NumberSequanceCanceledSerials' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[hh_ST_NumberSequanceCanceledSerials]
    (
        [NumberSequanceID]          NVARCHAR(50)    NOT NULL,
        [CanceledSerial]            BIGINT          NOT NULL DEFAULT 0,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,

        CONSTRAINT [PK_hh_ST_NumberSequanceCanceledSerials] PRIMARY KEY CLUSTERED ([NumberSequanceID], [CanceledSerial]),
        CONSTRAINT [FK_hh_ST_CanceledSerials_Seq] FOREIGN KEY ([NumberSequanceID]) REFERENCES [dbo].[hh_ST_NumberSequance]([NumberSequanceID])
    );
END
GO

-- hh_ST_NumberSequanceCanceledSerialsBU
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hh_ST_NumberSequanceCanceledSerialsBU' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[hh_ST_NumberSequanceCanceledSerialsBU]
    (
        [ShortCode]                 NVARCHAR(5)     NOT NULL,
        [CanceledSerial]            BIGINT          NOT NULL,
        [NumberSequanceID]          NVARCHAR(50)    NOT NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,

        CONSTRAINT [PK_hh_ST_NumberSequanceCanceledSerialsBU] PRIMARY KEY CLUSTERED ([ShortCode], [CanceledSerial], [NumberSequanceID]),
        CONSTRAINT [FK_hh_ST_CanceledSerialsBU_Seq] FOREIGN KEY ([NumberSequanceID]) REFERENCES [dbo].[hh_ST_NumberSequance]([NumberSequanceID])
    );
END
GO

-- =================================================================
-- SECTION 4: EVENT LOGGING
-- =================================================================

-- ST_EventLogMaster
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ST_EventLogMaster' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ST_EventLogMaster]
    (
        [ProcessID]                 DECIMAL(15,0)   IDENTITY NOT NULL,
        [SQLUserName]               NVARCHAR(128)   NULL,
        [NTUserName]                NVARCHAR(128)   NULL,
        [WorkStationName]           NVARCHAR(128)   NULL,
        [ProcessStart]              DATETIME        NOT NULL DEFAULT GETDATE(),
        [ProcessEnd]                DATETIME        NULL,
        [Description]               NVARCHAR(75)    NULL,
        [ArabicDescription]         NVARCHAR(75)    NULL,
        [UserId]                    NVARCHAR(25)    NULL,
        [BUID]                      NVARCHAR(25)    NULL,
        [IsBatchJob]                TINYINT         NULL,
        [OverAllStatus]             TINYINT         NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_ST_EventLogMaster] PRIMARY KEY CLUSTERED ([ProcessID])
    );
END
GO

-- ST_EventLogDetail
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ST_EventLogDetail' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ST_EventLogDetail]
    (
        [ProcessID]                 DECIMAL(15,0)   NOT NULL,
        [EventSerialNo]             DECIMAL(15,0)   NOT NULL,
        [EventID]                   INT             NULL,
        [EventDateTime]             DATETIME        NOT NULL DEFAULT GETDATE(),
        [Var1]                      NVARCHAR(250)   NULL,
        [Var2]                      NVARCHAR(250)   NULL,
        [Var3]                      NVARCHAR(250)   NULL,
        [Var4]                      NVARCHAR(250)   NULL,
        [Var5]                      NVARCHAR(250)   NULL,
        [Var6]                      NVARCHAR(250)   NULL,
        [Var7]                      NVARCHAR(250)   NULL,
        [Var8]                      NVARCHAR(250)   NULL,
        [Var9]                      NVARCHAR(250)   NULL,
        [Var10]                     NVARCHAR(250)   NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_ST_EventLogDetail] PRIMARY KEY CLUSTERED ([ProcessID], [EventSerialNo]),
        CONSTRAINT [FK_ST_EventLogDetail_Master] FOREIGN KEY ([ProcessID]) REFERENCES [dbo].[ST_EventLogMaster]([ProcessID])
    );
END
GO

-- ST_EventDefinition
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ST_EventDefinition' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[ST_EventDefinition]
    (
        [EventID]                   INT             NOT NULL,
        [Eventlangid]               SMALLINT        NOT NULL,
        [EventText]                 NVARCHAR(255)   NOT NULL,
        [EventType]                 TINYINT         NOT NULL DEFAULT 0,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_ST_EventDefinition] PRIMARY KEY CLUSTERED ([EventID], [Eventlangid])
    );
END
GO

-- =================================================================
-- SECTION 5: BUSINESS TABLES
-- =================================================================

-- BS_Years
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BS_Years' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[BS_Years]
    (
        [YearId]                    NVARCHAR(15)    NOT NULL,
        [YearStartDate]             DATETIME        NOT NULL,
        [YearEndDate]               DATETIME        NOT NULL,
        [L1Description]             NVARCHAR(100)   NULL,
        [L2Description]             NVARCHAR(100)   NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_BS_Years] PRIMARY KEY CLUSTERED ([YearId])
    );
END
GO

-- BS_Periods
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BS_Periods' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[BS_Periods]
    (
        [YearId]                    NVARCHAR(15)    NOT NULL,
        [PeriodId]                  NVARCHAR(15)    NOT NULL,
        [PeriodKey]                 INT             NOT NULL,
        [StartDate]                 DATETIME        NOT NULL,
        [EndDate]                   DATETIME        NOT NULL,
        [L1Description]             NVARCHAR(100)   NULL,
        [L2Description]             NVARCHAR(100)   NULL,
        [displayorder]              INT             NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_BS_Periods] PRIMARY KEY CLUSTERED ([YearId], [PeriodId]),
        CONSTRAINT [UQ_BS_Periods_PeriodKey] UNIQUE NONCLUSTERED ([PeriodKey])
    );
END
GO

-- HH_Salesman
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_Salesman' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_Salesman]
    (
        [SalesmanNo]                NVARCHAR(15)    NOT NULL,
        [SalesmanNameE]             NVARCHAR(200)   NULL,
        [SalesmanNameA]             NVARCHAR(200)   NULL,
        [CategoryId]                NVARCHAR(15)    NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [BranchNo]                  NVARCHAR(15)    NULL,
        [SalesManType]              INT             NULL,
        [IsUser]                    BIT             NOT NULL DEFAULT 0,
        [WareHouse]                 NVARCHAR(50)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_Salesman] PRIMARY KEY CLUSTERED ([SalesmanNo])
    );
END
GO

-- HH_Item
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_Item' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_Item]
    (
        [ItemNo]                    NVARCHAR(40)    NOT NULL,
        [ItemNameE]                 NVARCHAR(200)   NULL,
        [ItemNameA]                 NVARCHAR(200)   NULL,
        [DefaultUOM]                NVARCHAR(15)    NOT NULL,
        [BrandNo]                   NVARCHAR(15)    NULL,
        [TaxCodeID]                 NVARCHAR(15)    NULL,
        [GroupID]                   NVARCHAR(15)    NULL,
        [CategoryID]                NVARCHAR(15)    NULL,
        [buid]                      NVARCHAR(15)    NOT NULL DEFAULT '1',
        [barcode1]                  NVARCHAR(50)    NULL,
        [barcode2]                  NVARCHAR(50)    NOT NULL DEFAULT '1',
        [MasterBrandID]             NVARCHAR(15)    NULL,
        [Type]                      INT             NULL,
        [ReturnUOM]                 NVARCHAR(15)    NULL,
        [SalesUOM]                  NVARCHAR(15)    NULL,
        [PurchaseUOM]               NVARCHAR(15)    NULL,
        [SmallUOM]                  NVARCHAR(15)    NULL,
        [LargeUOM]                  NVARCHAR(15)    NULL,
        [RecordSource]              TINYINT         NOT NULL DEFAULT 0,
        [EnableReturn]              TINYINT         NOT NULL DEFAULT 1,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_Item] PRIMARY KEY CLUSTERED ([ItemNo])
    );
END
GO

-- HH_ItemUoms
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_ItemUoms' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_ItemUoms]
    (
        [ItemNo]                    NVARCHAR(40)    NOT NULL,
        [SmallUOM]                  NVARCHAR(15)    NOT NULL,
        [LargeUOM]                  NVARCHAR(15)    NOT NULL,
        [Factor]                    DECIMAL(28,8)   NULL,
        [MultiplyDivide]            TINYINT         NULL,
        [buid]                      NVARCHAR(15)    NOT NULL DEFAULT '1',
        [RecordSource]              TINYINT         NOT NULL DEFAULT 0,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_ItemUoms] PRIMARY KEY CLUSTERED ([ItemNo], [SmallUOM], [LargeUOM])
    );
END
GO

-- HH_IC_UOMDetail
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_IC_UOMDetail' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_IC_UOMDetail]
    (
        [UOMID]                     NVARCHAR(15)    NOT NULL,
        [LinkedUOM]                 NVARCHAR(15)    NOT NULL,
        [Factor]                    DECIMAL(28,8)   NULL,
        [MultiplyDivide]            TINYINT         NULL,
        [buid]                      NVARCHAR(15)    NOT NULL DEFAULT '1',
        [RecordSource]              TINYINT         NOT NULL DEFAULT 0,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_IC_UOMDetail] PRIMARY KEY CLUSTERED ([UOMID], [LinkedUOM])
    );
END
GO

-- HH_Customer
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_Customer' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_Customer]
    (
        [CustomerNo]                NVARCHAR(15)    NOT NULL,
        [CustomerNameE]             NVARCHAR(200)   NULL,
        [CustomerNameA]             NVARCHAR(200)   NULL,
        [SalesmanNo]                NVARCHAR(15)    NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [Mobile]                    NVARCHAR(50)    NULL,
        [Address]                   NVARCHAR(500)   NULL,
        [InActive]                  TINYINT         NULL,
        [RecordSource]              TINYINT         NULL,
        [Latitude]                  DECIMAL(24,15)  NULL,
        [Longitude]                 DECIMAL(24,15)  NULL,
        [Altitude]                  DECIMAL(24,15)  NULL,
        [EmailTemplateType]         NVARCHAR(15)    NULL,
        [SalesDivisionID]           NVARCHAR(2)     NULL,
        [WorkFLowStatus]            TINYINT         NOT NULL DEFAULT 0,
        [ChannelID]                 NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_Customer] PRIMARY KEY CLUSTERED ([CustomerNo])
    );
END
GO

-- HH_CustomerLocations
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_CustomerLocations' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_CustomerLocations]
    (
        [CustomerNo]                NVARCHAR(15)    NOT NULL,
        [LineSerial]                INT             NOT NULL,
        [CustomerLocationsGUID]     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        [LocationNo]                NVARCHAR(15)    NOT NULL,
        [Barcode]                   NVARCHAR(50)    NULL,
        [SerialNumber]              NVARCHAR(50)    NULL,
        [Year]                      NVARCHAR(50)    NULL,
        [ContractID]                NVARCHAR(50)    NULL,
        [ContractDate]              DATETIME        NULL,
        [AssetNO]                   NVARCHAR(15)    NULL,
        [AssetID]                   NVARCHAR(15)    NULL,
        [InactiveDate]              DATETIME        NULL,
        [StartDate]                 DATETIME        NULL,
        [EndDate]                   DATETIME        NULL,
        [TypeInfo]                  NVARCHAR(150)   NULL,
        [BUID]                      NVARCHAR(30)    NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [RecordSource]              INT             NULL,

        CONSTRAINT [PK_HH_CustomerLocations] PRIMARY KEY CLUSTERED ([CustomerNo], [LineSerial], [CustomerLocationsGUID])
    );
END
GO

-- HH_PARAMS
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_PARAMS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_PARAMS]
    (
        [PARAM_ID]                  INT             NOT NULL,
        [PARAM_NAME]                NVARCHAR(50)    NULL,
        [PARAM_VALUE]               NVARCHAR(4000)  NULL,
        [SystemParam]               TINYINT         NULL,
        [PerBU]                     TINYINT         NULL,
        [DefaultValue]              NVARCHAR(4000)  NULL,
        [ParamControlType]          TINYINT         NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_PARAMS] PRIMARY KEY CLUSTERED ([PARAM_ID])
    );
END
GO

-- HH_PARAMS_BU
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_PARAMS_BU' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_PARAMS_BU]
    (
        [PARAM_ID]                  INT             NOT NULL,
        [BUID]                      NVARCHAR(15)    NOT NULL,
        [PARAM_NAME]                NVARCHAR(50)    NULL,
        [PARAM_VALUE]               NVARCHAR(4000)  NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_PARAMS_BU] PRIMARY KEY CLUSTERED ([PARAM_ID], [BUID])
    );
END
GO

-- HH_Messages
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_Messages' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_Messages]
    (
        [MessageID]                 INT             NOT NULL,
        [Sender]                    NVARCHAR(50)    NOT NULL,
        [Subject]                   NVARCHAR(100)   NOT NULL,
        [Body]                      NVARCHAR(500)   NOT NULL,
        [SalesManNo]                NVARCHAR(15)    NULL,
        [BranchNo]                  NVARCHAR(15)    NULL,
        [SalesManType]              INT             NULL,
        [FromDate]                  DATETIME        NULL,
        [ToDate]                    DATETIME        NULL,
        [BUID]                      NVARCHAR(15)    NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_Messages] PRIMARY KEY CLUSTERED ([MessageID])
    );
END
GO

-- hh_Target
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hh_Target' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[hh_Target]
    (
        [id]                        INT             NOT NULL,
        [NameA]                     NVARCHAR(200)   NULL,
        [NameE]                     NVARCHAR(200)   NULL,
        [ItemBased]                 BIT             NULL,
        [isCustomer]                TINYINT         NULL,
        [isDistributor]             BIT             NULL,
        [HasDetail]                 BIT             NOT NULL DEFAULT 0,
        [ISCalculated]              BIT             NULL,
        [DisplayOrder]              SMALLINT        NULL,
        [IsVisible]                 TINYINT         NULL,
        [SurveyRefId]               NVARCHAR(50)    NULL,
        [RequestRefID]              NVARCHAR(50)    NULL,
        [ISPercentage]              BIT             NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_hh_Target] PRIMARY KEY CLUSTERED ([id])
    );
END
GO

-- HH_AR_SalesmenCats
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_AR_SalesmenCats' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_AR_SalesmenCats]
    (
        [CategoryId]                NVARCHAR(15)    NOT NULL,
        [Description]               NVARCHAR(200)   NULL,
        [ArabicDescription]         NVARCHAR(200)   NULL,
        [buid]                      NVARCHAR(15)    NULL,
        [CommissionSchemeID]        NVARCHAR(15)    NULL,
        [RecordSource]              TINYINT         NULL,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_AR_SalesmenCats] PRIMARY KEY CLUSTERED ([CategoryId])
    );
END
GO

-- HH_AR_SalesmenPcts
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HH_AR_SalesmenPcts' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[HH_AR_SalesmenPcts]
    (
        [SalesmanId]                NVARCHAR(15)    NOT NULL,
        [SubordinateId]             NVARCHAR(15)    NOT NULL,
        [Serial]                    INT             NULL,
        [BUID]                      NVARCHAR(15)    NOT NULL DEFAULT '1',
        [RecordSource]              TINYINT         NOT NULL DEFAULT 0,
        [CreatedOn]                 DATETIME        NULL,
        [Createdby]                 NVARCHAR(15)    NULL,
        [ModifiedOn]                DATETIME        NULL,
        [ModifiedBy]                NVARCHAR(15)    NULL,

        CONSTRAINT [PK_HH_AR_SalesmenPcts] PRIMARY KEY CLUSTERED ([SalesmanId], [SubordinateId])
    );
END
GO

-- =================================================================
-- SECTION 6: STORED PROCEDURE
-- =================================================================

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Get_AuditCriteria' AND schema_id = SCHEMA_ID('dbo'))
    DROP PROCEDURE [dbo].[Get_AuditCriteria];
GO

CREATE PROCEDURE [dbo].[Get_AuditCriteria]
    @userName NVARCHAR(100),
    @TableName NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT TOP 1 1 FROM SA_AuditCriteria WHERE UserName = @userName AND TableName = @TableName)
        SELECT TableName, CAST(OperationType AS INT) AS OperationType, TableFields
        FROM SA_AuditCriteria WHERE UserName = @userName AND TableName = @TableName;
    ELSE
        SELECT TableName, CAST(OperationType AS INT) AS OperationType, TableFields
        FROM SA_AuditCriteria WHERE UserName = 'ALLusers' AND TableName = @TableName;
END
GO

-- =================================================================
-- SECTION 7: SEED DATA
-- =================================================================

-- Business Unit
IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_BU] WHERE [BUID] = 'C100')
BEGIN
    INSERT INTO [dbo].[HH_SA_BU] ([BUID], [Description], [DescriptionA], [Level], [ShortCode], [CreatedOn], [Createdby])
    VALUES ('C100', 'Default Business Unit', N'الوحدة التجارية الافتراضية', 0, 'C100', GETDATE(), 'system');
END
GO

-- Roles
IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_Roles] WHERE [RoleID] = 'user')
BEGIN
    INSERT INTO [dbo].[HH_SA_Roles] ([RoleID], [Description], [DescriptionA], [NeedExplicitUpdatePermission], [CreatedOn], [Createdby])
    VALUES ('user', 'User', N'مستخدم', 1, GETDATE(), 'system');
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_Roles] WHERE [RoleID] = 'admin')
BEGIN
    INSERT INTO [dbo].[HH_SA_Roles] ([RoleID], [Description], [DescriptionA], [NeedExplicitUpdatePermission], [CreatedOn], [Createdby])
    VALUES ('admin', 'Administrator', N'مدير النظام', 0, GETDATE(), 'system');
END
GO

-- Login Users
IF NOT EXISTS (SELECT 1 FROM [dbo].[loginusers] WHERE [userName] = 'demo')
BEGIN
    INSERT INTO [dbo].[loginusers] ([userName], [RoleID], [BUID], [InActive], [FullName], [CreatedOn], [Createdby])
    VALUES ('demo', 'user', 'C100', 0, 'Demo User', GETDATE(), 'system');
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[loginusers] WHERE [userName] = 'admin')
BEGIN
    INSERT INTO [dbo].[loginusers] ([userName], [RoleID], [BUID], [InActive], [FullName], [CreatedOn], [Createdby])
    VALUES ('admin', 'admin', 'C100', 0, 'Administrator', GETDATE(), 'system');
END
GO

-- User BU Permissions
IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_UserBUPermissions] WHERE [UserID] = 'demo' AND [BUID] = 'C100')
BEGIN
    INSERT INTO [dbo].[HH_SA_UserBUPermissions] ([UserID], [BUID], [CreatedOn], [Createdby])
    VALUES ('demo', 'C100', GETDATE(), 'system');
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_UserBUPermissions] WHERE [UserID] = 'admin' AND [BUID] = 'C100')
BEGIN
    INSERT INTO [dbo].[HH_SA_UserBUPermissions] ([UserID], [BUID], [CreatedOn], [Createdby])
    VALUES ('admin', 'C100', GETDATE(), 'system');
END
GO

-- Role Permissions (returnreasons CRUD for both roles)
IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_RolePermissions] WHERE [RoleID] = 'user' AND [KeyID] = 'returnreasons')
BEGIN
    INSERT INTO [dbo].[HH_SA_RolePermissions] ([RoleID], [KeyID], [CanRead], [CanInsert], [CanUpdate], [CanDelete], [CanExecute], [CreatedOn], [Createdby])
    VALUES ('user', 'returnreasons', 1, 1, 1, 1, 0, GETDATE(), 'system');
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_SA_RolePermissions] WHERE [RoleID] = 'admin' AND [KeyID] = 'returnreasons')
BEGIN
    INSERT INTO [dbo].[HH_SA_RolePermissions] ([RoleID], [KeyID], [CanRead], [CanInsert], [CanUpdate], [CanDelete], [CanExecute], [CreatedOn], [Createdby])
    VALUES ('admin', 'returnreasons', 1, 1, 1, 1, 0, GETDATE(), 'system');
END
GO

-- Entity BU Control
IF NOT EXISTS (SELECT 1 FROM [dbo].[HH_EntityBUControl] WHERE [TableName] = 'ReturnReasons')
BEGIN
    INSERT INTO [dbo].[HH_EntityBUControl] ([TableName], [BUControl], [CreatedOn], [Createdby])
    VALUES ('ReturnReasons', 1, GETDATE(), 'system');
END
GO

-- =================================================================
-- DONE
-- =================================================================
PRINT '==========================================';
PRINT 'SalesBuzz SDK schema initialized successfully.';
PRINT 'Tables created:  32';
PRINT 'Stored Procedure: 1 (Get_AuditCriteria)';
PRINT 'Seed data: BU=C100, Users=demo/admin, Roles=user/admin';
PRINT '==========================================';
GO
