USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[SP_AddInfFinalResultadoOrdenMeritoParticipantesFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Guarda los resultados de orden de mérito de los participantes
====================================================================================================*/

ALTER PROCEDURE [BANNER].[SP_AddInfFinalResultadoOrdenMeritoParticipantesFinalReportAp]
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
    	SET @p_IdDocumentoFinalReportAp = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, 'TMP000'), REPLACE(@p_user_creacion, ' ', ''))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
    
        -- Validación de parámetros más robusta
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos con la estructura <Students><Student><StudentCode>valor</StudentCode></Student></Students>', 16, 1)
            RETURN
        END
        
        IF NULLIF(@ProgramCode, '') IS NULL
        BEGIN
            RAISERROR('El parámetro @ProgramCode es requerido', 16, 1)
            RETURN
        END

        -- Crear tabla temporal para los estudiantes con clave primaria
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        -- Insertar datos del XML con validación
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;

        -- Verificar que se hayan procesado estudiantes
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron códigos de estudiante válidos en el XML proporcionado', 16, 1)
            RETURN
        END

        -- Construir lista de Students para Oracle (método compatible con versiones anteriores)
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        DECLARE @BDOracle VARCHAR(10)='BANNER';
        
        IF (@p_Accion=1)
        BEGIN
            -- Crear tabla temporal para resultados
            CREATE TABLE #RESULTADO ( 
                Codigo VARCHAR(100),
                Apellidos_Nombres VARCHAR(200),
                Curso VARCHAR(200),
                Nota INT,
                Promedio FLOAT,
                Orden VARCHAR(100),
                Seccion VARCHAR(50),
                Programa VARCHAR(100)
            )        

            -- Consultas Oracle separadas para mejor legibilidad

            -- Consulta Oracle para Tipo_Reporte = 4
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            WITH T_NOTAS AS (
                SELECT PIDM, DNI, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, NOMBRE, 
                       NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO, VERSION_PLAN, 
                       PROGRAM_CODE, DEPT_CODE, ASIGNATURA, ESTADO_ASIGNATURA, 
                       PORCENT_INASISTENCIA, to_number(NVL(GRDE_CODE,''0'')) AS NOTA,
                       BLOQUE_MATRICULA AS SECCION,
                       PROGRAM_DESC AS PROGRAMA
                    FROM BANINST1.SZVALDI
                    WHERE DNI IN (' + @StudentList + ')
                        AND PROGRAM_CODE = ''' + @ProgramCode + '''
                        
                        AND SUBSTR(AREA_CODE,4,1)<>''C'')
            ,T_RESUMEN AS (
                SELECT PIDM, STUDYPATH_BLOQUE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                        SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 ELSE 0 END) AS CursosAprobados,
                        SUM(NOTA) AS SumaNotas
                    FROM T_NOTAS
                    GROUP BY PIDM, STUDYPATH_BLOQUE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE)
            ,T_APROBADOS AS (
                SELECT PIDM, SUMANOTAS, CANTCURSOS
                    FROM T_RESUMEN A
                    INNER JOIN (
                            SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
                            FROM BANINST1.SZVMALLA
                            GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD) B 
                        ON B.TERM_CODE_EFF=A.VERSION_PLAN 
                        AND B.PROGRAM=A.PROGRAM_CODE 
                        AND B.MODALIDAD=A.DEPT_CODE
                    WHERE CURSOSAPROBADOS=CANTCURSOS)

                SELECT DNI, NOMBRE, NOMBRE_CURSO, NOTA, D.PROMEDIO,
                        (CASE WHEN ORDEN=1 THEN ''PRIMER LUGAR'' 
                            WHEN ORDEN=2 THEN ''SEGUNDO LUGAR'' 
                            ELSE ''TERCER LUGAR'' END) AS ORDEN,
                        SECCION,
                        PROGRAMA
                    FROM T_NOTAS C
                    INNER JOIN 
                            (SELECT PIDM, ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
                                FROM T_APROBADOS) D 
                        ON C.PIDM=D.PIDM
                    INNER JOIN
                            (SELECT ROWNUM AS ORDEN, PROMEDIO 
                                FROM
                                    (SELECT DISTINCT ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
                                        FROM T_APROBADOS
                                        ORDER BY PROMEDIO DESC)
                                WHERE ROWNUM <= 3) E 
                        ON E.PROMEDIO=D.PROMEDIO'

            -- Consulta Oracle para Tipo_Reporte = 5
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            WITH T_NOTAS AS (
                SELECT PIDM, DNI, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, NOMBRE, 
                       NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO,
                       VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, A.ASIGNATURA, 
                       ESTADO_ASIGNATURA, PORCENT_INASISTENCIA, 
                       TO_NUMBER(NVL(GRDE_CODE,''0'')) AS NOTA,
                       BLOQUE_MATRICULA AS SECCION,
                       PROGRAM_DESC AS PROGRAMA
                    FROM BANINST1.SZVALDI A
                    WHERE DNI IN (' + @StudentList + ')
                        AND PROGRAM_CODE = ''' + @ProgramCode + '''
                        
                        AND AREA_CODE=''' + @p_Area + ''')
            ,T_RESUMEN AS (
                SELECT PIDM, STUDYPATH_BLOQUE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                        SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 ELSE 0 END) AS CursosAprobados,
                        SUM(NOTA) AS SumaNotas
                    FROM T_NOTAS
                    GROUP BY PIDM, STUDYPATH_BLOQUE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE)
            ,T_APROBADOS AS (
                SELECT PIDM, SUMANOTAS, CANTCURSOS
                    FROM T_RESUMEN A
                    INNER JOIN (
                            SELECT TERM_CODE_EFF, PROGRAM, COUNT(KEY_RULE) AS CANTCURSOS
                                FROM BANINST1.SZVMALLA
                                WHERE AREA_CODE=''' + @p_Area + '''
                                GROUP BY TERM_CODE_EFF, PROGRAM) B 
                        ON B.TERM_CODE_EFF=A.VERSION_PLAN 
                        AND B.PROGRAM=A.PROGRAM_CODE
                    WHERE CURSOSAPROBADOS=CANTCURSOS)

                SELECT DNI, NOMBRE, NOMBRE_CURSO, NOTA, D.PROMEDIO,
                        (CASE WHEN ORDEN=1 THEN ''PRIMER LUGAR'' 
                            WHEN ORDEN=2 THEN ''SEGUNDO LUGAR'' 
                            ELSE ''TERCER LUGAR'' END) AS ORDEN,
                        SECCION,
                        PROGRAMA
                    FROM T_NOTAS C
                    INNER JOIN 
                            (SELECT PIDM, ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
                                FROM T_APROBADOS) D 
                        ON C.PIDM=D.PIDM
                    INNER JOIN
                            (SELECT ROWNUM AS ORDEN, PROMEDIO 
                                FROM
                                    (SELECT DISTINCT ROUND(SUMANOTAS/CANTCURSOS,3) AS PROMEDIO
                                        FROM T_APROBADOS
                                        ORDER BY PROMEDIO DESC)
                                WHERE ROWNUM <= 3) E 
                        ON E.PROMEDIO=D.PROMEDIO'

            -- Consultas dinámicas completas con INSERT
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Orden, Seccion, Programa)
            SELECT DNI, NOMBRE, NOMBRE_CURSO, NOTA, PROMEDIO, ORDEN, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Orden, Seccion, Programa)
            SELECT DNI, NOMBRE, NOMBRE_CURSO, NOTA, PROMEDIO, ORDEN, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;

                INSERT INTO dbo.tblInfFinalResultadoOrdenMeritoParticipantes (
                    Seccion, No, Codigo, Apellidos_Nombres, Curso, Nota, 
                    Promedio, Orden, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp)
                SELECT
                    Seccion,
                    STR(ROW_NUMBER() OVER (ORDER BY Promedio DESC)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    Curso,
                    CONVERT(VARCHAR,Nota) AS Nota,
                    CONVERT(VARCHAR,Promedio) AS Promedio,
                    Orden,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode,
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY Promedio DESC, Apellidos_Nombres;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;

                INSERT INTO dbo.tblInfFinalResultadoOrdenMeritoParticipantes (
                    Seccion, No, Codigo, Apellidos_Nombres, Curso, Nota, 
                    Promedio, Orden, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp)
                SELECT
                    Seccion,
                    STR(ROW_NUMBER() OVER (ORDER BY Promedio DESC)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    Curso,
                    CONVERT(VARCHAR,Nota) AS Nota,
                    CONVERT(VARCHAR,Promedio) AS Promedio,
                    Orden,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode,
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO
                ORDER BY Promedio DESC, Apellidos_Nombres;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblInfFinalResultadoOrdenMeritoParticipantes] 
            WHERE Programa_Codigo = @ProgramCode 
            AND Tipo_Reporte = @p_Tipo_Reporte;
            
            SELECT 0 AS 'NRO_RESPUESTA',
                    'SE ELIMINÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';            
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status;
    END CATCH
END