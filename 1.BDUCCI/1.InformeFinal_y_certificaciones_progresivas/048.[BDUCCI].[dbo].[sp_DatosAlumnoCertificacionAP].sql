USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_DatosAlumnoCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Lista los alumnos matriculados en la sección de CP
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_DatosAlumnoCertificacionAP]
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
	      Apellidos_Nombres  VARCHAR(200),
	      Telefono VARCHAR(20),
	      Correo_Continental  VARCHAR(100),
	      Correo_Personal  VARCHAR(100)
       )

       DECLARE @QUERY NVARCHAR(MAX) = '
       SELECT DNI,NOMBRE,TELEFONO,correo_continental,correo_personal
		   FROM OPENQUERY ('+@BDOracle+',''
			   SELECT DISTINCT A.DNI,A.NOMBRE,NVL(SPRTELE_PHONE_NUMBER,'''' '''') AS TELEFONO, A.DNI || ''''@continental.edu.pe'''' AS correo_continental,
						E.GOREMAL_EMAIL_ADDRESS AS correo_personal
				   FROM BANINST1.SZVALDI A
				   INNER JOIN BANINST1.SZVMALLA B 
					   ON B.PROGRAM=A.PROGRAM_CODE 
					   AND B.TERM_CODE_EFF=A.VERSION_PLAN 
					   AND B.KEY_RULE=A.ASIGNATURA 
					   AND B.AREA_CODE=A.AREA_CODE 
					   AND B.AREA_CODE='''''+@AreaCert+'''''
				   LEFT JOIN (
							SELECT C.GOREMAL_PIDM,C.GOREMAL_EMAIL_ADDRESS
								FROM GENERAL.GOREMAL C
								INNER JOIN (
										SELECT GOREMAL_PIDM,MAX(GOREMAL_SURROGATE_ID) AS GOREMALID
											FROM GENERAL.GOREMAL
											WHERE GOREMAL_EMAL_CODE=''''EPER''''
											GROUP BY GOREMAL_PIDM
											) D 
									ON D.GOREMAL_PIDM=C.GOREMAL_PIDM 
									AND D.GOREMALID=C.GOREMAL_SURROGATE_ID
								WHERE GOREMAL_EMAL_CODE=''''EPER'''') E 
					   ON E.GOREMAL_PIDM=A.PIDM
				   LEFT JOIN SATURN.SPRTELE F 
					   ON F.SPRTELE_PIDM=A.PIDM 
					   AND F.SPRTELE_SEQNO=2
				   WHERE A.DNI IN (' + @StudentList + ')
       ''
       )'

       INSERT INTO #RESULTADO
       EXEC (@QUERY)

       SELECT 
			  STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres))  AS 'No',  
			  Codigo ,
			  Apellidos_Nombres,
			  Telefono,
			  Correo_Continental,
			  Correo_Personal
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