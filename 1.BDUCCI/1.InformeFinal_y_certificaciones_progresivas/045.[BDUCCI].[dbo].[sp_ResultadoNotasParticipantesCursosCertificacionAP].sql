USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra la lista de cursos de los participantes de la certificación progresiva

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAP]
(
	 @XmlStudents XML,
     @AreaCert VARCHAR(20)
)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        DECLARE @BDOracle NVARCHAR(128) = N'BANNER';
        DECLARE @SafeAreacert NVARCHAR(MAX) = REPLACE(@AreaCert, '''', '''''');
        DECLARE @ExecQuery NVARCHAR(MAX);
        DECLARE @OracleQuery NVARCHAR(MAX);

        CREATE TABLE #RESULTADO ( 
            Curso VARCHAR(200)
        );

        SET @OracleQuery = N'
            SELECT DISTINCT KEY_RULE || '' - '' || ASIGNATURA AS CURSO
            FROM BANINST1.SZVMALLA 
            WHERE AREA_CODE = ''' + @SafeAreacert + '''';

        SET @ExecQuery = N'INSERT INTO #RESULTADO (Curso)
                           SELECT Curso FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')';

        EXEC sp_executesql @ExecQuery;

        SELECT Curso    
        FROM #RESULTADO
        ORDER BY Curso;

        DROP TABLE #RESULTADO;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#RESULTADO') IS NOT NULL DROP TABLE #RESULTADO;

        DECLARE @ErrorMessage VARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT  @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status;
    END CATCH
END