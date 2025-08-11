USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: dbo.sp_ProgramacionEquipoDocenteFinalReportAp
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Trae la lista de docentes
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ProgramacionEquipoDocenteFinalReportAp] 
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
            CICLO NVARCHAR(5),
            ASIGNATURA VARCHAR(200),
            APELLIDOS_NOMBRE_DOCENTE VARCHAR(200),
            HORAS_LECTIVAS FLOAT,
            FECHA_INICIO_ASIGNATURA DATE,
            FECHA_FIN_ASIGNATURA DATE
        )

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        SELECT CICLO, NOMBRE_CURSO, NOMBRE_DOCENTE, HT AS HORAS_LECTIVAS, 
               MIN(FECHA_INICIO) AS FECHA_INICIO, MAX(FECHA_FIN) AS FECHA_FIN
        FROM (
            SELECT DISTINCT SUBSTR(A.AREA_DESC,9,3) AS CICLO, A.NOMBRE_CURSO, A.NOMBRE_DOCENTE, 
                   B.HT, C.SSRMEET_START_DATE AS FECHA_INICIO, C.SSRMEET_END_DATE AS FECHA_FIN
            FROM BANINST1.SZVALDI A
            INNER JOIN BANINST1.SZVMALLA B 
                ON B.PROGRAM = A.PROGRAM_CODE 
                AND B.TERM_CODE_EFF = A.VERSION_PLAN 
                AND B.KEY_RULE = A.ASIGNATURA
            INNER JOIN SSRMEET C 
                ON C.SSRMEET_TERM_CODE = A.PERIODO_MATRICULA 
                AND C.SSRMEET_CRN = A.NRC
            WHERE A.DNI IN (' + @StudentList + ') 
                AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(A.AREA_CODE,4,1) <> ''C''     
        )
        GROUP BY CICLO, NOMBRE_CURSO, NOMBRE_DOCENTE, HT'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (CICLO, ASIGNATURA, APELLIDOS_NOMBRE_DOCENTE, HORAS_LECTIVAS, FECHA_INICIO_ASIGNATURA, FECHA_FIN_ASIGNATURA)
        SELECT CICLO, NOMBRE_CURSO AS ASIGNATURA, NOMBRE_DOCENTE AS APELLIDOS_NOMBRE_DOCENTE, 
               HORAS_LECTIVAS, FECHA_INICIO AS FECHA_INICIO_ASIGNATURA, FECHA_FIN AS FECHA_FIN_ASIGNATURA
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT CICLO AS [Ciclo],
              ASIGNATURA AS [Asignaturas],
              APELLIDOS_NOMBRE_DOCENTE AS [Docente],
              str(HORAS_LECTIVAS) AS [Horas_Lectivas],
              FECHA_INICIO_ASIGNATURA AS [Fecha_Inicio],
              FECHA_FIN_ASIGNATURA AS [Fecha_Fin]
        FROM #RESULTADO 
        ORDER BY CICLO, FECHA_INICIO_ASIGNATURA

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