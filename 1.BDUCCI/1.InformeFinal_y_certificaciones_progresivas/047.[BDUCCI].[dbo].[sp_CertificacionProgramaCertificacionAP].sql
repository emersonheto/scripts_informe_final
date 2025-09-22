USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_CertificacionProgramaCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Lista los alumnos que lograron la certificaci�n en la secci�n de CP

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACI�N
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_CertificacionProgramaCertificacionAP]
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
           RAISERROR('El par�metro @XmlStudents debe contener datos XML v�lidos', 16, 1)
           RETURN
       END
       
       DECLARE @Students TABLE (
           StudentCode VARCHAR(9)
       )

       INSERT INTO @Students (StudentCode)
       SELECT 
           Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
       FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
       
	   DECLARE  @BDOracle VARCHAR(10)='BANNER'
	   
	   DECLARE @StudentList NVARCHAR(MAX) = ''
       SELECT @StudentList = @StudentList + '''''' + REPLACE(StudentCode, '''', '''''') + ''''','
       FROM @Students
        
       IF LEN(@StudentList) > 0
           SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

       CREATE TABLE #RESULTADO ( 
          Codigo VARCHAR(10),
	      Apellidos_Nombres  VARCHAR(200)
       )


       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT DNI,NOMBRE
		   FROM OPENQUERY ('+@BDOracle+',''
			WITH T_ULTIMO_INTENTO AS (
			-- Paso 1: Aislamos el �LTIMO INTENTO de cada curso para cada alumno.
			SELECT
				A.DNI, A.NOMBRE, A.VERSION_PLAN, A.PROGRAM_CODE, A.DEPT_CODE,
				A.ESTADO_ASIGNATURA, A.PORCENT_INASISTENCIA,
				ROW_NUMBER() OVER(PARTITION BY A.DNI, A.ASIGNATURA ORDER BY A.FECHA_TERMINO_NRC DESC) as orden_intento
			FROM BANINST1.SZVALDI A
			INNER JOIN BANINST1.SZVMALLA B
				ON B.PROGRAM = A.PROGRAM_CODE
				AND B.TERM_CODE_EFF = A.VERSION_PLAN
				AND B.KEY_RULE = A.ASIGNATURA
			WHERE
				B.AREA_CODE = '''''+ @AreaCert + '''''
				AND A.DNI IN (' + @StudentList + ')
			),
			T_RESUMEN_APROBADOS AS (
			-- Paso 2: Contamos los cursos aprobados del alumno, bas�ndonos solo en su �ltimo intento.
			SELECT
				DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
				SUM(CASE WHEN ESTADO_ASIGNATURA = ''''Aprobado'''' AND PORCENT_INASISTENCIA <= 20 THEN 1 ELSE 0 END) AS CursosAprobados
			FROM T_ULTIMO_INTENTO
			WHERE orden_intento = 1
			GROUP BY
				DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE
			),
			T_TOTAL_CURSOS AS (
			-- Paso 3: Contamos el total de cursos requeridos por la malla para ese AreaCert.
			SELECT
				TERM_CODE_EFF, PROGRAM, MODALIDAD,
				COUNT(KEY_RULE) AS CANTCURSOS
			FROM BANINST1.SZVMALLA
			WHERE
				AREA_CODE = '''''+ @AreaCert + '''''
			GROUP BY
				TERM_CODE_EFF, PROGRAM, MODALIDAD
			)
			-- Paso 4: Comparamos el total de aprobados del alumno (A) con el total requerido por la malla (B).
			SELECT
			A.DNI,
			A.NOMBRE
			FROM T_RESUMEN_APROBADOS A
			INNER JOIN T_TOTAL_CURSOS B
			ON B.TERM_CODE_EFF = A.VERSION_PLAN
			AND B.PROGRAM = A.PROGRAM_CODE
			AND B.MODALIDAD = A.DEPT_CODE
			WHERE
			A.CursosAprobados = B.CANTCURSOS
       ''
       )'
       
	   INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			  STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres))  AS 'No',  
			  Codigo ,
			  Apellidos_Nombres
          FROM #RESULTADO 
          ORDER BY Apellidos_Nombres

       DROP TABLE #RESULTADO
	END TRY
	BEGIN CATCH
		DECLARE	@ErrorMessage VARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage =ERROR_MESSAGE(),
				@ErrorSeverity=ERROR_SEVERITY(),
				@ErrorState=ERROR_STATE();
				RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
				SELECT @ErrorMessage AS status
	END CATCH
END