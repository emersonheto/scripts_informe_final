USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos
FECHA	: 08/09/2025
AUTOR	: Emerson Herrera(Waytech)
OBJETIVO: Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final

====================================================================================================*/

ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] ADD [Area] varchar(20) NULL
GO
ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] ALTER COLUMN [Seccion] varchar(50)  NULL

