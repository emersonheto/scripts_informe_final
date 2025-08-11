USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoTipoAlumnoCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra los resultados por tipo de alumno
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoTipoAlumnoCertificacionAP]
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
		   Tipo VARCHAR(30),
		   IDAlumno INT
       )

       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT TipoAlumno,PIDM FROM OPENQUERY ('+@BDOracle+',''
			SELECT DISTINCT (CASE WHEN NVL(STYP_DESC,'''' '''')='''' '''' THEN ''''NO TIENE'''' ELSE STYP_DESC END) AS TipoAlumno,
					PIDM  
				FROM BANINST1.SZVALDI A
				INNER JOIN BANINST1.SZVMALLA B 
					ON B.PROGRAM=A.PROGRAM_CODE 
					AND B.TERM_CODE_EFF=A.VERSION_PLAN 
					AND B.KEY_RULE=A.ASIGNATURA 
					AND B.AREA_CODE=A.AREA_CODE 
					AND B.AREA_CODE='''''+@AreaCert+'''''
				WHERE A.DNI IN (' + @StudentList + ')
       ''
       )'

       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			  Tipo ,
			  COUNT(IDAlumno) AS Cantidad_Alumnos
		   FROM #RESULTADO 
		   GROUP BY Tipo

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