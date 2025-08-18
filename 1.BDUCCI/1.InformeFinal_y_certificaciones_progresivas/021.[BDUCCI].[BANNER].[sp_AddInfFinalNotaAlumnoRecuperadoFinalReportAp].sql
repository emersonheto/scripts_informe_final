USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Reporte de consolidado de notas estudiantes recuperados
====================================================================================================*/

CREATE PROCEDURE [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoFinalReportAp] 
(
    @XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @p_Tipo_Reporte INT,
    @p_user_creacion VARCHAR(200),
    @p_Accion INT,
    @p_IdDocumento VARCHAR(5),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
    	SET @p_IdDocumentoFinalReportAp = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, 'TMP000'), REPLACE(@p_user_creacion, ' ', ''))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
    	
        -- Validación de parámetros más robusta
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

        -- Crear tabla temporal para los estudiantes con clave primaria
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        -- Insertar datos del XML con validación
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;

        -- Verificar que se hayan procesado estudiantes
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron códigos de estudiante válidos en el XML proporcionado', 16, 1)
            RETURN
        END

        -- Construir lista de Students para Oracle (método compatible con versiones anteriores)
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        IF(@p_Accion=1)
        BEGIN
            DECLARE @BDOracle VARCHAR(10)='BANNER';

            -- Crear tabla temporal para resultados
            CREATE TABLE #RESULTADO ( 
                Codigo VARCHAR(10),
                Apellidos_Nombres VARCHAR(200),
                Seccion_Antigua VARCHAR(20),
                Curso VARCHAR(200),
                Nota INT,
                Estado_Recuperacion VARCHAR(20),
                Seccion_Actual VARCHAR(20),
                Programa VARCHAR(100)
            )

            -- Consulta Oracle mejor estructurada
            DECLARE @OracleQuery NVARCHAR(MAX) = N'
            WITH cursos_recuperados AS (
            SELECT 
                    DNI, NOMBRE, NVL(A.STUDYPATH_BLOQUE,'' '') AS STUDYPATH_BLOQUE, 
                    A.BLOQUE_MATRICULA AS SECCION_ACTUAL,
                    NRC||'' - ''||NOMBRE_CURSO AS NOMBRE_CURSO,
                    NVL(GRDE_CODE,''0'') AS GRDE_CODE, ''RECUPERADO'' AS ESTADO_RECUPERACION,
                    A.FECHA_INICIO_NRC,
                    A.ESTADO_ASIGNATURA,
                    A.PROGRAM_DESC AS PROGRAMA,
                    COUNT(A.NRC) OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB) AS total_intentos,
                    ROW_NUMBER() OVER (
                            PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB 
                            ORDER BY A.FECHA_INICIO_NRC ASC
                    ) AS numero_de_intento 
            FROM BANINST1.SZVALDI A
            WHERE   
            A.DNI IN  (' + @StudentList + ')
                    AND A.PROGRAM_CODE= ''' + @ProgramCode + '''
                    AND SUBSTR(A.AREA_CODE,4,1) <> ''C'' 
            )	

            SELECT 
                DNI,NOMBRE,STUDYPATH_BLOQUE,SECCION_ACTUAL,NOMBRE_CURSO, GRDE_CODE,PROGRAMA,ESTADO_RECUPERACION -- , numero_de_intento, FECHA_INICIO_NRC
            FROM cursos_recuperados
            WHERE 
                    total_intentos > 1  AND 
                    numero_de_intento <= 2
            ORDER BY  FECHA_INICIO_NRC asc  				
            '

            -- Consulta dinámica completa con INSERT
            DECLARE @QUERY NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Seccion_Antigua, Curso, Nota, Estado_Recuperacion, Seccion_Actual, Programa)
            SELECT DNI, NOMBRE, STUDYPATH_BLOQUE, NOMBRE_CURSO, GRDE_CODE, ESTADO_RECUPERACION, SECCION_ACTUAL, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')'

            EXEC sp_executesql @QUERY;

            INSERT INTO dbo.tblInfFinalConsolidadoNotasEstudiantesRecuperados (
                Seccion, No, Codigo, Apellidos_Nombres, Seccion_Origen, 
                Curso, Nota, Estado_Recuperacion, Fecha_Registro, 
                Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Programa, Programa_Codigo, IdDocumentoFinalReportAp
            )
            SELECT 
                Seccion_Actual,
                STR(ROW_NUMBER() OVER (ORDER BY Codigo)) AS 'No',  
                Codigo,
                Apellidos_Nombres,
                ISNULL(Seccion_Antigua,'') AS Seccion_Origen,
                Curso,
                Nota,
                Estado_Recuperacion,
                GETDATE() AS 'Fecha_Registro',
                NULL AS 'Fecha_Edicion',
                @p_Tipo_Reporte AS 'Tipo_Reporte',
                @p_user_creacion AS 'Usuario_Creacion',
                Programa,
                @ProgramCode,
                @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
            FROM #RESULTADO 
            ORDER BY Codigo;

            DROP TABLE #RESULTADO;
            
            SELECT 0 AS 'NRO_RESPUESTA',
                   'SE INSERTÓ CORRECTAMENTE LAS NOTAS DE ALUMNOS RECUPERADOS' AS 'MSG';
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM dbo.tblInfFinalConsolidadoNotasEstudiantesRecuperados 
            WHERE Programa_Codigo = @ProgramCode;
            
            SELECT 0 AS 'NRO_RESPUESTA',
                   'SE ELIMINÓ CORRECTAMENTE LAS NOTAS DE ALUMNOS RECUPERADOS' AS 'MSG';
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status;
    END CATCH
END

