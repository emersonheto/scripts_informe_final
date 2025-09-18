USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes
NRO		    FECHA		USUARIO					    MODIFICACION
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoNotasParticipantesFinalReportAp] 
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
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Curso VARCHAR(200),
            Nota INT,
            Promedio INT,
            Tipo_Alumno VARCHAR(30),
            Estado_Academico VARCHAR(20),
            Estado_CAPP VARCHAR(10)
        )

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
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
						-- A.NRC || '' - '' || A.NOMBRE_CURSO AS CURSO,
						A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS CURSO,
						COUNT(1) OVER (
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
						total_intentos AS veces_cursado
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
				END AS ESTADO_CAPP
		FROM T_NOTAS C
		INNER JOIN T_ESTADO_FINAL D ON D.PIDM = C.PIDM
		ORDER BY C.DNI, C.SUBJ_CODE, C.CRSE_NUMB, C.FECHA_INICIO_NRC
		'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP)
        SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            Curso,
            Nota,
            Promedio,
            Tipo_Alumno,
            Estado_Academico,
            Estado_CAPP
        FROM #RESULTADO 
        ORDER BY Codigo, Apellidos_Nombres

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