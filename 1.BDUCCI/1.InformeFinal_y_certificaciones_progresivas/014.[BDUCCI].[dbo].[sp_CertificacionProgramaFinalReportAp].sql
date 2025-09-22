USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_CertificacionProgramaFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los datos de Certificaci�n
NRO		    FECHA		USUARIO					    MODIFICACION
1           22/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el �ltimo intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_CertificacionProgramaFinalReportAp] 
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

        
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200)
        )

        
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        WITH T_RESUMEN AS ( 
            SELECT DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                   SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 
                       ELSE 0 END) AS CursosAprobados
            FROM BANINST1.SZVALDI
            WHERE DNI IN (' + @StudentList + ')
                AND PROGRAM_CODE = ''' + @ProgramCode + '''
                AND SUBSTR(AREA_CODE,4,1)<>''C''                
            GROUP BY DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE)

        SELECT DNI, NOMBRE
        FROM T_RESUMEN A
        INNER JOIN (
            SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
            FROM BANINST1.SZVMALLA
            WHERE SUBSTR(AREA_CODE,4,1)<>''C''  
            GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD) B 
               ON B.TERM_CODE_EFF=A.VERSION_PLAN 
               AND B.PROGRAM=A.PROGRAM_CODE 
               AND B.MODALIDAD=A.DEPT_CODE
        WHERE A.CURSOSAPROBADOS=B.CANTCURSOS'

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres)
        SELECT DNI AS Codigo, 
               NOMBRE AS Apellidos_Nombres
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
            Codigo,
            Apellidos_Nombres
        FROM #RESULTADO 
        ORDER BY Apellidos_Nombres

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