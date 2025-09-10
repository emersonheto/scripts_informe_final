USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes de la certificación

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final

====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoNotasParticipantesCertificacionAP]
(
    @XmlStudents XML,
    @AreaCert VARCHAR(20)
)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos', 16, 1)
            RETURN
        END

        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)')
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)

        DECLARE @BDOracle VARCHAR(10) = 'BANNER';

        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        DECLARE @SafeAreacert NVARCHAR(MAX) = REPLACE(@AreaCert, '''', '''''');

        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Curso VARCHAR(200),
            Nota INT,
            Promedio INT,
            Tipo_Alumno VARCHAR(30),
            Estado_Academico VARCHAR(20),
            Estado_CAPP VARCHAR(10)
        )

        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        WITH 
            intentos_del_programa AS (
                SELECT 
                    PIDM, DNI, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, NOMBRE,
                    A.ASIGNATURA || '' - '' || NOMBRE_CURSO AS NOMBRE_CURSO,
                    NVL(STYP_DESC, '' '') AS TIPO_ALUMNO,
                    VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, A.ASIGNATURA,
                    ESTADO_ASIGNATURA, PORCENT_INASISTENCIA,
                    TO_NUMBER(NVL(GRDE_CODE, ''0'')) AS NOTA,
                    A.FECHA_INICIO_NRC
                FROM BANINST1.SZVALDI A
                INNER JOIN BANINST1.SZVMALLA B 
                    ON B.PROGRAM = A.PROGRAM_CODE 
                    AND B.TERM_CODE_EFF = A.VERSION_PLAN 
                    AND B.KEY_RULE = A.ASIGNATURA 
                    AND B.AREA_CODE = A.AREA_CODE 
                    AND B.AREA_CODE = ''' + @SafeAreacert + '''
                WHERE A.DNI IN (' + @StudentList + ')
            ), 
            T_NOTAS AS (
                SELECT *
                FROM (
                    SELECT 
                        i.*,
                        ROW_NUMBER() OVER(
                            PARTITION BY i.DNI, i.ASIGNATURA 
                            ORDER BY i.FECHA_INICIO_NRC DESC
                        ) AS orden_ultimo_intento
                    FROM intentos_del_programa i
                )
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
                    -- =================== INICIO DE LA CORRECCIÓN DEL PROMEDIO ===================
                    -- El promedio ahora se divide entre el total de cursos de la malla (B.CANTCURSOS), no los llevados.
                    CASE 
                        WHEN B.CANTCURSOS > 0 THEN ROUND(A.SumaNotas / B.CANTCURSOS, 0)
                        ELSE 0
                    END AS PROMEDIO, 
                    -- =================== FIN DE LA CORRECCIÓN DEL PROMEDIO =====================
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
                    WHERE AREA_CODE = ''' + @SafeAreacert + '''
                    GROUP BY TERM_CODE_EFF, PROGRAM
                ) B ON B.TERM_CODE_EFF = A.VERSION_PLAN 
                    AND B.PROGRAM = A.PROGRAM_CODE
            ),
            ALUMNOS_CON_INFO_BASE AS (
                SELECT DISTINCT DNI, NOMBRE, PIDM, TIPO_ALUMNO, VERSION_PLAN, PROGRAM_CODE
                FROM T_NOTAS
            ),
            CURSOS_REQUERIDOS AS (
                SELECT DISTINCT KEY_RULE AS ASIGNATURA, KEY_RULE || '' - '' || ASIGNATURA AS NOMBRE_CURSO 
                FROM BANINST1.SZVMALLA 
                WHERE AREA_CODE = ''' + @SafeAreacert + '''
            ),
            GRID_ALUMNO_CURSO AS (
                SELECT
                    A.DNI, A.NOMBRE, A.PIDM, A.TIPO_ALUMNO, A.VERSION_PLAN, A.PROGRAM_CODE,
                    C.ASIGNATURA, C.NOMBRE_CURSO
                FROM ALUMNOS_CON_INFO_BASE A
                CROSS JOIN CURSOS_REQUERIDOS C
            )
        SELECT 
            G.DNI AS CODIGO, 
            G.NOMBRE AS APELLIDOS_NOMBRES, 
            G.NOMBRE_CURSO AS CURSO,
            NVL(C.NOTA, 0) AS NOTA,
            D.PROMEDIO, 
            G.TIPO_ALUMNO, 
            D.ESTADO_ACADEMICO,
            CASE 
                WHEN (
                    SELECT MAX(NVL(SMBPOGN_REQUEST_NO, 0))
                    FROM SATURN.SMBPOGN PO
                    WHERE PO.SMBPOGN_TERM_CODE_EFF = G.VERSION_PLAN
                        AND PO.SMBPOGN_PROGRAM = G.PROGRAM_CODE
                        AND PO.SMBPOGN_PIDM = G.PIDM
                ) = 0 THEN ''NO CAPP''
                ELSE ''OK''
            END AS ESTADO_CAPP
        FROM GRID_ALUMNO_CURSO G
        LEFT JOIN T_NOTAS C ON G.DNI = C.DNI AND G.ASIGNATURA = C.ASIGNATURA
        INNER JOIN T_ESTADO_FINAL D ON D.PIDM = G.PIDM
        ORDER BY G.DNI, G.NOMBRE_CURSO
        '

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP)
        SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Codigo, Curso)) AS 'No',
            Codigo,
            Apellidos_Nombres,
            Curso,
            Nota,
            Promedio,
            Tipo_Alumno,
            Estado_Academico,
            Estado_CAPP
        FROM #RESULTADO
        ORDER BY Codigo, Curso

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