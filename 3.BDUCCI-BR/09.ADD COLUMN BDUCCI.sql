USE [BDUCCI]
GO
/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Brus Paucar (WAYTECH)
OBJETIVO	: Crear tablas y añadir columnas a tablas existentes
=================================================================================================================== */ 

--Agregar columnas en tabla Certificacion
ALTER TABLE [dbo].[tblInfFinalSeccionCertificar] ADD    
    [Programa_Codigo] VARCHAR(3),
    [IdDocumentoFinalReportAp] VARCHAR(50)

--va a permitir saber a partir de qué id temporal se creó el id definitivo
ALTER TABLE [dbo].[tblDocumentoFinalReportAp] ADD
    [IdDocumentoFinalReportApTMP] VARCHAR(50)