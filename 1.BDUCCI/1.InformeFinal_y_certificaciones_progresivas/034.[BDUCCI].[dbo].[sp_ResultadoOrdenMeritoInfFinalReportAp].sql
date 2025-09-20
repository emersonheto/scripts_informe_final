USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Muestra los resultados de orden de mérito de los participantes

NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoOrdenMeritoInfFinalReportAp]
(
    --@XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @TipoReporte INT,
    @Area VARCHAR(20),
    @IdDocumentoFinalReportAp VARCHAR(50)
)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        -- Obtener orden de mérito, numerado por curso, con reconteo desde el 1 por estudiante
        SELECT  
            CONVERT(VARCHAR(10), ROW_NUMBER() OVER (
                PARTITION BY Codigo 
                ORDER BY Curso
            )) AS No,
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
        ORDER BY Promedio DESC, Apellidos_Nombres, Curso

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