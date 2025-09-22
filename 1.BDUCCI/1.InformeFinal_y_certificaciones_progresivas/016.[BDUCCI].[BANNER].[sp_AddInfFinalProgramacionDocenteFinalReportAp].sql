USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[SP_AddInfFinalProgramacionDocenteFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Guarda la programacion de horarios de los docentes
NRO		    FECHA		USUARIO					    MODIFICACION
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento
====================================================================================================*/

ALTER PROCEDURE [BANNER].[SP_AddInfFinalProgramacionDocenteFinalReportAp]
    @XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @p_Area VARCHAR(20),
    @p_Tipo_Reporte INT,
    @p_user_creacion VARCHAR(200),
    @p_Accion INT,
    @p_IdDocumento VARCHAR(5),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        -- Validaci�n de par�metros
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El par�metro @XmlStudents debe contener datos XML v�lidos con la estructura <Students><Student><StudentCode>valor</StudentCode></Student></Students>', 16, 1)
            RETURN
        END
        
        IF NULLIF(@ProgramCode, '') IS NULL
        BEGIN
            RAISERROR('El par�metro @ProgramCode es requerido', 16, 1)
            RETURN
        END

        -- Crear tabla temporal para los estudiantes
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9) PRIMARY KEY
        )

        -- Insertar datos del XML
        INSERT INTO @Students (StudentCode)
        SELECT DISTINCT
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;

        -- Verificar que se hayan procesado estudiantes
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron c�digos de estudiante v�lidos en el XML proporcionado', 16, 1)
            RETURN
        END

        IF(@p_Accion=1)
        BEGIN
            DECLARE @BDOracle VARCHAR(10)='BANNER';

            -- Crear tabla temporal sin �ndice
            CREATE TABLE #RESULTADO ( 
                CICLO NVARCHAR(10),
                ASIGNATURA VARCHAR(200),
                APELLIDOS_NOMBRE_DOCENTE VARCHAR(200),
                HORAS_LECTIVAS FLOAT,
                FECHA_INICIO_ASIGNATURA DATE,
                FECHA_FIN_ASIGNATURA DATE,
                SECCION VARCHAR(50),
                PROGRAMA VARCHAR(1000)
            )
            
            -- Construir lista de estudiantes para Oracle
            DECLARE @StudentList NVARCHAR(MAX) = ''
            SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
            FROM @Students
            
            IF LEN(@StudentList) > 0
                SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

            -- Query 4 para Oracle
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            WITH datos_base AS (
                SELECT 
                    CASE
                        -- MAESTR�AS
                        WHEN A.PROGRAM_CODE LIKE ''MG%''  THEN 
                            TRIM(REGEXP_SUBSTR(A.AREA_DESC, ''(I{1,3}|IV|V|VI{1,3}|IX|X)''))
                        -- PROGRAMAS DE ESPECIALIZACI�N / DIPLOMADOS
                        WHEN A.PROGRAM_CODE LIKE ''P%'' OR A.PROGRAM_CODE LIKE ''D%'' THEN 
                            ''�NICO''
                        -- OTROS (CGR, cursos libres, etc.)
                        ELSE 
                            ''�NICO''
                    END AS CICLO,
                    A.NOMBRE_CURSO,
                    A.NOMBRE_DOCENTE,
                    B.HT AS HORAS_LECTIVAS,
                    C.SSRMEET_START_DATE,
                    C.SSRMEET_END_DATE,
                    A.BLOQUE_MATRICULA AS SECCION,
                    A.PROGRAM_DESC AS PROGRAMA
                FROM 
                    BANINST1.SZVALDI A
                    INNER JOIN BANINST1.SZVMALLA B ON (
                        B.PROGRAM = A.PROGRAM_CODE 
                        AND B.TERM_CODE_EFF = A.VERSION_PLAN 
                        AND B.KEY_RULE = A.ASIGNATURA
                        AND B.MODALIDAD = A.DEPT_CODE
                        AND A.AREA_CODE = B.AREA_CODE
                    )
                    INNER JOIN SATURN.SSRMEET C ON (
                        C.SSRMEET_TERM_CODE = A.PERIODO_MATRICULA 
                        AND C.SSRMEET_CRN = A.NRC
                    )
                WHERE 
                    A.DNI IN (' + @StudentList + ')
                    AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                    AND SUBSTR(A.AREA_CODE,4,1) <> ''C''
            )
            SELECT DISTINCT
                CICLO,
                NOMBRE_CURSO,
                NOMBRE_DOCENTE,
                HORAS_LECTIVAS,
                TO_CHAR(MIN(SSRMEET_START_DATE), ''YYYY-MM-DD'') AS FECHA_INICIO,
                TO_CHAR(MAX(SSRMEET_END_DATE), ''YYYY-MM-DD'') AS FECHA_FIN,
                SECCION,
                PROGRAMA
            FROM datos_base
            GROUP BY 
                CICLO,
                NOMBRE_CURSO,
                NOMBRE_DOCENTE,
                HORAS_LECTIVAS,
                SECCION,
                PROGRAMA';
            
            -- Query 5 para Oracle
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
                SELECT CICLO,
                        NOMBRE_CURSO,
                        NOMBRE_DOCENTE,
                        HT AS HORAS_LECTIVAS,
                        MIN(FECHA_INICIO) AS FECHA_INICIO,
                        MAX(FECHA_FIN) AS FECHA_FIN,
                        SECCION,
                        PROGRAMA
                FROM (
                    SELECT DISTINCT
                        CASE
                            -- MAESTR�AS
                            WHEN A.PROGRAM_CODE LIKE ''MG%'' THEN 
                                TRIM(REGEXP_SUBSTR(A.AREA_DESC, ''(I{1,3}|IV|V|VI{1,3}|IX|X)''))
                            -- PROGRAMAS DE ESPECIALIZACI�N / DIPLOMADOS
                            WHEN A.PROGRAM_CODE LIKE ''P%'' OR A.PROGRAM_CODE LIKE ''D%'' THEN 
                                ''�NICO''
                            -- OTROS (CGR, cursos libres, etc.)
                            ELSE 
                                ''�NICO''
                        END AS CICLO,                        
                        A.NOMBRE_CURSO,
                        A.NOMBRE_DOCENTE,
                        B.HT,
                        C.SSRMEET_START_DATE AS FECHA_INICIO,
                        C.SSRMEET_END_DATE AS FECHA_FIN,
                        A.BLOQUE_MATRICULA AS SECCION,
                        A.PROGRAM_DESC AS PROGRAMA
                    FROM BANINST1.SZVALDI A
                    INNER JOIN BANINST1.SZVMALLA B 
                        ON B.PROGRAM = A.PROGRAM_CODE 
                        AND B.TERM_CODE_EFF = A.VERSION_PLAN 
                        AND B.KEY_RULE = A.ASIGNATURA 
                        AND B.AREA_CODE = ''' + @p_Area + '''
                    INNER JOIN SATURN.SSRMEET C 
                        ON C.SSRMEET_TERM_CODE = A.PERIODO_MATRICULA 
                        AND C.SSRMEET_CRN = A.NRC
                    WHERE A.DNI IN (' + @StudentList + ')
                )
                GROUP BY CICLO,
                        SECCION,
                        NOMBRE_CURSO,
                        NOMBRE_DOCENTE,
                        HT,
                        PROGRAMA
            ';
            
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (
                CICLO, ASIGNATURA, APELLIDOS_NOMBRE_DOCENTE, 
                HORAS_LECTIVAS, FECHA_INICIO_ASIGNATURA, FECHA_FIN_ASIGNATURA,
                SECCION, PROGRAMA
            )
            SELECT 
                CICLO, 
                NOMBRE_CURSO AS ASIGNATURA, 
                NOMBRE_DOCENTE AS APELLIDOS_NOMBRE_DOCENTE, 
                HORAS_LECTIVAS, 
                CAST(FECHA_INICIO AS DATE) AS FECHA_INICIO_ASIGNATURA, 
                CAST(FECHA_FIN AS DATE) AS FECHA_FIN_ASIGNATURA,
                SECCION,
                PROGRAMA
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')';
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (
                CICLO, ASIGNATURA, APELLIDOS_NOMBRE_DOCENTE, 
                HORAS_LECTIVAS, FECHA_INICIO_ASIGNATURA, FECHA_FIN_ASIGNATURA,
                SECCION, PROGRAMA
            )
            SELECT 
                CICLO, 
                NOMBRE_CURSO AS ASIGNATURA, 
                NOMBRE_DOCENTE AS APELLIDOS_NOMBRE_DOCENTE, 
                HORAS_LECTIVAS, 
                CAST(FECHA_INICIO AS DATE) AS FECHA_INICIO_ASIGNATURA, 
                CAST(FECHA_FIN AS DATE) AS FECHA_FIN_ASIGNATURA,
                SECCION,
                PROGRAMA
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')';

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;
            
                INSERT INTO [dbo].[tblInfFinalProgramacionDocente] (
                    Seccion, Ciclo, Asignaturas, Docente, Horas_Lectivas, 
                    Fecha_Inicio, Fecha_Fin, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT 
                    SECCION AS 'Seccion',
                    CICLO AS 'Ciclo',
                    ASIGNATURA AS 'Asignaturas',
                    ISNULL(APELLIDOS_NOMBRE_DOCENTE,'') AS 'Docente',
                    STR(ISNULL(HORAS_LECTIVAS,0)) AS 'Horas_Lectivas',
                    FECHA_INICIO_ASIGNATURA AS 'Fecha_Inicio',
                    FECHA_FIN_ASIGNATURA AS 'Fecha_Fin',
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    PROGRAMA AS 'Programa',
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY CICLO, FECHA_INICIO_ASIGNATURA;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERT� CORRECTAMENTE LA PROGRAMACI�N DOCENTE' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
	            EXEC sp_executesql @QUERY5;
                
                WITH CTE AS (
                        SELECT 
                            SECCION,
                            CICLO,
                            ASIGNATURA,
                            APELLIDOS_NOMBRE_DOCENTE,
                            HORAS_LECTIVAS,
                            FECHA_INICIO_ASIGNATURA,
                            FECHA_FIN_ASIGNATURA,
                            PROGRAMA,
                            ROW_NUMBER() OVER (
                                PARTITION BY CICLO, ASIGNATURA, APELLIDOS_NOMBRE_DOCENTE
                                ORDER BY FECHA_INICIO_ASIGNATURA
                            ) AS RN
                        FROM #RESULTADO
                    )
            
                INSERT INTO [dbo].[tblInfFinalProgramacionDocente] (
                    Seccion, Ciclo, Asignaturas, Docente, Horas_Lectivas, 
                    Fecha_Inicio, Fecha_Fin, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT 
                    SECCION AS 'Seccion',
                    CICLO AS 'Ciclo',
                    ASIGNATURA AS 'Asignaturas',
                    ISNULL(APELLIDOS_NOMBRE_DOCENTE,'') AS 'Docente',
                    STR(ISNULL(HORAS_LECTIVAS,0)) AS 'Horas_Lectivas',
                    FECHA_INICIO_ASIGNATURA AS 'Fecha_Inicio',
                    FECHA_FIN_ASIGNATURA AS 'Fecha_Fin',
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    PROGRAMA AS 'Programa',
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM CTE
                 WHERE RN = 1
                ORDER BY CICLO, FECHA_INICIO_ASIGNATURA;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERT� CORRECTAMENTE LA PROGRAMACI�N DOCENTE' AS 'MSG';
            END
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblInfFinalProgramacionDocente]             
            WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp
            
            SELECT 0 AS 'NRO_RESPUESTA',
                'ELIMINAR PROGRAMACI�N DOCENTE' AS 'MSG';
        END
    END TRY 
    BEGIN CATCH        
        IF OBJECT_ID('tempdb..#RESULTADO') IS NOT NULL
            DROP TABLE #RESULTADO;
            
        SELECT -1 AS 'NRO_RESPUESTA',
            ERROR_MESSAGE() AS 'MSG';
    END CATCH
END
