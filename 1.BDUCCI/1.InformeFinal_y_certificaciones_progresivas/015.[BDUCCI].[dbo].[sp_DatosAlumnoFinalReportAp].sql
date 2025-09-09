USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_DatosAlumnoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra los datos de los alumnos par el Informe
NRO		    FECHA		USUARIO					    MODIFICACION
1           08/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_DatosAlumnoFinalReportAp] 
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
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos', 16, 1)
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

        -- Tabla temporal para resultados (igual a la original)
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Telefono VARCHAR(20),
            Correo_Continental VARCHAR(100),
            Correo_Personal VARCHAR(100)
        )

        -- Consulta dinámica manteniendo la estructura original pero con nuevos filtros
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
        SELECT DISTINCT A.DNI, A.NOMBRE, NVL(SPRTELE_PHONE_NUMBER,'' '') AS TELEFONO, 
               A.DNI || ''@continental.edu.pe'' AS correo_continental,
               D.GOREMAL_EMAIL_ADDRESS AS correo_personal
        FROM BANINST1.SZVALDI A
        LEFT JOIN (
            SELECT B.GOREMAL_PIDM, B.GOREMAL_EMAIL_ADDRESS
            FROM GENERAL.GOREMAL B
            INNER JOIN (
                SELECT GOREMAL_PIDM, MAX(GOREMAL_SURROGATE_ID) AS GOREMALID
                FROM GENERAL.GOREMAL
                WHERE GOREMAL_EMAL_CODE=''EPER''
                GROUP BY GOREMAL_PIDM
            ) C ON C.GOREMAL_PIDM=B.GOREMAL_PIDM 
                AND C.GOREMALID=B.GOREMAL_SURROGATE_ID
            WHERE GOREMAL_EMAL_CODE=''EPER''
        ) D ON D.GOREMAL_PIDM=A.PIDM
        LEFT JOIN SATURN.SPRTELE E 
            ON E.SPRTELE_PIDM=A.PIDM 
            AND E.SPRTELE_SEQNO=2
        WHERE A.DNI IN (' + @StudentList + ')
            AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
            AND SUBSTR(A.AREA_CODE,4,1)<>''C''  '         

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Telefono, Correo_Continental, Correo_Personal)
        SELECT DNI AS Codigo, 
               NOMBRE AS Apellidos_Nombres,
               TELEFONO,
               correo_continental AS Correo_Continental,
               correo_personal AS Correo_Personal
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales (igual al original)
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            Telefono,
            Correo_Continental,
            Correo_Personal
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