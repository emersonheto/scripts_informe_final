USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalResultadoNotasParticipantesFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Guarda los resultados de notas de los participantes
NRO		    FECHA		USUARIO					    MODIFICACION
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [BANNER].[sp_AddInfFinalResultadoNotasParticipantesFinalReportAp]
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
                Promedio INT,
                Tipo_Alumno VARCHAR(100),
                Estado_Academico VARCHAR(100),
                Estado_CAPP VARCHAR(100),
                Seccion VARCHAR(50),
                Programa VARCHAR(1000)
            )

            -- Consulta Oracle para Tipo_Reporte = 4
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            WITH cursos_con_intentos AS (
                SELECT 
                        A.PIDM,
                        A.DNI,
                        A.NOMBRE,
                        A.STUDYPATH_STATUS_DESC,
                        NVL(A.STYP_DESC, '' '') AS TIPO_ALUMNO,
                        A.VERSION_PLAN,
                        A.PROGRAM_CODE,
                        A.DEPT_CODE,
                        A.SUBJ_CODE,
                        A.CRSE_NUMB,
                        A.ASIGNATURA,
                        A.PORCENT_INASISTENCIA,
                        A.FECHA_INICIO_NRC,
                        A.ESTADO_ASIGNATURA,
                        TO_NUMBER(NVL(GRDE_CODE, ''0'')) AS NOTA,
                        A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS CURSO,
                        A.BLOQUE_MATRICULA AS SECCION,
                        A.PROGRAM_DESC AS PROGRAMA,
                        COUNT(A.PIDM) OVER (
                                PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB
                        ) AS total_intentos,
                        ROW_NUMBER() OVER (
                                PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB 
                                ORDER BY A.FECHA_INICIO_NRC DESC
                        ) AS orden_ultimo_intento
                FROM BANINST1.SZVALDI A
                WHERE A.DNI IN (' + @StudentList + ')
                        AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                        AND SUBSTR(A.AREA_CODE, 4, 1) <> ''C''
            ),
            T_NOTAS AS (
                SELECT 
                        PIDM,
                        DNI,
                        NOMBRE,
                        STUDYPATH_STATUS_DESC,
                        CURSO,
                        SUBJ_CODE,
                        CRSE_NUMB,
                        TIPO_ALUMNO,
                        PROGRAM_CODE,
                        PORCENT_INASISTENCIA,
                        NOTA,
                        VERSION_PLAN,
                        DEPT_CODE,
                        FECHA_INICIO_NRC,
                        ESTADO_ASIGNATURA,
                        total_intentos AS veces_cursado,
                        SECCION,
                        PROGRAMA
                FROM cursos_con_intentos
                WHERE orden_ultimo_intento = 1
            ),
            T_RESUMEN AS (
                SELECT 
                        PIDM,
                        STUDYPATH_STATUS_DESC,
                        VERSION_PLAN,
                        PROGRAM_CODE,
                        DEPT_CODE,
                        SUM(CASE 
                                        WHEN ESTADO_ASIGNATURA = ''Aprobado'' AND PORCENT_INASISTENCIA <= 20 
                                        THEN 1 ELSE 0 
                        END) AS CursosAprobados,
                        SUM(NOTA) AS SumaNotas
                FROM T_NOTAS
                GROUP BY PIDM, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
            ),
            T_ESTADO_FINAL AS (
                SELECT 
                        A.PIDM,
                        ROUND(A.SumaNotas / B.CANTCURSOS, 0) AS PROMEDIO,
                        CASE 
                                WHEN A.CursosAprobados = B.CANTCURSOS THEN ''APROBADO''
                                WHEN A.STUDYPATH_STATUS_DESC <> ''Activo'' THEN A.STUDYPATH_STATUS_DESC
                                ELSE ''DESAPROBADO''
                        END AS ESTADO_ACADEMICO
                FROM T_RESUMEN A
                INNER JOIN (
                        SELECT 
                                TERM_CODE_EFF, 
                                PROGRAM, 
                                MODALIDAD, 
                                COUNT(KEY_RULE) AS CANTCURSOS
                        FROM BANINST1.SZVMALLA
                        WHERE SUBSTR(AREA_CODE, 4, 1) <> ''C''
                        GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD
                ) B ON B.TERM_CODE_EFF = A.VERSION_PLAN 
                        AND B.PROGRAM = A.PROGRAM_CODE 
                        AND B.MODALIDAD = A.DEPT_CODE
            )
            SELECT 
                C.DNI AS CODIGO,
                C.NOMBRE AS APELLIDOS_NOMBRES,
                C.CURSO,
                C.NOTA,
                D.PROMEDIO,
                C.TIPO_ALUMNO,
                D.ESTADO_ACADEMICO,
                CASE 
                    WHEN (
                            SELECT MAX(NVL(SMBPOGN_REQUEST_NO, 0))
                            FROM SATURN.SMBPOGN PO
                            WHERE PO.SMBPOGN_TERM_CODE_EFF = C.VERSION_PLAN
                                    AND PO.SMBPOGN_PROGRAM = C.PROGRAM_CODE
                                    AND PO.SMBPOGN_PIDM = C.PIDM
                    ) = 0 THEN ''NO CAPP''
                    ELSE ''OK''
                END AS ESTADO_CAPP,
                C.SECCION,
                C.PROGRAMA
            FROM T_NOTAS C
            INNER JOIN T_ESTADO_FINAL D ON D.PIDM = C.PIDM
            ORDER BY C.DNI, C.SUBJ_CODE, C.CRSE_NUMB, C.FECHA_INICIO_NRC'

            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            WITH 
                cursos_con_intentos AS (
                    SELECT 
                        A.PIDM, A.DNI, A.NOMBRE, A.STUDYPATH_STATUS_DESC,
                        NVL(A.STYP_DESC, '' '') AS TIPO_ALUMNO, A.VERSION_PLAN, A.PROGRAM_CODE,
                        A.DEPT_CODE, A.ASIGNATURA, A.PORCENT_INASISTENCIA,
                        A.FECHA_INICIO_NRC, A.ESTADO_ASIGNATURA,
                        TO_NUMBER(NVL(GRDE_CODE, ''0'')) AS NOTA,
                        A.ASIGNATURA || '' - '' || A.NOMBRE_CURSO AS NOMBRE_CURSO_COMPLETO,
                        A.BLOQUE_MATRICULA AS SECCION, A.PROGRAM_DESC AS PROGRAMA,
                        ROW_NUMBER() OVER (
                            PARTITION BY A.DNI, A.ASIGNATURA 
                            ORDER BY A.FECHA_INICIO_NRC DESC
                        ) AS orden_ultimo_intento
                    FROM BANINST1.SZVALDI A
                    WHERE A.DNI IN (' + @StudentList + ')
                        AND A.AREA_CODE = ''' + REPLACE(@p_Area, '''', '''''') + '''
                ),
                T_NOTAS AS (
                    SELECT 
                        PIDM, DNI, NOMBRE, STUDYPATH_STATUS_DESC, TIPO_ALUMNO, 
                        VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, ASIGNATURA, 
                        PORCENT_INASISTENCIA, FECHA_INICIO_NRC, ESTADO_ASIGNATURA,
                        NOTA, NOMBRE_CURSO_COMPLETO, SECCION, PROGRAMA
                    FROM cursos_con_intentos
                    WHERE orden_ultimo_intento = 1
                ),
                T_RESUMEN AS (
                    SELECT 
                        PIDM, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                        SUM(CASE WHEN ESTADO_ASIGNATURA = ''Aprobado'' AND PORCENT_INASISTENCIA <= 20 THEN 1 ELSE 0 END) AS CursosAprobados,
                        SUM(NOTA) AS SumaNotas,
                        COUNT(ASIGNATURA) AS CursosLlevados
                    FROM T_NOTAS
                    GROUP BY PIDM, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
                ),
                T_ESTADO_FINAL AS (
                    SELECT 
                        A.PIDM,
                        -- CORRECCIÓN: El promedio se divide entre el total de cursos de la malla (B.CANTCURSOS).
                        CASE 
                            WHEN B.CANTCURSOS > 0 THEN ROUND(A.SumaNotas / B.CANTCURSOS, 0)
                            ELSE 0 
                        END AS PROMEDIO,
                        CASE 
                            WHEN A.CursosAprobados = B.CANTCURSOS THEN ''APROBADO''
                            WHEN A.STUDYPATH_STATUS_DESC <> ''Activo'' THEN A.STUDYPATH_STATUS_DESC
                            ELSE ''DESAPROBADO''
                        END AS ESTADO_ACADEMICO
                    FROM T_RESUMEN A
                    INNER JOIN (
                        SELECT 
                            TERM_CODE_EFF, PROGRAM, COUNT(KEY_RULE) AS CANTCURSOS
                        FROM BANINST1.SZVMALLA
                        WHERE AREA_CODE = ''' + REPLACE(@p_Area, '''', '''''') + '''
                        GROUP BY TERM_CODE_EFF, PROGRAM
                    ) B ON B.TERM_CODE_EFF = A.VERSION_PLAN AND B.PROGRAM = A.PROGRAM_CODE
                ),                
                ALUMNOS_CON_INFO_BASE AS (
                    SELECT DISTINCT DNI, NOMBRE, PIDM, TIPO_ALUMNO, VERSION_PLAN, PROGRAM_CODE
                    FROM T_NOTAS
                ),
                CURSOS_REQUERIDOS AS (
                    SELECT DISTINCT 
                        KEY_RULE AS ASIGNATURA, 
                        KEY_RULE || '' - '' || ASIGNATURA AS NOMBRE_CURSO_COMPLETO
                    FROM BANINST1.SZVMALLA 
                    WHERE AREA_CODE = ''' + REPLACE(@p_Area, '''', '''''') + '''
                ),
                GRID_ALUMNO_CURSO AS (
                    SELECT
                        A.DNI, A.NOMBRE, A.PIDM, A.TIPO_ALUMNO, A.VERSION_PLAN, A.PROGRAM_CODE,
                        C.ASIGNATURA, C.NOMBRE_CURSO_COMPLETO
                    FROM ALUMNOS_CON_INFO_BASE A
                    CROSS JOIN CURSOS_REQUERIDOS C
                )                
            SELECT 
                G.DNI AS CODIGO,
                G.NOMBRE AS APELLIDOS_NOMBRES,
                G.NOMBRE_CURSO_COMPLETO AS CURSO,
                NVL(C.NOTA, 0) AS NOTA, -- Si no hay nota, se pone 0
                D.PROMEDIO,
                G.TIPO_ALUMNO,
                D.ESTADO_ACADEMICO,
                CASE WHEN (
                    SELECT MAX(NVL(SMBPOGN_REQUEST_NO, 0))
                    FROM SATURN.SMBPOGN PO
                    WHERE PO.SMBPOGN_TERM_CODE_EFF = G.VERSION_PLAN
                        AND PO.SMBPOGN_PROGRAM = G.PROGRAM_CODE
                        AND PO.SMBPOGN_PIDM = G.PIDM
                ) = 0 THEN ''NO CAPP'' ELSE ''OK'' END AS ESTADO_CAPP,
                NVL(C.SECCION, '''') AS SECCION,    -- Si la sección es NULL, se convierte a ''
                NVL(C.PROGRAMA, '''') AS PROGRAMA  -- Si el programa es NULL, se convierte a ''
            FROM GRID_ALUMNO_CURSO G
            LEFT JOIN T_NOTAS C ON G.DNI = C.DNI AND G.ASIGNATURA = C.ASIGNATURA
            INNER JOIN T_ESTADO_FINAL D ON D.PIDM = G.PIDM
            ORDER BY G.DNI, G.NOMBRE_CURSO_COMPLETO
            '

            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP, Seccion, Programa)
            SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP, Seccion, Programa)
            SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;

                INSERT INTO [dbo].[tblInfFinalResultadoNotasParticipantes] (
                    Seccion, No, Codigo, Apellidos_Nombres, Curso, Nota, Promedio, 
                    TipoAlumno, Estado_Academico, Estado_CAPP, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    Seccion,
                    STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    Curso,
                    Nota,
                    Promedio,
                    Tipo_Alumno,
                    Estado_Academico,
                    Estado_CAPP,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY Codigo;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;

                INSERT INTO [dbo].[tblInfFinalResultadoNotasParticipantes] (
                    Seccion, No, Codigo, Apellidos_Nombres, Curso, Nota, Promedio, 
                    TipoAlumno, Estado_Academico, Estado_CAPP, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    ISNULL(Seccion, ''),
                    STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    Curso,
                    Nota,
                    Promedio,
                    Tipo_Alumno,
                    Estado_Academico,
                    Estado_CAPP,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY Codigo;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END        
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblInfFinalResultadoNotasParticipantes] 
            WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp
            
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
