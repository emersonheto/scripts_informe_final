USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoNotasParticipantesCursosFinalReportAp]
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

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        SELECT DISTINCT NRC||'' - ''||NOMBRE_CURSO AS CURSO
        FROM BANINST1.SZVALDI A
        INNER JOIN BANINST1.SZVMALLA B 
            ON B.TERM_CODE_EFF=A.VERSION_PLAN 
            AND B.PROGRAM=A.PROGRAM_CODE 
            AND B.MODALIDAD=A.DEPT_CODE
        WHERE A.DNI IN (' + @StudentList + ')
            AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
            AND SUBSTR(A.AREA_CODE,4,1)<>''C''            
            AND NVL(A.STUDYPATH_BLOQUE, '' '') = A.BLOQUE_MATRICULA'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Curso)
        SELECT CURSO
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT Curso   
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