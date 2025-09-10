USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[SP_AddInfFinalSeccionCertificarAPFinalReport]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar Matos (Waytech)
OBJETIVO: Registro de la información de la sección a certificar para los tipos 4 y 5
====================================================================================================*/

CREATE PROCEDURE [BANNER].[SP_AddInfFinalSeccionCertificarAPFinalReport] 
(
	@XmlStudents XML,
	@ProgramCode VARCHAR(3),
	@p_Area VARCHAR(20) = NULL,
	@p_Tipo_Reporte INT,
	@p_user_creacion VARCHAR(200),	
	@p_Accion INT,
	@p_IdDocumentoFinalReportAp VARCHAR(50)
)
AS 
SET NOCOUNT ON
BEGIN
   BEGIN TRY
        -- Validación de parámetros
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos con la estructura <Students><Student><StudentCode>valor</StudentCode></Student></Students>', 16, 1)
            RETURN
        END
        
        IF NULLIF(@ProgramCode, '') IS NULL
        BEGIN
            RAISERROR('El parámetro @ProgramCode es requerido', 16, 1)
            RETURN
        END

        -- Crear tabla temporal para los estudiantes
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9) PRIMARY KEY
        )

        -- Insertar datos del XML
        INSERT INTO @Students (StudentCode)
        SELECT DISTINCT
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;

        -- Verificar que se hayan procesado estudiantes
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron códigos de estudiante válidos en el XML proporcionado', 16, 1)
            RETURN
        END


		IF (@p_Accion=1)
		BEGIN
			DECLARE        
	        @BDOracle VARCHAR(10) = 'BANNER'
	        
	        CREATE TABLE #RESULTADO (
	            PROGRAMA VARCHAR(100),
	            SEDE VARCHAR(20),
	            FECHA_INICIO DATETIME,
	            FECHA_FIN DATETIME
	        )

            -- Construir lista de estudiantes para Oracle
            DECLARE @StudentList NVARCHAR(MAX) = ''
            SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
            FROM @Students
            
            IF LEN(@StudentList) > 0
                SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)
	        
	        DECLARE @OracleQuery NVARCHAR(MAX) = N'
			SELECT 
				PROGRAM_DESC,
				MIN(REPLACE(REPLACE (CAMP_DESC, ''SEDE '', ''''), ''FILIAL '', '''')) AS CAMP_DESC,       
				MIN(FECHA_INICIO_NRC) AS FECHA_INICIO_NRC,
				MAX(FECHA_TERMINO_NRC) AS FECHA_TERMINO_NRC
			FROM BANINST1.SZVALDI
			WHERE PROGRAM_CODE = ''' + @ProgramCode + ''' AND DNI IN (' + @StudentList + ')
			GROUP BY PROGRAM_DESC'
	        
			DECLARE @QUERY NVARCHAR(MAX) = N'
	        INSERT INTO #RESULTADO (PROGRAMA, SEDE, FECHA_INICIO, FECHA_FIN)
	        SELECT PROGRAM_DESC, CAMP_DESC, FECHA_INICIO_NRC, FECHA_TERMINO_NRC
	        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'
	
	        EXEC sp_executesql @QUERY

			INSERT INTO [dbo].[tblInfFinalSeccionCertificar]
			SELECT
				'' AS Seccion
				,PROGRAMA
				,SEDE
				,NULL
				,NULL
				,CONVERT(DATETIME, FECHA_INICIO)
				,CONVERT(DATETIME, FECHA_FIN)
				,NULL
				,NULL
				,GETDATE()
				,NULL
				,@p_user_creacion
				,NULL
				,@p_Tipo_Reporte
				,CASE
					WHEN @p_Tipo_Reporte = 4 THEN ''
					WHEN @p_Tipo_Reporte = 5 Then @p_Area
				END [Area]
				,@ProgramCode
				,@p_IdDocumentoFinalReportAp
			FROM #RESULTADO
			
			SELECT 0 AS 'NRO_RESPUESTA',
				'SE INSERTÓ CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG'
			
		END
		ELSE IF(@p_Accion=2)
		BEGIN
				DELETE FROM [dbo].[tblInfFinalSeccionCertificar]
				WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp

				SELECT 1 AS 'NRO_RESPUESTA',
		              'SE ELIMINÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG'
		END
   END 
	 TRY
   BEGIN 
	 CATCH
        SELECT 
            ERROR_NUMBER() AS 'NRO_RESPUESTA',
            ERROR_MESSAGE() AS 'MSG'
   END CATCH
END