USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra los resultados de notas de los participantes de la certificación
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
		-- Validar XML
		IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
		BEGIN
			RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos', 16, 1)
			RETURN
		END

		-- Tabla temporal de alumnos
		DECLARE @Students TABLE (
			StudentCode VARCHAR(9)
		)

		INSERT INTO @Students (StudentCode)
		SELECT 
			Student.value('(StudentCode)[1]', 'VARCHAR(9)')
		FROM @XmlStudents.nodes('/Students/Student') AS T(Student)

		DECLARE @BDOracle VARCHAR(10) = 'DEVL';

		-- Construir lista de alumnos
		DECLARE @StudentList NVARCHAR(MAX) = ''
		SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
		FROM @Students
		
		IF LEN(@StudentList) > 0
			SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

		-- Tabla de resultados
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

		-- Consulta Oracle
		DECLARE @OracleQuery NVARCHAR(MAX) = N'
		WITH 
			T_NOTAS AS (
				SELECT 
					PIDM,
					DNI,
					STUDYPATH_BLOQUE,
					STUDYPATH_STATUS_DESC,
					NOMBRE,
					--NRC || '' - '' || NOMBRE_CURSO AS NOMBRE_CURSO,
					A.ASIGNATURA || '' - '' || NOMBRE_CURSO AS NOMBRE_CURSO,
					NVL(STYP_DESC, '' '') AS TIPO_ALUMNO,
					VERSION_PLAN,
					PROGRAM_CODE,
					DEPT_CODE,
					A.ASIGNATURA,
					ESTADO_ASIGNATURA,
					PORCENT_INASISTENCIA,
					TO_NUMBER(NVL(GRDE_CODE, ''0'')) AS NOTA
				FROM BANINST1.SZVALDI A
				INNER JOIN BANINST1.SZVMALLA B 
					ON B.PROGRAM = A.PROGRAM_CODE 
					AND B.TERM_CODE_EFF = A.VERSION_PLAN 
					AND B.KEY_RULE = A.ASIGNATURA 
					AND B.AREA_CODE = A.AREA_CODE 
					AND B.AREA_CODE = ''' + @AreaCert + '''
				WHERE A.DNI IN (' + @StudentList + ')
				--SUBSTR(AREA_CODE, 4, 1) <> ''C''
			),
			T_RESUMEN AS (
				SELECT 
					PIDM,
					STUDYPATH_BLOQUE,
					STUDYPATH_STATUS_DESC,
					VERSION_PLAN,
					PROGRAM_CODE,
					DEPT_CODE,
					SUM(CASE WHEN ESTADO_ASIGNATURA = ''Aprobado'' AND PORCENT_INASISTENCIA <= 20 THEN 1 ELSE 0 END) AS CursosAprobados,
					SUM(NOTA) AS SumaNotas
				FROM T_NOTAS
				GROUP BY PIDM, STUDYPATH_BLOQUE, STUDYPATH_STATUS_DESC, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
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
						COUNT(KEY_RULE) AS CANTCURSOS
					FROM BANINST1.SZVMALLA
					WHERE AREA_CODE = ''' + @AreaCert + '''
					GROUP BY TERM_CODE_EFF, PROGRAM
				) B ON B.TERM_CODE_EFF = A.VERSION_PLAN AND B.PROGRAM = A.PROGRAM_CODE
			)
		SELECT 
			C.DNI AS CODIGO,
			C.NOMBRE AS APELLIDOS_NOMBRES,
			C.NOMBRE_CURSO AS CURSO,
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
		ORDER BY C.DNI, C.NOMBRE_CURSO
		'

		-- Ejecutar contra Oracle
		DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Curso, Nota, Promedio, Tipo_Alumno, Estado_Academico, Estado_CAPP)
        SELECT CODIGO, APELLIDOS_NOMBRES, CURSO, NOTA, PROMEDIO, TIPO_ALUMNO, ESTADO_ACADEMICO, ESTADO_CAPP
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

		EXEC sp_executesql @QUERY

		-- Resultado final
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
