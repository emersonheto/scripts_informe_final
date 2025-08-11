USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoOrdenMeritoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de orden de mérito de los alumnos
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoOrdenMeritoFinalReportAp] 
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

        -- Tabla temporal para resultados (igual a la original)
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Curso VARCHAR(200),
            Nota INT,
            Promedio FLOAT,
            Orden VARCHAR(30)
        )

        -- Consulta dinámica manteniendo la estructura original pero con nuevos filtros
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        WITH T_NOTAS AS (
            SELECT PIDM,DNI,
            -- STUDYPATH_BLOQUE,
            STUDYPATH_STATUS_DESC,NOMBRE,NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE,ASIGNATURA,ESTADO_ASIGNATURA,PORCENT_INASISTENCIA,to_number(NVL(GRDE_CODE,''0'')) AS NOTA
            FROM BANINST1.SZVALDI
            WHERE DNI IN (' + @StudentList + ')
                AND PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(AREA_CODE,4,1)<>''C''   
        )             
        ,T_RESUMEN AS (
            SELECT PIDM,STUDYPATH_BLOQUE,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE,
                   SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 ELSE 0 END) AS CursosAprobados,
                   SUM(NOTA) AS SumaNotas
            FROM T_NOTAS
            GROUP BY PIDM,
            -- STUDYPATH_BLOQUE,
            VERSION_PLAN,PROGRAM_CODE,DEPT_CODE)
        ,T_APROBADOS AS (
            SELECT PIDM,SUMANOTAS,CANTCURSOS
            FROM T_RESUMEN A
            INNER JOIN (
                SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
                FROM BANINST1.SZVMALLA
                GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD) B ON B.TERM_CODE_EFF=A.VERSION_PLAN AND B.PROGRAM=A.PROGRAM_CODE AND B.MODALIDAD=A.DEPT_CODE
            WHERE CURSOSAPROBADOS=CANTCURSOS)

        SELECT DNI,NOMBRE,NOMBRE_CURSO,NOTA,D.PROMEDIO,
               (CASE WHEN ORDEN=1 THEN ''PRIMER LUGAR'' 
                     WHEN ORDEN=2 THEN ''SEGUNDO LUGAR'' 
                     ELSE ''TERCER LUGAR'' END) AS ORDEN 
        FROM T_NOTAS C
        INNER JOIN 
            (SELECT PIDM,ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
             FROM T_APROBADOS) D ON C.PIDM=D.PIDM
        INNER JOIN
            (SELECT ROWNUM AS ORDEN,PROMEDIO 
             FROM
                (SELECT DISTINCT ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
                 FROM T_APROBADOS
                 ORDER BY PROMEDIO DESC)
             WHERE ROWNUM <= 3) E ON E.PROMEDIO=D.PROMEDIO'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Orden)
        SELECT DNI AS Codigo, 
               NOMBRE AS Apellidos_Nombres,
               NOMBRE_CURSO AS Curso,
               NOTA,
               PROMEDIO,
               ORDEN
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales (igual al original)
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Promedio DESC)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            Curso,
            CONVERT(VARCHAR,Nota) AS Nota,
            CONVERT(VARCHAR,ROUND(Promedio,2)) AS Promedio,
            Orden
        FROM #RESULTADO 
        ORDER BY Promedio DESC, Apellidos_Nombres

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