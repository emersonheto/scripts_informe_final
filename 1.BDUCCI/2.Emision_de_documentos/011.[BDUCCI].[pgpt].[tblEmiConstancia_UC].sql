ALTER TABLE [pgpt].[tblEmiConstancia_UC] ADD [iddocumentofinalreportap] varchar(100) NULL
GO

EXEC sp_addextendedproperty
'MS_Description', N'emisión de documentos IF reportAP ',
'SCHEMA', N'pgpt',
'TABLE', N'tblEmiConstancia_UC',
'COLUMN', N'iddocumentofinalreportap'



