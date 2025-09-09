USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes
NRO		    FECHA		USUARIO					    MODIFICACION
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp]
(
    @XmlStudents XML,
    @ProgramCode VARCHAR(3)
)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        -- Validar XML de entrada
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos', 16, 1)
            RETURN
        END
        
        -- Crear tabla temporal para los estudiantes
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        -- Insertar datos del XML
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)

        DECLARE @BDOracle VARCHAR(10) = 'BANNER';

        -- Construir lista de Students para Oracle
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        -- Tabla temporal para resultados
        CREATE TABLE #RESULTADO ( 
            Curso VARCHAR(200)
        ) 
        
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        SELECT DISTINCT 
            A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS CURSO,
            A.CRSE_NUMB, 
            A.FECHA_INICIO_NRC
        FROM (
                SELECT DISTINCT
                        SUBJ_CODE, CRSE_NUMB, NOMBRE_CURSO, FECHA_INICIO_NRC,
                        ROW_NUMBER() OVER (PARTITION BY DNI, SUBJ_CODE, CRSE_NUMB ORDER BY FECHA_INICIO_NRC DESC) AS orden_ultimo_intento
                FROM BANINST1.SZVALDI
                WHERE DNI IN (' + @StudentList + ')
                AND PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(AREA_CODE,4,1) <>  ''C''
        ) A
        WHERE A.orden_ultimo_intento = 1
        '

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Curso)
        SELECT CURSO
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT DISTINCT Curso   
        FROM #RESULTADO
        ORDER BY Curso

        DROP TABLE #RESULTADO
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status
    END CATCH
END