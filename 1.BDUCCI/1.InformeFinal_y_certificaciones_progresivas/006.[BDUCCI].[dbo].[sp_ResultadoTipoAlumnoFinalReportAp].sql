USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_ResultadoTipoAlumnoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Muestra los resultados por tipo de alumno
NRO		    FECHA		USUARIO					    MODIFICACION
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_ResultadoTipoAlumnoFinalReportAp] 
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
            RAISERROR('El par�metro @XmlStudents debe contener datos XML v�lidos', 16, 1)
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
            Tipo VARCHAR(30),
            IDAlumno INT
        )

        -- Consulta din�mica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        SELECT DISTINCT 
            (CASE WHEN NVL(STYP_DESC,'' '')='' '' THEN ''NO TIENE'' ELSE STYP_DESC END) AS TipoAlumno,
            PIDM  
        FROM BANINST1.SZVALDI
        WHERE DNI IN (' + @StudentList + ') 
            AND PROGRAM_CODE = ''' + @ProgramCode + '''
            AND SUBSTR(AREA_CODE,4,1) <> ''C'' '

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Tipo, IDAlumno)
        SELECT TipoAlumno AS Tipo, PIDM AS IDAlumno
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            Tipo,
            COUNT(IDAlumno) AS Cantidad_Alumnos
        FROM #RESULTADO 
        GROUP BY Tipo
        ORDER BY Tipo

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