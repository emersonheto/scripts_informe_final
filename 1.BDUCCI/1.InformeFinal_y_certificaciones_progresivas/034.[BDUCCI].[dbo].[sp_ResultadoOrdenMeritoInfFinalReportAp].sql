USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Muestra los resultados de orden de mérito de los participantes
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp]
(
    --@XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @TipoReporte INT,
    @Area VARCHAR(20),
    @IdDocumentoFinalReportAp VARCHAR(15)
)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        -- Obtener orden de mérito
        SELECT  
            CONVERT(VARCHAR(10), ROW_NUMBER() OVER (ORDER BY Promedio DESC, Apellidos_Nombres)) AS No,
            Codigo,
            Apellidos_Nombres,
            Curso,
            CONVERT(VARCHAR, Nota) AS Nota,
            CONVERT(VARCHAR, ROUND(Promedio, 2)) AS Promedio,
            Orden
        FROM [dbo].[tblInfFinalResultadoOrdenMeritoParticipantes]
        WHERE Programa_Codigo = @ProgramCode
            AND Tipo_Reporte = @TipoReporte
            AND UPPER(ISNULL(Area,'')) = (CASE WHEN @TipoReporte=5 THEN UPPER(@Area) ELSE UPPER(ISNULL(Area,'')) END)
            AND IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp 
        ORDER BY Promedio DESC, Apellidos_Nombres

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT  @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status
    END CATCH
END