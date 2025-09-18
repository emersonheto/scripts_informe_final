USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_NotaAlumnoRecuperadoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: Muestra las notas de los alumnos que recuperaron
NRO		    FECHA		USUARIO					    MODIFICACION
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [dbo].[sp_NotaAlumnoRecuperadoFinalReportAp] 
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

        -- Tabla temporal para resultados
        CREATE TABLE #RESULTADO ( 
            Codigo VARCHAR(10),
            Apellidos_Nombres VARCHAR(200),
            Seccion_Antigua VARCHAR(20),
            Curso VARCHAR(200),
            Nota INT,
            Estado_Recuperacion VARCHAR(20)
        )

        -- Consulta dinámica simplificada
        DECLARE @OracleQuery NVARCHAR(MAX) = N'
				  WITH cursos_recuperados AS (
						SELECT 
								DNI, NOMBRE, NVL(A.STUDYPATH_BLOQUE,BLOQUE_MATRICULA) AS STUDYPATH_BLOQUE, 
							 NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO,
							 NVL(GRDE_CODE,''0'') AS GRDE_CODE, ''RECUPERADO'' AS ESTADO_RECUPERACION,
								A.FECHA_INICIO_NRC,
								A.ESTADO_ASIGNATURA,
								COUNT(A.NRC) OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB) AS total_intentos,
								ROW_NUMBER() OVER (
										PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB 
										ORDER BY A.FECHA_INICIO_NRC DESC
								) AS numero_de_intento 
						FROM BANINST1.SZVALDI A
						WHERE   
						A.DNI IN  (' + @StudentList + ')
								AND A.PROGRAM_CODE= ''' + @ProgramCode + '''
								AND SUBSTR(A.AREA_CODE,4,1) <> ''C'' 
				)	
				
				SELECT 
					DNI,NOMBRE,STUDYPATH_BLOQUE,NOMBRE_CURSO, GRDE_CODE,ESTADO_RECUPERACION -- , numero_de_intento, FECHA_INICIO_NRC
				FROM cursos_recuperados
				WHERE 
						total_intentos > 1  AND 
					 numero_de_intento <= 2
				ORDER BY  FECHA_INICIO_NRC asc  				
				'		

        DECLARE @QUERY NVARCHAR(MAX) = N'
        INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Seccion_Antigua, Curso, Nota, Estado_Recuperacion)
        SELECT DNI AS Codigo, NOMBRE AS Apellidos_Nombres, 
               STUDYPATH_BLOQUE AS Seccion_Antigua, 
               NOMBRE_CURSO AS Curso, 
               CAST(GRDE_CODE AS INT) AS Nota, 
               ESTADO_RECUPERACION
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

        EXEC sp_executesql @QUERY

        -- Resultados finales
        SELECT 
            STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
            Codigo,
            Apellidos_Nombres,
            ISNULL(Seccion_Antigua,'') AS Seccion_Antigua,
            Curso,
            Nota,
            Estado_Recuperacion
        FROM #RESULTADO 
        ORDER BY Codigo, Apellidos_Nombres

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