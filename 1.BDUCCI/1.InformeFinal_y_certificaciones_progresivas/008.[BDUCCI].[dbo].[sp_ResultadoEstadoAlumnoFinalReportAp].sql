USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados por estado de alumno
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoEstadoAlumnoFinalReportAp] 
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
            Estado VARCHAR(20),
            IDAlumno INT
        )

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        WITH T_CURSOSAPROBADOS AS (
            SELECT PIDM, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                   SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 
                       ELSE 0 END) AS CursosAprobados
            FROM BANINST1.SZVALDI
            WHERE DNI IN (' + @StudentList + ')
                AND PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(AREA_CODE,4,1)<>''C''
                AND NVL(STUDYPATH_BLOQUE, '' '') = BLOQUE_MATRICULA
            GROUP BY PIDM, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
        )
        SELECT (CASE WHEN A.CURSOSAPROBADOS=B.CANTCURSOS THEN ''APROBADO'' 
                    ELSE (CASE WHEN A.STUDYPATH_STATUS_DESC<>''Activo'' THEN A.STUDYPATH_STATUS_DESC 
                        ELSE ''DESAPROBADO'' END) END) AS ESTADO_ACADEMICO,
               A.PIDM
        FROM T_CURSOSAPROBADOS A
        INNER JOIN (
            SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
            FROM BANINST1.SZVMALLA
            GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD
        ) B ON B.TERM_CODE_EFF=A.VERSION_PLAN 
            AND B.PROGRAM=A.PROGRAM_CODE 
            AND B.MODALIDAD=A.DEPT_CODE'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Estado, IDAlumno)
        SELECT Estado_Academico AS Estado, PIDM AS IDAlumno
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            Estado,
            COUNT(IDAlumno) AS Cantidad_Alumnos
        FROM #RESULTADO 
        GROUP BY Estado
        ORDER BY Estado

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