USE [BDUCCI]
GO

/* ===================================================================================================================
NOMBRE		: [pgpt].[tblEmiConstancia_UC]
FECHA		: 17/09/2025
AUTOR		: Emerson Herrera Waytech
OBJETIVO	: Agregar columna iddocumentofinalreportap a tabla emiconstancias
=================================================================================================================== */
ALTER TABLE [pgpt].[tblEmiConstancia_UC] ADD [iddocumentofinalreportap] varchar(100) NULL
GO

EXEC sp_addextendedproperty
'MS_Description', N'emisión de documentos IF reportAP ',
'SCHEMA', N'pgpt',
'TABLE', N'tblEmiConstancia_UC',
'COLUMN', N'iddocumentofinalreportap'



