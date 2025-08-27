USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ProgramacionEquipoDocenteCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra la programacion de horarios de los docentes de la certificación
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ProgramacionEquipoDocenteCertificacionAP] 
(
	 @XmlStudents XML,
	 @AreaCert VARCHAR (20)
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
	      CICLO NVARCHAR(5),
		  SECCION VARCHAR(50),
	      ASIGNATURA VARCHAR(200),
	      APELLIDOS_NOMBRE_DOCENTE VARCHAR(200),
	      HORAS_LECTIVAS FLOAT,
	      FECHA_INICIO_ASIGNATURA DATE,
	      FECHA_FIN_ASIGNATURA DATE
       )

       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT CICLO,SECCION,NOMBRE_CURSO,NOMBRE_DOCENTE,HORAS_LECTIVAS,FECHA_INICIO,FECHA_FIN
		   FROM OPENQUERY ('+@BDOracle+',''
			  SELECT CICLO,SECCION,NOMBRE_CURSO,NOMBRE_DOCENTE,HT AS HORAS_LECTIVAS,MIN(FECHA_INICIO) AS FECHA_INICIO,MAX(FECHA_FIN) AS FECHA_FIN
				  FROM (
					 SELECT DISTINCT
						CASE
								-- MAESTRÍAS
								WHEN A.PROGRAM_CODE LIKE ''''MG%''''  THEN 
									TRIM(REGEXP_SUBSTR(A.AREA_DESC, ''''(I{1,3}|IV|V|VI{1,3}|IX|X)''''))

								-- PROGRAMAS DE ESPECIALIZACIÓN / DIPLOMADOS
								WHEN A.PROGRAM_CODE LIKE ''''P%'''' OR A.PROGRAM_CODE LIKE ''''D%'''' THEN 
										''''MÓDULO''''
								
								-- OTROS (CGR, cursos libres, etc.)
								ELSE 
										''''ÚNICO''''
						END AS CICLO,
					 
					 A.SECCION,A.NOMBRE_CURSO,A.NOMBRE_DOCENTE,B.HT,C.SSRMEET_START_DATE AS FECHA_INICIO,C.SSRMEET_END_DATE AS FECHA_FIN
						 FROM BANINST1.SZVALDI A
						 INNER JOIN BANINST1.SZVMALLA B 
							 ON B.PROGRAM=A.PROGRAM_CODE 
							 AND B.TERM_CODE_EFF=A.VERSION_PLAN 
							 AND B.KEY_RULE=A.ASIGNATURA 
							 AND B.AREA_CODE='''''+@AreaCert+'''''
							 --AND SUBSTR(B.AREA_CODE,4,1)<>''''C'''' --BR: Si la lista inicial es correcta, no debe llevar esto
						 INNER JOIN SATURN.SSRMEET C 
							 ON C.SSRMEET_TERM_CODE=A.PERIODO_MATRICULA 
							 AND C.SSRMEET_CRN=A.NRC
						 WHERE A.DNI IN (' + @StudentList + ')
							 --AND SUBSTR(A.AREA_CODE,4,1)<>''''C'''' --BR: Si la lista inicial es correcta, no debe llevar esto
					 )
			  GROUP BY CICLO,SECCION,NOMBRE_CURSO,NOMBRE_DOCENTE,HT
          ''
       )'
					
       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT CICLO AS 'Ciclo',
				SECCION AS 'Seccion',
				ASIGNATURA AS 'Asignaturas',
				APELLIDOS_NOMBRE_DOCENTE AS 'Docente',
				str(HORAS_LECTIVAS) AS 'Horas_Lectivas',
				FECHA_INICIO_ASIGNATURA AS 'Fecha_Inicio',
				FECHA_FIN_ASIGNATURA AS 'Fecha_Fin'
		   FROM #RESULTADO 
		   ORDER BY CICLO,FECHA_INICIO

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