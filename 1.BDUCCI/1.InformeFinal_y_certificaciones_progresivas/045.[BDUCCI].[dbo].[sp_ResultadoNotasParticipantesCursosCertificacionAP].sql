USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra la lista de cursos de los participantes de la certificación progresiva
====================================================================================================*/

CREATE PROCEDURE [dbo].[sp_ResultadoNotasParticipantesCursosCertificacionAP]
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
       
	DECLARE @BDOracle VARCHAR(10)='BANNER'
	   
	DECLARE @StudentList NVARCHAR(MAX) = ''
    SELECT @StudentList = @StudentList + '''''' + REPLACE(StudentCode, '''', '''''') + ''''','
    FROM @Students
        
    IF LEN(@StudentList) > 0
        SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)
	
    CREATE TABLE #RESULTADO ( 
       Curso VARCHAR(200)
    )

    DECLARE @QUERY NVARCHAR(MAX) = '
    SELECT CURSO FROM OPENQUERY ('+@BDOracle+',''
		SELECT DISTINCT NRC||'''' - ''''||NOMBRE_CURSO AS CURSO
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

    SELECT Curso   
		FROM #RESULTADO
		ORDER BY Curso 

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