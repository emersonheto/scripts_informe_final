USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_CertificacionProgramaCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Lista los alumnos que lograron la certificación en la sección de CP
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_CertificacionProgramaCertificacionAP]
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
          Codigo VARCHAR(10),
	      Apellidos_Nombres  VARCHAR(200)
       )


       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT DNI,NOMBRE
		   FROM OPENQUERY ('+@BDOracle+',''
		   WITH T_RESUMEN AS ( 
			  SELECT DNI,NOMBRE,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE,
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
				  GROUP BY DNI,NOMBRE,VERSION_PLAN,PROGRAM_CODE,DEPT_CODE)

		   SELECT DNI,NOMBRE
			   FROM T_RESUMEN A
			   INNER JOIN (
					  SELECT TERM_CODE_EFF, PROGRAM, COUNT(KEY_RULE) AS CANTCURSOS
						  FROM BANINST1.SZVMALLA
						  WHERE AREA_CODE='''''+@AreaCert+'''''
						  GROUP BY TERM_CODE_EFF, PROGRAM) B 
					ON B.TERM_CODE_EFF=A.VERSION_PLAN 
					AND B.PROGRAM=A.PROGRAM_CODE
			   WHERE A.CURSOSAPROBADOS=B.CANTCURSOS
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