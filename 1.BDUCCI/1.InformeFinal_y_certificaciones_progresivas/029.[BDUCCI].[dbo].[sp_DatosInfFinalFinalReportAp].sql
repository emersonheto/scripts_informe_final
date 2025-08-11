USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_DatosInfFinalFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Lista los datos generales del Informe
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_DatosInfFinalFinalReportAp] 
(
	 @Seccion VARCHAR(20),
	 @TipoReporte INT,
	 @Area VARCHAR(20)
)
AS
SET NOCOUNT ON
BEGIN
	BEGIN TRY
	
	SET LANGUAGE Spanish
	
	IF @TipoReporte = 4
	BEGIN
		SELECT 
			SC.Seccion,
			ISNULL(Nombre_Programa,' ') AS  Nombre_Programa,
			ISNULL(Nombre_Sede,' ') AS  Nombre_Sede,
			ISNULL(Edicion,' ') AS Edicion,
			ISNULL(Ciclo,' ') AS Ciclo ,
			CONVERT(VARCHAR(20),DATENAME(MONTH,GETDATE())) Mes_Crea,
			CONVERT(VARCHAR(4),DATEPART(yy,GETDATE())) Anio_Crea,
			(DATENAME(DAY,Fecha_Inicio) + ' de '+ DATENAME(MONTH,Fecha_Inicio) + ' del ' + DATENAME(year,Fecha_Inicio)) AS Fecha_Inicio,
			(DATENAME(DAY,Fecha_Fin) + ' de '+ DATENAME(MONTH,Fecha_Fin) + ' del ' + DATENAME(year,Fecha_Fin)) AS Fecha_Fin,
			ISNULL(Empresa,' ') AS Empresa 
		FROM [dbo].[tblInfFinalSeccionCertificar] SC
		LEFT JOIN [dbo].[tblInfFinalDatosEntidades] DE 
			ON DE.Seccion=SC.Seccion 
			AND DE.Tipo_Reporte=SC.Tipo_Reporte
		WHERE SC.Seccion = @Seccion
			AND SC.Tipo_Reporte = @TipoReporte
	END
	
	IF @TipoReporte = 5
	BEGIN
		SELECT 
			SC.Seccion,
			ISNULL(Nombre_Programa,' ') AS  Nombre_Programa,
			ISNULL(Nombre_Sede,' ') AS  Nombre_Sede,
			ISNULL(Edicion,' ') AS Edicion,
			ISNULL(Ciclo,' ') AS Ciclo ,
			CONVERT(VARCHAR(20),DATENAME(MONTH,GETDATE())) Mes_Crea,
			CONVERT(VARCHAR(4),DATEPART(yy,GETDATE())) Anio_Crea,
			(DATENAME(DAY,Fecha_Inicio) + ' de '+ DATENAME(MONTH,Fecha_Inicio) + ' del ' + DATENAME(year,Fecha_Inicio)) AS Fecha_Inicio,
			(DATENAME(DAY,Fecha_Fin) + ' de '+ DATENAME(MONTH,Fecha_Fin) + ' del ' + DATENAME(year,Fecha_Fin)) AS Fecha_Fin,
			ISNULL(Empresa,' ') AS Empresa 
		FROM [dbo].[tblInfFinalSeccionCertificar] SC
		LEFT JOIN [dbo].[tblInfFinalDatosEntidades] DE 
			ON DE.Seccion=SC.Seccion 
			AND DE.Tipo_Reporte=SC.Tipo_Reporte
		WHERE SC.Seccion = @Seccion
			AND SC.Tipo_Reporte = @TipoReporte
			AND SC.Area = @Area
	END
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
				SELECT @ErrorMessage AS status
	END CATCH

END