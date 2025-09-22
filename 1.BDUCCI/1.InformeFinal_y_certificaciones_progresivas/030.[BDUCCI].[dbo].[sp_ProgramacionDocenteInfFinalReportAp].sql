USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ProgramacionDocenteInfFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Reporte de programacion de horarios de docentes
NRO		    FECHA		USUARIO					    MODIFICACI�N
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/
ALTER PROCEDURE [dbo].[sp_ProgramacionDocenteInfFinalReportAp] 
(
    @IdDocumentoFinalReportAp VARCHAR(50)
)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
 
    ;WITH Grupos AS (
        SELECT  
            Asignaturas,
            Docente,
            SUM(CASE WHEN ISNUMERIC(Horas_Lectivas) = 1 THEN CAST(Horas_Lectivas AS INT) ELSE 0 END) AS Horas_Lectivas,
            MIN(Fecha_Inicio) AS Fecha_Inicio,
            MAX(Fecha_Fin) AS Fecha_Fin
        FROM 
            [dbo].[tblInfFinalProgramacionDocente]
        WHERE 
            IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp
        GROUP BY 
            Asignaturas, Docente
    )
    SELECT
        STUFF((
            SELECT DISTINCT ', ' + T2.Ciclo
            FROM [dbo].[tblInfFinalProgramacionDocente] T2
            WHERE T2.IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp
              AND T2.Asignaturas = G.Asignaturas
              AND T2.Docente = G.Docente
            FOR XML PATH('')
        ), 1, 2, '') AS Ciclo,
        G.Asignaturas,
        G.Docente,        
        G.Horas_Lectivas,
        G.Fecha_Inicio,
        G.Fecha_Fin
    FROM 
        Grupos G
    ORDER BY 
        G.Asignaturas, G.Docente;

    END TRY
    BEGIN CATCH
        SELECT 
            -1 AS NRO_RESPUESTA,
            ERROR_MESSAGE() AS MSG;
    END CATCH      
END