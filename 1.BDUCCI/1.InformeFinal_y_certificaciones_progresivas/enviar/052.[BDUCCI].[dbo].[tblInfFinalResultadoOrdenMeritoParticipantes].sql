USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.tblInfFinalResultadoOrdenMeritoParticipantes
FECHA	: 08/09/2025
AUTOR	: Emerson Herrera(Waytech)
OBJETIVO: Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final

====================================================================================================*/

ALTER TABLE [dbo].[tblInfFinalResultadoOrdenMeritoParticipantes] ALTER COLUMN [Seccion] varchar(50) NULL
