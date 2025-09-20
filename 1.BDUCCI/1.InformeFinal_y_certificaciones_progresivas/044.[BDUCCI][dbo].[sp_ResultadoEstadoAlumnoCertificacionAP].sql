USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoEstadoAlumnoCertificacionAp]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra los resultados de los alumnos de la certificación

MODIFICACIONES:
NRO		FECHA		USUARIO					    MODIFICACIÓN
1       17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoEstadoAlumnoCertificacionAp]
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
           Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
       FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
       
	   DECLARE  @BDOracle VARCHAR(10)='BANNER'
	   
	   DECLARE @StudentList NVARCHAR(MAX) = ''
       SELECT @StudentList = @StudentList + '''''' + REPLACE(StudentCode, '''', '''''') + ''''','
       FROM @Students
        
       IF LEN(@StudentList) > 0
           SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

       CREATE TABLE #RESULTADO ( 
		   Estado VARCHAR(20),
		   IDAlumno INT
       )

	   DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT Estado_Academico,PIDM FROM OPENQUERY ('+@BDOracle+',''
       WITH T_CURSOSAPROBADOS AS (
          SELECT PIDM,STUDYPATH_STATUS_DESC,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE,
                 SUM(CASE WHEN ESTADO_ASIGNATURA=''''Aprobado'''' AND PORCENT_INASISTENCIA<=20 THEN 1 
 	                 ELSE 0 END) AS CursosAprobados
			  FROM BANINST1.SZVALDI A
			  INNER JOIN BANINST1.SZVMALLA B 
				  ON B.PROGRAM=A.PROGRAM_CODE 
				  AND B.TERM_CODE_EFF=A.VERSION_PLAN 
				  AND B.KEY_RULE=A.ASIGNATURA 
				  AND B.AREA_CODE=A.AREA_CODE 
				  AND B.AREA_CODE='''''+@AreaCert+'''''
			  WHERE A.DNI IN (' + @StudentList + ')
			  GROUP BY PIDM,STUDYPATH_STATUS_DESC,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE)

		SELECT (CASE WHEN A.CURSOSAPROBADOS>=B.CANTCURSOS THEN ''''APROBADO'''' 
					ELSE (CASE WHEN A.STUDYPATH_STATUS_DESC<>''''Activo'''' THEN A.STUDYPATH_STATUS_DESC 
					ELSE ''''DESAPROBADO'''' END) END) AS ESTADO_ACADEMICO,
					A.PIDM
			FROM T_CURSOSAPROBADOS A
			INNER JOIN (
						SELECT TERM_CODE_EFF, PROGRAM, COUNT(KEY_RULE) AS CANTCURSOS
							FROM BANINST1.SZVMALLA
							WHERE AREA_CODE='''''+@AreaCert+'''''
							GROUP BY TERM_CODE_EFF, PROGRAM) B 
				ON B.TERM_CODE_EFF=A.VERSION_PLAN 
				AND B.PROGRAM=A.PROGRAM_CODE
			''
          )
          '
       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			 Estado ,
			 COUNT(IDAlumno) AS Cantidad_Alumnos
		   FROM #RESULTADO 
		   GROUP BY Estado

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